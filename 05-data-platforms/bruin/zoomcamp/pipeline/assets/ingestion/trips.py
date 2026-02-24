"""@bruin
name: ingestion.trips
type: python  # asset type
image: python:3.11
connection: duckdb-default  # the connection

materialization:
  # `table` or `view` (ingestion generally `table`)
  type: table
  strategy: append   # appends to existing table
@bruin"""

# Example run:
# bruin run ./pipeline/assets/ingestion/trips.py \
#   --environment default \
#   --start-date 2022-01-01 \
#   --end-date 2022-02-28 \
#   --var taxi_types='["yellow"]'

import io
import json
import os
from datetime import datetime, timezone
from typing import List, Tuple

import pandas as pd
import requests
from dateutil.relativedelta import relativedelta

# NYC Taxi TLC data endpoint
BASE_URL = "https://d37ci6vzurychx.cloudfront.net/trip-data"


def generate_months_to_ingest(start_date: str, end_date: str) -> List[Tuple[int, int]]:
    """Generate a list of (year, month) tuples for each month in the date range.

    Args:
        start_date: Start date string in YYYY-MM-DD format.
        end_date: End date string in YYYY-MM-DD format.

    Returns:
        List of (year, month) tuples covering the date range.
    """
    start = datetime.strptime(start_date, "%Y-%m-%d").replace(day=1)
    end = datetime.strptime(end_date, "%Y-%m-%d")

    months = []
    current = start
    while (current.year, current.month) <= (end.year, end.month):
        months.append((current.year, current.month))
        current += relativedelta(months=1)

    return months


def build_parquet_url(taxi_type: str, year: int, month: int) -> str:
    """Build the TLC parquet file URL for a given taxi type and month.

    Args:
        taxi_type: Taxi type (e.g. 'yellow', 'green').
        year: Four-digit year.
        month: Month as integer (1-12).

    Returns:
        Full URL string to the parquet file.
    """
    filename = f"{taxi_type}_tripdata_{year}-{month:02d}.parquet"
    return f"{BASE_URL}/{filename}"


def fetch_trip_data(taxi_type: str, year: int, month: int) -> pd.DataFrame:
    """Fetch NYC taxi trip data for a given taxi type and month.

    Args:
        taxi_type: Taxi type (e.g. 'yellow', 'green').
        year: Four-digit year.
        month: Month as integer (1-12).

    Returns:
        DataFrame with raw trip data and an added 'taxi_type' column.
    """
    url = build_parquet_url(taxi_type, year, month)
    print(f"Fetching {url}")

    response = requests.get(url)
    response.raise_for_status()

    df = pd.read_parquet(io.BytesIO(response.content))
    df["taxi_type"] = taxi_type

    return df


def materialize() -> pd.DataFrame:
    """Ingest NYC taxi trip data for the Bruin run window.

    Reads BRUIN_START_DATE and BRUIN_END_DATE from environment variables,
    parses taxi_types from BRUIN_VARS, fetches one parquet file per taxi
    type per month, and returns the concatenated raw DataFrame with an
    extracted_at timestamp column for lineage tracking.
    """
    start_date = os.environ["BRUIN_START_DATE"]
    end_date = os.environ["BRUIN_END_DATE"]

    bruin_vars = json.loads(os.environ.get("BRUIN_VARS", "{}"))
    taxi_types = bruin_vars.get("taxi_types", ["yellow"])

    months = generate_months_to_ingest(start_date, end_date)

    frames = []
    for year, month in months:
        for taxi_type in taxi_types:
            df = fetch_trip_data(taxi_type, year, month)
            frames.append(df)

    result = pd.concat(frames, ignore_index=True)
    result["extracted_at"] = datetime.now(timezone.utc)

    return result

## Week 2 Homework

**`Prerequisites & Disclaimers`**:
- To avoid uploading the complete `mage-zoomcamp`-folder to Github, the relevant files for reconstructing the ETL pipeline are provided in the [src](src/)-folder
- If you want to test the code, you have to provide your own api-key / credentials, project-name, bucket-name etc.
- The `dev`-profile as seen in the Lecture 2.2.3 has to be set.  

### Assignment

The goal will be to construct an ETL pipeline that loads the data, performs some transformations, and writes the data to a database (and Google Cloud!).

#### Constructing the ETL-Pipeline:

**Data Loader - Python > API**
- Code: [green_taxi_loader.py](src/green_taxi_loader.py)
- Create a new pipeline, call it `green_taxi_etl`
- Add a data loader block and use Pandas to read data for the final quarter of 2020 (months `10`, `11`, `12`).
  - You can use the same datatypes and date parsing methods shown in the course.
  - `BONUS`: load the final three months using a for loop and `pd.concat`

```python
# Solution for the dataloader
import io
import pandas as pd
import requests
if 'data_loader' not in globals():
    from mage_ai.data_preparation.decorators import data_loader
if 'test' not in globals():
    from mage_ai.data_preparation.decorators import test


@data_loader
def load_data_from_api(*args, **kwargs) -> pd.DataFrame:
    """
    Template for loading data from API
    """

    taxi_dtypes = {
        'VendorID': pd.Int64Dtype(),
        'passenger_count': pd.Int64Dtype(),
        'trip_distance': float,
        'RatecodeID': pd.Int64Dtype(),
        'store_and_fwd_flag': str,
        'PULocationID': pd.Int64Dtype(),
        'DOLocationID': pd.Int64Dtype(),
        'payment_type': pd.Int64Dtype(),
        'fare_amount': float,
        'extra': float,
        'mta_tax': float,
        'tip_amount': float,
        'tolls_amount': float,
        'improvement_surcharge': float,
        'total_amount': float,
        'congestion_surcharge': float
    }

    parse_dates = ["lpep_pickup_datetime", "lpep_dropoff_datetime"]

    year = 2020
    months = [10, 11, 12]
    dfs = []

    for m in months:
        url = f"https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_{year}-{m:02}.csv.gz"
        response = requests.get(url)
        if response.status_code == 200:
            df_month = pd.read_csv(
                url, sep=",", compression="gzip",
                dtype=taxi_dtypes,
                parse_dates=parse_dates
            )
            dfs.append(df_month)

    df = pd.concat(dfs, ignore_index=True)
    return df

@test
def test_output(output, *args) -> None:
    """
    Template code for testing the output of the block.
    """
    assert output is not None, 'The output is undefined'

```

**Transformer - Python (Generic)**:
- Code: [green_taxi_cleaner.py](src/green_taxi_cleaner.py)
- Add a transformer block and perform the following:
  - Remove rows where the passenger count is equal to 0 _or_ the trip distance is equal to zero.
  - Create a new column `lpep_pickup_date` by converting `lpep_pickup_datetime` to a date.
  - Rename columns in Camel Case to Snake Case, e.g. `VendorID` to `vendor_id`.
  - Add three assertions:
    - `vendor_id` is one of the existing values in the columns (currently)
    - `passenger_count` is greater than 0
    - `trip_distance` is greater than 0

```python
# Solution for the transformer
if 'transformer' not in globals():
    from mage_ai.data_preparation.decorators import transformer
if 'test' not in globals():
    from mage_ai.data_preparation.decorators import test


@transformer
def transform(data, *args, **kwargs):
    ## Removing "bad" data

    # Removing rows where passenger count is 0
    passenger_filter = data["passenger_count"] > 0
    # Removing rows where trip-distance is 0
    distance_filter = data["trip_distance"] > 0

    data = data[passenger_filter & distance_filter]

    ## Creating a date-column that can be used 
    ## for slitting transformer outputs
    data["lpep_pickup_date"] = data["lpep_pickup_datetime"].dt.date

    ## CamelCase to Snake_Case
    cc2sc = {
        "VendorID": "vendor_id",
        "RatecodeID": "ratecode_id",
        "PULocationID": "pu_location_id",
        "DOLocationID": "do_location_id",
    }
    data.rename(columns=cc2sc, inplace=True)

    return data

@test
def test_output(output, *args) -> None:
    """
    Template code for testing the output of the block.
    """
    assert output is not None, 'The output is undefined'

@test
def test_vendor_id(output, *args) -> None:
    """
    Check if `vendor_id` is in dataframe
    """
    assert "vendor_id" in output

@test
def test_passenger_count(output, *args) -> None:
    """
    Check if there are no 0-passenger trips (all > 0)
    """
    assert (output['passenger_count'] > 0).all()

@test
def test_trip_distance(output, *args) -> None:
    """
    Check if there are no 0-distance trips (all > 0)
    """
    assert (output['trip_distance'] > 0).all()
```

**Data exporter (Python > PostgreSQL)**:
- Code: [green_taxi_postgres_exporter.py](src/green_taxi_postgres_exporter.py)
- Using a Postgres data exporter (SQL or Python), write the dataset to a table called `green_taxi` in a schema `mage`. Replace the table if it already exists.

```python
# Solution for Postgres data exporter (Python)
from mage_ai.settings.repo import get_repo_path
from mage_ai.io.config import ConfigFileLoader
from mage_ai.io.postgres import Postgres
from pandas import DataFrame
from os import path

if 'data_exporter' not in globals():
    from mage_ai.data_preparation.decorators import data_exporter


@data_exporter
def export_data_to_postgres(df: DataFrame, **kwargs) -> None:

    schema_name = 'mage'  # Specify the name of the schema to export data to
    table_name = 'green_taxi'  # Specify the name of the table to export data to
    config_path = path.join(get_repo_path(), 'io_config.yaml')
    config_profile = 'dev'

    with Postgres.with_config(ConfigFileLoader(config_path, config_profile)) as loader:
        loader.export(
            df,
            schema_name,
            table_name,
            index=False,  # Specifies whether to include index in exported table
            if_exists='replace',  # Specify resolution policy if table name already exists
        )

```

**Data exporter (Python > GoogleCloudStorage)**:
- Code: [green_taxi2gcs_partitioned.py](src/green_taxi2gcs_partitioned.py)
- Write your data as Parquet files to a bucket in GCP, partioned by `lpep_pickup_date`. Use the `pyarrow` library!
```python
import os
import pyarrow as pa
import pyarrow.parquet as pq

if 'data_exporter' not in globals():
    from mage_ai.data_preparation.decorators import data_exporter


os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "path/to/credentials.json"

bucket_name = "bucket-name"
project_id = "project-id"
table_name = "green_taxi"
root_path = f"{bucket_name}/{table_name}"

@data_exporter
def export_data(data, *args, **kwargs):
    table = pa.Table.from_pandas(data)
    gcs = pa.fs.GcsFileSystem()

    pq.write_to_dataset(
        table,
        root_path=root_path,
        partition_cols=["lpep_pickup_date"],
        filesystem=gcs
    )
```

- Schedule your pipeline to run daily at 5AM UTC.

- **Relevant parameters for the solution**:
    - `Trigger name`: Daily 5AM green-taxi runner
    - `Trigger description`: Runs the pipeline every morning at 5 AM UTC
    - `Cron expression`: _0 5 * * *_
    - `Frequency`: Custom


### Questions

## Question 1. Data Loading

Once the dataset is loaded, what's the shape of the data?

* 266,855 rows x 20 columns
* 544,898 rows x 18 columns
* 544,898 rows x 20 columns
* 133,744 rows x 20 columns

**Answer**: 
- 266,855 rows x 20 columns
- Code used: `df.shape`

## Question 2. Data Transformation

Upon filtering the dataset where the passenger count is greater than 0 _and_ the trip distance is greater than zero, how many rows are left?

* 544,897 rows
* 266,855 rows
* 139,370 rows
* 266,856 rows

**Answer**:
- 139,370 rows
- Code used: `data.shape[0]`

## Question 3. Data Transformation

Which of the following creates a new column `lpep_pickup_date` by converting `lpep_pickup_datetime` to a date?

* `data = data['lpep_pickup_datetime'].date`
* `data('lpep_pickup_date') = data['lpep_pickup_datetime'].date`
* `data['lpep_pickup_date'] = data['lpep_pickup_datetime'].dt.date`
* `data['lpep_pickup_date'] = data['lpep_pickup_datetime'].dt().date()`

**Answer**:
```python
data["lpep_pickup_date"] = data["lpep_pickup_datetime"].dt.date
```

## Question 4. Data Transformation

What are the existing values of `VendorID` in the dataset?

* 1, 2, or 3
* 1 or 2
* 1, 2, 3, 4
* 1

**Answer**: 
- `1 or 2`
- Code used in transformer-block: `data["vendor_id"].unique()`

## Question 5. Data Transformation

Ho many columns need to be renamed to snake case?

* 3
* 6
* 2
* 4

**Answer**: 4
- `VendorID` $\rightarrow$ `vendor_id`
- `RatecodeID` $\rightarrow$ `Ratecode_id`
- `PULocationID` $\rightarrow$ `pu_location_id`
- `DOLocationID` $\rightarrow$ `do_location_id`

## Question 6. Data Exporting

Once exported, how many partitions (folders) are present in Google Cloud?

* 96
* 56
* 67
* 108

**Answer**: 96

## Submitting the solutions

* Form for submitting: https://courses.datatalks.club/de-zoomcamp-2024/homework/hw2
* Check the link above to see the due date
  
## Solution

Will be added after the due date
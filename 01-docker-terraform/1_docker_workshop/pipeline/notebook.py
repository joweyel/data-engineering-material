#!/usr/bin/env python
# coding: utf-8

import os
import math
import json
import pandas as pd
from tqdm.auto import tqdm
from sqlalchemy import create_engine


dtype = {
    "VendorID": "Int64",
    "passenger_count": "Int64",
    "trip_distance": "float64",
    "RatecodeID": "Int64",
    "store_and_fwd_flag": "string",
    "PULocationID": "Int64",
    "DOLocationID": "Int64",
    "payment_type": "Int64",
    "fare_amount": "float64",
    "extra": "float64",
    "mta_tax": "float64",
    "tip_amount": "float64",
    "tolls_amount": "float64",
    "improvement_surcharge": "float64",
    "total_amount": "float64",
    "congestion_surcharge": "float64"
}

parse_dates = [
    "tpep_pickup_datetime",
    "tpep_dropoff_datetime"
]

def ingest_data(
    url: str,
    engine,
    target_table: str,
    chunksize: int = 100_000
) -> pd.DataFrame:

    df_iter = pd.read_csv(
        url,
        dtype=dtype,
        parse_dates=parse_dates,
        iterator=True,
        chunksize=chunksize
    )
    
    # Get first chunk for creating table
    first_chunk = next(df_iter)
    
    # Create table with no entrie
    first_chunk.head(0).to_sql(
        name=target_table,
        con=engine,
        if_exists="replace"
    )
    
    print(f"Table {target_table} created")
    
    first_chunk.to_sql(
        name=target_table,
        con=engine,
        if_exists="append"
    )
    
    print(f"Inserted first chunk: {len(first_chunk)}")
    
    for df_chunk in tqdm(df_iter):
        df_chunk.to_sql(
            name=target_table,
            con=engine,
            if_exists="append"
        )
        print(f"Inserted chunk: {len(df_chunk)}")
    
    print(f"Done ingesting: {target_table}")
    
    
def main():
    try:
        with open("ingestion_config.json", "r") as json_file:
            data = json.load(json_file)
    except Exception as e:
        print("Data Loading Error: ", e)
        return
    
    pg_user = data["pg_user"]
    pg_pass = data["pg_pass"]
    pg_host = data["pg_host"]
    pg_port = data["pg_port"]
    pg_db = data["pg_db"]
    year = data["year"]
    month = data["month"]
    chunksize = data["chunksize"]
    target_table = data["target_table"]
    
    engine = create_engine(f"postgresql://{pg_user}:{pg_pass}@{pg_host}:{pg_port}/{pg_db}")
    utl_prefix = "https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow"
    filename = f"yellow_tripdata_{year:04d}-{month:02d}.csv.gz"
    url = f"{utl_prefix}/{filename}"
    
    ingest_data(
        url if not os.path.exists(filename) else filename,
        engine=engine,
        target_table=target_table,
        chunksize=chunksize
    )
    
if __name__ == "__main__":
    main()
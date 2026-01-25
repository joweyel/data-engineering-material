#!/usr/bin/env python
# coding: utf-8

import os
import pandas as pd
import click
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
    url_zones: str,
    engine,
    target_table: str,
    chunksize: int = 100_000,
) -> pd.DataFrame:


    # Zones Lookup-Table
    df_zones = pd.read_csv(url_zones)
    df_zones.to_sql(
        name="zones", 
        con=engine, 
        if_exists="replace"
    )
    print(f"Table 'zones' created")

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
    
    print(f"Table '{target_table}' created")
    
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
    
    
@click.command()
@click.option("--pg-user", required=True, help="PostgreSQL username")
@click.option("--pg-pass", required=True, help="PostgreSQL password")
@click.option("--pg-host", required=True, help="PostgreSQL host")
@click.option("--pg-port", required=True, type=int, help="PostgreSQL port")
@click.option("--pg-db", required=True, help="PostgreSQL database name")
@click.option("--year", required=True, type=int, help="Year of taxi data")
@click.option("--month", required=True, type=int, help="Month of taxi data")
@click.option("--chunksize", default=100000, type=int, help="Chunk size for ingestion")
@click.option("--target-table", required=True, help="Target table name in database")
def run(pg_user, pg_pass, pg_host, pg_port, pg_db, year, month, chunksize, target_table):
    engine = create_engine(f"postgresql://{pg_user}:{pg_pass}@{pg_host}:{pg_port}/{pg_db}")
    
    url_prefix = "https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow"
    filename = f"yellow_tripdata_{year:04d}-{month:02d}.csv.gz"
    url = f"{url_prefix}/{filename}"
    
    zones_filename = "taxi+_zone_lookup.csv"
    url_zones = f"https://d37ci6vzurychx.cloudfront.net/misc/{zones_filename}"
    

    ingest_data(
        url if not os.path.exists(filename) else filename,
        url_zones if not os.path.exists(zones_filename) else zones_filename,
        engine=engine,
        target_table=target_table,
        chunksize=chunksize,
    )


if __name__ == "__main__":
    run()
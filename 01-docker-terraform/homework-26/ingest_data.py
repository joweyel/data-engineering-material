import os
from time import time
import pandas as pd
import click
import numpy as np
from sqlalchemy import create_engine
import pyarrow.parquet as pq


def ingest_data(
    user: str, 
    password: str, 
    host: str, 
    port: int, 
    db: str, 
    tb: str, 
    url: str,
):    
    filename = url.split("/")[-1]
    os.system(f"wget -c {url} -O {filename}")
    engine = create_engine(f"postgresql://{user}:{password}@{host}:{port}/{db}")
    
    if filename.endswith(".parquet"):
        pq_file = pq.ParquetFile(filename)
        df = next(pq_file.iter_batches(batch_size=10)).to_pandas()
        df_iter = pq_file.iter_batches(batch_size=100000)
    elif filename.endswith(".csv"):
        df = pd.read_csv(filename, nrows=10)
        df_iter = pd.read_csv(filename, iterator=True, chunksize=100000)
    else:
        raise ValueError(f"Unknown file type [{filename.split('.')[-1]}]")
        
    # Create the table
    df.head(0).to_sql(name=tb, con=engine, if_exists="replace")
    
    # Ingest data into database
    count = 0
    t_start = time()
    for batch in df_iter:
        count += 1
        
        if filename.endswith(".parquet"):
            batch_df = batch.to_pandas()
        else:
            batch_df = batch
        print(f"Inserting batch: {count}")

        batch_df.to_sql(name=tb, con=engine, if_exists="append")

    t_end = time()
    print(f"inserted! time taken {t_end - t_start:10.3f} seconds.\n")
    

@click.command()
@click.option("--user", required=True, help="PostgreSQL username")
@click.option("--password", required=True, help="PostgreSQL password")
@click.option("--host", required=True, help="PostgreSQL host")
@click.option("--port", required=True, type=int, help="PostgreSQL port")
@click.option("--db", required=True, help="PostgreSQL database name")
@click.option("--tb", required=True, help="Destination table name for Postgres")
@click.option("--url", required=True, help="URL for .paraquet file")
def run(user, password, host, port, db, tb, url):
    ingest_data(user, password, host, port, db, tb, url)

if __name__ == "__main__":
    run()
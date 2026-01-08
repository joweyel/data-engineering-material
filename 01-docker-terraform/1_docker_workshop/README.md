# Module 1: Containerization and Infrastructure as Code

## Instroduction to Docker

- Docker allows to run software in isolated containers where all relevant dependencies are installed
- Why should we care about Docker?
    - Reproducibility of environments
    - Allows local experiments in isolation
    - Integrations Tests (CI/CD)
    - Running Pipelines on the cloud (AWS Batch, Kubernetes jobs, ... )
    - Spark (for Datapipelines)
    - Serversless (AWS Lambda, Google functions, ...)

Installation instructions for Docker can be found here: https://docs.docker.com/get-docker/ 

After installation you can test if docker is correctly installed with some test-commands:

```bash
# Basic example script for verification of installation
docker run hello-world
```

Run a Python container:
```bash
docker run -it --rm --entrypoint bash python:3.13.11-slim
```
- `run`: creates docker container and starts it
- `-it`: interactive (`-i`) + tty-mode (`-t`)
- `--rm`: Removes created container after closing
  - Without this there will be new container created every time the `docker run` command is called
  - Creates and deletes new docker container every time the command is called
- `--entrypoint`: Program that is executed when entering the container (here: opens  `bash`)
- `python:3.13.11-slim`:
  - `python`: Docker image name
  - `3.13.11-slim`: Tag for specific version of docker image


So, we know that with docker we can restore any container to it's initial state in a reproducible manner. But what about data? A common way to do so is with volumes.

Let's create some data in test:

```bash
mkdir test
cd test
touch file1.txt file2.txt file3.txt
echo "Hello from host" > file1.txt
cd ..
```

Now let's create a simple script [`test/list_files.py`](test/list_files.pyV) that shows the files in the folder:

```bash
from pathlib import Path

current_dir = Path.cwd()
current_file = Path(__file__).name

print(f"Files in {current_dir}:")

for filepath in current_dir.iterdir():
    if filepath.name == current_file:
        continue

    print(f"  - {filepath.name}")

    if filepath.is_file():
        content = filepath.read_text(encoding='utf-8')
        print(f"    Content: {content}")
```

To make content of a specific directory available to the container you can mount the folder like this:
```bash
# Important: Must be in the folder where "test/" is located at
docker run -it \
    --rm \
    -v $(pwd)/test:/app/test \
    --entrypoint=bash \
    python:3.13.11-slim
```

Inside the container, run:
```bash
cd /app/test
ls -la
cat file1.txt
python list_files.py
```


## Data Pipelines

A data pipeline is a service that receives data as input and outputs more data. For example, reading a file with data, transforming the data somehow and storing it as a table in a PostgreSQL database or some other data storage offline or online in the cloud.

```mermaid
graph LR
    A[CSV File] --> B[Data Pipeline]
    B --> C[Parquet File]
    B --> D[PostgreSQL Database]
    B --> E[Data Warehouse]
    style B fill:#4CAF50,stroke:#333,stroke-width:2px,color:#fff
```

In this workshop, we'll build pipelines that:

- Download CSV data from the web
- Transform and clean the data with pandas
- Load it into PostgreSQL for querying
- Process data in chunks to handle large files

Create the directory [`pipeline/`](./pipeline) and create a script with the same name [`pipeline.py`](pipeline/pipeline.py)

```bash
mkdir -p pipeline
touch pipeline/pipeline.py
```

```python
# pipeline.py

import sys
import pandas as pd

print('arguments', sys.argv)

month = int(sys.argv[1])

# Pandas Dataframe with columns "day" and "num_passengers"
df = pd.DataFrame({"day": [1, 2], "num_passengers": [3, 4]})
df['month'] = month
print(df.head())

# Saves to parquet file
df.to_parquet(f"output_{month}.parquet")

print(f'hello pipeline, month={month}')
```

To use this script, the package `pandas` has to be installed. For this a virtual environment tool called `uv` is used:

```bash
pip install uv
```

Call the following command:
```bash
uv init --python 3.13
```
This command created a bunch of files that can be used to configure the python project.



This should reult in 
```
Initialized project `pipeline`
```

Check python version in the uv-environment:
```bash
uv run python -V 
# Using CPython 3.13.5
# Creating virtual environment at: .venv
# Python 3.13.5
```

Install additional package with uv (inside the directory where `uv init` was called):
```bash
uv add pandas pyarrow
```

uv automatically adds all dependencies to the [`pyproject.toml`](pipeline/pyproject.toml)
```toml
[project]
name = "pipeline"
version = "0.1.0"
description = "Add your description here"
readme = "README.md"
requires-python = ">=3.13"
dependencies = [
    "pandas>=2.3.3",
    "pyarrow>=22.0.0",
]
```

Calling the script.
```bash
uv run python3 pipeline.py 12
# arguments ['pipeline.py', '12']
#    day  num_passengers  month
# 0    1               3     12
# 1    2               4     12
# hello pipeline, month=12
```

### Dockerfile for creating your own custom image

- **Source**: [`Dockerfile`](pipeline/Dockerfile)

<details>

<summary><b>Dockerfile</b></summary>

```Dockerfile
FROM python:3.13.11-slim

# Copy from existing Docker image the folder /uv to /bin
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin

# Setting workdirectory 
WORKDIR /code

# Puts uv's python binary in path (no `uv run` needed in entrypoint)
ENV PATH="/code/.venv/bin:$PATH"

COPY pyproject.toml .python-version uv.lock ./

# Install dependencies specified in uv.lock files
RUN uv sync --locked


# Copy file into container
COPY pipeline.py .

# Executes this command upon entering container
ENTRYPOINT [ "python3", "pipeline.py" ]
```

</details>


To create the image use:
```bash
docker build -t test:pandas .
```
- `-t` for setting image identifier / tag
- `test:pandas`: name and tag of new docker image
- `.`: context is current folder `.` (where to look for Docker Image definititon / Dockerfile)


## Running PostgreSQL with Docker

- Dockerized version of PostgreSQL does not require installation, since it is created with Dockerfile / obtained from image
- Only requires environment-variables as well as a volume for storing data

Example for running PostgreSQL in Docker container:

```bash
docker run -it --rm \
    -e POSTGRES_USER="root" \
    -e POSTGRES_PASSWORD="root" \
    -e POSTGRES_DB="ny_taxi" \
    -v ny_taxi_postgres_data:/var/lib/postgresql \
    -p 5432:5432 \
    postgres:18
```

Setting environement variables with `-e`:

- `-e POSTGRES_USER="root"`
- `-e POSTGRES_PASSWORD="root"`
- `-e POSTGRES_DB="ny_taxi"`

Create docker-volume `ny_taxi_postgres_data` with `-v ny_taxi_postgres_data:/var/lib/postgresql`:
- Is persistent (not ephemoral) where data is saved to
- Different from mounting a folder, where the folder path has to be provided

Port-Mapping with `-p 5432:5432`:
- Maps container-internal port 5432 (default PostgreSQL port) to the outside of the container also at port 5432
- PostgreSQL is accessessible on host at http://localhost:5432

After the container was pulled and has started the database is ready to be used. For accessing the database with Python the tool `pgcli` can be used and installed with `uv`:

```bash
uv add --dev pgcli
```
The `--dev` flag specifies that the installed dependency is a "developement" dependency and not "production" dependency. In the final deployment the cli-tool `pgcli` for postgres will not be used, since it is mostly required for accessing a database via the cli.

Futhermore, to finally connect to the running PostgreSQL Docker container you have to use the commmand here:
```bash
uv run pgcli -h localhost -p 5432 -u root -d ny_taxi
```
- `-h`: Host-URL -> Here localhost
- `-p 5432`: Port of postgres DB
- `-u root`: DB username
- `-d ny_taxi` : DB name

Use `\dt` for listing all tables in the `ny_taxi` database. Then create a new table `test`:

```sql
CREATE TABLE test (id INTEGER, name VARCHAR(50));
```

Now the new (empty) table can be queried:
```sql
SELECT * FROM test;
```

Result:
```
+----+------+
| id | name |
|----+------|
+----+------+
SELECT 0
Time: 0.009s
```

Insert data, show data and close the cli tool:
```sql
INSERT INTO test VALUES(1, 'Hello Docker');

SELECT * FROM test;

\q
```

Output:
```bash
root@localhost:ny_taxi> INSERT INTO test VALUES(1, 'Hello Docker');
 
INSERT 0 1
Time: 0.006s
root@localhost:ny_taxi> SELECT * FROM test;
 
+----+--------------+
| id | name         |
|----+--------------|
| 1  | Hello Docker |
+----+--------------+
SELECT 1
Time: 0.008s
```

## Using Jupyter Notebooks for Python code

Jupyter is interactive environment wher python code can be executed in blocks. It is alos possible to use text cells that follow markdown-formatting rules.

Installing jupyter:
```bash
uv add --dev jupyter 
```

Start jupyter notebook:
```bash
uv run jupyter notebook
```

On your local computer this command will open a new tab in the browser. In codespaces a port will be forwarded that you can see in the Ports tab of the VS Code instance on Github.

### Create Notebook

- Loading csv is more work than loading parquet
  - Parquet has already a pre-defined data-schedma but csv does not

- `[File]` > `[New]` > `[Notebook]`
- Rename to notebook
- All further explanations are in the notebook
- The notebook: [`notebook.ipynb`](pipeline/notebook.ipynb)

### Ingesting Data into Postgres

Steps in the Jupyter Notebook:

1. Download the CSV file
2. Read dataframe in chunks with `pandas`
3. Convert datetime columns
4. Insert data into PostgreSQL using `SQLAlchemy`

Install `SQLAlchemy`:
```bash
uv add sqlalchemy psycopg2-binary
```

See section "**Connect to Postgres DB with `SQLAlchemy`**" in [`notebook.ipynb`](pipeline/notebook.ipynb)

## Using Docker-Container for Data-Ingestion

The next step after ingesting the data to the dockerized pg-database is to create a python script from the notebook. Scripts are much better suited to be used in data pipelines.

```bash
uv run jupyter nbconvert --to=script notebook.ipynb
```

After cleaning up the notebook and renaming + some additions you get the [`ingest_data.py`](pipeline/ingest_data.py) file:

<details>

<summary><b>ingest_data.py</b></summary>

```python
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
    
    
@click.command()
@click.option("--pg_user", required=True, help="PostgreSQL username")
@click.option("--pg_pass", required=True, help="PostgreSQL password")
@click.option("--pg_host", required=True, help="PostgreSQL host")
@click.option("--pg_port", required=True, type=int, help="PostgreSQL port")
@click.option("--pg_db", required=True, help="PostgreSQL database name")
@click.option("--year", required=True, type=int, help="Year of taxi data")
@click.option("--month", required=True, type=int, help="Month of taxi data")
@click.option("--chunksize", default=100000, type=int, help="Chunk size for ingestion")
@click.option("--target_table", required=True, help="Target table name in database")
def run(pg_user, pg_pass, pg_host, pg_port, pg_db, year, month, chunksize, target_table):
    engine = create_engine(f"postgresql://{pg_user}:{pg_pass}@{pg_host}:{pg_port}/{pg_db}")
    url_prefix = "https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow"
    filename = f"yellow_tripdata_{year:04d}-{month:02d}.csv.gz"
    url = f"{url_prefix}/{filename}"

    ingest_data(
        url if not os.path.exists(filename) else filename,
        engine=engine,
        target_table=target_table,
        chunksize=chunksize
    )


if __name__ == "__main__":
    run()
```

</details>

Install `click` with **uv**:
```bash
uv add click
```


The script can be callsed for example with this:

```bash
uv run python ingest_data.py \
    --pg_user root \
    --pg_pass root \
    --pg_host localhost \
    --pg_port 5432 \
    --pg_db ny_taxi \
    --year 2021 \
    --month 1 \
    --chunksize 100000 \
    --target_table yellow_taxi_data
```

Check the postgres db with `pgcli`:
```bash
uv run pgcli -h localhost -p 5432 -u root -d ny_taxi
```

```
root@localhost:ny_taxi> \dt
+--------+------------------+-------+-------+
| Schema | Name             | Type  | Owner |
|--------+------------------+-------+-------|
| public | test             | table | root  |
| public | yellow_taxi_data | table | root  |
+--------+------------------+-------+-------+
SELECT 2
Time: 0.020s
root@localhost:ny_taxi> SELECT COUNT(1) FROM yellow_taxi_data;
+---------+
| count   |
|---------|
| 1369765 |
+---------+
SELECT 1
Time: 0.099s
root@localhost:ny_taxi>
```

The ingest script until now ran with uv, however also the ingest script should be dockerized for much better portability. For this a new docker container is created:

```bash
docker build -t taxi_ingest:v001 .
```

Run the container for data-ingestion:
```bash
docker run -it --rm \
  taxi_ingest:v001 \
    --pg-user=root \
    --pg-pass=root \
    --pg-host=localhost \
    --pg-port=5432 \
    --pg-db=ny_taxi \
    --target-table=yellow_taxi_trips_2021_1 \
    --year 2021 \
    --month 1 \
    --chunksize=100000
```

This will fail, since the ingestion container cant connet to the same localhost where the data is stores. For this a docker network is needed. 

Create docker network:
```bash
docker network create pg-network
```
This network can now be specified in docker run command and connecect all container that use the same network. The new versions of the docker commands are as follows:

```bash
docker run -it --rm \
    -e POSTGRES_USER="root" \
    -e POSTGRES_PASSWORD="root" \
    -e POSTGRES_DB="ny_taxi" \
    -v ny_taxi_postgres_data:/var/lib/postgresql \
    -p 5432:5432 \
    --network=pg-network \
    --name pgdatabase \
    postgres:18
```

```bash
docker run -it --rm \
  --network=pg-network \
  taxi_ingest:v001 \
    --pg-user=root \
    --pg-pass=root \
    --pg-host=pgdatabase \
    --pg-port=5432 \
    --pg-db=ny_taxi \
    --target-table=yellow_taxi_trips_2021_1 \
    --year 2021 \
    --month 1 \
    --chunksize=100000
```
The `taxi_ingest` container will now connect to the docker container **`pgdatabase`** that is visible inside the docker network `pg-network`.


### pgAdmin as Graphical Database UI

For a proper ui for interacting with the database the program **`pgAdmin`** is used:

```bash
docker run -it \
  -e PGADMIN_DEFAULT_EMAIL="admin@admin.com" \
  -e PGADMIN_DEFAULT_PASSWORD="root" \
  -v pgadmin_data:/var/lib/pgadmin \
  -p 8085:80 \
  --network=pg-network \
  --name pgadmin \
  dpage/pgadmin4
```

This creates but does not delete the container after creation. The container can be "re-started" with (this should take a shiort while):
```bash
docker start pgadmin
```

Open pgadmin ui at http://localhost:8085


In pgAdmin

- Create a server in pgadmin
- Connect to db with credentials
- Open Query Tool

```sql
-- Test code
SELECT
	*
FROM
	public.yellow_taxi_trips_2021_1
LIMIT
	10;
```

### Docker-Compose

- Starts multiple docker container with one command
- Can handle configuration with a single file but still references Images / Dockerfiles of used container


<details>

<summary><b>docker-compose.yaml</b></summary>

```yml
---
```
<details>

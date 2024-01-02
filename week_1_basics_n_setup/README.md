# Module 1: Introduction & Prerequisites

- Course overview
- Introduction to GCP
- Docker and docker-compose
- Running Postgres locally with Docker
- Setting up infrastructure on GCP with Terraform
- Preparing the environment for the course
- Homework

## 1.2.1 Introduction to Docker

- Docker allows to run software in isolated containers where all relevant dependencies are installed
- Why should we care about Docker?
    - Reproducibility of environments
    - Allows local experiments in isolation
    - Integrations Tests (CI/CD)
    - Running Pipelines on the cloud (AWS Batch, Kubernetes jobs, ... )
    - Spark (for Datapipelines)
    - Serversless (AWS Lambda, Google functions, ...)

- **Relevance for Data-Engineering**: Isolate a data-pipeline, that processes input-data, in a docker container
    - Input: csv-file
    - Output: Postgres-database

Installation instructions for Docker can be found here: https://docs.docker.com/get-docker/ 

After installation you can test if docker is correctly installed with some test-commands:
```bash
# Basic example script for verification of installation
docker run hello-world

# Obtaining an Ubuntu image and enter it (into bash)
docker run -it ubuntu bash

# Obtaining an Python image and enter it (into python-console)
docker run python:3.9
``` 

For the use-case of Data Engineering often Python-container are used. To be utilized such containers need to have required dependencies to be installed. This can be easily done by entering the python-container with into the bash. Installation is then done with pip.

```bash
# Enter container
docker run -it --entrypoint=bash python:3.9
# install dependency
pip install pandas 
```

Checking if all worked out correct (`python`):
```python
import pandas as pd
print(pd.__version__)
```

After leaving the docker-container all changes will be lost and the "original" image will be used to instantiate a container. To create a customer container with all the relevant components, the usage of Dockerfiles is advised. 

### Creating a Dockerfile
- Used to build a docker container (everything needed will be specified there)

A "dummy" data-pipeline is put into the container:
```python
import sys
import pandas as pd

print(sys.argv)

day = sys.argv[1]

# Some processing!

print(f"Job finished successfully for day = {day}")
```

The used [Dockerfile](1_docker_sql/Dockerfile):
```Dockerfile
FROM python:3.9.1

# Installing pandas in the container
RUN pip install pandas

# Changing working directory + copying the pipeline
WORKDIR /app
COPY pipeline.py pipeline.py

# Enter container into bash by default
ENTRYPOINT [ "python", "pipeline.py" ]
```

Building the container with:
```bash
docker build -t test:pandas .
```

Running the container:
```bash
docker run -it test:pandas 2024-01-01
```

Output:
```txt
Job finished successfully for day = 2024-01-01
```

## 1.2.2 - Ingesting NY Taxi Data to Postgres

The first step is to create a docker-container that uses Postgres.
```bash
docker run -it \
    -e POSTGRES_USER="root" \
    -e POSTGRES_PASSWORD="root" \
    -e POSTGRES_DB="ny_taxi" \
    -v $(pwd)/ny_taxi_postgres_data:/var/lib/postgresql/data \
    -p 5432:5432 \
    postgres:13
```

In another terminal the database will now be accessed. For this the python-package `pgcli` needs to be insrtalled (globally or in specific environment for the course):
```bash
pip install pgcli
```

To finally connect to the database, the following command is used:
```bash
pgcli -h localhost -p 5432 -u root -d ny_taxi
```

You are now insid the container, but there are no Databases yet!
```bash
root@localhost:ny_taxi> \dt # lists databases
+--------+------+------+-------+
| Schema | Name | Type | Owner |
|--------+------+------+-------|
+--------+------+------+-------+
SELECT 0
Time: 0.018s
```

To put the dataset into the container, [this](upload-data.ipynb) Jupyter Notebook will be used (can also be done with python-scripts etc.).

After executing the code in the notebook the result is:
```bash
root@localhost:ny_taxi> \dt
+--------+------------------+-------+-------+
| Schema | Name             | Type  | Owner |
|--------+------------------+-------+-------|
| public | yellow_taxi_data | table | root  |
+--------+------------------+-------+-------+
SELECT 1
Time: 0.014s
```


## 1.2.3 - Connecting pgAdmin and Postgres
Now that the data is put into the database, you can play arount a little bit with the data.

Example:
```SQL
SELECT 
    max(tpep_pickup_datetime), 
    min(tpep_dropoff_datetime), 
    max(total_amount) 
FROM 
    yellow_taxi_data;
```

Output:
```bash
+---------------------+---------------------+---------+
| max                 | min                 | max     |
|---------------------+---------------------+---------|
| 2021-02-22 16:52:16 | 2008-12-31 23:07:22 | 7661.28 |
+---------------------+---------------------+---------+
SELECT 1
Time: 0.239s
```

With the query above you get:
- The latest pickuptime was in February 2021
- The earliest pickuptime was in December 2008
- The highest amount paid was about $7661

This works, but it would be better to have a GUI to access the database. For this purpose [pgAdmin](https://www.pgadmin.org/download/pgadmin-4-container/) for is used with docker.

The docker-image for [`pgAdmin4`](https://hub.docker.com/r/dpage/pgadmin4/) will be used for building the required container:

```bash
docker run -it \
    -e PGADMIN_DEFAULT_EMAIL="admin@admin.com" \
    -e PGADMIN_DEFAULT_PASSWORD="root" \
    -p 8080:80 \
    dpage/pgadmin4
```

After everything is set up, the Web-GUI of `pgAdmin` is available at [http://localhost:8080](https://localhost:8080). For the login, the credentials are used that were specified during `docker run`.

Steps for setting up the Web-Version of pgAdmin locally:
1. `Create new server`: Rightclick on [Servers], then register new server
2. `General`: Name the server "Local docker"
3. `Connection`: Set hostname to "localhost", set Username to "root"

This configurations fails initially, since `pgAdmin` looks for `postgres` inside the `pgAdmin` docker-container and not the `postgres` docker-container. To remedy this problem, a [network](https://docs.docker.com/engine/reference/commandline/network_create/) between the 2 container has to be established!

Creating a network + connecting the docker-container:
```bash
docker network create pg-network

docker run -it \
    -e POSTGRES_USER="root" \
    -e POSTGRES_PASSWORD="root" \
    -e POSTGRES_DB="ny_taxi" \
    -v $(pwd)/ny_taxi_postgres_data:/var/lib/postgresql/data \
    -p 5432:5432 \
    --network=pg-network \
    --name pg-database \
    postgres:13
```

It is important to check if the data is still present in the database. For open the postgres-client and execute some query:

```bash
pgcli -h localhost -p 5432 -u root -d ny_taxi
```

Now check if all rows are still present in the database:
```sql
SELECT COUNT(1) FROM yellow_taxi_data;
```

Output:
```bash
+---------+
| count   |
|---------|
| 1369765 |
+---------+
SELECT 1
Time: 0.198s
```

Now that the postgres-database is present in the network, the pgAdmin has to be put in this network aswell:

```bash
docker run -it \
    -e PGADMIN_DEFAULT_EMAIL="admin@admin.com" \
    -e PGADMIN_DEFAULT_PASSWORD="root" \
    -p 8080:80 \
    --network=pg-network \
    --name pgadmin \
    dpage/pgadmin4
```

With both database and pgAdmin running in the same network you can reopen [http://localhost:8080](http://localhost:8080) and create a Server:
1. `General`: Name the server "Docker localhost"
2. `Connection`: set Host name/address to "pg-database" + set username and password to "root" (as specified before)


After saving the configuration the database from the postgres-container will be available:
![pgadmin_docker](1_docker_sql/imgs/pgadmin_docker.png)

To query the connected database the query-tool of pgAdmin can be used:
![query_tool](1_docker_sql/imgs/query_tool.jpg)
![query](1_docker_sql/imgs/query.png)
To query the database, `[F5]` is used.

Another way to connect multiple docker-container in a network is to use `docker-compose`, which will be presented in following sections.

## 1.2.4 - Dockerizing the Ingestion Script

The [notebook](1_docker_sql/upload-data.ipynb) that populated the postgres-database and the [dummy-pipeline](1_docker_sql/pipeline.py) will be adapted to create a proper pipeline for data-ingestion.

### Converting the notebook to a Python script

Converting to Python:
```bash
jupyter nbconvert --to=script upload-data.ipynb

```
A new file [ingest_data.py](1_docker_sql/ingest_data.py) is created and the exported code is adapted.

The file requires many parameters that have to be given as arguments when calling the program:
```bash
URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2021-01.csv.gz"

python ingest_data.py \
  --user=root \
  --password=root \
  --host=localhost \
  --port=5432 \
  --db=ny_taxi \
  --table_name=yellow_taxi_trips \
  --url=${URL}
```

After the ingestion-process is finished, it is possible to look into the data with pgAdmin: 

```sql
SELECT 
	COUNT(1)
FROM
	yellow_taxi_trips;
```

### Dockerizing the ingestion-script

Now the ingestion-process has to be dockerized. For this the [Dockerfile](1_docker_sql/Dockerfile) from before will be adapted:

```Dockerfile
FROM python:3.9.1

# Installing dependencies
RUN apt-get install wget
RUN pip install pandas sqlalchemy psycopg2

WORKDIR /app
COPY ingest_data.py ingest_data.py

ENTRYPOINT [ "python", "ingest_data.py" ]
```

Build the container:
```bash
docker build -t taxi_ingest:v001 .
```

Running the container with the required parameters:
```bash
URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2021-01.csv.gz"

docker run taxi_ingest:v001 \
  --user=root \
  --password=root \
  --host=localhost \
  --port=5432 \
  --db=ny_taxi \
  --table_name=yellow_taxi_trips \
  --url=${URL}
```

- This looks good, but does not work! This is again because of `localhost` and it's meaning inside of a docker-container.

- To solve the problem the container has to be killed, if it is currently still running.

The first idea is again to use `docker network`:
```bash
URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2021-01.csv.gz"

docker run -it \
  --network=pg-network \
  taxi_ingest:v001 \
    --user=root \
    --password=root \
    --host=pg-database \
    --port=5432 \
    --db=ny_taxi \
    --table_name=yellow_taxi_trips \
    --url=${URL}
```
The important changes were the specification of the network and setting the host to the postgres-database.

Establishing the network and configuring multiple `docker run` statements by hand is not really that handy. A better solution is to write a script that automates the creation of required docker-container and that connects them accordingly. For this `docker-compose` can be used.

## 1.2.5 - Running Postgres and pgAdmin with Docker-Compose
Installing `docker-compose`: https://docs.docker.com/compose/install/

What is `docker-compose`:
- Docker Compose is a tool for defining and running multi-container Docker applications
- Configured with `yaml`-file(s)
- Allows for far more simpler orchestration of docker-container in conjunction with each other

The docker-compose file that creates a network and uses both relevant docker-container is [docker-compose.yaml](1_docker_sql/docker-compose.yaml):
```yaml
services:
  pgdatabase:
    image: postgres:13
    environment:
    - POSTGRES_USER=root
    - POSTGRES_PASSWORD=root
    - POSTGRES_DB=ny_taxi
    volumes:
      - "./ny_taxi_postgres_data:/var/lib/postgresql/data:rw"
    ports:
      - "5432:5432"
  pgadmin:
    image: dpage/pgadmin4
    environment:
      - PGADMIN_DEFAULT_EMAIL=admin@admin.com
      - PGADMIN_DEFAULT_PASSWORD=root
    ports:
      - "8080:80"
```

To use the configuration-file, use the follwing command:
```bash
docker-compose up
```

During configuration of the postgres-database connection everything stays basically the same and the host-name must be the name of the database-service in the docker-compose config (`pgdatabase`). 

To shut down docker compose you can either use 

**The quick and dirty method**: 
```txt
[Ctrl] + [C]
```
**The proper way (from different console)**: 
```bash
docler-compose down
```

With this, everythig is set up and we can finally work with the ingested database.

`Note:` to make pgAdmin configuration persistent, create a folder `data_pgadmin`. Change its permission via
```bash
sudo chown 5050:5050 data_pgadmin
```

and mount it to the `/var/lib/pgadmin` folder:

```yaml
services:
  pgadmin:
    image: dpage/pgadmin4
    volumes:
      - ./data_pgadmin:/var/lib/pgadmin
    ...
```

## 1.2.6 - SQL Refresher
- **TODO**
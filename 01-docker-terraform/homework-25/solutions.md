# Homework 1

- [Homework 1](#homework-1)
  - [Question 1. Understanding docker first run](#question-1-understanding-docker-first-run)
    - [Answer 1](#answer-1)
  - [Question 2. Understanding Docker networking and docker-compose](#question-2-understanding-docker-networking-and-docker-compose)
    - [Anaswer 2](#anaswer-2)
  - [Prepare Postgres](#prepare-postgres)
  - [Question 3. Trip Segmentation Count](#question-3-trip-segmentation-count)
    - [Answer 3](#answer-3)
  - [Question 4. Longest trip for each day](#question-4-longest-trip-for-each-day)
    - [Answer 4](#answer-4)
  - [Question 5. Three biggest pickup zones](#question-5-three-biggest-pickup-zones)
    - [Answer 5](#answer-5)


## Question 1. Understanding docker first run

Run docker with the `python:3.12.8` image in an interactive mode, use the entrypoint `bash`.

What's the version of `pip` in the image?

- `24.3.1`
- `24.2.1`
- `23.3.1`
- `23.2.1`

### Answer 1

Run docker container (pull if not yet there)
```bash
docker run -it python:3.12.8 bash
```
Result
```bash
pip -V
# pip 24.3.1 from /usr/local/lib/python3.12/site-packages/pip (python 3.12)
```

The installed version is `24.3.1`.



## Question 2. Understanding Docker networking and docker-compose

Given the following [`docker-compose.yaml`](docker-compose.yaml), what is the `hostname` and `port` that **pgadmin** should use to connect to the postgres database?

<details>
<summary><b>Code:</b> docker-compose.yaml</summary>

```yaml
services:
  db:
    container_name: postgres
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: 'postgres'
      POSTGRES_PASSWORD: 'postgres'
      POSTGRES_DB: 'ny_taxi'
    ports:
      - '5433:5432'
    volumes:
      - vol-pgdata:/var/lib/postgresql/data

  pgadmin:
    container_name: pgadmin
    image: dpage/pgadmin4:latest
    environment:
      PGADMIN_DEFAULT_EMAIL: "pgadmin@pgadmin.com"
      PGADMIN_DEFAULT_PASSWORD: "pgadmin"
    ports:
      - "8080:80"
    volumes:
      - vol-pgadmin_data:/var/lib/pgadmin  

volumes:
  vol-pgdata:
    name: vol-pgdata
  vol-pgadmin_data:
    name: vol-pgadmin_data
```
</details>

- postgres:5433
- localhost:5432
- db:5433
- postgres:5432
- db:5432

If there are more than one answers, select only one of them.

### Anaswer 2 
- The `db`-container maps the internal port `5432` (postgres) to the external port `5433`
- To connect to the postgres-database you connect to the host `db` over the port `5433`
  - Complete Answer: `db:5433` 


##  Prepare Postgres

Run Postgres and load data as shown in the videos.

The data is obtained from these urls (will be downloaded in ingestion script):
- **`Green Taxi data`**: https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2019-10.csv.gz
- **`Zones data`**: https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv

Start the docker-compose from question 2:
```bash
docker-compose up
```

Create `venv` for data-ingestion:
```bash
python3.9 -m venv hw1
source hw1/bin/activate
pip install -r reqirements.txt
```

Run data-ingestion for taxi data and zones data:
```bash
URL_TAXI=https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2019-10.csv.gz

python3 ingest_data.py \
  --user postgres \
  --password postgres \
  --host localhost \
  --port 5433 \
  --db ny_taxi \
  --tb green_taxi_trips \
  --url ${URL_TAXI}


URL_ZONES=https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv

python3 ingest_data.py \
  --user postgres \
  --password postgres \
  --host localhost \
  --port 5433 \
  --db ny_taxi \
  --tb zones \
  --url ${URL_ZONES}
```

After creation of a server in `pgAdmin` you will have access to the data in the created tables.

Alternatively it is possible to connect to the database with `pgcli`:
```bash
pgcli -h localhost -p 5433 -u postgres -d ny_taxi

# postgres@localhost:ny_taxi> \dt 
# +--------+------------------+-------+----------+
# | Schema | Name             | Type  | Owner    |
# |--------+------------------+-------+----------|
# | public | green_taxi_trips | table | postgres |
# | public | zones            | table | postgres |
# +--------+------------------+-------+----------+
```

## Question 3. Trip Segmentation Count

During the period of October 1st 2019 (inclusive) and November 1st 2019 (exclusive), how many trips, **respectively**, happened:
1. Up to 1 mile
2. In between 1 (exclusive) and 3 miles (inclusive),
3. In between 3 (exclusive) and 7 miles (inclusive),
4. In between 7 (exclusive) and 10 miles (inclusive),
5. Over 10 miles 

Answers:

- 104,802;  197,670;  110,612;  27,831;  35,281
- 104,802;  198,924;  109,603;  27,678;  35,189
- 104,793;  201,407;  110,612;  27,831;  35,281
- 104,793;  202,661;  109,603;  27,678;  35,189
- 104,838;  199,013;  109,645;  27,688;  35,202


### Answer 3

Used Queries:
```sql
-- During the period of October 1st 2019 (inclusive) and November 1st 2019 (exclusive), 
-- how many trips, respectively, happened:

-- 1. Up to 1 mile
SELECT 
	COUNT(*) as trip_count
FROM 
	green_taxi_trips
WHERE
	DATE(lpep_pickup_datetime) BETWEEN '2019-10-01' AND '2019-10-31' 
	AND
	DATE(lpep_dropoff_datetime) BETWEEN '2019-10-01' AND '2019-10-31'
	AND 
	trip_distance <= 1.0;


-- 2. In between 1 (exclusive) and 3 miles (inclusive),
SELECT 
	COUNT(*) as trip_count
FROM 
	green_taxi_trips
WHERE
	DATE(lpep_pickup_datetime) BETWEEN '2019-10-01' AND '2019-10-31' 
	AND
	DATE(lpep_dropoff_datetime) BETWEEN '2019-10-01' AND '2019-10-31'
	AND 
	trip_distance > 1.0 AND trip_distance <= 3.0;


-- 3. In between 3 (exclusive) and 7 miles (inclusive),
SELECT 
	COUNT(*) as trip_count
FROM 
	green_taxi_trips
WHERE
	DATE(lpep_pickup_datetime) BETWEEN '2019-10-01' AND '2019-10-31' 
	AND
	DATE(lpep_dropoff_datetime) BETWEEN '2019-10-01' AND '2019-10-31'
	AND 
	trip_distance > 3.0 AND trip_distance <= 7.0;


-- 4. In between 7 (exclusive) and 10 miles (inclusive),
SELECT 
	COUNT(*) as trip_count
FROM 
	green_taxi_trips
WHERE
	DATE(lpep_pickup_datetime) BETWEEN '2019-10-01' AND '2019-10-31' 
	AND
	DATE(lpep_dropoff_datetime) BETWEEN '2019-10-01' AND '2019-10-31'
	AND 
	trip_distance > 7.0 AND trip_distance <= 10.0;

-- 5. Over 10 miles
SELECT 
	COUNT(*) as trip_count
FROM 
	green_taxi_trips
WHERE
	DATE(lpep_pickup_datetime) BETWEEN '2019-10-01' AND '2019-10-31' 
	AND
	DATE(lpep_dropoff_datetime) BETWEEN '2019-10-01' AND '2019-10-31'
	AND 
	trip_distance > 10.0;
```

- ***Results***: `104,802;  198,924;  109,603;  27,678;  35,189`


## Question 4. Longest trip for each day

Which was the pick up day with the longest trip distance?
Use the pick up time for your calculations.

*`Tip`*: For every day, we only care about one single trip with the longest distance. 

- 2019-10-11
- 2019-10-24
- 2019-10-26
- 2019-10-31


### Answer 4

Used Query:
```sql
SELECT
	DATE(lpep_pickup_datetime),
	MAX(trip_distance) AS max_distance
FROM
	green_taxi_trips
GROUP BY
	DATE(lpep_pickup_datetime)
ORDER BY
	MAX(trip_distance) DESC
LIMIT
	1;
```

Query result:
| **`date`** | **`max_distance`** |
| ---------- | ------------------ |
| 2019-10-31 |       515.89       |

- ***Result***: `2019-10-31`


## Question 5. Three biggest pickup zones

Which were the top pickup locations with over 13,000 in
`total_amount` (across all trips) for 2019-10-18?

Consider only `lpep_pickup_datetime` when filtering by date.
 
- East Harlem North, East Harlem South, Morningside Heights
- East Harlem North, Morningside Heights
- Morningside Heights, Astoria Park, East Harlem South
- Bedford, East Harlem North, Astoria Park

### Answer 5

Used Query:
```sql
TODO
```

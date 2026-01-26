## Question 1. Understanding Docker images

Run docker with the `python:3.13` image. Use an entrypoint `bash` to interact with the container.

What's the version of `pip` in the image?

- `25.3`
- `24.3.1`
- `24.2.1`
- `23.3.1`

### Answer 1
```bash
docker run -it --rm --entrypoint=bash python:3.13

root@7e9058cf228e:/# pip --version 
pip 25.3 from /usr/local/lib/python3.13/site-packages/pip (python 3.13)
```

> `25.3`


## Question 2. Understanding Docker networking and docker-compose

Given the following `docker-compose.yaml`, what is the `hostname` and `port` that pgadmin should use to connect to the postgres database?

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

- postgres:5433
- localhost:5432
- db:5433
- postgres:5432
- db:5432

If multiple answers are correct, select any 


### Answer 2

`postgres:5432` (docker-container name) or `db:5432` (docker-compose service name)


## Question 3. Counting short trips

For the trips in November 2025 (`lpep_pickup_datetime` between `'2025-11-01'` and `'2025-12-01'`, exclusive of the upper bound), how many trips had a `trip_distance` of less than or equal to 1 mile?

- 7,853
- 8,007
- 8,254
- 8,421


### Answer 3

#### Preparation
Obtainin the data:
```bash
wget -c https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-11.parquet
wget -c https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv
```

Create venv with dependencies:
```bash
python3 -m venv hw1
source hw1/bin/activate
pip install pandas click tqdm sqlalchemy psycopg2 pyarrow
```

```bash
URL_GREEN=https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-11.parquet

python3 ingest_data.py \
    --user postgres \
    --password postgres \
    --host localhost \
    --port 5433 \
    --db ny_taxi \
    --tb green_taxi_data \
    --url "${URL_GREEN}"

URL_ZONES=https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv

python3 ingest_data.py \
    --user postgres \
    --password postgres \
    --host localhost \
    --port 5433 \
    --db ny_taxi \
    --tb zones \
    --url "${URL_ZONES}"
```

After ingesting the data, the pgadmin UI can be opened at [http://localhost:8080](http://localhost:8080)


#### Answer 3 - SQL

```sql
SELECT
	COUNT(1) AS "trip_count"
FROM
	green_taxi_data AS t
WHERE
	CAST(t.lpep_pickup_datetime AS DATE) BETWEEN '2025-11-01' and '2025-11-30'
	AND trip_distance <= 1.0;
```

**Result**: `8007`



## Question 4. Longest trip for each day

Which was the pick up day with the longest trip distance? Only consider trips with `trip_distance` less than 100 miles (to exclude data errors).

Use the pick up time for your calculations.

- `2025-11-14`
- `2025-11-20`
- `2025-11-23`
- `2025-11-25`

### Answer 4

```sql
SELECT
	t.trip_distance AS "Trip Distance",
	CAST(t.lpep_pickup_datetime AS DATE) as "Day"
FROM 
	green_taxi_data AS t
WHERE
	t.trip_distance <= 100.0
ORDER BY
	t.trip_distance DESC;
```


**Result**: 
| **Trip Distance** | **Day**    |
| ----------------- | ---------- |
| 88.03             | 2025-11-14 |


## Question 5. Biggest pickup zone

Which was the pickup zone with the largest `total_amount` (sum of all trips) on November 18th, 2025?

- East Harlem North
- East Harlem South
- Morningside Heights
- Forest Hills


### Answer 5

```sql
SELECT
	z."Zone",
	ROUND(CAST(SUM(t.total_amount) AS NUMERIC), 2) as sum_total
FROM
	green_taxi_data AS t
	JOIN zones AS z
		ON t."PULocationID" = z."LocationID"
WHERE
	CAST(t.lpep_pickup_datetime AS DATE) = '2025-11-18'
GROUP BY
	z."Zone"
ORDER BY
	sum_total DESC
LIMIT
	1;
```

Table:
| **Zone**          | **sum_total** |
| ----------------- | ------------- |
| East Harlem North | 9281.92       |



## Question 6. Largest tip

For the passengers picked up in the zone named "East Harlem North" in November 2025, which was the drop off zone that had the largest tip?

Note: it's `tip` , not `trip`. We need the name of the zone, not the ID.

- JFK Airport
- Yorkville West
- East Harlem North
- LaGuardia Airport


### Answer 6

```sql
SELECT
	  zdo."Zone" AS dropoff_zone,
	  MAX(t.tip_amount) AS max_tip
FROM
	  green_taxi_data AS t
	  JOIN zones AS zpu
	  	  ON t."PULocationID" = zpu."LocationID"
	  JOIN zones AS zdo
	  	  ON t."DOLocationID" = zdo."LocationID"
WHERE	
	  t.lpep_pickup_datetime >= '2025-11-01' AND 
	  t.lpep_pickup_datetime < '2025-12-01' AND
	  zpu."Zone" = 'East Harlem North'
GROUP BY
	  dropoff_zone
ORDER BY
	  max_tip DESC
LIMIT
    1;
```

Result:
| **dropoff_zone** | **max_tip** |
| ---------------- | ----------- |
| Yorkville West   | 81.89       |


## Question 7. Terraform Workflow

Which of the following sequences, respectively, describes the workflow for:
1. Downloading the provider plugins and setting up backend,
2. Generating proposed changes and auto-executing the plan
3. Remove all resources managed by terraform`

Answers:
- terraform import, terraform apply -y, terraform destroy
- teraform init, terraform plan -auto-apply, terraform rm
- terraform init, terraform run -auto-approve, terraform destroy
- terraform init, terraform apply -auto-approve, terraform destroy
- terraform import, terraform apply -y, terraform rm

### Answer 7

```bash
terraform init
terraform apply -auto-approve
terraform destroy
```

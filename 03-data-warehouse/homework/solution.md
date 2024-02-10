# Solution

<b>SETUP:</b></br>
Create an external table using the Green Taxi Trip Records Data for 2022. </br>
Create a table in BQ using the Green Taxi Trip Records for 2022 (do not partition or cluster this table). </br>
</p>

```sql
-- Create an external table using the Green Taxi Trip Records Data for 2022. 
CREATE OR REPLACE EXTERNAL TABLE dtc-de-410018.nytaxi.external_green_tripdata
OPTIONS (
    format = 'PARQUET',
    uris = ['gs://nyc-tl-data-dtc-de/trip data/green_taxi_trip_data/green_tripdata_2022-*.parquet']
);
```

```sql
-- Create a table in BQ using the Green Taxi Trip Records for 2022 
-- (do not partition or cluster this table).
CREATE OR REPLACE TABLE dtc-de-410018.nytaxi.green_tripdata_non_partitoned AS
    SELECT 
        * 
    FROM 
        dtc-de-410018.nytaxi.external_green_tripdata;
```

## Question 1:
Question 1: What is count of records for the 2022 Green Taxi Data??
- 65,623,481
- 840,402
- 1,936,423
- 253,647

**`Solution`**:
```sql
SELECT 
    COUNT(*) 
FROM 
    dtc-de-410018.nytaxi.external_green_tripdata;
```
| **`Row`** | **`f0_`** |
| --------- | --------- |
|     1     |  840,402  |

## Question 2:
Write a query to count the distinct number of PULocationIDs for the entire dataset on both the tables.</br> 
What is the estimated amount of data that will be read when this query is executed on the External Table and the Table?

- 0 MB for the External Table and 6.41MB for the Materialized Table
- 18.82 MB for the External Table and 47.60 MB for the Materialized Table
- 0 MB for the External Table and 0MB for the Materialized Table
- 2.14 MB for the External Table and 0MB for the Materialized Table

**`Soluation`**:
```sql
-- External Table (0 MB)
SELECT
    COUNT(DISTINCT PULocationID) 
FROM 
    dtc-de-410018.nytaxi.external_green_tripdata;

-- Materialized Table (6.41 MB)
SELECT 
    COUNT(DISTINCT PULocationID) 
FROM 
    dtc-de-410018.nytaxi.green_tripdata_non_partitoned;
```

## Question 3:
How many records have a fare_amount of 0?
- 12,488
- 128,219
- 112
- 1,622

**`Soluation`**:

```sql
SELECT
    COUNT(*)
FROM 
    dtc-de-410018.nytaxi.green_tripdata_non_partitoned
WHERE
    fare_amount = 0;    
```
| **`Row`** | **`f0_`** |
| --------- | --------- |
|     1     |   1,622   |


## Question 4:
What is the best strategy to make an optimized table in Big Query if your query will always order the results by `PULocationID` and filter based on `lpep_pickup_datetime`? (Create a new table with this strategy)
- Cluster on `lpep_pickup_datetime` Partition by `PULocationID`
- Partition by `lpep_pickup_datetime` Cluster on `PULocationID`
- Partition by `lpep_pickup_datetime` and Partition by `PULocationID`
- Cluster on by `lpep_pickup_datetime` and Cluster on `PULocationID`

**`Solution`**:
```sql
-- Partition by `lpep_pickup_datetime` Cluster on `PUlocationID`
CREATE OR REPLACE TABLE dtc-de-410018.nytaxi.green_tripdata_optimized_2
PARTITION BY DATE(lpep_pickup_datetime)
CLUSTER BY PULocationID AS
SELECT * FROM dtc-de-410018.nytaxi.green_tripdata_non_partitoned;
```

- Partitioning by `lpep_pickup_datetime` then Clustering on `PULocationID`


## Question 5:
Write a query to retrieve the distinct `PULocationID` between `lpep_pickup_datetime`
06/01/2022 and 06/30/2022 (inclusive)</br>

Use the materialized table you created earlier in your from clause and note the estimated bytes. Now change the table in the from clause to the partitioned table you created for question 4 and note the estimated bytes processed. What are these values? </br>

Choose the answer which most closely matches.</br> 

- `22.82 MB` for non-partitioned table and `647.87 MB` for the partitioned table
- `12.82 MB` for non-partitioned table and   `1.12 MB` for the partitioned table
-  `5.63 MB` for non-partitioned table and      `0 MB` for the partitioned table
- `10.31 MB` for non-partitioned table and  `10.31 MB` for the partitioned table

**`Solution`**:
```sql
-- The full Table
SELECT DISTINCT(PULocationID)
FROM dtc-de-410018.nytaxi.green_tripdata_non_partitoned
WHERE DATE(lpep_pickup_datetime) BETWEEN '2022-06-01' AND '2022-07-01';

-- The optimized Table
SELECT DISTINCT(PULocationID)
FROM dtc-de-410018.nytaxi.green_tripdata_optimized_2
WHERE DATE(lpep_pickup_datetime) BETWEEN '2022-06-01' AND '2022-07-01';
```
- Non-partitioned: `12.82 MB`
- Partitioned: `1.12 MB`


## Question 6: 
Where is the data stored in the External Table you created?

- Big Query
- GCP Bucket
- Big Table
- Container Registry

**`Solution`**:
- GCP Bucket

## Question 7:
It is best practice in Big Query to always cluster your data:
- `True`
- `False`

**`Solution`**:
- `True`

Clustering can be useful because of several reasons, for example:
- `Improving Query Performance`: Clustering columns can help speed up the query, because it avoids searching the whole table
- `Lower Cost`: Since only relevant "cluster" are processed and not the whole table, a query will incur lower cost


## (Bonus: Not worth points) Question 8:
No Points: Write a `SELECT count(*)` query FROM the materialized table you created. How many bytes does it estimate will be read? Why?

**`Solution`**:
```sql
SELECT 
    COUNT(*)
FROM 
    dtc-de-410018.nytaxi.green_tripdata_non_partitoned;
```
`Job-Information`:
```
Duration: 0 sec
Bytes processed: 0 B
Bytes billed: 0 B
Slot milliseconds: 60
Job priority: INTERACTIVE
Use legacy SQL: false
Destination table: Temporary table
```

- BigQuery obtains the number of records that is usually computed with `COUNT(*)` from the metadata instead of parsing the table itself.
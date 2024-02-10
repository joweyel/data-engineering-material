-- Preliminaries

-- Create an external table using the Green Taxi Trip Records Data for 2022. 
CREATE OR REPLACE EXTERNAL TABLE dtc-de-410018.nytaxi.external_green_tripdata
OPTIONS (
    format = 'PARQUET',
    uris = ['gs://nyc-tl-data-dtc-de/trip data/green_taxi_trip_data/green_tripdata_2022-*.parquet']
);

-- Check green trip data
SELECT * FROM dtc-de-410018.nytaxi.external_green_tripdata LIMIT 10;

-- Create a table in BQ using the Green Taxi Trip Records for 2022 
-- (do not partition or cluster this table).
CREATE OR REPLACE TABLE dtc-de-410018.nytaxi.green_tripdata_non_partitoned AS
SELECT * FROM dtc-de-410018.nytaxi.external_green_tripdata;



-- Question 1: 
-- What is count of records for the 2022 Green Taxi Data??
SELECT COUNT(*) FROM dtc-de-410018.nytaxi.external_green_tripdata;

-- Question 2: 
-- Write a query to count the distinct number of PULocationIDs for the entire 
-- dataset on both the tables. What is the estimated amount of data that will be read when 
-- this query is executed on the External Table and the Table?
SELECT COUNT(DISTINCT PULocationID) FROM dtc-de-410018.nytaxi.external_green_tripdata;       -- 0.00 MB
SELECT COUNT(DISTINCT PULocationID) FROM dtc-de-410018.nytaxi.green_tripdata_non_partitoned; -- 6.41 MB

-- Question 3:
-- How many records have a fare_amount of 0?
SELECT COUNT(*) FROM dtc-de-410018.nytaxi.green_tripdata_non_partitoned WHERE fare_amount = 0;


-- Question 4:

-- Cluster on `lpep_pickup_datetime` Partition by `PUlocationID`
CREATE OR REPLACE TABLE dtc-de-410018.nytaxi.green_tripdata_optimized_1
PARTITION BY PULocationID
CLUSTER BY DATE(lpep_pickup_datetime) AS
SELECT * FROM dtc-de-410018.nytaxi.green_tripdata_non_partitoned;

-- Error: Cant partition by PULocationID


-- Partition by `lpep_pickup_datetime` Cluster on `PUlocationID`
CREATE OR REPLACE TABLE dtc-de-410018.nytaxi.green_tripdata_optimized_2
PARTITION BY DATE(lpep_pickup_datetime)
CLUSTER BY PULocationID AS
SELECT * FROM dtc-de-410018.nytaxi.green_tripdata_non_partitoned;

-- Result:
-- Duration: 12 sec
-- Bytes processed: 114.11 MB
-- Bytes billed: 115 MB
-- Slot milliseconds: 274934
-- Job priority: INTERACTIVE
-- Use legacy SQL: false
-- Destination table: dtc-de-410018.nytaxi.green_tripdata_optimized_2


-- Partition by `lpep_pickup_datetime` and Partition by `PUlocationID`
CREATE OR REPLACE TABLE dtc-de-410018.nytaxi.green_tripdata_optimized_3
PARTITION BY DATE(lpep_pickup_datetime), PULocationID AS
SELECT * FROM dtc-de-410018.nytaxi.green_tripdata_non_partitoned;

-- Result: Only a single PARTITION BY expression is supported but found 2


-- Cluster on by `lpep_pickup_datetime` and Cluster on `PUlocationID`
CREATE OR REPLACE TABLE dtc-de-410018.nytaxi.green_tripdata_optimized_4
CLUSTER BY DATE(lpep_pickup_datetime), PULocationID AS
SELECT * FROM dtc-de-410018.nytaxi.green_tripdata_non_partitoned;

-- Result:
-- Duration: 5 sec
-- Bytes processed: 114.11 MB
-- Bytes billed: 115 MB
-- Slot milliseconds: 20440
-- Job priority: INTERACTIVE
-- Use legacy SQL: false
-- Destination table: dtc-de-410018.nytaxi.green_tripdata_optimized_4


-- Question 5:
-- Write a query to retrieve the distinct PULocationID between lpep_pickup_datetime 06/01/2022 and 06/30/2022 (inclusive)

-- The full Table
SELECT DISTINCT(PULocationID)
FROM dtc-de-410018.nytaxi.green_tripdata_non_partitoned
WHERE DATE(lpep_pickup_datetime) BETWEEN '2022-06-01' AND '2022-07-01';

-- The optimized Table
SELECT DISTINCT(PULocationID)
FROM dtc-de-410018.nytaxi.green_tripdata_optimized_2
WHERE DATE(lpep_pickup_datetime) BETWEEN '2022-06-01' AND '2022-07-01';


-- Question 8: (Bonus: Not worth points)
-- No Points: Write a `SELECT count(*)` query FROM the materialized table you created. 
-- How many bytes does it estimate will be read? Why?
SELECT COUNT(*)
FROM dtc-de-410018.nytaxi.green_tripdata_non_partitoned;

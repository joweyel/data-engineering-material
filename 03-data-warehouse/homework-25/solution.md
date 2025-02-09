## Module 3 Homework Solutions

<b>BIG QUERY SETUP:</b></br>

1. Create dataset with a name like `ny_taxi_hw3`

2. Create an external table using the Yellow Taxi Trip Records.
   ```sql
   CREATE OR REPLACE EXTERNAL TABLE `kestra-workspace.ny_taxi_hw3.external_yellow_tripdata`
   OPTIONS (
       format = 'PARQUET',
       uris = [
           'gs://dezoomcamp_hw3_2025_jw/yellow_tripdata_2024-*.parquet'
       ]
   );
   ```
2. Create a (regular/materialized) table in BQ using the Yellow Taxi Trip Records (do not partition or cluster this table).
   ```sql
   CREATE OR REPLACE TABLE `kestra-workspace.ny_taxi_hw3.yellow_tripdata_non_partitoned` AS 
   SELECT * FROM `kestra-workspace.ny_taxi_hw3.external_yellow_tripdata`;
   ```


## Question 1
What is count of records for the 2024 Yellow Taxi Data?
- 65,623
- 840,402
- 20,332,093
- 85,431,289

### Answer 1
`20,332,093`

Query:
```sql
SELECT COUNT(1) FROM `kestra-workspace.ny_taxi_hw3.yellow_tripdata_non_partitoned`;
```
Or by looking up the `Storage info` of the table in the Details tab of the table.


## Question 2
Write a query to count the distinct number of PULocationIDs for the entire dataset on both the tables.</br> 
What is the **estimated amount** of data that will be read when this query is executed on the External Table and the Table?

- 18.82 MB for the External Table and 47.60 MB for the Materialized Table
- 0 MB for the External Table and 155.12 MB for the Materialized Table
- 2.14 GB for the External Table and 0MB for the Materialized Table
- 0 MB for the External Table and 0MB for the Materialized Table

### Answer 2
- 0 MB for the External Table and 155.12 MB for the Materialized Table

Query (External Table):
```sql
SELECT 
    COUNT(DISTINCT PULocationID)
FROM
    `kestra-workspace.ny_taxi_hw3.external_yellow_tripdata`;
```

Query (Materialized Table):
```sql
SELECT 
    COUNT(DISTINCT PULocationID)
FROM
    `kestra-workspace.ny_taxi_hw3.yellow_tripdata_non_partitoned`;
```


## Question 3
Write a query to retrieve the `PULocationID` from the table (not the external table) in BigQuery. Now write a query to retrieve the `PULocationID` and DOLocationID on the same table. Why are the estimated number of Bytes different?
- BigQuery is a columnar database, and it only scans the specific columns requested in the query. Querying two columns (`PULocationID`, `DOLocationID`) requires 
reading more data than querying one column (`PULocationID`), leading to a higher estimated number of bytes processed.
- BigQuery duplicates data across multiple storage partitions, so selecting two columns instead of one requires scanning the table twice, 
doubling the estimated bytes processed.
- BigQuery automatically caches the first queried column, so adding a second column increases processing time but does not affect the estimated bytes scanned.
- When selecting multiple columns, BigQuery performs an implicit join operation between them, increasing the estimated bytes processed

### Answer 3
TODO


## Question 4
How many records have a `fare_amount` of 0?
- 128,210
- 546,578
- 20,188,016
- 8,333

### Answer 4

`8,333`

Query:
```sql
SELECT COUNT(fare_amount)
FROM `kestra-workspace.ny_taxi_hw3.yellow_tripdata_non_partitoned`
WHERE fare_amount = 0;
```


## Question 5
What is the best strategy to make an optimized table in BigQuery if your query will always filter based on `tpep_dropoff_datetime` and order the results by `VendorID` (Create a new table with this strategy)
- Partition by `tpep_dropoff_datetime` and Cluster on `VendorID`
- Cluster on by `tpep_dropoff_datetime` and Cluster on `VendorID`
- Cluster on `tpep_dropoff_datetime` Partition by `VendorID`
- Partition by `tpep_dropoff_datetime` and Partition by `VendorID`

### Answer 5

- Partition by `tpep_dropoff_datetime` and Cluster on `VendorID`

Query:
```sql
-- TODO
```


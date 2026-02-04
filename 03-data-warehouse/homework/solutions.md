# Module 3 Homework: Data Warehousing & BigQuery

## Loading the Data directly in Google Colab

- Jupyter notebook with DLT: [DLT_upload_to_GCP.ipynb](./DLT_upload_to_GCP.ipynb)

To avoid downloading and uploading data to GCP, the jupyter notebook above can be executed in Google Colab inside the Google ecosystem. This can dramatically reduce the time required for uploading the required data. There are however 2 requirements:

1. The GCS bucket that is used has to be created beforehand
2. The credentials (full json) have to provided as Secret and made accessible to the notebook

![Colab](images/colab_upload.png)

Move data to bucket-root and remove the dlt folder structure in the Cloud Shell Terminal:
```bash
gsutil cp gs://dezoomcamp_hw3_485415/rides_dataset/rides/*.parquet gs://dezoomcamp_hw3_485415
gsutil rm -r gs://dezoomcamp_hw3_485415/rides_dataset/
```

## BigQuery Setup

1. Create dataset with name `ny_taxi_hw3`
2. Create an external table using the Yellow Taxi Trip Records:
   ```sql
   CREATE OR REPLACE EXTERNAL TABLE `de-zoomcamp-26-485415.ny_taxi_hw3.external_yellow_tripdata`
   OPTIONS (
       format = 'PARQUET',
       uris = [
           'gs://dezoomcamp_hw3_485415/yellow_tripdata_2024_*.parquet'
       ]
   );
   ```
4. Create a (regular/materialized) table in BQ using the Yellow Taxi Trip Records (do not partition or cluster this table):
   ```sql
   CREATE OR REPLACE TABLE `de-zoomcamp-26-485415.ny_taxi_hw3.yellow_tripdata_materialized` AS
   SELECT * FROM `de-zoomcamp-26-485415.ny_taxi_hw3.external_yellow_tripdata`;
   ```

## Question 1. Counting records

What is count of records for the 2024 Yellow Taxi Data?
- 65,623
- 840,402
- 20,332,093
- 85,431,289

### Answer 1

From Table-Details:

- `20,332,093`

From query result:
```sql
SELECT COUNT(1) FROM `de-zoomcamp-26-485415.ny_taxi_hw3.yellow_tripdata_materialized`;
```


## Question 2. Data read estimation

Write a query to count the distinct number of PULocationIDs for the entire dataset on both the tables.
 
What is the **estimated amount** of data that will be read when this query is executed on the External Table and the Table?

- 18.82 MB for the External Table and 47.60 MB for the Materialized Table
- 0 MB for the External Table and 155.12 MB for the Materialized Table
- 2.14 GB for the External Table and 0MB for the Materialized Table
- 0 MB for the External Table and 0MB for the Materialized Table

## Question 3. Understanding columnar storage

Write a query to retrieve the PULocationID from the table (not the external table) in BigQuery. Now write a query to retrieve the PULocationID and DOLocationID on the same table.

Why are the estimated number of Bytes different?
- BigQuery is a columnar database, and it only scans the specific columns requested in the query. Querying two columns (PULocationID, DOLocationID) requires 
reading more data than querying one column (PULocationID), leading to a higher estimated number of bytes processed.
- BigQuery duplicates data across multiple storage partitions, so selecting two columns instead of one requires scanning the table twice, 
doubling the estimated bytes processed.
- BigQuery automatically caches the first queried column, so adding a second column increases processing time but does not affect the estimated bytes scanned.
- When selecting multiple columns, BigQuery performs an implicit join operation between them, increasing the estimated bytes processed

## Question 4. Counting zero fare trips

How many records have a fare_amount of 0?
- 128,210
- 546,578
- 20,188,016
- 8,333

## Question 5. Partitioning and clustering

What is the best strategy to make an optimized table in Big Query if your query will always filter based on tpep_dropoff_datetime and order the results by VendorID (Create a new table with this strategy)

- Partition by tpep_dropoff_datetime and Cluster on VendorID
- Cluster on by tpep_dropoff_datetime and Cluster on VendorID
- Cluster on tpep_dropoff_datetime Partition by VendorID
- Partition by tpep_dropoff_datetime and Partition by VendorID


## Question 6. Partition benefits

Write a query to retrieve the distinct VendorIDs between tpep_dropoff_datetime
2024-03-01 and 2024-03-15 (inclusive)


Use the materialized table you created earlier in your from clause and note the estimated bytes. Now change the table in the from clause to the partitioned table you created for question 5 and note the estimated bytes processed. What are these values? 


Choose the answer which most closely matches.
 

- 12.47 MB for non-partitioned table and 326.42 MB for the partitioned table
- 310.24 MB for non-partitioned table and 26.84 MB for the partitioned table
- 5.87 MB for non-partitioned table and 0 MB for the partitioned table
- 310.31 MB for non-partitioned table and 285.64 MB for the partitioned table


## Question 7. External table storage

Where is the data stored in the External Table you created?

- Big Query
- Container Registry
- GCP Bucket
- Big Table

## Question 8. Clustering best practices

It is best practice in Big Query to always cluster your data:
- True
- False


## Question 9. Understanding table scans

No Points: Write a `SELECT count(*)` query FROM the materialized table you created. How many bytes does it estimate will be read? Why?

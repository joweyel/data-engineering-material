
-- Option 1: Green Table (External) with parquet files
CREATE OR REPLACE EXTERNAL TABLE `kestra-workspace.trips_data_all.ext_green_tripdata`
OPTIONS (
    format = 'PARQUET',
    uris = [
        'gs://ny_taxi_data_2025/green/green_tripdata_2019-*.parquet',
        'gs://ny_taxi_data_2025/green/green_tripdata_2020-*.parquet'
    ]
);

-- Option 2: Green Table (External) with CSV files
CREATE OR REPLACE EXTERNAL TABLE `kestra-workspace.trips_data_all.ext_green_tripdata`
OPTIONS (
    format = 'CSV',
    uris = [
        'gs://ny_taxi_data_2025/green/green_tripdata_2019-*.csv.gz',
        'gs://ny_taxi_data_2025/green/green_tripdata_2020-*.csv.gz'
    ]
);


-- Green Table (Materialized)
CREATE OR REPLACE TABLE `kestra-workspace.trips_data_all.green_tripdata` AS 
SELECT * FROM `kestra-workspace.trips_data_all.ext_green_tripdata`;




-- Option 1: Yellow Table (External) with Parquet files
CREATE OR REPLACE EXTERNAL TABLE `kestra-workspace.trips_data_all.ext_yellow_tripdata`
OPTIONS (
    format = 'PARQUET',
    uris = [
        'gs://ny_taxi_data_2025/yellow/yellow_tripdata_2019-*.parquet',
        'gs://ny_taxi_data_2025/yellow/yellow_tripdata_2020-*.parquet'
    ]
);

-- Option 2: Yellow Table (External) with CSV files
CREATE OR REPLACE EXTERNAL TABLE `kestra-workspace.trips_data_all.ext_yellow_tripdata`
OPTIONS (
    format = 'CSV',
    uris = [
        'gs://ny_taxi_data_2025/yellow/yellow_tripdata_2019-*.csv.gz',
        'gs://ny_taxi_data_2025/yellow/yellow_tripdata_2020-*.csv.gz'
    ]
);

-- Yellow Table (Materialized)
CREATE OR REPLACE TABLE `kestra-workspace.trips_data_all.yellow_tripdata` AS 
SELECT * FROM `kestra-workspace.trips_data_all.ext_yellow_tripdata`;



-- Option 1: FHV Table (External) with Parquet Files
CREATE OR REPLACE EXTERNAL TABLE `kestra-workspace.trips_data_all.ext_fhv_tripdata`
OPTIONS (
    format = 'PARQUET',
    uris = [
        'gs://ny_taxi_data_2025/fhv/fhv_tripdata_2019-*.parquet'
    ]
);

-- Option 2: FHV Table (External) with CSV Files
CREATE OR REPLACE EXTERNAL TABLE `kestra-workspace.trips_data_all.ext_fhv_tripdata`
OPTIONS (
    format = 'CSV',
    uris = [
        'gs://ny_taxi_data_2025/fhv/fhv_tripdata_2019-*.csv.gz'
    ]
);

-- Yellow Table (Materialized)
CREATE OR REPLACE TABLE `kestra-workspace.trips_data_all.fhv_tripdata` AS 
SELECT * FROM `kestra-workspace.trips_data_all.ext_fhv_tripdata`;
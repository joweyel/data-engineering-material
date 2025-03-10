# Week 5: Batch Processing

## 5.1 Introduction

### 5.1.1 - Introduction to Batch processing

- Batch vs. Streaming
- Types of batch jobs
    - SQL, Pything scripts, Spark, Flink
- Orchestrating batch jobs
- Advantages and disadvantages of batch jobs
    - `Advantages`: easy to manage, retry, scale, easier to orchestrate
    - `Disadvantages`: delay

#### Batch vs. Streaming

**`Batch`**: processing of a chunk of data at regular intervals
![w5_1_batch](images/w5_1_batch.jpg)

**Batch jobs**

Batch jobs often run with the data used from a specified time interval, e.g.:
- Weekly
- `Daily` (most common)
- `Hourly` (most common)
- 3x per hour
- Every 5 minutes

**Technologies**

What can be used to run batch jobs:
- Python scripts (most flexible; Can run on:, Kubernetes, AWS Batch, ...)
- SQL
- Spark
- Flink

**Workflow**

Every part of this workflow works in batches. Workflows can be run with tools like Airflow or Mage

![w5_3_workflow](images/w5_3_workflow.jpg)

1. Data Lake with CSV files
2. Python script
    - Put data in data warehouse
    - Transforming data
3. SQL for data preparation
    - DBT
    - ...
4. Spark
5. Python

**Advantages of batch processing**
- Easy to:
    - `manage` (workflow tools used in every step)
    - `retry` (running workflow with other configuration by changing parameter)
    - `scale` (provisioning more resources easily done)

Due to these advantages, batch processing is used in 80% of the data engineering use-cases, the remaining 20% is stream-processing

**Disadvantage of batch processing**
- `delay` (results are available at a later point in time) 


**`Stream`** processing data on the fly

![w5_2_stream](images/w5_2_stream.jpg)


### 5.1.2 - Introduction to Spark

Spark is an open-source multi-language (Java, Scala, Python, ...) unified analytics `engine` for large-scale data processing. PySpark is the method of choice when the rest of the environment is also in python (e.g. in data science).

![w5_4_spark](images/w5_4_spark.jpg)

#### When is Spark used?

![w5_4_spark_use](images/w5_4_spark_use.jpg)

If data is located in a data lake and can be processed by SQL alone, then tools like `Hive`, `Presto`, `Athena`, etc. are used. If the data requires more granular processing and is used for a more complex use-case (like Machine Learning), Spark is the better choice, because it provides more flexibility in the process. However there is also the possibility to use both SQL processing and Spark. An example can be seen here:

![w5_5_spark_use2](images/w5_5_spark_use2.jpg)

**Steps**:

1. Raw data is saved to data lake
2. SQL tool on the cloud service processes the data (most of pre-processing done here)
3. Spark finalizes the processing
4. Using data for training ML model (returns `model`)
5. Using Spark to apply the `model` on the processed data
6. Saving the results to the data lake
 

## 5.2 Installation

- `Spark on Windows`: [Link](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/05-batch/setup/windows.md)
- `Spark on MacOS`: [Link](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/05-batch/setup/macos.md)
- `Spark on Linux`: [Link](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/05-batch/setup/linux.md)

- `PySpark`: [Link](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/05-batch/setup/pyspark.md)

**Installing Spark and PySpark on Linux (short version)**

```bash
# The installation folder
mkdir -p ~/spark
cd ~/spark

# Java JDK 11.0.2
wget -c https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz
tar xzfv openjdk-11.0.2_linux-x64_bin.tar.gz
echo 'export JAVA_HOME="${HOME}/spark/jdk-11.0.2"' >> ~/.bashrc
echo 'export PATH="${JAVA_HOME}/bin:${PATH}"' >> ~/.bashrc
rm openjdk-11.0.2_linux-x64_bin.tar.gz
source ~/.bashrc # update

# Spark (3.3.2)
wget -c https://archive.apache.org/dist/spark/spark-3.3.2/spark-3.3.2-bin-hadoop3.tgz
tar xzfv spark-3.3.2-bin-hadoop3.tgz
rm spark-3.3.2-bin-hadoop3.tgz
echo 'export SPARK_HOME="${HOME}/spark/spark-3.3.2-bin-hadoop3"' >> ~/.bashrc
echo 'export PATH="${SPARK_HOME}/bin:${PATH}"' >> ~/.bashrc
source ~/.bashrc # update

# PySpark
echo 'export PYTHONPATH="${SPARK_HOME}/python/:$PYTHONPATH"' >> ~/.bashrc
echo 'export PYTHONPATH="${SPARK_HOME}/python/lib/py4j-0.10.9-src.zip:$PYTHONPATH"' >> ~/.bashrc

# If you get the errror: `ModuleNotFoundError: No module named 'py4j'` use this
export PYTHONPATH="${SPARK_HOME}/python/lib/py4j-0.10.9.5-src.zip:$PYTHONPATH"
```

A very basic test to check if you can import `pyspark` is to open the `IPython`-console and import `pyspark`:

A more elaborate test of functionality of `pyspark` is to create a jupyter [notebook](code/1_pyspark-test-notebook.ipynb) and executing the follosing code:

```python
import pyspark
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .master("local[*]") \       # connect to "local" master with all available cpus [*]
    .appName('test') \          # application name
    .getOrCreate()              

# Read in taxi zone lookup table to spark dataframe
df = spark.read \
    .option("header", "true") \     # otherwise headers are unknown
    .csv('taxi+_zone_lookup.csv')
df.show()

# Test that writing works as well (writes parquet file to `zones` folder)
df.write.parquet('zones')
```

The code of this section can be found in the notebook [1_pyspark-test-notebook.ipynb](code/1_pyspark-test-notebook.ipynb)

## 5.3 Spark SQL and DataFrames

### 5.3.1 - First Look at Spark / PySpark

The code of this section can be found in the notebook [4_pyspark.ipynb](code/4_pyspark.ipynb)

Until now the data was read in as one big file, however this does not utilize the parrallel processing properties of Spark. To do computations more effectively, the data is split in multiple partitions so that it can be processed by a Spark cluster faster. 

![w5_6_spak_partition](images/w5_6_spak_partition.jpg)

### 5.3.2 - Spark DataFrames

The code of this section can be found in the notebook [4_pyspark.ipynb](code/4_pyspark.ipynb)

#### SELECT in PySpark
This is used similar to the keyword in SQL, to select certain data. The functionality is similar to a pandas dataframe that has a list of columns given, to get a subset of the data. The column names can be given as a list or as multiple parameters themself. Here the `filter` method works like  `WHERE` in SQL. To obtain the data, `.show()` has to be used, because `select` and `filter` use lazy execution.

```python
cols = ["pickup_datetime", "dropoff_datetime", "PULocationID", "DOLocationID"]
df.select(cols) \
  .filter(df.hvfhs_license_num == "HV0003") \
  .show()
```

#### Actions vs. Transformations

- **Transformations (lazy execution)**:
    - Used for transforming data
    - Not executed right away (require explicit call)
    - *Examples*: Selecting columns, filtering, JOINs, GROUP BY, ... 

- **Actions (eager execution)**:
    - Used for extracting data (data required immediately)
    - Executed immediately
    - show, take, head
    - Write-functions that write files

#### Functions available in Spark
- *Example*: Using SQL functions on columns with `pyspark.sql.functions`
  ```python
  from pyspark.sql import functions as F
  df.withColumn("pickup_date", F.to_date(df.pickup_date))
  ```
  - Adds a date column that was generated from a datatime column

- Defining your own function
  ```python
  def crazy_stuff(base_num):
    num = int(base_num[1:])
    if num % 7 == 0:
        return f"s/{num:03x}"
    elif num % 3 == 0:
        return f"a/{num:03x}"
    else:
        return f"e/{num:03x}"
    
  # function that works on Spark df's
  crazy_stuff_udf = F.udf(crazy_stuff, returnType=types.StringType())
  # applying the function
  df.withColumn("base_id", crazy_stuff_udf(df.dispatching_base_num))
  ```

### 5.3.3 Getting the Yellow and Green Taxi data

The code to download the required data from the NYC taxi data repository can be found in the file [download_data.py](data/download_data.py)

### 5.3.4 SQL with Spark

The practical application of the concepts of this section can be found in the notebook [4_pyspark.ipynb](code/4_pyspark.ipynb)

**Overview: Contents of this section**

- Loading parquet data
  ```python
  df = spark.read.parquet("data/raw/taxi/*/*/")
  ```
- Renaming columns
  ```python
  df = df.withColumnRenamed("old_name", "new_name")
  ```
- Getting overlapping columns of datasets
  ```python
  cols = set(df1.columns) & set(df1.columns)
  ```
- Adding column to dataframe & filling it with literal-value
  ```python
  from pyspark.sql import functions as F
  df = df.select(cols).withColumn("col", F.lit("value")) 
  ```
- Unifying subsets of dataframes that have same columns
  ```python
  df_union = df1.unionAll(df2)
  ```
- Counting of grouped values of a column
  ```python
  df_union.groupBy("col_name").count().show()
  ```
- Creating a SQL view on which the spark dataframe can be queried
  ```python
  df_union.createOrReplaceTempView("table")
  ```
- Getting data from spark with SQL queries
  ```python
  spark.sql("""
    SELECT col, COUNT(1) as count FROM table
    GROUP BY col;
  """).show()
  ```
- Saving / writing results as specified amount of files. Coalescing of the dataframe reduces the number of partitions when saving
  ```python
  n = ...           # Number of output files the partitions should be put into
  save_path = ...   # Path where data should be saved to
  df_result.coalesce(n).write.parquet(save_path)
  ```


## 5.4 Spark Internals

### 5.4.1 Anatomy of a Spark Cluster

**Content of this section**:

- Spark Driver, Master and Executor

In previous sections the used Spark-Cluster was run locally on the computer, however it is also possible to run a cluster in the cloud / on a server.

![w5_7_spark_cluster](images/w5_7_spark_cluster.jpg)

**Main components of using a spark cluster**:

- **`User / Client`**:
    -  with Driver that submits `spark-submits` to a spark cluster
- **`Cluster`**:
    - Has a `Master`-Service that is accessible over the cluster address on port `4040`.
    - `Executors` are computers in the cluster that are assigned tasks from the `Master`
- **`Data Center`**:
    - Stores, loads and saves the data / dataframe that is used in the computation
    - Data partitions are assigned to executors in the spark cluster
    - S3, GCS, ...

### 5.4.2 GroupBy in Spark

**Content of this section**:

- How `GroupBy` works internally
- Shuffling 

The practical application of the concepts of this section can be found in the notebook [groupby_join.ipynb](code/groupby_join.ipynb)

The `GROUP BY` command from SQL is executed in Spark dataframes in a specific way which will be explored here. As an example the following query is used:

```sql
SELECT
    date_trunc('hour', lpep_pickup_datetime) AS hour,
    PULocationID AS zone,

    ROUND(SUM(total_amount), 2) AS amount,
    COUNT(1) AS number_records
FROM
    green
WHERE 
    lpep_pickup_datetime >= '2020-01-01 00:00:00'
GROUP BY
    1, 2
ORDER BY
    1, 2
```

The process of `GROUP BY` in Spark can in general be divided into 2 steps (the 3rd step in the image below is `ORDER BY`)
1. Preparing for `GROUP BY`
2. The `GROUP BY` operation itself

![w5_8_groubpy3](images/w5_8_groubpy3.jpg)

Lets dive deeper in the respective stages for `GROUP BY` in Spark and look into what is happening:

<div style="display:flex; align-items: center;">
     <div style="flex:1">
          <img src="images/w5_8_groubpy1.jpg"/>
     </div>
     <div style="flex:1;padding-left:10px;">
          <img src="images/w5_8_groubpy2.jpg" />
     </div>
</div>

#### Stage #1
1. Put partitions of the dataframe to an executor which is then filtered for the specified columns
2. Initial `GROUP BY` is applied to filtered data
  - Returns grouped tables
3. When all partitions are processed by the executors, the intermediate results that were returned are used for Stage #2 

#### Stage #2 
1. Given the outputs with grouped tables of partitions, `Reshuffling` will be applied to the data
  - `Reshuffling`: Moving entries from partitions to other partitions
 - Moves results to different partitions based on keys used for `GROUP BY`
2. Applying another group by to each of the partition
3. Returning the reduced records

### 5.4.3 Joins in Spark

- Joining two large tables
- Merge Sort Join
- Joining one large tabele and one small table
- Broadcasting

#### Joining two large tables

![w5_9_join](images/w5_9_join.jpg)

In the graphic above 2 tables (green and yello taxi data) will be joined along the `hour` and `zone` columns. The remaining columns are the revenue and the amound of yellow taxis and the green taxis.

Joining spark dataframes can be easily done with one line of code, however in the background there is a specific algorithm at work s.t. big amounts of data can be handled.

```python
join_cols = [...]
df_join = df1.join(df2, on=join_cols, how="outer")
```   

What does spark do internally when joining tables. Lets have look at the internals of the operation.

#### Merge Sort Join

![w5_10_join2](images/w5_10_join2.png)

This graph from the Spark Web-UI shows 2 inputs, which are yellow and green taxi, that are then combined in the next step on the right. This overview however is only an high level overview over join process that is much more advanced under the hood. A detailed explanation can be found in this [video](https://youtu.be/lu7TrqAWuH4?si=Bby3wqrv3qP9Ax4u&t=324).

#### Joining one large tabele and one small table

![w5_11_small_join](images/w5_11_small_join.jpg)

Given are a partitioned big dataframe and a non-partitioned small dataframe, then the following steps can be taken for joining them:

1. `Data Distribution`: The partitions of the large dataframe are distributed across the executors in the Spark cluster.
2. `Broadcasting`: The entire small dataframe is copied (or "broadcast") to each executor. This is known as a "broadcast join". Broadcasting is efficient when one of the dataframes is small enough to fit in the memory of each executor.
3. `Join Operation`: The join operation is performed on each executor separately. This is done in parallel, which is one of the key advantages of Spark's distributed computing model.
4. `Result Aggregation`: Finally, the results from each executor are collected and appended together to form the final result.

This approach allows Spark to perform the join operation in a distributed and parallel manner. However, it is important to note that this method works best when one dataframe is significantly smaller than the other.

## 5.5 (Optional) Resilient Distributed Datasets

### 5.5.1 (Optional) Operations on Spark RDDs

**Content of this section**:

- What is RDD and how it is related to dataframes
- From DataFrame to RDD
- Operations on RDD: map, filter, reduceByKey
- From RDD to DataFrame

The code if this section can be found in the notebook [spark_rdd.ipynb](code/spark_rdd.ipynb)

- RDD's are on layer of abstraction lower than dataframes. 
- Dataframes in spark use RDD's in the background.
- While Dataframes have a schema, RDD's are a collection of objects 


### 5.5.2 Spark RDD mapPartition

**Content of this section**:

- Using mapPartition on RDD's

The code if this section can be found in the notebook [spark_rdd.ipynb](code/spark_rdd.ipynb)


In Spark, `mapPartitions` is an operation on RDDs. It is an advanced version of the map transformation that allows you to process each partition of the RDD independently. The primary difference between map and `mapPartitions` is that map operates on individual elements of the RDD, while `mapPartitions` processes entire partitions at once.

1. **`Partition-wise Operation:`** Instead of applying the provided function to each element individually, `mapPartitions` applies the function to each partition of the RDD. The function is invoked once for each partition, and it receives an iterator containing all the elements in that partition.

2. **`Iterator Input and Output:`** The user-defined function passed to mapPartitions takes an iterator as an input, allowing you to iterate through all the elements in a partition efficiently. The function should return an iterator, which will be used to construct the new RDD.

3. **`Efficiency:`** Because mapPartitions processes entire partitions at once, it can be more efficient than map in certain scenarios. For example, if your processing logic involves some per-partition initialization or aggregation, using mapPartitions can avoid redundant setup and teardown operations for each element.


## 5.6 Running Spark in the Cloud

### 5.6.1 Connecting to Google Cloud Storage

**Content of this section**:

- Uploading data to GCS
- Connecting Spark jobs to GCS

#### Uploading data to GCS

To upload the data used in previous sections to GCS, the following line can be used:

```python
gsutil -m cp -r data/raw/ gs://dtc_data_lake_de-zoomcap-nytaxi/pq
```

#### Connecting Spark to GCS

For the connection between PySpark and GCS, the cloud storage connector for Hadoop is needed. The required library can be obtained directly from GCS:

```python
gsutil cp gs://hadoop-lib/gcs/gcs-connector-hadoop3-2.2.5.jar gcs-connector-hadoop3-2.2.5.jar
mkdir -p code/lib/
mv gcs-connector-hadoop3-2.2.5.jar code/lib/
```

With the data in the cloud and the gcs-connector jar downloaded a connection to GCS can be establised. An exemplary connection is established in [this](code/spark_gcs.ipynb) notebook.


### 5.6.2 Creating a Local Spark Cluster

**Content of this section**:

- Creating the cluster
- Turning the notebook into a script
- Using spark-submit for submitting spark-jobs


The first step is starting the Spark master from the console. This was previously done in a notebook directly after the PySpark imports. This can be done by:
```bash
# Assuming SPARK_HOME variable is set correctly
bash ${SPARK_HOME}/sbin/start-master.sh 
```

The spark-master is now accessible over http://localhost:8080/. Instead of `"local[*]"`, the URL displayed in the Spark UI is used in the `SparkSession`.

```python
spark = SparkSession.builder \
    .master("spark://hp-computer:7077") \
    .appName("test") \
    .getOrCreate()
```

There is still some problem with the execution of anything that has to do with spark. This can be seen in the following error:
```log
24/02/27 21:59:13 WARN TaskSchedulerImpl: Initial job has not accepted any resources; check your cluster UI to ensure that workers are registered and have sufficient resources
```
There are no worker registered on the local cluster. This can be remedied by calling one of these two commands (usable interchangabley):
```bash
URL=<your-spark-url>:7077
./start-slave.sh $URL
# or
./start-worker.sh $URL
```
In the Spark-UI there is now a worker present, that will handle spark related tasks.

The notebook of this section is [local_cluster_spark.ipynb](code/local_cluster_spark.ipynb). This notebook has to be converted to a python script. For this purpose the following command is used:
```bash
jupyter nbconvert --to=script local_cluster_spark.ipynb
```

After cleaning up and some adaptions to the exported script, the scipt [local_cluster_spark.py](code/local_cluster_spark.py) can be used with
```bash
python3 local_cluster_spark.py --input_green <green-path> --input_yellow <yellow-path> --output <output-path>
```
or by using the following script with pre-defined paths:
```bash
./run_local_cluster_script.sh
```
The script contains the following code:
```bash
#!/usr/bin/bash

URL="spark://hp-computer:7077"

spark-submit \
    --master="${URL}" \
    local_cluster_spark.py \
        --input_green=../data/data/raw/green/2021/*/ \
        --input_yellow=../data/data/raw/yellow/2021/*/ \
        --output=../data/data/report-2021
```
This specifies the spark-master, which is used to execute the following program `local_cluster_spark.py`. After running the script, the master and the worker have to be shut down. This is done with the following commands:
```bash
bash ${SPARK_HOME}/sbin/stop-worker.sh
bash ${SPARK_HOME}/sbin/stop-master.sh
```

### 5.6.3 Setting up a Dataproc Cluster

**Content of this section**:
- Creating a cluster
- Running a Spark job with Dataproc
- Submitting the job with the cloud SDK

#### Setup process
1. Search for `Dataproc` on GCP
2. Create a new cluster
  - **Name**: `de-zoomcamp-cluster`
  - **Location**: `Your choice`
  - **Cluster type**: `Single Node` (for experimentation purposes)
  - **Optional components**:
    - `Jupyter Notebook`
    - `Docker`
  - All other options can be left as default

After the cluster is set up, you are able to send spark-jobs to it. In order to do this, the file with the PySpark code has to be on GCS. For this purpose the following code has to be used:
```bash
gsutil cp code/local_cluster_spark.py gs://dtc_data_lake_de-zoomcap-nytaxi/code/local_cluster_spark.py
```
After opening the cluster and clicking on `Submit Job`, you have to configure the job:
- **Job ID**: Any number
- **Job type**: `PySpark`
- **Main python file**: `gs://dtc_data_lake_de-zoomcap-nytaxi/code/local_cluster_spark.py`
- **Arguments**: 
  ```
  --input_green=gs://dtc_data_lake_de-zoomcap-nytaxi/pq/raw/green/2021/*/
  --input_yellow=gs://dtc_data_lake_de-zoomcap-nytaxi/pq/raw/yellow/2021/*/
  --output=gs://dtc_data_lake_de-zoomcap-nytaxi/report-2021
  ```

Now the job can be submitted! After the job has finished the results of the code are written to GCS at the specified location.

Ok, this was all done over Web-UI, which is not very convenient. To remedy this, a json for calling `Dataproc` over REST-API is provided under the `Configuration`-part of the job-details by clicking `Equivalent REST`.

The information for a call to `Dataproc` can be extracted from the file:
```bash
glcoud dataproc jobs submit pyspark \
  --cluster=cluster-name \
  --region=region \
  other dataproc-flags \
  -- job-args
```

Example call:
```bash
gcloud dataproc jobs submit pyspark \
  --cluster=cluster-e87b \
  --region=europe-west3 \
  gs://dtc_data_lake_de-zoomcap-nytaxi/code/local_cluster_spark.py \
  -- \
      --input_green=gs://dtc_data_lake_de-zoomcap-nytaxi/pq/raw/green/2021/*/ \
      --input_yellow=gs://dtc_data_lake_de-zoomcap-nytaxi/pq/raw/yellow/2021/*/ \
      --output=gs://dtc_data_lake_de-zoomcap-nytaxi/report-2021
```

This command will fail if you dont have provided access to the service account you use. For this purpose you have to add the following permissions to the servive account:
- `Dataproc Administrator`

Now you should be able to see something like this and further outputs:
```
Job [22a94a77a2694d9c892d615515399377] submitted.
Waiting for job output...
```

### 5.6.4 Connecting Spark to Big Query

**Content of this section**:

- Writing the spark job directly to BigQuery

*Pre-Requisite (Optional)*: 
- If the data is in another GCP project, it is required either to copy the data from one bucket to the bucket of the current project and load the parquet files to BigQuery. The other option is to change the service account and use the project where the data is already present. 
- Alternatively: copying of BigQuery dataset
  ```bash
  bq mk --transfer_config \
    --project_id=[PROJECT_ID] \
    --data_source=[DATA_SOURCE] \
    --target_dataset=[DATASET] \
    --display_name=[NAME] \
    --params='[PARAMETERS]'
  ```
  **Example Application** (copies full `trips_data_all` dataset from `taxi-rides-ny` to `dtc-de`):
  ```bash
  bq mk \
    --transfer_config \
    --project_id=dtc-de \
    --target_dataset=trips_data_all \
    --display_name='Taxi_Transfer' \
    --params='{
      "source_dataset_id":"trips_data_all",
      "source_project_id":"taxi-rides-ny",
      "overwrite_destination_table":"true"
      }'
  ```
In the command above, replace [PROJECT_ID], [DATA_SOURCE], [DATASET], [NAME], and [PARAMETERS] with your specific details. The --params option is used for specifying the source dataset and other options.

The content of the file [local_cluster_spark.py](code/local_cluster_spark.py) can be easily adapted for using BigQuery ([bigquery_spark.py](code/bigquery_spark.py)) to save the data to. For this only one command has to be changed:
```python
# Local or Dataproc Version:
df_result.coalesce(1).write.parquet(output, mode="overwrite")
# BigQuery Version:
df_result.write.format("bigquery").option("table", output).save()
```
The `output` parameter specifies the table where the result will be saved to in BigQuery. To run the Spark + BigQuery scipt you can use the run script [run_bigquery_spark.sh](code/bigquery_spark.py) or the following command in the console:
```bash
#!/usr/bin/bash

gcloud dataproc jobs submit pyspark \
    --cluster=cluster-e87b \
    --region=europe-west3 \
    gs://dtc_data_lake_de-zoomcap-nytaxi/code/bigquery_spark.py \
    --jars=gs://spark-lib/bigquery/spark-bigquery-latest_2.12.jar \
    -- \
        --input_green=gs://dtc_data_lake_de-zoomcap-nytaxi/pq/raw/green/2020/*/ \
        --input_yellow=gs://dtc_data_lake_de-zoomcap-nytaxi/pq/raw/yellow/2020/*/ \
        --output=trips_data_all.reports-2020
```

After running the command there will appear a `reports-2020` table in the `trips_data_all` dataset. SUCCESS!

## Homework
- The homework [questions](homework/homework.md)
- The homework [solutions](homework/solutions.ipynb)
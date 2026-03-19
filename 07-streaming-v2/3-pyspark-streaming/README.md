# PySpark Structured Streaming (Optional)

## Table of Contents

- [PySpark Structured Streaming (Optional)](#pyspark-structured-streaming-optional)
  - [Table of Contents](#table-of-contents)
  - [Kafka streaming with Python](#kafka-streaming-with-python)
    - [Why Python?](#why-python)
    - [Serialization](#serialization)
    - [Docker networking for Kafka](#docker-networking-for-kafka)
  - [PySpark Structured Streaming](#pyspark-structured-streaming)
    - [Mental model](#mental-model)
  - [Infrastructure setup](#infrastructure-setup)
  - [Python producer and consumer (Docker Kafka)](#python-producer-and-consumer-docker-kafka)
    - [Producer](#producer)
    - [Consumer](#consumer)
  - [Reading a Kafka topic with Spark](#reading-a-kafka-topic-with-spark)
  - [Parsing and transforming the stream](#parsing-and-transforming-the-stream)
  - [Output modes and sinks](#output-modes-and-sinks)
    - [Sinks](#sinks)
    - [Output modes](#output-modes)
    - [Example: write to console](#example-write-to-console)
    - [Example: write to Kafka](#example-write-to-kafka)
    - [Example: write to PostgreSQL with foreachBatch](#example-write-to-postgresql-with-foreachbatch)
  - [Streaming vs. batch DataFrames](#streaming-vs-batch-dataframes)


## Kafka streaming with Python

This section shows Kafka producer/consumer in Python using Docker-hosted Kafka (not Confluent Cloud). It mirrors the Java examples from the theory section.

### Why Python?

The theory videos use Java because the Kafka client library is most mature in Java. Python alternatives exist (`kafka-python`, `confluent-kafka`) and work well for most use cases. The main limitation is that Python does not have a mature equivalent of the Kafka Streams library for stateful processing. For stateful stream processing in Python, use Flink (workshop) or PySpark Structured Streaming (this section).

### Serialization

Kafka sends and receives raw bytes. Both the producer and consumer must agree on how to encode and decode values. In Python:

```python
# Producer side: Python object -> bytes
def json_serializer(data):
    return json.dumps(data).encode('utf-8')

# Consumer side: bytes -> Python object
def json_deserializer(data):
    return json.loads(data.decode('utf-8'))
```

For the key (usually an integer or string):

```python
def key_serializer(key):
    return str(key).encode('utf-8')

def key_deserializer(key):
    return int(key.decode('utf-8'))
```

The serialization and deserialization must be exact inverses. If the producer uses `json.dumps` then `encode('utf-8')`, the consumer must use `decode('utf-8')` then `json.loads`.

### Docker networking for Kafka

When running Kafka in Docker and connecting from a Python script on the host machine, there are two advertised addresses:

- `PLAINTEXT://kafka:29092` for containers inside the Docker network (e.g., Spark workers)
- `OUTSIDE://localhost:9092` for clients on the host machine (e.g., your Python producer script)

Connect from Python scripts on the host with `bootstrap_servers='localhost:9092'`.

Connect from inside Docker containers (e.g., Spark workers in `docker exec` or notebook) with `bootstrap_servers='kafka:29092'`.

This is the same PLAINTEXT/OUTSIDE split explained in the workshop Redpanda section.


## PySpark Structured Streaming

Spark Structured Streaming is Spark's streaming engine. It processes an infinite stream as if it were a continuously growing DataFrame. Your Spark SQL or DataFrame API code looks nearly identical to batch code.

### Mental model

In Structured Streaming, a **streaming DataFrame** represents an unbounded table. Each micro-batch, Spark reads new rows from the source (Kafka, files, socket), appends them to this logical table, and re-evaluates your query.

You write transformations (filter, groupBy, join) on the streaming DataFrame exactly as you would on a batch DataFrame. Spark figures out how to execute them incrementally.


## Infrastructure setup

The extras section uses a custom Docker Compose with Kafka and Spark:

```
kafka/docker-compose.yml    # Kafka + Schema Registry + Control Center
docker/docker-compose.yml   # Spark + JupyterLab
```

Two Docker networks are needed for cross-service communication:

```bash
# Create the shared bridge network
docker network create kafka-spark-network

# Start Kafka services
cd kafka && docker compose up -d

# Start Spark services
cd docker && docker compose up -d
```

JupyterLab is then available at `http://localhost:8888`.

Spark services: JupyterLab (notebook interface), Spark Master, Spark Worker.


## Python producer and consumer (Docker Kafka)

### Producer

Read a CSV file and produce each row as a JSON message:

```python
from kafka import KafkaProducer
import json
import csv

producer = KafkaProducer(
    bootstrap_servers='localhost:9092',
    key_serializer=lambda k: str(k).encode('utf-8'),
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

with open('resources/rides.csv') as f:
    reader = csv.DictReader(f)
    for row in reader:
        key = row['VendorID']
        producer.send('rides', key=key, value=row)

producer.flush()
```

### Consumer

```python
from kafka import KafkaConsumer
import json

consumer = KafkaConsumer(
    'rides',
    bootstrap_servers='localhost:9092',
    auto_offset_reset='earliest',
    group_id='python-consumer',
    key_deserializer=lambda k: k.decode('utf-8'),
    value_deserializer=lambda v: json.loads(v.decode('utf-8'))
)

for message in consumer:
    print(f"key={message.key}, value={message.value}")
```

For Avro serialization (using `confluent-kafka` and the Schema Registry), replace the serializer/deserializer with `AvroSerializer`/`AvroDeserializer`. The schema is registered automatically on first produce.


## Reading a Kafka topic with Spark

Spark requires additional JAR files to connect to Kafka. Pass them via `spark.jars.packages` when creating the SparkSession:

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .master('local[*]') \
    .appName('kafka-streaming') \
    .config('spark.jars.packages',
            'org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0') \
    .getOrCreate()
```

Spark downloads the JAR automatically on first run. Subsequent runs use the cached JAR.

Read the Kafka topic as a streaming DataFrame:

```python
df_raw = spark.readStream \
    .format('kafka') \
    .option('kafka.bootstrap.servers', 'kafka:29092') \
    .option('subscribe', 'rides') \
    .option('startingOffsets', 'earliest') \
    .load()
```

The resulting DataFrame has these columns:

| Column | Type | Description |
|---|---|---|
| key | binary | Message key |
| value | binary | Message payload (your actual data) |
| topic | string | Topic name |
| partition | int | Partition number |
| offset | long | Offset within the partition |
| timestamp | timestamp | Broker timestamp |
| timestampType | int | 0 = CREATE_TIME, 1 = LOG_APPEND_TIME |

The `value` column contains your data but is still raw bytes. You must cast or parse it.

`df_raw.isStreaming` returns `True`, confirming this is a streaming DataFrame. Calling `.show()` on a streaming DataFrame raises an error. You must use `.writeStream` to output it.


## Parsing and transforming the stream

Cast `key` and `value` from bytes to strings:

```python
from pyspark.sql.functions import col

df_strings = df_raw.selectExpr(
    'CAST(key AS STRING) as key',
    'CAST(value AS STRING) as value'
)
```

If the value is JSON, parse it using `from_json` with a defined schema:

```python
from pyspark.sql.functions import from_json
from pyspark.sql.types import StructType, StructField, StringType, FloatType, IntegerType

schema = StructType([
    StructField('VendorID', StringType()),
    StructField('tpep_pickup_datetime', StringType()),
    StructField('tpep_dropoff_datetime', StringType()),
    StructField('passenger_count', FloatType()),
    StructField('trip_distance', FloatType()),
    StructField('payment_type', IntegerType()),
    StructField('total_amount', FloatType()),
])

df_parsed = df_strings.withColumn('data', from_json(col('value'), schema)) \
                      .select('data.*')
```

After `select('data.*')`, you have a proper streaming DataFrame with typed columns. Apply any transformation you would apply to a batch DataFrame: filter, join, groupBy, withColumn, etc.


## Output modes and sinks

A streaming query is started with `writeStream`. You must specify:

1. **Format (sink):** where the output goes
2. **Output mode:** which rows to output in each micro-batch
3. **Checkpoint location:** where Spark saves progress (required for fault tolerance)

### Sinks

| Sink | Use case |
|---|---|
| `console` | Debugging. Prints to driver logs. Not for production. |
| `memory` | Debugging. Stores in an in-memory table queryable with Spark SQL. Not for production. |
| `kafka` | Write results to a Kafka topic. |
| `parquet` / `csv` | Write to files on disk or cloud storage. |
| `foreach` / `foreachBatch` | Custom sink logic (e.g., write to PostgreSQL). |

### Output modes

| Mode | When to use |
|---|---|
| `append` | Only new rows are output per micro-batch. Use with stateless transforms (filter, map) or windowed aggregations after the window closes. |
| `complete` | The entire result table is output every micro-batch. Only valid with aggregations. Expensive for large results. |
| `update` | Only rows that changed since the last micro-batch are output. Useful for running aggregations where you want incremental updates. |

Not all combinations of transformation and output mode are valid. For example, a `groupBy` without a window requires `complete` or `update` mode. Spark will raise an error if you choose an incompatible mode.

### Example: write to console

```python
query = df_parsed \
    .writeStream \
    .format('console') \
    .outputMode('append') \
    .option('checkpointLocation', '/tmp/spark-checkpoint') \
    .start()

query.awaitTermination()
```

### Example: write to Kafka

```python
from pyspark.sql.functions import to_json, struct

df_out = df_parsed.select(
    col('VendorID').alias('key'),
    to_json(struct('*')).alias('value')
)

query = df_out \
    .writeStream \
    .format('kafka') \
    .option('kafka.bootstrap.servers', 'kafka:29092') \
    .option('topic', 'rides-output') \
    .option('checkpointLocation', '/tmp/spark-checkpoint') \
    .outputMode('append') \
    .start()
```

### Example: write to PostgreSQL with foreachBatch

```python
import psycopg2

def write_to_postgres(batch_df, batch_id):
    conn = psycopg2.connect(
        host='localhost', port=5432,
        dbname='postgres', user='postgres', password='postgres'
    )
    cur = conn.cursor()
    rows = batch_df.collect()
    for row in rows:
        cur.execute(
            "INSERT INTO rides (vendor_id, trip_distance) VALUES (%s, %s)",
            (row['VendorID'], row['trip_distance'])
        )
    conn.commit()
    conn.close()

query = df_parsed \
    .writeStream \
    .foreachBatch(write_to_postgres) \
    .option('checkpointLocation', '/tmp/spark-checkpoint') \
    .start()
```

`foreachBatch` gives you a regular batch DataFrame for each micro-batch. You can use any Python library inside it. This is the recommended way to write to databases not natively supported by Spark.


## Streaming vs. batch DataFrames

Spark Structured Streaming is intentionally similar to batch Spark. The key behavioral differences:

| Aspect | Batch | Streaming |
|---|---|---|
| `.show()` | Works | Raises AnalysisException |
| `.count()` | Returns a number | Requires writeStream |
| Action trigger | `.show()`, `.collect()`, `.write` | `.writeStream.start()` |
| Execution | Runs once and finishes | Runs continuously until cancelled |
| Fault tolerance | Re-run the whole job | Checkpoint + exactly-once guarantees |

A streaming DataFrame knows it is streaming (`df.isStreaming == True`). Spark tracks this through the query plan. Operations that require seeing all data at once (like `.sort()` without a window) are not supported on streaming DataFrames.

The checkpoint location stores:
- Offsets consumed per partition (so Spark knows where to restart after a crash)
- State store data (for stateful aggregations like groupBy, deduplication, joins)

Always set a checkpoint location for production streaming jobs. Without it, a job restart replays all data from the beginning.

# Kafka Theory (Optional)

## Table of Contents

- [Kafka Theory (Optional)](#kafka-theory-optional)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [What is stream processing?](#what-is-stream-processing)
    - [The notice board analogy](#the-notice-board-analogy)
    - [Batch vs. stream](#batch-vs-stream)
    - [Why microservices need Kafka](#why-microservices-need-kafka)
  - [What is Kafka?](#what-is-kafka)
    - [Core concepts](#core-concepts)
    - [Why Kafka is special](#why-kafka-is-special)
  - [Confluent Cloud](#confluent-cloud)
  - [Kafka producer and consumer (Java)](#kafka-producer-and-consumer-java)
    - [Java producer](#java-producer)
    - [Java consumer](#java-consumer)
  - [Kafka configuration](#kafka-configuration)
    - [Replication](#replication)
    - [Partitions](#partitions)
    - [Offset and `auto.offset.reset`](#offset-and-autooffsetreset)
    - [Acknowledgement (`acks`)](#acknowledgement-acks)
    - [Retention](#retention)
    - [Configuration recap](#configuration-recap)
  - [Kafka Streams basics](#kafka-streams-basics)
  - [Kafka Streams join](#kafka-streams-join)
  - [Kafka Streams testing](#kafka-streams-testing)
  - [Kafka stream windowing](#kafka-stream-windowing)
  - [ksqlDB and Connect](#ksqldb-and-connect)
  - [Schema registry](#schema-registry)
    - [The problem](#the-problem)
    - [The solution](#the-solution)
    - [Avro](#avro)
    - [Compatibility modes](#compatibility-modes)


## Introduction

This section covers the conceptual foundations of stream processing and the specific Kafka features that make it suitable for building production streaming systems.

Topics:

- What is stream processing and how it differs from batch
- What Kafka is and why it is so widely used
- Producers, consumers, topics, partitions, and offsets
- Kafka configuration parameters
- Kafka Streams (a stream processing library that runs on top of Kafka)
- ksqlDB (a SQL interface for Kafka Streams)
- Schema registry and Avro for schema evolution


## What is stream processing?

**Data exchange** is the foundation: two systems sharing information. A producer puts data somewhere; a consumer reads it. That description fits both batch (an email, a daily CSV file) and streaming.

The difference is latency. In batch processing, data is exchanged with a delay of minutes or hours. In stream processing, the exchange happens in near real time, typically within seconds.

### The notice board analogy

Think of a notice board with multiple topic areas (Kafka, Spark, BigData). A producer pins a message to the Kafka topic. Only consumers subscribed to that topic receive it. They can act on it immediately instead of checking the board once a day.

This is exactly how a pub/sub message bus works. Kafka is that notice board, operated at massive scale and with strong reliability guarantees.

### Batch vs. stream

| Property | Batch | Stream |
|---|---|---|
| Trigger | Scheduled (e.g., hourly) | Continuous, event-driven |
| Latency | Minutes to hours | Seconds or less |
| Processing unit | A bounded set of records | An unbounded, ongoing flow |
| Typical use case | Daily reports, ETL pipelines | Fraud detection, real-time dashboards |

### Why microservices need Kafka

Modern architectures decompose large monolithic applications into many small microservices. Those services need to communicate. They can use REST APIs (synchronous, tight coupling) or a message bus (asynchronous, loose coupling).

Kafka acts as the message bus. One service writes an event to a Kafka topic. Other services that care about that event consume it independently. The producer does not know or care who is consuming. Services can be added, removed, or restarted without coordinating with each other.

Kafka also enables **CDC (Change Data Capture)**: a database connector streams every INSERT/UPDATE/DELETE as a Kafka event, so microservices can react to database changes without polling the database.


## What is Kafka?

Kafka is a distributed streaming platform. Its core abstraction is the **topic**: an append-only, ordered log of events.

### Core concepts

**Topic.** A named, ordered sequence of events. Each event in a topic is called a record or message. Topics are like database tables, except they are append-only and have a configurable retention period (messages expire after N days or when the topic reaches a size limit).

**Event / Record.** A single data point at a specific timestamp. For example: the temperature of a room at 14:32:05. In Kafka, every record has three fields:

| Field | Description |
|---|---|
| Key | Used for partitioning. Records with the same key always go to the same partition. Can be null. |
| Value | The actual payload. Usually JSON or Avro binary. |
| Timestamp | When the event occurred. |

**Producer.** An application that writes records to a topic. The producer chooses the key; Kafka routes the record to a partition based on the key hash.

**Consumer.** An application that reads records from a topic. Multiple consumers can read the same topic independently. Kafka does not delete messages after a consumer reads them (unlike a traditional queue).

**Consumer group.** A group of consumers that together process a topic. Each partition is assigned to exactly one consumer in the group. This enables horizontal scaling: more consumers in the group means more parallelism. Two separate groups each receive all messages independently.

**Offset.** An integer that uniquely identifies each record within a partition (0, 1, 2, ...). Kafka tracks how far each consumer group has read by recording the committed offset in a special internal topic (`__consumer_offsets`). On restart, the consumer asks Kafka for the last committed offset and continues from there.

### Why Kafka is special

**Robustness.** Data is replicated across multiple broker nodes. If a node goes down, a replica on another node takes over. No data loss, no interruption to producers or consumers.

**Flexibility.** Topics can be tiny (a few events per hour) or massive (millions per second). You can connect hundreds of consumers, databases via Kafka Connect, stream processors via Kafka Streams or Flink, and analytics engines via KSQL.

**Scalability.** Partitions are the unit of parallelism. A topic with 10 partitions can be processed by up to 10 consumers in parallel. Adding partitions scales throughput linearly.

**Retention.** Messages are not deleted when consumed. They persist for a configured duration (e.g., 7 days) or until the topic reaches a size limit. This allows consumers to replay history, or to be restarted after a failure and catch up.


## Confluent Cloud

Confluent Cloud is a managed Kafka service. For learning and small workloads, the free trial is sufficient. An alternative is running Kafka or Redpanda locally via Docker (what the workshop does).

To set up a cluster on Confluent Cloud:

1. Sign up and select **Basic cluster** (free tier)
2. Choose a cloud provider and region
3. Create an API key with **Global scope** for connecting clients
4. Create a topic with the desired partition count and retention policy

The free trial grants $400 of credit for 30 days. Note: if you run a Datagen Source connector, it consumes credit quickly. Stop it when not needed.


## Kafka producer and consumer (Java)

The theory videos use Java to show producer/consumer concepts. Java was historically the primary Kafka client language and the library is the most feature-complete.

### Java producer

The `JsonProducer` class reads taxi trip records and publishes them to the `rides` topic:

```java
public void publishRides(List<Ride> rides) throws ExecutionException, InterruptedException {
    KafkaProducer<String, Ride> kafkaProducer = new KafkaProducer<>(props);
    for (Ride ride : rides) {
        var record = kafkaProducer.send(
            new ProducerRecord<>("rides", String.valueOf(ride.DOLocationID), ride),
            (metadata, exception) -> {
                if (exception != null) System.out.println(exception.getMessage());
            }
        );
        System.out.println(record.get().offset());
        Thread.sleep(500);
    }
}
```

Key points:
- The second argument to `ProducerRecord` is the message key. Here, `DOLocationID` is used as the key. All rides with the same dropoff location go to the same partition, so a consumer reading one partition gets all rides for that location.
- The callback `(metadata, exception)` fires asynchronously after the broker acknowledges the message.

### Java consumer

The `JsonConsumer` class polls the topic and prints each record:

```java
public void consumeFromKafka() {
    var results = consumer.poll(Duration.of(1, ChronoUnit.SECONDS));
    do {
        for (ConsumerRecord<String, Ride> result : results) {
            System.out.println(result.value().DOLocationID);
        }
        results = consumer.poll(Duration.of(1, ChronoUnit.SECONDS));
    } while (!results.isEmpty() || i < 10);
}
```

`poll()` fetches records in batches. The consumer keeps polling until no more records arrive.


## Kafka configuration

### Replication

A Kafka topic can be replicated across multiple broker nodes. With replication factor 3:

- One node is the **Leader**: producers and consumers communicate with it
- Two nodes are **Followers**: they copy the leader's data

If the leader node goes down, one follower is elected the new leader automatically. The replication factor is set when creating a topic.

### Partitions

A topic can be split into multiple **partitions**. Each partition is an independent ordered log. Partitions enable:

- **Parallelism:** multiple consumers (one per partition) process the topic simultaneously
- **Distribution:** partitions live on different broker nodes, spreading load

Records with the same key always land in the same partition. Records with no key are distributed round-robin.

### Offset and `auto.offset.reset`

When a new consumer group first connects to a topic, there is no committed offset. The `auto.offset.reset` setting determines where to start:

| Value | Behavior |
|---|---|
| `earliest` | Start from the beginning of the topic partition. Process all historical messages. |
| `latest` | Start from the end. Only process new messages arriving after the consumer starts. This is the default. |
| `none` | Throw an exception if no offset exists for the group. |

### Acknowledgement (`acks`)

When a producer sends a message, it waits for acknowledgement before proceeding. The `acks` parameter controls what "acknowledged" means:

| acks value | Meaning | Use case |
|---|---|---|
| `0` | Fire and forget. Producer does not wait. | Non-critical data, maximum throughput |
| `1` | Leader acknowledged (wrote to its log). | Good balance of safety and speed |
| `all` | Leader and all in-sync replicas acknowledged. | Critical data, no message loss |

### Retention

`retention.ms` controls how long messages are kept. After this time, old messages are deleted regardless of whether they were consumed. Default is 7 days. A separate `retention.bytes` limit can also be set per partition.

### Configuration recap

| Concept | What it does |
|---|---|
| Partition | Sub-divides a topic for parallelism; one consumer per partition in a group |
| Replication | Copies topic data to multiple nodes for fault tolerance |
| Offset | Tracks how far each consumer group has read |
| `auto.offset.reset` | Where to start when no offset exists |
| `acks` | How many nodes must confirm before the producer considers a send successful |
| Retention | How long messages are kept before deletion |


## Kafka Streams basics

Kafka Streams is a client library (not a separate cluster) for building stream processing applications on top of Kafka. It runs inside your application process. No separate Flink or Spark cluster needed.

The core abstraction is the **topology**: a directed graph of sources, processors, and sinks.

A `StreamsBuilder` defines the topology. `KStream` represents a stream of records from a topic:

```java
StreamsBuilder streamsBuilder = new StreamsBuilder();
KStream<String, Ride> rides = streamsBuilder.stream(
    "rides",
    Consumed.with(Serdes.String(), CustomSerdes.getSerde(Ride.class))
);
```

A **Serde** (serializer-deserializer) tells Kafka Streams how to convert topic bytes to Java objects and back. Each `KStream` type parameter needs its own Serde.

A simple processing step: count rides per pickup location and write the result back to a new topic:

```java
rides
    .groupBy((key, ride) -> String.valueOf(ride.PULocationID),
             Grouped.with(Serdes.String(), CustomSerdes.getSerde(Ride.class)))
    .count(Materialized.as("pickup-count-store"))
    .toStream()
    .to("rides-pulocation-count", Produced.with(Serdes.String(), Serdes.Long()));
```

Keys matter: records with the same key are always processed together. Kafka Streams uses the key for grouping, joining, and repartitioning.


## Kafka Streams join

A stream join merges records from two topics based on a shared key within a time window. Example: join the `rides` topic with a `pickup-location` topic on `PULocationID` to produce a combined `VendorInfo` record.

```java
var joined = rides.join(
    pickupLocationsKeyedOnPUId,
    (ride, pickupLocation) -> {
        var period = Duration.between(ride.tpep_dropoff_datetime, pickupLocation.tpep_pickup_datetime);
        if (period.abs().toMinutes() > 10) return Optional.empty();
        return Optional.of(new VendorInfo(
            ride.VendorID,
            pickupLocation.PULocationID,
            pickupLocation.tpep_pickup_datetime,
            ride.tpep_dropoff_datetime
        ));
    },
    JoinWindows.ofTimeDifferenceAndGrace(Duration.ofMinutes(20), Duration.ofMinutes(5)),
    StreamJoined.with(...)
);
```

Key rules for Kafka Streams joins:

- The two streams must be **co-partitioned**: same number of partitions and same key type. Kafka Streams ensures this by repartitioning if needed.
- The `JoinWindows` controls how far apart in time two records can be and still match.
- The `grace` period allows late events to still be joined.

Available join types: inner join (only matching records), left join (all left records, right is optional), outer join (all records from both sides).


## Kafka Streams testing

The `Topology` object that `StreamsBuilder` produces can be tested without running a real Kafka cluster. `TopologyTestDriver` simulates the Kafka protocol in memory:

```java
TopologyTestDriver testDriver = new TopologyTestDriver(topology, props);

TestInputTopic<String, Ride> inputTopic = testDriver.createInputTopic(
    "rides", Serdes.String().serializer(), CustomSerdes.getSerde(Ride.class).serializer()
);

TestOutputTopic<String, Long> outputTopic = testDriver.createOutputTopic(
    "rides-pulocation-count", Serdes.String().deserializer(), Serdes.Long().deserializer()
);

inputTopic.pipeInput("key1", sampleRide);
assertEquals(1L, outputTopic.readValue());
```

This is significantly faster than integration tests and does not require Docker. Always test your topology before deploying it to a real cluster.


## Kafka stream windowing

Windowing allows you to aggregate events over a time range. Kafka Streams supports:

**Tumbling windows:** fixed size, non-overlapping. 1-minute tumbling windows produce results at t+1, t+2, t+3, etc. Each record belongs to exactly one window.

**Hopping (sliding) windows:** fixed size, with a step smaller than the window size. A 10-minute window with a 5-minute step produces overlapping windows. Each record belongs to multiple windows.

**Session windows:** grouped by inactivity gaps. A session closes when there is no activity for a defined period. Useful for user session tracking where sessions vary in length.

**KTable vs. KStream:** A `KTable` represents the latest value per key (like a database table). A `KStream` represents every event including updates. You can convert a stream to a table (`toTable()`) and perform joins between tables and streams.

**Global KTable:** a KTable that is fully replicated to every instance of your application. Useful for small reference data (e.g., location names) that needs to be joined with the main stream without repartitioning.


## ksqlDB and Connect

**ksqlDB** is a SQL engine that runs on top of Kafka. It lets you query and transform Kafka topics using SQL without writing Java or Python code. It is good for exploratory analysis and simple pipelines.

Create a stream from a topic:

```sql
CREATE STREAM rides_stream (
    VendorID VARCHAR,
    trip_distance DOUBLE,
    payment_type INT,
    passenger_count DOUBLE
) WITH (
    KAFKA_TOPIC = 'rides',
    VALUE_FORMAT = 'JSON',
    AUTO_OFFSET_RESET = 'earliest'
);
```

Query it like a table:

```sql
SELECT payment_type, COUNT(*) FROM rides_stream
GROUP BY payment_type
EMIT CHANGES;
```

Create a **persistent query** (always running, writes to a new topic):

```sql
CREATE TABLE payment_type_sessions AS
    SELECT payment_type, COUNT(*) as count
    FROM rides_stream
    WINDOW TUMBLING (SIZE 60 SECONDS)
    GROUP BY payment_type;
```

The difference between `SELECT ... EMIT CHANGES` (push query) and `CREATE TABLE AS` (persistent query):
- Push query: runs while you watch, results go to your terminal
- Persistent query: runs forever in the background, writes to a Kafka topic

**Kafka Connect** is the integration framework for connecting Kafka to external systems without writing code. Connectors exist for PostgreSQL, S3, Elasticsearch, Snowflake, and hundreds of other systems. A **source connector** imports data from an external system into Kafka. A **sink connector** exports data from Kafka to an external system.


## Schema registry

### The problem

When a producer sends JSON to Kafka, the consumer must know the structure of that JSON. If the producer changes a field name or type, the consumer breaks silently (it parses the wrong value) or loudly (JSON parse error). With many consumers reading a topic, coordinating schema changes becomes impossible without a central registry.

### The solution

The **schema registry** (provided by Confluent, also available open-source) is a centralized service that stores and enforces schemas for Kafka topics.

Flow:

1. **Producer publishes schema.** Before sending the first message, the producer registers its schema with the registry. The registry returns a schema ID.
2. **Registry validates compatibility.** If the topic already has a schema, the registry checks whether the new schema is compatible with the old one.
3. **Producer sends messages.** Each message is prefixed with the schema ID so consumers know which version was used.
4. **Consumer fetches schema.** The consumer reads the schema ID from the message, fetches the schema from the registry, and deserializes the message accordingly.

### Avro

The workshop and most production systems use **Avro** as the schema format. Avro advantages:

- Schema is written in JSON (human-readable)
- Data is encoded in binary (compact, efficient)
- Fields are referenced by name, not position (unlike Protobuf's field numbers)
- Rich type system: `long`, `timestamp`, `date`, `enum`, `union`, `record`, `array`
- Native support for schema evolution with compatibility rules

### Compatibility modes

| Mode | What it allows |
|---|---|
| Backward | New consumers can read old messages. You can add optional fields. |
| Forward | Old consumers can read new messages. You can remove optional fields. |
| Full | Both directions. Any combination of adding/removing optional fields. |
| None | No compatibility checking. Dangerous in production. |

In practice: when adding a new field, make it optional with a default value. This is both forward and backward compatible. When removing a field, first make it optional, then remove it in a later version.

Schema evolution in action: if a consumer is running with schema version 2 and the producer upgrades to version 3, the consumer continues to work as long as versions 2 and 3 are compatible. The registry enforces this at the point of schema registration, not at runtime.

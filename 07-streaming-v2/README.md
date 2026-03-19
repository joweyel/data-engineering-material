# Week 7: Stream Processing

## What we build

By the end of the workshop, you will have a working real-time pipeline:

```
Producer (Python) -> Redpanda (Kafka-compatible) -> Flink -> PostgreSQL
```

NYC yellow taxi trip records are the data source. The workshop starts from zero (no broker, no database) and builds each layer incrementally.

## Structure

| Folder                                       | Content                                                                                                 | Required for homework? |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------- | ---------------------- |
| [1-workshop/](1-workshop/)                   | Step-by-step PyFlink pipeline with Redpanda, Python, Flink 2.x, and PostgreSQL                          | Yes                    |
| [2-theory/](2-theory/)                       | Kafka concepts: topics, partitions, replication, Kafka Streams, ksqlDB, schema registry (Java examples) | No (optional)          |
| [3-pyspark-streaming/](3-pyspark-streaming/) | PySpark Structured Streaming consuming from Kafka                                                       | No (optional)          |

## Homework

The homework uses the workshop's Docker infrastructure. Topics covered: Redpanda version check, Kafka producer/consumer in Python, PyFlink tumbling windows, session windows, writing results to PostgreSQL.

## Tech stack

| Component        | What it is                                                       |
| ---------------- | ---------------------------------------------------------------- |
| Redpanda         | Kafka-compatible message broker, written in C++, no JVM required |
| Apache Flink 2.2 | Stateful stream processing engine with SQL-based windowing       |
| PostgreSQL 18    | Sink database for Flink job results                              |
| kafka-python     | Python Kafka client library for producer and consumer code       |
| uv               | Python package and project manager                               |

## Prerequisites

- Docker and Docker Compose
- uv (`curl -LsSf https://astral.sh/uv/install.sh | sh`)
- A SQL client: `uvx pgcli`, DBeaver, pgAdmin, or DataGrip

## Quick start

```bash
cd 1-workshop/
docker compose build
docker compose up -d
```

This starts Redpanda on `localhost:9092`, Flink Job Manager at `http://localhost:8081`, and PostgreSQL on `localhost:5432`.

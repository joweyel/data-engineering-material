# Quickstart

## 1. Start services

```bash
docker compose up --build -d
```

## 2. Create PostgreSQL tables

```bash
uvx pgcli -h localhost -p 5432 -U postgres -d postgres
# password: postgres
```

```sql
CREATE TABLE processed_events (
    PULocationID INTEGER,
    DOLocationID INTEGER,
    trip_distance DOUBLE PRECISION,
    total_amount DOUBLE PRECISION,
    pickup_datetime TIMESTAMP
);

CREATE TABLE processed_events_aggregated (
    window_start TIMESTAMP, 
    PULocationID INTEGER,
    num_trips BIGINT,
    total_revenue DOUBLE PRECISION,
    PRIMARY KEY (window_start, PULocationID)
);
```

## 3. Create Kafka topic

```bash
docker compose exec redpanda rpk topic create rides
```

## 4. Submit Flink job

Pass-through:

```bash
docker compose exec jobmanager ./bin/flink run \
    -py /opt/src/job/pass_through_job.py \
    --pyFiles /opt/src -d
```

Aggregation:

```bash
docker compose exec jobmanager ./bin/flink run \
    -py /opt/src/job/aggregation_job.py \
    --pyFiles /opt/src -d
```

## 5. Send data

Historical data (1000 trips from parquet, runs once):

```bash
uv run python src/producers/producer.py
```

Real-time data (synthetic events, runs continuously, ~20% late events):

```bash
uv run python src/producers/producer_realtime.py
# Ctrl+C to stop
```

## Clean restart

```bash
docker compose down -v
```
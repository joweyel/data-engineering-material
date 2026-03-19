## Question 1. Redpanda version

Run `rpk version` inside the Redpanda container:

```bash
docker exec -it 1-workshop-redpanda-1 rpk version
```

What version of Redpanda are you running?

### Answer 1

```log
rpk version: v25.3.9
Git ref:     836b4a36ef6d5121edbb1e68f0f673c2a8a244e2
Build date:  2026 Feb 26 07 48 21 Thu
OS/Arch:     linux/amd64
Go version:  go1.24.3

Redpanda Cluster
  node-1  v25.3.9 - 836b4a36ef6d5121edbb1e68f0f673c2a8a244e2
```

> `v25.3.9`

--- 


## Question 2. Sending data to Redpanda

Create a topic called `green-trips`:

```bash
docker exec -it workshop-redpanda-1 rpk topic create green-trips
```

Now write a producer to send the green taxi data to this topic.

Read the parquet file and keep only these columns:

- `lpep_pickup_datetime`
- `lpep_dropoff_datetime`
- `PULocationID`
- `DOLocationID`
- `passenger_count`
- `trip_distance`
- `tip_amount`
- `total_amount`

Convert each row to a dictionary and send it to the `green-trips` topic.
You'll need to handle the datetime columns - convert them to strings
before serializing to JSON.

Measure the time it takes to send the entire dataset and flush:

```python
from time import time

t0 = time()

# send all rows ...

producer.flush()

t1 = time()
print(f'took {(t1 - t0):.2f} seconds')
```

How long did it take to send the data?

- 10 seconds
- 60 seconds
- 120 seconds
- 300 seconds


### Answer 2

Create Kafka topic:
 
```bash
docker compose exec redpanda rpk topic create green-trips
```

Create models in src folder and producer script in `producers/` folder:
```bash
touch src/models_green.py
touch src/producers/producer_green.py
```
Code can be found here:
- [src/models_green.py](../src/models_green.py)
- [src/producers/producer_green.py](../src/producers/producer_green.py)

Run the producer and get te answer:

```bash
uv run python src/producers/producer_green.py 
# took 10.65 seconds
```

> `10 seconds`

--- 


## Question 3. Consumer - trip distance

Write a Kafka consumer that reads all messages from the `green-trips` topic
(set `auto_offset_reset='earliest'`).

Count how many trips have a `trip_distance` greater than 5.0 kilometers.

How many trips have `trip_distance` > 5?

- 6506
- 7506
- 8506
- 9506

### Answer 3

Create consumer script in `consumers/` folder:
```bash
touch src/consumers/consumer_green.py
```

Code can be found here: 
- [src/consumers/consumer_green.py](../src/consumers/consumer_green.py)

Run consumer:
```bash
uv run python src/consumers/consumer_green.py
```

Result:
```bash
Total trips: 49416
Trips with distance > 5km: 8506
```

> `8506`

---

## Part 2: PyFlink (Questions 4-6)

For the PyFlink questions, you'll adapt the workshop code to work with
the green taxi data. The key differences from the workshop:

- Topic name: `green-trips` (instead of `rides`)
- Datetime columns use `lpep_` prefix (instead of `tpep_`)
- You'll need to handle timestamps as strings (not epoch milliseconds)


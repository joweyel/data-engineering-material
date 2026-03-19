import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

import pandas as pd
from kafka import KafkaProducer
from models_green import ride_from_row, ride_serializer


url: str = (
    "https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-10.parquet"
)

columns: list[str] = [
    "lpep_pickup_datetime",
    "lpep_dropoff_datetime",
    "PULocationID",
    "DOLocationID",
    "passenger_count",
    "trip_distance",
    "tip_amount",
    "total_amount",
]

df = pd.read_parquet(url, columns=columns)

server: str = "localhost:9092"

producer = KafkaProducer(
    bootstrap_servers=[server],
    value_serializer=ride_serializer,
)

t0 = time.time()

for _, row in df.iterrows():
    ride = ride_from_row(row)
    producer.send("green-trips", value=ride)
    
producer.flush()

t1 = time.time()
print(f"took {(t1 - t0):.2f} seconds")


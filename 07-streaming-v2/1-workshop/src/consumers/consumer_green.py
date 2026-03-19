import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from kafka import KafkaConsumer
from models_green import ride_deserializer

server = 'localhost:9092'
topic_name = 'green-trips'

consumer = KafkaConsumer(
    topic_name,
    bootstrap_servers=[server],
    auto_offset_reset='earliest',
    group_id='hw7-consumer',
    value_deserializer=ride_deserializer
)

print(f"Listening to {topic_name}...")

count = 0
total = 0

for message in consumer:
    ride = message.value
    total += 1
    if ride.trip_distance > 5.0:
        count += 1
    if total % 5000 == 0:
        print(f"  processed {total} messages, {count} with distance > 5km")
    if consumer.assignment() and all(
        consumer.position(tp) >= consumer.end_offsets([tp])[tp]
        for tp in consumer.assignment()
    ):
        break

consumer.close()

print(f"\nTotal trips: {total}")
print(f"Trips with distance > 5km: {count}")

# Week 6: Stream Processing

**Sections:**
- `6.1` [Introduction](#introduction)
- `6.2` [What is stream processing](#stream-processing)
- `6.3` [What is kafka](#kafka)
- `6.4` [Confluent cloud](#confluence)
- `6.5` [Kafka producer consumer](#producer-consumer)
- `6.6` [Kafka configuration](#kafka-configurtation)
- `6.7` [Kafka streams basics](#kafka-streams-basics)
- `6.8` [Kafka stream join](#stream-join)
- `6.9` [Kafka stream testing](#stream-testing)
- `6.10` [Kafka stream windowing](#stream-windowing)
- `6.11` [Kafka ksqldb & Connect](#ksqldb)
- `6.12` [Kafka Schema registry](#schema-registry)
- `6.13` [Kafka Streaming with Python](#kafka-streaming-python)
- `6.14` [Pyspark Structured Streaming](#python-structured-streaming)

<a id="introduction"></a>
## 6.1 Introduction

In this week the following questions will be answered:

- What is Stream Processing?
- What is Kafka?
- What is the role of Kafka in stream processing?
- What are message properties of stream processing?
- What are the configuration parameters for stream processing with Kafka?
- What are Kafka-Producers & Kafka-Consumers?
- How to programmatically consume or produce data?
- How data is partitioned in stream processing?
- How schemas play an important role in stream processing?
- What is `ksqldb`?

This weeks code will be in Java and Python + Spark. 

<a id="stream-processing"></a>
## 6.2 What is stream processing

Stream processing describes a continuous process of obtaining, analyzing and processing data in **a more real-time fashion**. This property of stream processing allows you to get results faster, instead of waiting for a full batch to be processed (as seen in batch processing). A visualization of stream processing could be that a producer is generating data, which is then sent to a topic. The topic is subscribed by consumers and everytime something new is provided, the consumer will obtain and process the data.

![w6_2_kafka_1](images/w6_2_kafka_1.jpg)

<a id="kafka"></a>
## 6.3 What is Kafka

**`To make it short`**: Kafka is a software for stream processing 

### Important concepts
- `Producer`: User that creates and provides data (events) to topics
- `Topic`: Data scructure to which data is send to
- `Consumer`: User that recieves data from topic

### What (exactly) is a topic?
- A topic is a continuous stream of events that subscribers can access
- `Event`: is a datapoint of something that was measured/recorded at a certain timestep (e.g. temperature of a room in °C at a given time)
    - Events are the data that is read by consumers
- `Logs`: Data storage of events
- `Events` contain a `Message` (e.g. timestamp and temperature of a room)
- `Message`: consists of key, value (content) & tiestamp

![w6_3_topic](images/w6_3_topic.jpg)

### But why kafka?

Kafka provides:

- **Robustness**: This means that data is still provided, even when a server goes down. Data is replicated accross different nodes, which enables access, even when one goes down.
- **Flexibility:**: Topics can be very small or big, there could be hundreds of consumers and many more. It is also possible to connect many different components to the topic.
- **Scalability**: Can handle small and big loads of data easily

<a id="confluence"></a>
## 6.4 Confluent cloud

[confluent.cloud](https://confluent.cloud) is a webservice that can be used for hosting kafka clusters. After setting up a free account, you can start and create your first cluster. For this class the free tier is sufficient. For setting up the cluster follow these steps:

1. **`Select cluster type`**: Basic (Free Tier)
2. **`Region/zones`**:
    - `Cloud Provider`: <u>Google Cloud</u> / AWS / Azure
    - `Region`: as you wish
    - `Availability`: as you wish
3. **`Set payment`** Skipped (using free credit)
4. **`Review and launch`**
    - `Cluster name`: kafka_tutorial_cluster

The kafka cluster will now be set up and you will see a dashboard.

<!-- TODO -->
![w6_4_dashboard](images/w6_4_dashboard.jpg)


### Creating an API Key for confluent.cloud
To connect to the newly created cluster on confluent.cloud, an API key is required. This can be easily done by clicking on the `API Key` option on the left sidebar. When on the API-Key page, click `Create key` with `Global scope` for the API key. This should have generated the key. Don't forget to give the key a fitting description like `kafka_cluster_tutorial_key`. Now the key can be downloaded and used.s

### Creating a Topic

Steps to create a topic:

1. Click on the topic-option on the left sidebar, then `Create topic`
2. Create new topic with following (examplary) parameters:
    - **`General`**
        - `Topic name`: tutorial_topic
        - `Partitions`: 2
    - **`Storage`**
        - `Cleanup policy`: delete
        - `Retention time`: 1 day
        - `Retention size`: Infinite (default / no changes)
    - **`Message size`**
        - `Maximum message size in bytes`: (default / no changes)
3. Click `Save & create`

![w6_4_create_topic](images/w6_4_create_topic.jpg)

Now the topic is created with the specified parameters. It can now send end recieve messages. To test it's functionality, go to the `Message` section of the created topic and click `Produce a new message to this topic` and then `Produce` it by clicking on the `Produce` button. Now you should be able to see `key`, `value` and `header` of a `Message`.

**Value**
```json
{
    "ordertime": 1497014222380,
    "orderid": 18,
    "itemid": "Item_184",
    "address": {
        "city": "Mountain View",
        "state": "CA",
        "zipcode": 94041
    }
}
```
**Key**
```json
18
```
**Header**
```json 
[]
```

### Creating a (dummy) connector

Go to the `Connector` option on the left sidebar and choose `Datagen Source`. Then follow the steps:
1. `Topic Selection`: tutorial_topic
2. `Kafka credentials`: Global access
3. `Configuration`: 
    - Output record value format: json
    - Template: Orders
4. `Sizing`: 
    - Connector sizing: 1
5. `Review and launch`:
    - Connector name: OrdersConnector_tutorial

Now click on **`Continue`** to create the connector! After wating a short period of time, you should be able to see messages in json-format incoming to the topic.

<u>**`Important`**</u>: The connector has to be shut down after the tutorial. Otherwise the granted credit for the free tier of confluence.cloud will be use up very fast.



<a id="producer-consumer"></a>
## 6.5 Kafka producer consumer

In this section data with be produced and consumed programmatically, instead of auto generated sample data. For this section the code will be in Java. Python is also available, but is not that well maintained. There are examples from previous versions of the Data Engineering class, where Python was used with docker.

- For this section, a new `topic` is created

![w6_5_topic](images/w6_5_topic.jpg)

- The next step is to connect the topic to a client. For this purpose a Java client is used. For this purpose, click on the `Clients` section on the left side-bar and then choose `Java`. After choosing `Java`, there will appear a configuration snipped that is required for connecting with kafka. 
The code for this client can be found [here](java/kafka_examples/).

### Java Producer

For sending data to the topic the `Secrets`-class has to be given the api-key as well as the `StreamsConfig.BOOTSTRAP_SERVERS_CONFIG` in the [`JSONProducer`-class](java/kafka_examples/src/main/java/org/example/JsonProducer.java). Other than that, the code can stay the same. The `JSONProducer` can then be build with gradle and executed. The program will start sending messages to the `rides` topic. 

```java
// The pulishing method
public void publishRides(List<Ride> rides) throws ExecutionException, InterruptedException {
    KafkaProducer<String, Ride> kafkaProducer = new KafkaProducer<String, Ride>(props);
    for(Ride ride: rides) {
        ride.tpep_pickup_datetime = LocalDateTime.now().minusMinutes(20);
        ride.tpep_dropoff_datetime = LocalDateTime.now();
        var record = kafkaProducer.send(new ProducerRecord<>("rides", String.valueOf(ride.DOLocationID), ride), (metadata, exception) -> {
            if(exception != null) {
                System.out.println(exception.getMessage());
            }
        });
        System.out.println(record.get().offset());
        System.out.println(ride.DOLocationID);
        Thread.sleep(500);
    }
}
```

### Java Consuer
As the name implies the [`JSONConsumer`-class](java/kafka_examples/src/main/java/org/example/JsonConsumer.java) is used to recieve messages from a topic. After building and running it, the client will obtain data from the topic.

```java
// The consuming method
public void consumeFromKafka() {
    System.out.println("Consuming form kafka started");
    var results = consumer.poll(Duration.of(1, ChronoUnit.SECONDS));
    var i = 0;
    do {
        for(ConsumerRecord<String, Ride> result: results) {
            System.out.println(result.value().DOLocationID);
        }
        results =  consumer.poll(Duration.of(1, ChronoUnit.SECONDS));
        System.out.println("RESULTS:::" + results.count());
        i++;
    }
    while(!results.isEmpty() || i < 10);
}
```

<a id="kafka-configurtation"></a>
## 6.6 Kafka configuration

<a id="kafka-streams-basics"></a>
## 6.7 Kafka streams basics

<a id="stream-join"></a>
## 6.8 Kafka stream join

<a id="stream-testing"></a>
## 6.9 Kafka stream testing

<a id="stream-windowing"></a>
## 6.10 Kafka stream windowing

<a id="ksqldb"></a>
## 6.11 Kafka ksqldb & Connect

<a id="schema-registry"></a>
## 6.12 Kafka Schema registry

<a id="kafka-streaming-python"></a>
## 6.13 Kafka Streaming with Python

<a id="python-structured-streaming"></a>
## 6.14 Pyspark Structured Streaming
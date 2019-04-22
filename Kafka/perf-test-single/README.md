# Kafka Single Load Test
### Build the Container
```bash
docker build -t <name> .
```

### Run test to confirm producers and consumers are working
##### Source: https://medium.com/selectstarfromweb/setup-kafka-8f77fbd02688
1. Start Zookeeper
2. Start Kakfa server
3. Create test topic
4. Check test topic exists
5. Start producer
6. Start consumer

Expected: Type something in the producer console - it appears in the consumer console.
```bash
cd kafka_2.12-2.2.0
sh bin/zookeeper-server-start.sh config/zookeeper.properties
sh bin/kafka-server-start.sh config/server.properties
sh bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic test
sh bin/kafka-topics.sh --list --zookeeper localhost:2181
bin/kafka-console-producer.sh --broker-list localhost:9092 --topic test
bin/kafka-console-consumer.sh --bootstrap-server localhost:2181 --topic test                     
```
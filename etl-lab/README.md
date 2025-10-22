# Docker environement for the ETL practice
## Components
* Python container with usefull data/etl libs.
* Kafka container with UI
* Postgresql with PGAdmin
* Apache Nifi

## For the first time run: 
```
# from the current directory
sh init.sh # In NIx OS
# OR in Windows OS
pwsh -File .\setup-env.ps1
# then run
docker compose up -d --build
```
## You can restart the docker env with the following command:
```
docker compose restart
```
## Using the environement
```
docker exec -it pyetlenv /bin/bash
```

## Some Kafka useful commands
```
docker exec -it etlkafka kafka-topics.sh --list --bootstrap-server localhost:9092
docker exec -it etlkafka kafka-topics.sh --create --topic topic-test --bootstrap-server localhost:9092 --partitions 2
docker exec -it etlkafka kafka-console-producer.sh --broker-list localhost:9092 --topic topic-test
docker exec -it etlkafka kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic topic-test --from-beginning
docker exec -it etlkafka kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --all-groups
docker exec -it etlkafka kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic topic-test --time -1
docker exec -it etlkafka kafka-topics.sh --delete --topic topic-test --bootstrap-server localhost:9092

docker exec -it etlkafka kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic topic_step1 --from-beginning
docker exec -it etlkafka kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic input_topic --from-beginning
docker exec -it etlkafka kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic btc_prices --from-beginning

```



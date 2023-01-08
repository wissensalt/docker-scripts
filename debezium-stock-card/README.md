# KF Stock Card 
## debezium-postgresql-elasticsearch

## Tech Stack
- Docker
- Postgresql
- Zookeeper
- ~~Schema Registry (Avro)~~ (There is timestamp issue when using Avro)
- Kafka
- Debezium
- Elasticsearch

## How to Run
```sh
# load environment variables
source .env

# Run all docker instances
docker-compose up
```

```sh
# Check if debezium is UP
curl -H "Accept:application/json" localhost:8083/
```

```sh
# Check if elasticsearch is UP
curl http://localhost:9200
```


```sh
# Deploy all configurations when elasticsearch and debezium is UP
sh deploy-configurations.sh
```

```sh
# Check installed debezium connector plugins
curl -H "Accept:application/json" http://localhost:8083/connector-plugins
```

```sh
# Check installed debezium configurations
curl -H "Accept:application/json" http://localhost:8083/connectors
```

```sh
# Check installed source connector status
curl -H "Accept:application/json" http://localhost:8083/connectors/postgres-stock_card_details-source/status
```

```sh
# Check installed sink connector status
curl -H "Accept:application/json" http://localhost:8083/connectors/es-stock_card_details-sink/status
```

```sh
# Check elasticsearch configurations
curl -H "Accept:application/json" http://localhost:9200/public.stock_card_details
```

```sh
# Check if debezium topic is created 
docker-compose exec kafka /kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 --list
```

```sh
# Check if elasticsearch already has content
curl -H "Accept:application/json" http://localhost:9200/public.stock_card_details/_search?pretty
```

# Watch Message via console consumer
```sh
bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic public.stock_card_details --from-beginning
```

# List Kafka Topics
```sh
bin/kafka-topics.sh --list --bootstrap-server kafka:9092
```

# Delete Kafka Topics
```sh
bin/kafka-topics.sh --bootstrap-server kafka:9092 --delete --topic public.stock_card_details
```

```sh
# Watch messages from debezium topic as Binary
docker-compose exec kafka /kafka/bin/kafka-console-consumer.sh \
    --bootstrap-server kafka:9092 \
    --from-beginning \
    --property print.key=true \
    --topic public.expired_date_details

# Watch messages from debezium topic as Converted Avro to Json
docker run -it --rm --name avro-consumer --network=debezium-stock-card_default \
    --link cdc_zookeeper \
    --link cdc_kafka \
    --link cdc_postgres \
    --link cdc_schema_registry \
    debezium/connect:1.8.1.Final \
    /kafka/bin/kafka-console-consumer.sh \
      --bootstrap-server kafka:9092 \
      --property print.key=true \
      --formatter io.confluent.kafka.formatter.AvroMessageFormatter \
      --property schema.registry.url=http://schema-registry:8081 \
      --topic public.stock_card_details

# Terminate all docker instances
sh shutdown.sh
```

## References
- https://github.com/YegorZaremba/sync-postgresql-with-elasticsearch-example/
- https://github.com/debezium/debezium-examples/tree/main/tutorial
- https://medium.com/dana-engineering/streaming-data-changes-in-mysql-into-elasticsearch-using-debezium-kafka-and-confluent-jdbc-sink-8890ad221ccf
- https://debezium.io/documentation/reference/stable/connectors/mysql.html
- https://debezium.io/documentation/reference/connectors/postgresql.html
- https://docs.confluent.io/debezium-connect-mysql-source/current/mysql_source_connector_config.html
- https://debezium.io/documentation/reference/0.10/configuration/avro.html
- https://debezium.io/documentation/reference/1.2/configuration/event-flattening.html
- https://github.com/confluentinc/demo-scene/blob/master/kafka-to-elasticsearch/README.adoc
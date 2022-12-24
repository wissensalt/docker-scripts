#!/usr/bin/env bash

docker-compose down

docker image rm debezium-stock-card_zookeeper -f

docker image rm debezium-stock-card_kafka -f

docker image rm debezium-stock-card_postgres -f

docker image rm debezium-stock-card_schema_registry -f

docker image rm debezium-stock-card_connect -f

docker image rm debezium-stock-card_elasticsearch -f

docker volume prune
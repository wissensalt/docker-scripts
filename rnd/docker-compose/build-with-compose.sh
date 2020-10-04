#!/bin/sh

# build the springboot app
mvn clean package -DskipTests

# stop and remove existing container and image
docker-compose down

# create and run image
docker-compose up
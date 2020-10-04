#!/bin/sh

# build the springboot app
mvn clean package -DskipTests

# stop existing container
docker container rm docker-copy-command

# remove existing image
docker image rm docker-copy-command

# create image
docker build -t docker-copy-command .

# run the container
docker container run --name docker-copy-command -p 8080:8080 docker-copy-command
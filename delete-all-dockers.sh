#!/bin/sh

# delete containers
docker container rm -f (docker container ls -aq)

# delete images
docker image rm -f (docker image ls -aq)
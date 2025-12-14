#!/bin/sh
# Wait for Redis nodes to be ready
sleep 20

# Create Redis cluster
redis-cli --cluster create \
  redis-1:6379 \
  redis-2:6379 \
  redis-3:6379 \
  --cluster-replicas 0 \
  --cluster-yes
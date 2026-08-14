#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

if command -v docker >/dev/null 2>&1; then
  COMPOSE="docker compose"
elif [ -x /usr/local/bin/docker-compose ]; then
  COMPOSE="/usr/local/bin/docker-compose"
elif command -v podman >/dev/null 2>&1; then
  COMPOSE="podman compose"
else
  echo "Docker Compose not found. Install Docker or Podman compose."
  exit 1
fi

echo "Stopping Redis cluster..."
$COMPOSE down

echo "Removing stale cluster state..."
for dir in redis-1-data redis-2-data redis-3-data; do
  if [ -d "$dir" ]; then
    find "$dir" -mindepth 1 -delete 2>/dev/null || true
  fi
done

echo "Starting Redis cluster with fresh state..."
$COMPOSE up -d

echo "Waiting for cluster initialization..."
for i in $(seq 1 30); do
  if redis-cli -a password -h 127.0.0.1 -p 6379 cluster info 2>/dev/null | grep -q "cluster_state:ok"; then
    break
  fi
  sleep 2
done

$COMPOSE logs redis-cluster-init

echo
echo "Verify from host:"
echo "  redis-cli -c -a password -h 127.0.0.1 -p 6379 CLUSTER NODES"
echo "  redis-cli -c -a password -h 127.0.0.1 -p 6379 SET foo bar"
echo
echo "Connection string:"
echo "  127.0.0.1:6379,127.0.0.1:6380,127.0.0.1:6381 (password: password)"

#!/bin/sh
set -e

REDIS_PASSWORD="password"
NODES="redis-1:6379 redis-2:6380 redis-3:6381"
ANNOUNCE_IP="${CLUSTER_ANNOUNCE_IP:-127.0.0.1}"

wait_for_node() {
  host="$1"
  port="$2"
  until redis-cli -h "$host" -p "$port" -a "$REDIS_PASSWORD" ping 2>/dev/null | grep -q PONG; do
    echo "Waiting for $host:$port..."
    sleep 2
  done
}

apply_announce() {
  host="$1"
  port="$2"
  announce_ip="$3"
  announce_port="$4"
  announce_bus_port="$5"

  redis-cli -h "$host" -p "$port" -a "$REDIS_PASSWORD" CONFIG SET cluster-announce-ip "$announce_ip" >/dev/null
  redis-cli -h "$host" -p "$port" -a "$REDIS_PASSWORD" CONFIG SET cluster-announce-port "$announce_port" >/dev/null
  redis-cli -h "$host" -p "$port" -a "$REDIS_PASSWORD" CONFIG SET cluster-announce-bus-port "$announce_bus_port" >/dev/null
}

cluster_already_formed() {
  known="$(redis-cli -h redis-1 -p 6379 -a "$REDIS_PASSWORD" cluster info 2>/dev/null \
    | awk -F: '/^cluster_known_nodes:/ { gsub("\r", "", $2); print $2 }')"
  [ "${known:-0}" -ge 3 ]
}

for node in $NODES; do
  host="${node%%:*}"
  port="${node##*:}"
  wait_for_node "$host" "$port"
done

if cluster_already_formed; then
  echo "Cluster membership already exists; skipping create."
else
  echo "Creating Redis cluster..."
  redis-cli -a "$REDIS_PASSWORD" --cluster create \
    $NODES \
    --cluster-replicas 0 \
    --cluster-yes
fi

echo "Applying host announce settings ($ANNOUNCE_IP)..."
apply_announce redis-1 6379 "$ANNOUNCE_IP" 6379 16379
apply_announce redis-2 6380 "$ANNOUNCE_IP" 6380 16380
apply_announce redis-3 6381 "$ANNOUNCE_IP" 6381 16381

until redis-cli -h redis-1 -p 6379 -a "$REDIS_PASSWORD" cluster info 2>/dev/null | grep -q "cluster_state:ok"; do
  echo "Waiting for cluster to become healthy..."
  sleep 2
done

echo "Cluster is ready for host connections."

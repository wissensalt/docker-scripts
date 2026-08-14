#!/bin/sh
set -e

CONF="/usr/local/etc/redis/redis.conf"
DATA="/data"
BOOTSTRAP_CONF="/tmp/redis.bootstrap.conf"
NODES_FILE="$(awk '/^cluster-config-file/ {print $2}' "$CONF")"
NODES_PATH="$DATA/$NODES_FILE"

cluster_formed() {
  if [ ! -f "$NODES_PATH" ]; then
    return 1
  fi

  node_lines="$(grep -cE '^[0-9a-f]{40} ' "$NODES_PATH" 2>/dev/null || true)"
  [ "$node_lines" -ge 3 ]
}

apply_announce_settings() {
  announce_ip="$(awk '/^cluster-announce-ip/ {print $2}' "$CONF")"
  announce_port="$(awk '/^cluster-announce-port/ {print $2}' "$CONF")"
  announce_bus_port="$(awk '/^cluster-announce-bus-port/ {print $2}' "$CONF")"

  if [ -z "$announce_ip" ] || [ -z "$announce_port" ]; then
    return 0
  fi

  echo "Applying host announce settings for clients."
  redis-cli -a "$(awk '/^requirepass/ {print $2}' "$CONF")" CONFIG SET cluster-announce-ip "$announce_ip" >/dev/null
  redis-cli -a "$(awk '/^requirepass/ {print $2}' "$CONF")" CONFIG SET cluster-announce-port "$announce_port" >/dev/null
  if [ -n "$announce_bus_port" ]; then
    redis-cli -a "$(awk '/^requirepass/ {print $2}' "$CONF")" CONFIG SET cluster-announce-bus-port "$announce_bus_port" >/dev/null
  fi
}

grep -v '^cluster-announce-' "$CONF" > "$BOOTSTRAP_CONF"

if ! cluster_formed; then
  echo "Cluster not formed yet; starting without announce settings."
  exec redis-server "$BOOTSTRAP_CONF"
fi

echo "Cluster detected; starting and applying host announce settings."
redis-server "$BOOTSTRAP_CONF" &
server_pid=$!

until redis-cli -a "$(awk '/^requirepass/ {print $2}' "$CONF")" ping 2>/dev/null | grep -q PONG; do
  sleep 1
done

apply_announce_settings

wait "$server_pid"

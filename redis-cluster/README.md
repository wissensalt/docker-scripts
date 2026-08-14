# Redis Cluster (Docker)

A local 3-node Redis Cluster for development, running in Docker or Podman Compose. The setup is tuned so applications on your **host machine** can connect through published ports without hitting unreachable Docker-internal IP redirects.

## Overview

| Property | Value |
|---|---|
| Redis version | 7.2 (Alpine) |
| Topology | 3 masters, 0 replicas |
| Hash slots | 16,384 (split across 3 nodes) |
| Password | `password` |
| Host endpoints | `127.0.0.1:6379`, `127.0.0.1:6380`, `127.0.0.1:6381` |

Each node listens on a **different port** inside and outside the container. That keeps host port mappings aligned with the cluster topology and avoids ambiguous redirects.

## Architecture

```
Host machine
  |
  | 127.0.0.1:6379  -> redis-1 (slots 0-5460)
  | 127.0.0.1:6380  -> redis-2 (slots 5461-10922)
  | 127.0.0.1:6381  -> redis-3 (slots 10923-16383)
  |
  v
Docker bridge network (redis-cluster-net)
  redis-1:6379  redis-2:6380  redis-3:6381
```

### Why host connectivity needs special handling

When a cluster client connects to `127.0.0.1:6379`, Redis responds with slot ownership via `CLUSTER SLOTS` or `MOVED` redirects. In a default Docker setup, those responses contain **bridge-network IPs** such as `10.89.7.x:6379`, which the host cannot reach.

This repository solves that with a two-phase startup:

1. **Bootstrap** — nodes start without announce settings and form a cluster on the Docker network.
2. **Announce** — `cluster-init` applies `127.0.0.1` announce settings at runtime via `CONFIG SET`, so host clients receive reachable addresses without breaking inter-node gossip.

On subsequent container restarts, `redis-entrypoint.sh` repeats the same pattern: start without announce, then apply announce settings once the node is up.

## Prerequisites

- Docker Desktop, Podman, or another Compose-compatible runtime
- Docker Compose v2, `docker-compose`, or `podman compose`
- `redis-cli` on your host (optional, for verification)

## Quick start

```bash
# Start the cluster
docker compose up -d

# Or reset from a clean state (recommended after config changes)
./reset-cluster.sh
```

Wait ~30 seconds for `redis-cluster-init` to finish. Then verify:

```bash
redis-cli -c -a password -h 127.0.0.1 -p 6379 CLUSTER INFO
redis-cli -c -a password -h 127.0.0.1 -p 6379 SET foo bar
redis-cli -c -a password -h 127.0.0.1 -p 6379 GET foo
```

Expected:

- `cluster_state:ok`
- `CLUSTER SLOTS` lists `127.0.0.1:6379`, `127.0.0.1:6380`, and `127.0.0.1:6381`
- `SET` / `GET` succeed from the host

## Connection details

### Host connection string

Use **all three nodes** as cluster seeds:

```
127.0.0.1:6379,127.0.0.1:6380,127.0.0.1:6381
```

| Setting | Value |
|---|---|
| Password | `password` |
| Mode | Cluster (not standalone) |
| TLS | Disabled |

### Port map

| Service | Host port | Container port | Cluster bus (host) |
|---|---|---|---|
| redis-1 | 6379 | 6379 | 16379 |
| redis-2 | 6380 | 6380 | 16380 |
| redis-3 | 6381 | 6381 | 16381 |

Cluster bus ports (`client_port + 10000`) are published for tooling and clients that need them.

### From other containers

Other containers on the same Compose network can reach nodes by service name:

```
redis-1:6379
redis-2:6380
redis-3:6381
```

Use cluster mode and the same password.

## Repository layout

```
redis-cluster/
├── docker-compose.yml      # Service definitions and port mappings
├── cluster-init.sh         # Creates cluster and applies host announce settings
├── redis-entrypoint.sh     # Bootstrap/announce startup logic per node
├── reset-cluster.sh        # Wipes data and recreates the cluster
├── redis-1.conf            # Node 1 config (port 6379)
├── redis-2.conf            # Node 2 config (port 6380)
├── redis-3.conf            # Node 3 config (port 6381)
├── redis-1-data/           # Node 1 persistent data (gitignored)
├── redis-2-data/           # Node 2 persistent data (gitignored)
└── redis-3-data/           # Node 3 persistent data (gitignored)
```

## Configuration

### Changing the password

1. Update `requirepass` in `redis-1.conf`, `redis-2.conf`, and `redis-3.conf`.
2. Update `REDIS_PASSWORD` in `cluster-init.sh`.
3. Run `./reset-cluster.sh`.

### Changing announce address

By default, nodes announce `127.0.0.1` for host-local development. To expose the cluster to other machines on your LAN:

1. Set `cluster-announce-ip` in each `redis-*.conf` to your host's LAN IP.
2. Update the matching values in `cluster-init.sh` (`apply_announce` calls).
3. Run `./reset-cluster.sh`.

### Node settings

All nodes share these settings:

- `cluster-enabled yes`
- `cluster-node-timeout 5000`
- `appendonly yes` (AOF persistence)
- `bind 0.0.0.0`
- `protected-mode no` (development only)

## Common operations

### Start

```bash
docker compose up -d
```

### Stop

```bash
docker compose down
```

### View logs

```bash
docker compose logs -f redis-1 redis-2 redis-3
docker compose logs redis-cluster-init
```

### Inspect cluster state

```bash
redis-cli -c -a password -h 127.0.0.1 -p 6379 CLUSTER NODES
redis-cli -c -a password -h 127.0.0.1 -p 6379 CLUSTER SLOTS
redis-cli -a password -h 127.0.0.1 -p 6379 CLUSTER INFO
```

### Reset cluster (wipe all data)

```bash
./reset-cluster.sh
```

This stops the stack, deletes contents of `redis-*-data/`, starts fresh, and waits until `cluster_state:ok`.

## Client examples

### redis-cli

Always use cluster mode (`-c`):

```bash
redis-cli -c -a password -h 127.0.0.1 -p 6379
```

### Node.js (ioredis)

```javascript
import { Cluster } from 'ioredis';

const cluster = new Cluster(
  [
    { host: '127.0.0.1', port: 6379 },
    { host: '127.0.0.1', port: 6380 },
    { host: '127.0.0.1', port: 6381 },
  ],
  {
    redisOptions: {
      password: 'password',
    },
  }
);

await cluster.set('foo', 'bar');
console.log(await cluster.get('foo'));
```

### Python (redis-py)

```python
from redis.cluster import RedisCluster

rc = RedisCluster(
    host="127.0.0.1",
    port=6379,
    password="password",
    decode_responses=True,
)

rc.set("foo", "bar")
print(rc.get("foo"))
```

Pass startup nodes for all three ports if your client supports multiple seeds.

## Troubleshooting

### `CLUSTERDOWN` or `Hash slot not served`

The cluster is incomplete or stale. Reset it:

```bash
./reset-cluster.sh
```

This usually happens when `redis-*-data/` contains a cluster formed with old Docker bridge IPs.

### `MOVED` redirects to `10.x.x.x` or another unreachable IP

Announce settings were not applied. Check init logs:

```bash
docker compose logs redis-cluster-init
```

You should see `Applying host announce settings...` followed by `Cluster is ready for host connections.` If not, run `./reset-cluster.sh`.

### `NOAUTH Authentication required`

Provide the password:

```bash
redis-cli -c -a password -h 127.0.0.1 -p 6379
```

### Connection refused on host ports

Confirm containers are running:

```bash
docker compose ps
```

Then check node logs:

```bash
docker compose logs redis-1
```

### Init container exits but cluster is not healthy

Wait a bit longer, then inspect:

```bash
docker compose logs redis-cluster-init
redis-cli -a password -h 127.0.0.1 -p 6379 CLUSTER INFO
```

If `cluster_state` is still not `ok` after a minute, run `./reset-cluster.sh`.

### Podman on macOS

This setup works with Podman Compose. If `docker` is aliased to Podman, both `docker compose` and `podman compose` should work. The `reset-cluster.sh` script detects available compose commands automatically.

## Security notes

This configuration is intended for **local development only**:

- A fixed, known password (`password`)
- `protected-mode no`
- No TLS
- Ports bound to all interfaces on the host

Do not expose this setup to untrusted networks or use it in production without hardening.

## Limitations

- **3 masters, no replicas** — losing a node loses its slot range until it is restored.
- **No automatic resharding** — adding or removing nodes requires manual `redis-cli --cluster` operations.
- **Announce settings are runtime-applied** — they are not persisted to disk via `CONFIG REWRITE` because config files are mounted read-only. The entrypoint and init scripts re-apply them on every start.
- **Single-host focused** — `127.0.0.1` announce works for apps on the same machine. Remote clients need a reachable announce IP.

## License

Part of the [docker-scripts](https://github.com/Wissensalt/docker-scripts) repository. Use at your own discretion for development purposes.

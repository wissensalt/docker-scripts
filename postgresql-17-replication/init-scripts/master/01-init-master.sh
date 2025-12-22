#!/bin/bash
set -e

# Create replication user
# We use the env variables passed to the container for the master user, but hardcode/configure replication user here
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'replicator_password';
    GRANT CONNECT ON DATABASE "$POSTGRES_DB" TO replicator;
    GRANT USAGE ON SCHEMA public TO replicator;
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO replicator;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO replicator;
EOSQL

# Append to pg_hba.conf to allow replication connections
# Trusting the subnet or specific IP would be better security, but for docker-compose 0.0.0.0/0 with md5 is acceptable for dev/local.
echo "host replication replicator 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"

# Reload configuration is handled by the server start, but since this runs during initdb, the server isn't fully "up" in the invalidatable sense usually, 
# but the config file is edited for the subsequent start.

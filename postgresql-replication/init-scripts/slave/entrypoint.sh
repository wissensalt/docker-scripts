#!/bin/bash
set -e

# Define master host and strings
MASTER_HOST=postgresql-master
REPLICATION_USER=replicator
REPLICATION_PASSWORD=replicator_password

# Wait until master is ready
until pg_isready -h "$MASTER_HOST" -p 5432 -U "$POSTGRES_USER"; do
    echo "Waiting for master ($MASTER_HOST)..."
    sleep 3
done

# If $PGDATA is empty, run base backup
if [ -z "$(ls -A "$PGDATA")" ]; then
    echo "Data directory is empty. Starting base backup from $MASTER_HOST..."
    
    # Run pg_basebackup as postgres user
    # -h: host, -U: user, -D: destination, -Fp: plain format, -Xs: stream WAL, -P: progress, -R: write config
    PGPASSWORD=$REPLICATION_PASSWORD pg_basebackup -h "$MASTER_HOST" -U "$REPLICATION_USER" -D "$PGDATA" -Fp -Xs -P -R
    
    echo "Base backup completed."
    
    # Ensure permissions are correct (since we might be running as root)
    chown -R postgres:postgres "$PGDATA"
    chmod 700 "$PGDATA"
else
    echo "Data directory is not empty. Skipping base backup."
fi

# Hand off to the official entrypoint
exec docker-entrypoint.sh "$@"

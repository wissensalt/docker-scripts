#!/usr/bin/env bash

echo ">>>>> start deploy configs for expired_date_details"

# setup elasticsearch indices
curl -i -X PUT -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:9200/public.expired_date_details?include_type_name=true -d @configs/expired_date_details/es-expired_date_details-index.json

# setup elasticsearch sink
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @configs/expired_date_details/es-expired_date_details-sink.json

# setup connector
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @configs/expired_date_details/postgres-expired_date_details-source.json

echo ">>>>> finish deploy configs for expired_date_details"
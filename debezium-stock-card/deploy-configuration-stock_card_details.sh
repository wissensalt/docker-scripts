#!/usr/bin/env bash

echo ">>>>> start deploy configs for stock_card_details"

# setup elasticsearch indices
curl -i -X PUT -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:9200/public.stock_card_details?include_type_name=true -d @configs/stock_card_details/es-stock_card_details-index.json

# setup elasticsearch sink
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @configs/stock_card_details/es-stock_card_details-sink.json

# setup connector
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @configs/stock_card_details/postgres-stock_card_details-source.json

echo ">>>>> finish deploy configs for stock_card_details"
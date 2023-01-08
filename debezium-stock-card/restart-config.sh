#!/usr/bin/env bash

# DELETE INDEX
curl -X DELETE http://localhost:9200/public.stock_card_details

# DELETE source connector
curl -X DELETE http://localhost:8083/connectors/postgres-stock_card_details-source

# DELETE sink connector
curl -X DELETE http://localhost:8083/connectors/es-stock_card_details-sink

echo ">>>>> start deploy configs for stock_card_details"

# setup index
curl -i -X PUT -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:9200/public.stock_card_details?include_type_name=true -d @configs/stock_card_details/es-stock_card_details-index.json

# setup source connector
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @configs/stock_card_details/postgres-stock_card_details-source.json

# setup sink connector
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @configs/stock_card_details/es-stock_card_details-sink.json

echo ">>>>> finish deploy configs for stock_card_details"
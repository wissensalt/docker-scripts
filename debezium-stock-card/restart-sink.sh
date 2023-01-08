#!/usr/bin/env bash

# DELETE sink connector
curl -X DELETE http://localhost:8083/connectors/es-stock_card_details-sink

# setup sink connector
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @configs/stock_card_details/es-stock_card_details-sink.json
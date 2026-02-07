#!/usr/bin/env bash
set -euo pipefail

RESOURCE_GROUP=${RESOURCE_GROUP:-}
TOPIC_NAME=${TOPIC_NAME:-}
SUBJECT=${SUBJECT:-fncast-demo}
DATA=${DATA:-'{ "message": "hello from event grid" }'}

if [[ -z "$RESOURCE_GROUP" || -z "$TOPIC_NAME" ]]; then
  echo "Usage: RESOURCE_GROUP=<rg> TOPIC_NAME=<topic> SUBJECT=<subject> DATA='<json>' ./publish-eventgrid.sh"
  exit 1
fi

TOPIC_ENDPOINT=$(az eventgrid topic show --resource-group "$RESOURCE_GROUP" --name "$TOPIC_NAME" --query endpoint -o tsv)
KEY=$(az eventgrid topic key list --resource-group "$RESOURCE_GROUP" --name "$TOPIC_NAME" --query key1 -o tsv)

EVENTS=$(cat <<EOF
[
  {
    "id": "$(uuidgen)",
    "eventType": "fncast.demo",
    "subject": "$SUBJECT",
    "eventTime": "$(date -Iseconds)",
    "data": $DATA,
    "dataVersion": "1.0"
  }
]
EOF
)

curl -sS -X POST "$TOPIC_ENDPOINT" \
  -H "aeg-sas-key: $KEY" \
  -H "Content-Type: application/json" \
  -d "$EVENTS"

echo "Event published to topic '$TOPIC_NAME'"

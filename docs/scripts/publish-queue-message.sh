#!/usr/bin/env bash
set -euo pipefail

QUEUE_NAME=${QUEUE_NAME:-fncast-events}
MESSAGE=${MESSAGE:-}
CONNECTION_STRING=${CONNECTION_STRING:-}
RESOURCE_GROUP=${RESOURCE_GROUP:-}
STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME:-}

if [[ -z "$MESSAGE" ]]; then
  echo "Usage: MESSAGE='<text>' CONNECTION_STRING='<conn>' ./publish-queue-message.sh"
  echo "Or: MESSAGE='<text>' RESOURCE_GROUP='<rg>' STORAGE_ACCOUNT_NAME='<name>' ./publish-queue-message.sh"
  exit 1
fi

if [[ -z "$CONNECTION_STRING" ]]; then
  if [[ -z "$RESOURCE_GROUP" || -z "$STORAGE_ACCOUNT_NAME" ]]; then
    echo "Provide either CONNECTION_STRING or (RESOURCE_GROUP and STORAGE_ACCOUNT_NAME)."
    exit 1
  fi
  KEY=$(az storage account keys list -g "$RESOURCE_GROUP" -n "$STORAGE_ACCOUNT_NAME" --query "[0].value" -o tsv)
  CONNECTION_STRING="DefaultEndpointsProtocol=https;AccountName=$STORAGE_ACCOUNT_NAME;AccountKey=$KEY;EndpointSuffix=core.windows.net"
fi

az storage queue create --name "$QUEUE_NAME" --connection-string "$CONNECTION_STRING" 1>/dev/null
az storage message put --queue-name "$QUEUE_NAME" --content "$MESSAGE" --connection-string "$CONNECTION_STRING"

echo "Message published to queue '$QUEUE_NAME'"

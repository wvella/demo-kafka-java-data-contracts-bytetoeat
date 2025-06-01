#!/bin/bash

# Check for unique-id argument
if [[ $# -lt 1 || -z "$1" ]]; then
  echo "❌ Unique ID not specified."
  echo "Usage: $0 <unique-id>"
  exit 1
fi
UNIQUE_ID="$1"
RESOURCE_GROUP="demo-data-contracts-bytetoeat-$UNIQUE_ID"

# Ensure you are logged in to Azure
az account show > /dev/null 2>&1 || az login

# Delete resource group
echo "📦 Deleting resource group: $RESOURCE_GROUP"
if az group show --name "$RESOURCE_GROUP" > /dev/null 2>&1; then
    az group delete --name "$RESOURCE_GROUP" --yes --no-wait
    echo "🗑 Resource group deleted: $RESOURCE_GROUP"
else
    echo "✅ Resource group not found: $RESOURCE_GROUP"
fi

# Delete app registrations
echo "🔍 Deleting app registrations for unique ID: $UNIQUE_ID"
APP_NAMES=("demo-data-contracts-bytetoeat-$UNIQUE_ID-tf" "demo-data-contracts-bytetoeat-$UNIQUE_ID-java-producer" "demo-data-contracts-bytetoeat-$UNIQUE_ID-java-consumer")

for APP_NAME in "${APP_NAMES[@]}"; do
    APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)
    if [[ -n "$APP_ID" ]]; then
        echo "🗑 Deleting app registration: $APP_NAME"
        az ad app delete --id "$APP_ID"
    else
        echo "✅ App registration not found: $APP_NAME"
    fi
done

echo "✅ Cleanup completed."

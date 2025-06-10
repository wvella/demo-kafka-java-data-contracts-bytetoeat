#!/bin/bash
# Usage: ./add-azure-role-assignment.sh <unique-id>

if [[ $# -lt 1 || -z "$1" ]]; then
  exit 1
fi
UNIQUE_ID="$1"

az account show > /dev/null 2>&1 || az login

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RESOURCE_GROUP="demo-data-contracts-bytetoeat-$UNIQUE_ID"

# List of Key Vault names to assign roles to
KEYVAULT_NAME_SHARED="bte-$UNIQUE_ID-kv-shared"
SP_NAME=("demo-data-contracts-bytetoeat-$UNIQUE_ID-tf")
SP_ID=$(az ad sp list --display-name "$SP_NAME" --query "[0].id" -o tsv 2>/dev/null)

# Owner User role
az role assignment create \
    --assignee "$SP_ID" \
    --role "Owner" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME_SHARED" \
    --only-show-errors > /dev/null 2>&1

# Assign Key Vault Administrator role on the Key Vault.
# Even with the Key Vault Administrator role at the resource group level, your service principal can delete the Key Vault,
# but reading the status of deleted vaults (to confirm deletion or for purge protection) requires the Microsoft.KeyVault/locations/deletedVaults/read permission at the subscription level.
az role assignment create \
    --assignee "$SP_ID" \
    --role "Key Vault Administrator" \
    --scope "/subscriptions/$SUBSCRIPTION_ID" \
    --only-show-errors > /dev/null 2>&1

# Assign Key Vault Administrator role on the Key Vault
az role assignment create \
    --assignee "$SP_ID" \
    --role "Key Vault Administrator" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
    --only-show-errors > /dev/null 2>&1

KEYVAULT_NAME="bte-$UNIQUE_ID-kv"
SP_NAME=("demo-data-contracts-bytetoeat-$UNIQUE_ID-java-producer")
SP_ID=$(az ad sp list --display-name "$SP_NAME" --query "[0].id" -o tsv 2>/dev/null)
if [[ -z "$SP_ID" ]]; then
    continue
fi

# Key Vault Crypto User role
az role assignment create \
    --assignee "$SP_ID" \
    --role "Key Vault Crypto User" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME" \
    --only-show-errors > /dev/null 2>&1

SP_NAME=("demo-data-contracts-bytetoeat-$UNIQUE_ID-java-consumer")
SP_ID=$(az ad sp list --display-name "$SP_NAME" --query "[0].id" -o tsv 2>/dev/null)
if [[ -z "$SP_ID" ]]; then
    continue
fi

# Key Vault Crypto User role
az role assignment create \
    --assignee "$SP_ID" \
    --role "Key Vault Crypto User" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME" \
    --only-show-errors > /dev/null 2>&1

# Sleep to ensure the role assignment is applied before proceeding
sleep 60

# Only output valid JSON as the last line
echo '{"result":"Role assignments completed."}'

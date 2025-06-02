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
KEYVAULT_NAMES=(
  "bte-$UNIQUE_ID-kv-shared"
  "bte-$UNIQUE_ID-kv"
)

# List of service principal names to assign roles to
SP_NAMES=("demo-data-contracts-bytetoeat-$UNIQUE_ID-tf")

for KEYVAULT_NAME in "${KEYVAULT_NAMES[@]}"; do
  for SP_NAME in "${SP_NAMES[@]}"; do
      SP_ID=$(az ad sp list --display-name "$SP_NAME" --query "[0].id" -o tsv 2>/dev/null)
      if [[ -z "$SP_ID" ]]; then
          continue
      fi

      # Owner User role
      az role assignment create \
          --assignee "$SP_ID" \
          --role "Owner" \
          --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME" \
          --only-show-errors > /dev/null 2>&1

      # Assign Key Vault Administrator role on the Key Vault
      az role assignment create \
          --assignee "$SP_ID" \
          --role "Key Vault Administrator" \
          --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
          --only-show-errors > /dev/null 2>&1
  done
done

# Only output valid JSON as the last line
echo '{"result":"Role assignments completed."}'

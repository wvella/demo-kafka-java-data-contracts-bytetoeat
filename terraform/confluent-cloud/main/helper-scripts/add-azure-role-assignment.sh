#!/bin/bash
# Usage: ./add-azure-role-assignment.sh <unique-id>

if [[ $# -lt 1 || -z "$1" ]]; then
  # echo "❌ Unique ID not specified." >&2
  # echo "Usage: $0 <unique-id>" >&2
  exit 1
fi
UNIQUE_ID="$1"

az account show > /dev/null 2>&1 || az login

SUBSCRIPTION_ID=$(az account show --query id -o tsv)

RESOURCE_GROUP="demo-data-contracts-bytetoeat-$UNIQUE_ID"
KEYVAULT_NAME="bytetoeat-$UNIQUE_ID-kv"

# List of service principal names to assign roles to
SP_NAMES=("demo-data-contracts-bytetoeat-$UNIQUE_ID-tf")

for SP_NAME in "${SP_NAMES[@]}"; do
    SP_ID=$(az ad sp list --display-name "$SP_NAME" --query "[0].id" -o tsv)
    if [[ -z "$SP_ID" ]]; then
        # echo "❌ Service principal not found: $SP_NAME" >&2
        continue
    fi

    # Owner User role
    # echo "🔑 Assigning 'Owner' role to $SP_NAME on Key Vault $KEYVAULT_NAME" >&2
    az role assignment create \
        --assignee "$SP_ID" \
        --role "Owner" \
        --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME" \
        --only-show-errors > /dev/null 2>&1

    # Assign Key Vault Administrator role on the resource group
    # echo "🛡 Assigning 'Key Vault Administrator' role to $SP_NAME on resource group $RESOURCE_GROUP" >&2
    az role assignment create \
        --assignee "$SP_ID" \
        --role "Key Vault Administrator" \
        --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME" \
        --only-show-errors > /dev/null 2>&1
done

# Only output valid JSON as the last line
echo '{"result":"Role assignments completed."}'

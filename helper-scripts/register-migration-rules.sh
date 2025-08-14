#!/bin/bash
# Run from root directory
# Variables
SUBJECT="raw.recipes-value"

TERRAFORM_DIR="./local"
DATA_CONTRACT_TEMPLATE="./helper-scripts/migration_rules.json"
DATA_CONTRACT="${TERRAFORM_DIR}/migration_rules.json"
# Retrieve credentials from Terraform outputs
SR_URL=$(terraform -chdir="${TERRAFORM_DIR}" output -raw schema_registry_url)
SR_API_KEY=$(terraform -chdir="${TERRAFORM_DIR}" output -raw env_manager_schema_registry_api_key)
SR_API_SECRET=$(terraform -chdir="${TERRAFORM_DIR}" output -raw env_manager_schema_registry_api_secret)
UNIQUE_ID=$(terraform -chdir="${TERRAFORM_DIR}" output -raw unique_id)

# Update the encrypt.kek.name in migration_rules.json
jq --arg kek "bytetoeat-$UNIQUE_ID-kek" '
  (.ruleSet.domainRules[] | select(.params["encrypt.kek.name"] != null) | .params["encrypt.kek.name"]) = $kek
' ${DATA_CONTRACT_TEMPLATE} > ${DATA_CONTRACT}

# Update the compatibility group name for the raw.recipes-value subject
curl -X PUT \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -H "Accept: application/vnd.schemaregistry.v1+json" \
  -u "${SR_API_KEY}:${SR_API_SECRET}" \
  --data '{
    "compatibilityGroup": "application.major.version"
  }' \
  "${SR_URL}/config/${SUBJECT}"

# Register the schema
curl -X POST \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -u "${SR_API_KEY}:${SR_API_SECRET}" \
  --json @${DATA_CONTRACT} \
  "${SR_URL}/subjects/${SUBJECT}/versions"

# Check the response
if [ $? -eq 0 ]; then
  echo "Schema registered successfully for subject: ${SUBJECT}"
else
  echo "Failed to register schema for subject: ${SUBJECT}"
fi

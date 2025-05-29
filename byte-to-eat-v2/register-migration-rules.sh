#!/bin/bash
# Variables
SUBJECT="raw.recipes-value"
DATA_CONTRACT="migration_rules.json"
# Retrieve credentials from Terraform outputs
TERRAFORM_DIR="../terraform/confluent-cloud"
SR_URL=$(terraform -chdir="$TERRAFORM_DIR" output -raw schema-registry-url)
SR_API_KEY=$(terraform -chdir="$TERRAFORM_DIR" output -raw env-manager-schema-registry-api-key)
SR_API_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw env-manager-schema-registry-api-secret)

# Update the compatibility group name for the raw.recipes-value subject
curl -X PUT \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -H "Accept: application/vnd.schemaregistry.v1+json" \
  -u "$SR_API_KEY:$SR_API_SECRET" \
  --data '{
    "compatibilityGroup": "application.major.version"
  }' \
  "$SR_URL/config/$SUBJECT"

# Register the schema
curl -X POST \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -u "$SR_API_KEY:$SR_API_SECRET" \
  --json @$DATA_CONTRACT \
  "$SR_URL/subjects/$SUBJECT/versions"

# Check the response
if [ $? -eq 0 ]; then
  echo "Schema registered successfully for subject: $SUBJECT"
else
  echo "Failed to register schema for subject: $SUBJECT"
fi

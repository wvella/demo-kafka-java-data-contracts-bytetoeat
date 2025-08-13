#!/bin/bash

# Is run from root directory

# Variables
TERRAFORM_DIR="./local"
PROPERTIES_TEMPLATE="./byte-to-eat-v2-docker-producer-recipes/producer-recipes.template"
PROPERTIES_FILE="./byte-to-eat-v2-docker-producer-recipes/producer-recipes.properties"
CLOUD=$(terraform -chdir="$TERRAFORM_DIR" output -raw cloud)

# Retrieve values from Terraform outputs
BOOTSTRAP_SERVERS=$(terraform -chdir="$TERRAFORM_DIR" output -raw kafka_url | sed 's/^SASL_SSL:\/\///')
SCHEMA_REGISTRY_URL=$(terraform -chdir="$TERRAFORM_DIR" output -raw schema_registry_url)
SR_API_KEY=$(terraform -chdir="$TERRAFORM_DIR" output -raw app_producer_schema_registry_api_key)
SR_API_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw app_producer_schema_registry_api_secret)
KAFKA_API_KEY=$(terraform -chdir="$TERRAFORM_DIR" output -raw app_producer_kafka_api_key)
KAFKA_API_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw app_producer_kafka_api_secret)
SCHEMA_ID=$(terraform -chdir="$TERRAFORM_DIR" output -raw raw_recipes_schema_identifier)

# Update the properties file
sed -e "s|^bootstrap.servers=.*|bootstrap.servers=$BOOTSTRAP_SERVERS|" \
    -e "s|^schema.registry.url=.*|schema.registry.url=$SCHEMA_REGISTRY_URL|" \
    -e "s|^use.schema.id=.*|use.schema.id="$SCHEMA_ID"|" \
    -e "s|^sasl.jaas.config=.*|sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='$KAFKA_API_KEY' password='$KAFKA_API_SECRET';|" \
    -e "s|^schema.registry.basic.auth.user.info=.*|schema.registry.basic.auth.user.info=$SR_API_KEY:$SR_API_SECRET|" \
   "$PROPERTIES_TEMPLATE" > "$PROPERTIES_FILE"

if [[ "$CLOUD" == "AZURE" ]]; then
  TENANT_ID=$(terraform -chdir="$TERRAFORM_DIR" output -raw azure_tenant_id)
  CLIENT_ID=$(terraform -chdir="$TERRAFORM_DIR" output -raw azure_java_producer_client_id)
  CLIENT_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw azure_java_producer_client_secret)
  echo "rule.executors._default_.param.tenant.id=$TENANT_ID" >> "$PROPERTIES_FILE"
  echo "rule.executors._default_.param.client.id=$CLIENT_ID" >> "$PROPERTIES_FILE"
  echo "rule.executors._default_.param.client.secret=$CLIENT_SECRET" >> "$PROPERTIES_FILE"

elif [[ "$CLOUD" == "AWS" ]]; then
  CLIENT_ID=$(terraform -chdir="$TERRAFORM_DIR" output -raw aws_java_producer_client_id)
  CLIENT_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw aws_java_producer_client_secret)
  echo "rule.executors._default_.param.access.key.id=$CLIENT_ID" >> "$PROPERTIES_FILE"
  echo "rule.executors._default_.param.secret.access.key=$CLIENT_SECRET" >> "$PROPERTIES_FILE"

elif [[ "$CLOUD" == "GCP" ]]; then
  CLIENT_EMAIL=$(terraform -chdir="$TERRAFORM_DIR" output -raw gcp_java_producer_client_email)
  CLIENT_SECRET_ID=$(terraform -chdir="$TERRAFORM_DIR" output -raw gcp_java_producer_client_secret_id)
  CLIENT_ID=$(terraform -chdir="$TERRAFORM_DIR" output -raw gcp_java_producer_client_id)
  CLIENT_SECRET_ENCODED=$(terraform -chdir="$TERRAFORM_DIR" output -raw gcp_java_producer_client_secret)
  CLIENT_SECRET=$(echo $CLIENT_SECRET_ENCODED | base64 --decode | jq .private_key | tr -d '"')
  echo "rule.executors._default_.param.client.email=$CLIENT_EMAIL" >> "$PROPERTIES_FILE"
  echo "rule.executors._default_.param.private.key.id=$CLIENT_SECRET_ID" >> "$PROPERTIES_FILE"
  echo "rule.executors._default_.param.client.id=$CLIENT_ID" >> "$PROPERTIES_FILE"
  echo "rule.executors._default_.param.private.key=$CLIENT_SECRET" >> "$PROPERTIES_FILE"

fi

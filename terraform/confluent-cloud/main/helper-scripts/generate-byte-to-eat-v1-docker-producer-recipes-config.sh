#!/bin/bash

# Variables
TERRAFORM_DIR="../tf-working"
PROPERTIES_TEMPLATE="../../../byte-to-eat-v1-docker-producer-recipes/producer-recipes.template"
PROPERTIES_FILE="../../../byte-to-eat-v1-docker-producer-recipes/producer-recipes.properties"
CLOUD=$(terraform -chdir="$TERRAFORM_DIR" output -raw cloud)

# Retrieve values from Terraform outputs
BOOTSTRAP_SERVERS=$(terraform -chdir="$TERRAFORM_DIR" output -raw kafka-url | sed 's/^SASL_SSL:\/\///')
SCHEMA_REGISTRY_URL=$(terraform -chdir="$TERRAFORM_DIR" output -raw schema-registry-url)
SR_API_KEY=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-producer-schema-registry-api-key)
SR_API_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-producer-schema-registry-api-secret)
KAFKA_API_KEY=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-producer-kafka-api-key)
KAFKA_API_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-producer-kafka-api-secret)
SCHEMA_ID=$(terraform -chdir="$TERRAFORM_DIR" output -raw raw-recipes-schema-identifier)

# Update the properties file
sed -e "s|^bootstrap.servers=.*|bootstrap.servers=$BOOTSTRAP_SERVERS|" \
    -e "s|^schema.registry.url=.*|schema.registry.url=$SCHEMA_REGISTRY_URL|" \
    -e "s|^use.schema.id=.*|use.schema.id="$SCHEMA_ID"|" \
    -e "s|^sasl.jaas.config=.*|sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='$KAFKA_API_KEY' password='$KAFKA_API_SECRET';|" \
    -e "s|^schema.registry.basic.auth.user.info=.*|schema.registry.basic.auth.user.info=$SR_API_KEY:$SR_API_SECRET|" \
    "$PROPERTIES_TEMPLATE" > "$PROPERTIES_FILE"

if [[ "$CLOUD" == "AZURE" ]]; then
  TENANT_ID=$(terraform -chdir="$TERRAFORM_DIR" output -raw azure-tenant-id)
  CLIENT_ID=$(terraform -chdir="$TERRAFORM_DIR" output -raw azure-java-producer-client-id)
  CLIENT_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw azure-java-producer-client-secret)
  echo "rule.executors._default_.param.tenant.id=$TENANT_ID" >> "$PROPERTIES_FILE"
  echo "rule.executors._default_.param.client.id=$CLIENT_ID" >> "$PROPERTIES_FILE"
  echo "rule.executors._default_.param.client.secret=$CLIENT_SECRET" >> "$PROPERTIES_FILE"

elif [[ "$CLOUD" == "AWS" ]]; then
  CLIENT_ID=$(terraform -chdir="$TERRAFORM_DIR" output -raw aws-java-producer-client-id)
  CLIENT_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw aws-java-producer-client-secret)
  echo "rule.executors._default_.param.access.key.id=$CLIENT_ID" >> "$PROPERTIES_FILE"
  echo "rule.executors._default_.param.secret.access.key=$CLIENT_SECRET" >> "$PROPERTIES_FILE"
fi

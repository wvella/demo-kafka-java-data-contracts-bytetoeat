#!/bin/bash

# Variables
TERRAFORM_DIR="../tf-working"
PROPERTIES_TEMPLATE="../../../byte-to-eat-v1-docker-consumer-recipes/consumer-recipes.template"
PROPERTIES_FILE="../../../byte-to-eat-v1-docker-consumer-recipes/consumer-recipes.properties"

# Retrieve values from Terraform outputs
BOOTSTRAP_SERVERS=$(terraform -chdir="$TERRAFORM_DIR" output -raw kafka-url | sed 's/^SASL_SSL:\/\///')
SCHEMA_REGISTRY_URL=$(terraform -chdir="$TERRAFORM_DIR" output -raw schema-registry-url)
SR_API_KEY=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-consumer-schema-registry-api-key)
SR_API_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-consumer-schema-registry-api-secret)
KAFKA_API_KEY=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-consumer-kafka-api-key)
KAFKA_API_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-consumer-kafka-api-secret)
AZURE_TENANT_ID=$(terraform -chdir="$TERRAFORM_DIR" output -raw azure-tenant-id)
AZURE_CLIENT_ID=$(terraform -chdir="$TERRAFORM_DIR" output -raw azure-java-consumer-client-id)
AZURE_CLIENT_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw azure-java-consumer-client-secret)

# Update the properties file
sed -e "s|^bootstrap.servers=.*|bootstrap.servers=$BOOTSTRAP_SERVERS|" \
    -e "s|^schema.registry.url=.*|schema.registry.url=$SCHEMA_REGISTRY_URL|" \
    -e "s|^sasl.jaas.config=.*|sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='$KAFKA_API_KEY' password='$KAFKA_API_SECRET';|" \
    -e "s|^schema.registry.basic.auth.user.info=.*|schema.registry.basic.auth.user.info=$SR_API_KEY:$SR_API_SECRET|" \
    -e "s|^rule.executors._default_.param.tenant.id=.*|rule.executors._default_.param.tenant.id=$AZURE_TENANT_ID|" \
    -e "s|^rule.executors._default_.param.client.id=.*|rule.executors._default_.param.client.id=$AZURE_CLIENT_ID|" \
    -e "s|^rule.executors._default_.param.client.secret=.*|rule.executors._default_.param.client.secret=$AZURE_CLIENT_SECRET|" \
    "$PROPERTIES_TEMPLATE" > "$PROPERTIES_FILE"

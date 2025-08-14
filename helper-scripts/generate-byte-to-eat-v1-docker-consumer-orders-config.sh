#!/bin/bash

# Is run from root directory

# Variables
TERRAFORM_DIR="./local"
PROPERTIES_TEMPLATE="./byte-to-eat-v1-docker-consumer-orders/consumer-orders.template"
PROPERTIES_FILE="./byte-to-eat-v1-docker-consumer-orders/consumer-orders.properties"

# Retrieve values from Terraform outputs
BOOTSTRAP_SERVERS=$(terraform -chdir="$TERRAFORM_DIR" output -raw kafka_url | sed 's/^SASL_SSL:\/\///')
SCHEMA_REGISTRY_URL=$(terraform -chdir="$TERRAFORM_DIR" output -raw schema_registry_url)
SR_API_KEY=$(terraform -chdir="$TERRAFORM_DIR" output -raw app_consumer_schema_registry_api_key)
SR_API_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw app_consumer_schema_registry_api_secret)
KAFKA_API_KEY=$(terraform -chdir="$TERRAFORM_DIR" output -raw app_consumer_kafka_api_key)
KAFKA_API_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw app_consumer_kafka_api_secret)

# Update the properties file
sed -e "s|^bootstrap.servers=.*|bootstrap.servers=$BOOTSTRAP_SERVERS|" \
    -e "s|^schema.registry.url=.*|schema.registry.url=$SCHEMA_REGISTRY_URL|" \
    -e "s|^sasl.jaas.config=.*|sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='$KAFKA_API_KEY' password='$KAFKA_API_SECRET';|" \
    -e "s|^schema.registry.basic.auth.user.info=.*|schema.registry.basic.auth.user.info=$SR_API_KEY:$SR_API_SECRET|" \
    "$PROPERTIES_TEMPLATE" > "$PROPERTIES_FILE"

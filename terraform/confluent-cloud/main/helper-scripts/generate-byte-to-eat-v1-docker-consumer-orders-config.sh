#!/bin/bash

# Variables
TERRAFORM_DIR="../tf-working"
PROPERTIES_TEMPLATE="../../../byte-to-eat-v1-docker-consumer-orders/consumer-orders.template"
PROPERTIES_FILE="../../../byte-to-eat-v1-docker-consumer-orders/consumer-orders.properties"

# Retrieve values from Terraform outputs
BOOTSTRAP_SERVERS=$(terraform -chdir="$TERRAFORM_DIR" output -raw kafka-url | sed 's/^SASL_SSL:\/\///')
SCHEMA_REGISTRY_URL=$(terraform -chdir="$TERRAFORM_DIR" output -raw schema-registry-url)
SR_API_KEY=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-consumer-schema-registry-api-key)
SR_API_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-consumer-schema-registry-api-secret)
KAFKA_API_KEY=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-consumer-kafka-api-key)
KAFKA_API_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-consumer-kafka-api-secret)

# Update the properties file
sed -e "s|^bootstrap.servers=.*|bootstrap.servers=$BOOTSTRAP_SERVERS|" \
    -e "s|^schema.registry.url=.*|schema.registry.url=$SCHEMA_REGISTRY_URL|" \
    -e "s|^sasl.jaas.config=.*|sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='$KAFKA_API_KEY' password='$KAFKA_API_SECRET';|" \
    -e "s|^schema.registry.basic.auth.user.info=.*|schema.registry.basic.auth.user.info=$SR_API_KEY:$SR_API_SECRET|" \
    "$PROPERTIES_TEMPLATE" > "$PROPERTIES_FILE"

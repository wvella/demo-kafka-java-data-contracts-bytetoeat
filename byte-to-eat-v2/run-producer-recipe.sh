#!/bin/bash
highlight_stderr() {
  "$@" 2> >(while IFS= read -r line; do
    if [[ "$line" =~ ERROR|Error|Exception ]]; then
      echo -e "\033[0;31m$line\033[0m" >&2  # Red
    elif [[ "$line" =~ WARN|Warning ]]; then
      echo -e "\033[0;33m$line\033[0m" >&2  # Yellow
    elif [[ "$line" =~ INFO ]]; then
      echo -e "\033[0;32m$line\033[0m" >&2  # Green
    else
      echo "$line" >&2  # Default
    fi
  done)
}

# Variables
TERRAFORM_DIR="../terraform/confluent-cloud"
PROPERTIES_TEMPLATE="producer-recipe.template"
PROPERTIES_FILE="producer-recipe.properties"

# Retrieve values from Terraform outputs
BOOTSTRAP_SERVERS=$(terraform -chdir="$TERRAFORM_DIR" output -raw kafka-url | sed 's/^SASL_SSL:\/\///')
SCHEMA_REGISTRY_URL=$(terraform -chdir="$TERRAFORM_DIR" output -raw schema-registry-url)
SR_API_KEY=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-producer-schema-registry-api-key)
SR_API_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-producer-schema-registry-api-secret)
KAFKA_API_KEY=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-producer-kafka-api-key)
KAFKA_API_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-producer-kafka-api-secret)

# Update the properties file
sed -e "s|^bootstrap.servers=.*|bootstrap.servers=$BOOTSTRAP_SERVERS|" \
    -e "s|^schema.registry.url=.*|schema.registry.url=$SCHEMA_REGISTRY_URL|" \
    -e "s|^sasl.jaas.config=.*|sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='$KAFKA_API_KEY' password='$KAFKA_API_SECRET';|" \
    -e "s|^schema.registry.basic.auth.user.info=.*|schema.registry.basic.auth.user.info=$SR_API_KEY:$SR_API_SECRET|" \
    "$PROPERTIES_TEMPLATE" > "$PROPERTIES_FILE"

# Toggle for listing all ingredients or only one ingredient
LIST_ALL_INGREDIENTS=${1:-true} # Default to true if no argument is provided

if [[ "$LIST_ALL_INGREDIENTS" != "true" && "$LIST_ALL_INGREDIENTS" != "false" ]]; then
  echo "Invalid argument: $LIST_ALL_INGREDIENTS. Please provide 'true' or 'false'."
  exit 1
fi

highlight_stderr mvn exec:java \
  -Dexec.mainClass=io.confluent.wvella.demo.datacontractsv2.ProducerAvroRecipe \
  -Dexec.args="producer-recipe.properties $LIST_ALL_INGREDIENTS"

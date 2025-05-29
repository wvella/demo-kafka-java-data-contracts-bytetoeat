#!/bin/bash

# Ensure the script is executable: chmod +x run-consumer-recipe.sh

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

# Retrieve credentials from Terraform outputs
TERRAFORM_DIR="../terraform/confluent-cloud"
SR_URL=$(terraform -chdir="$TERRAFORM_DIR" output -raw schema-registry-url)
SR_API_KEY=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-consumer-schema-registry-api-key)
SR_API_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-consumer-schema-registry-api-secret)
KAFKA_URL=$(terraform -chdir="$TERRAFORM_DIR" output -raw kafka-url | sed 's/^SASL_SSL:\/\///')
KAFKA_API_KEY=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-consumer-kafka-api-key)
KAFKA_API_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw app-consumer-kafka-api-secret)


highlight_stderr docker run -it --rm confluentinc/cp-schema-registry:7.9.0 \
kafka-avro-console-consumer \
--topic raw.recipes \
--from-beginning \
--bootstrap-server $KAFKA_URL \
--consumer-property security.protocol=SASL_SSL \
--consumer-property sasl.mechanism=PLAIN \
--consumer-property sasl.jaas.config="org.apache.kafka.common.security.plain.PlainLoginModule required username='$KAFKA_API_KEY' password='$KAFKA_API_SECRET';" \
--consumer-property group.id="confluent_cli_consumer_recipe_v2" \
--property schema.registry.url=$SR_URL \
--property basic.auth.credentials.source=USER_INFO \
--property basic.auth.user.info="$SR_API_KEY:$SR_API_SECRET" \
--property print.schema.ids=true \
--property use.latest.with.metadata=application.major.version=2

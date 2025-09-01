# Confluent Config File
# * client.properties file with env_manager API keys

# Generates client.properties file with env_manager API keys
resource "local_file" "client_properties" {
  filename = "${path.module}/client.properties"
  content  = <<-EOT
bootstrap.servers=${confluent_kafka_cluster.standard.bootstrap_endpoint}
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="${confluent_api_key.env_manager_kafka_api_key.id}" password="${confluent_api_key.env_manager_kafka_api_key.secret}";

schema.registry.url=${data.confluent_schema_registry_cluster.advanced.rest_endpoint}
basic.auth.credentials.source=USER_INFO
schema.registry.basic.auth.user.info=${confluent_api_key.env_manager_schema_registry_api_key.id}:${confluent_api_key.env_manager_schema_registry_api_key.secret}

key.converter.schema.registry.url=${data.confluent_schema_registry_cluster.advanced.rest_endpoint}
key.converter.basic.auth.credentials.source=USER_INFO
key.converter.schema.registry.basic.auth.user.info=${confluent_api_key.env_manager_schema_registry_api_key.id}:${confluent_api_key.env_manager_schema_registry_api_key.secret}

value.converter.schema.registry.url=${data.confluent_schema_registry_cluster.advanced.rest_endpoint}
value.converter.basic.auth.credentials.source=USER_INFO
value.converter.schema.registry.basic.auth.user.info=${confluent_api_key.env_manager_schema_registry_api_key.id}:${confluent_api_key.env_manager_schema_registry_api_key.secret}
EOT
}
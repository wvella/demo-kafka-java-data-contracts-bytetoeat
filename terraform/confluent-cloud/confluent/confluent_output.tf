output "unique_id" {
  value = var.unique_id
}
output "cloud" {
  value = var.cloud
}

output "kafka_url" {
  value = confluent_kafka_cluster.standard.bootstrap_endpoint
}
output "schema_registry_url" {
  value = data.confluent_schema_registry_cluster.advanced.rest_endpoint
}

output "raw_recipes_schema_identifier" {
  value = confluent_schema.raw_recipes_value.schema_identifier
}

output "console_dev_producer_command" {
  value = <<EOT

kafka-avro-console-producer \
  --bootstrap-server ${confluent_kafka_cluster.standard.bootstrap_endpoint} \
  --producer.config local/client.properties \
  --reader-config local/client.properties \
  --property schema.registry.url=${data.confluent_schema_registry_cluster.advanced.rest_endpoint} \
  --property value.schema.id=${confluent_schema.dev_orders_value.schema_identifier} \
  --topic dev.orders
EOT
}

output "console_dev_producer_sample_message" {
  value = <<EOT

{ "order_id": "1234567890", "name": "John Doe", "email": "john.doe@example.com", "recipe_id": "1234567890" }
EOT
}
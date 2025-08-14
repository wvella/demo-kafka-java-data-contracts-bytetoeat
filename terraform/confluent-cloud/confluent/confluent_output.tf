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

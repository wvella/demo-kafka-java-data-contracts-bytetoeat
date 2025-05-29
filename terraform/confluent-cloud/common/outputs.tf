output "resource-ids" {
  value = <<-EOT
  Environment ID:   ${confluent_environment.bytetoeat.id}
  Kafka Cluster Bootstrap Endpoint: ${confluent_kafka_cluster.standard.bootstrap_endpoint}
  Schema Registry REST Endpoint: ${data.confluent_schema_registry_cluster.advanced.rest_endpoint}
  EOT

}
output "kafka-url" {
  value     = confluent_kafka_cluster.standard.bootstrap_endpoint
}
output "schema-registry-url" {
  value     = data.confluent_schema_registry_cluster.advanced.rest_endpoint
}
output "app-producer-schema-registry-api-key" {
  value     = confluent_api_key.app-producer-schema-registry-api-key.id
  sensitive = true
}
output "app-producer-schema-registry-api-secret" {
  value     = confluent_api_key.app-producer-schema-registry-api-key.secret
  sensitive = true
}
output "app-consumer-schema-registry-api-key" {
  value     = confluent_api_key.app-consumer-schema-registry-api-key.id
  sensitive = true
}
output "app-consumer-schema-registry-api-secret" {
  value     = confluent_api_key.app-consumer-schema-registry-api-key.secret
  sensitive = true
}
output "env-manager-schema-registry-api-key" {
  value     = confluent_api_key.env-manager-schema-registry-api-key.id
  sensitive = true
}
output "env-manager-schema-registry-api-secret" {
  value     = confluent_api_key.env-manager-schema-registry-api-key.secret
  sensitive = true
}
output "app-manager-kafka-api-key" {
  value     = confluent_api_key.app-manager-kafka-api-key.id
  sensitive = true
}
output "app-manager-kafka-api-secret" {
  value     = confluent_api_key.app-manager-kafka-api-key.secret
  sensitive = true
}
output "app-producer-kafka-api-key" {
  value     = confluent_api_key.app-producer-kafka-api-key.id
  sensitive = true
}
output "app-producer-kafka-api-secret" {
  value     = confluent_api_key.app-producer-kafka-api-key.secret
  sensitive = true
}
output "app-consumer-kafka-api-key" {
  value     = confluent_api_key.app-consumer-kafka-api-key.id
  sensitive = true
}
output "app-consumer-kafka-api-secret" {
  value     = confluent_api_key.app-consumer-kafka-api-key.secret
  sensitive = true
}

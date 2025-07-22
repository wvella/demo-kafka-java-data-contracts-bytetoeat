output "unique-id" {
  value     = var.unique-id
}
output "cloud" {
  value     = var.cloud
}
output "kafka-url" {
  value     = confluent_kafka_cluster.standard.bootstrap_endpoint
}
output "schema-registry-url" {
  value     = data.confluent_schema_registry_cluster.advanced.rest_endpoint
}
output "raw-recipes-schema-identifier" {
  value     = confluent_schema.raw_recipes-value.schema_identifier
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
output "aws-java-producer-client-id" {
  value     = aws_iam_access_key.data-contracts-bytetoeat-java-producer.id
  sensitive = true
}
output "aws-java-producer-client-secret" {
  value     = aws_iam_access_key.data-contracts-bytetoeat-java-producer.secret
  sensitive = true
}
output "aws-java-consumer-client-id" {
  value     = aws_iam_access_key.data-contracts-bytetoeat-java-consumer.id
  sensitive = true
}
output "aws-java-consumer-client-secret" {
  value     = aws_iam_access_key.data-contracts-bytetoeat-java-consumer.secret
  sensitive = true
}

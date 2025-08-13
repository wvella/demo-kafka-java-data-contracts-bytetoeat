

output "app_manager_kafka_api_key" {
  value     = confluent_api_key.app_manager_kafka_api_key.id
  sensitive = true
}
output "app_manager_kafka_api_secret" {
  value     = confluent_api_key.app_manager_kafka_api_key.secret
  sensitive = true
}

output "app_producer_kafka_api_key" {
  value     = confluent_api_key.app_producer_kafka_api_key.id
  sensitive = true
}
output "app_producer_kafka_api_secret" {
  value     = confluent_api_key.app_producer_kafka_api_key.secret
  sensitive = true
}
output "app_consumer_kafka_api_key" {
  value     = confluent_api_key.app_consumer_kafka_api_key.id
  sensitive = true
}
output "app_consumer_kafka_api_secret" {
  value     = confluent_api_key.app_consumer_kafka_api_key.secret
  sensitive = true
}


output "app_producer_schema_registry_api_key" {
  value     = confluent_api_key.app_producer_schema_registry_api_key.id
  sensitive = true
}
output "app_producer_schema_registry_api_secret" {
  value     = confluent_api_key.app_producer_schema_registry_api_key.secret
  sensitive = true
}
output "app_consumer_schema_registry_api_key" {
  value     = confluent_api_key.app_consumer_schema_registry_api_key.id
  sensitive = true
}
output "app_consumer_schema_registry_api_secret" {
  value     = confluent_api_key.app_consumer_schema_registry_api_key.secret
  sensitive = true
}
output "env_manager_schema_registry_api_key" {
  value     = confluent_api_key.env_manager_schema_registry_api_key.id
  sensitive = true
}
output "env_manager_schema_registry_api_secret" {
  value     = confluent_api_key.env_manager_schema_registry_api_key.secret
  sensitive = true
}

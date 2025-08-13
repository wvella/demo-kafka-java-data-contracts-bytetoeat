output "gcp_java_producer_client_id" {
  value     = google_service_account.data_contracts_bytetoeat_java_producer.id
  sensitive = true
}

output "gcp_java_producer_client_email" {
  value     = google_service_account.data_contracts_bytetoeat_java_producer.email
  sensitive = true
}

output "gcp_java_producer_client_secret" {
  value     = google_service_account_key.data_contracts_bytetoeat_java_producer.private_key
  sensitive = true
}

output "gcp_java_producer_client_secret_id" {
  value     = google_service_account_key.data_contracts_bytetoeat_java_producer.id
  sensitive = true
}

output "gcp_java_consumer_client_id" {
  value     = google_service_account.data_contracts_bytetoeat_java_consumer.id
  sensitive = true
}
output "gcp_java_consumer_client_secret" {
  value     = google_service_account_key.data_contracts_bytetoeat_java_consumer.private_key
  sensitive = true
}

output "gcp_java_consumer_client_email" {
  value     = google_service_account.data_contracts_bytetoeat_java_consumer.email
  sensitive = true
}

output "gcp_java_consumer_client_secret_id" {
  value     = google_service_account_key.data_contracts_bytetoeat_java_consumer.id
  sensitive = true
}
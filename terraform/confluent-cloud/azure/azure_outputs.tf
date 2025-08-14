output "azure_tenant_id" {
  value = var.tenant_id
}

output "azure_java_producer_client_id" {
  value     = var.demo_data_contracts_bytetoeat_java_producer_client_id
  sensitive = true
}
output "azure_java_producer_client_secret" {
  value     = var.demo_data_contracts_bytetoeat_java_producer_client_secret
  sensitive = true
}
output "azure_java_consumer_client_id" {
  value     = var.demo_data_contracts_bytetoeat_java_consumer_client_id
  sensitive = true
}
output "azure_java_consumer_client_secret" {
  value     = var.demo_data_contracts_bytetoeat_java_consumer_client_secret
  sensitive = true
}

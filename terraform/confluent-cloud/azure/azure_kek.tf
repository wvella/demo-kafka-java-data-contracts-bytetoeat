# TODO: Refactor to confluent directory

# Add shared key to Schema Registry
resource "confluent_schema_registry_kek" "cc_kek_shared" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.advanced.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.advanced.rest_endpoint
  credentials {
    key    = confluent_api_key.env_manager_schema_registry_api_key.id
    secret = confluent_api_key.env_manager_schema_registry_api_key.secret
  }
  name        = "bytetoeat-${local.unique_id}-kek-shared"
  doc         = "Azure Key Encryption Key used for CSFLE encryption"
  kms_type    = "azure-kms"
  kms_key_id  = azurerm_key_vault_key.demo_data_contracts_bytetoeat_csfle_key_shared.id
  shared      = true
  hard_delete = true

  properties = {
    "azure.tenant.id" = var.tenant_id
    "azure.client.id" = azurerm_user_assigned_identity.demo_data_contracts_bytetoeat_cc_identity.client_id
  }
}

# Add unshared key to Schema Registry
resource "confluent_schema_registry_kek" "cc_kek" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.advanced.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.advanced.rest_endpoint
  credentials {
    key    = confluent_api_key.env_manager_schema_registry_api_key.id
    secret = confluent_api_key.env_manager_schema_registry_api_key.secret
  }
  name        = "bytetoeat-${local.unique_id}-kek"
  doc         = "Azure Key Encryption Key used for CSFLE encryption"
  kms_type    = "azure-kms"
  kms_key_id  = azurerm_key_vault_key.demo_data_contracts_bytetoeat_csfle_key.id
  shared      = false
  hard_delete = true
}

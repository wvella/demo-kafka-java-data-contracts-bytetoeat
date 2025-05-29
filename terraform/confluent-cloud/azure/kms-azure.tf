data "azurerm_resource_group" "my-resource-group" {
  name = var.resource_group
}

data "azurerm_client_config" "current" {}

data "azuread_service_principal" "current" {
  client_id = var.client_id
}

resource "azurerm_key_vault" "csfle-keyvault" {
  name                        = "csfle-keyvault"
  location                    = data.azurerm_resource_group.my-resource-group.location
  resource_group_name         = data.azurerm_resource_group.my-resource-group.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  enable_rbac_authorization   = true

  sku_name = "standard"

}

# Create an Azure Key
resource "azurerm_key_vault_key" "csfle-key" {
  name         = "csfle-key"
  key_vault_id = azurerm_key_vault.csfle-keyvault.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

}

resource "confluent_schema_registry_kek" "kek" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.advanced.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.advanced.rest_endpoint
  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }
  name        = "azure-kek-for-csfle"
  doc         = "AZURE Key Encryption Key used for CSFLE encryption"
  kms_type    = "azure-kms"
  kms_key_id  = azurerm_key_vault_key.csfle-key.id
  shared      = true
  hard_delete = true
}

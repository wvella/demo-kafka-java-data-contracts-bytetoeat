data "azurerm_client_config" "current" {}

data "azuread_service_principal" "current" {
  client_id = var.demo-data-contracts-bytetoeat-tf-client-id
}

data "external" "get-kek-policy" {
  program = ["python3", "${path.module}/../main/helper-scripts/get-kek-policy.py"]
  query = {
    sr_url  = data.confluent_schema_registry_cluster.advanced.rest_endpoint
    api_key = confluent_api_key.env-manager-schema-registry-api-key.id
    api_secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }
}

data "external" "add-azure-role-assignment" {
  program = ["${path.module}/../main/helper-scripts/add-azure-role-assignment.sh","${var.unique-id}"]
  depends_on = [
    azurerm_key_vault.demo-data-contracts-bytetoeat-keyvault,
    azurerm_key_vault.demo-data-contracts-bytetoeat-keyvault-shared
  ]
}

output "add-azure-role-assignment" {
  value = data.external.add-azure-role-assignment.result["result"]
}

locals {
  rest_endpoint = data.confluent_schema_registry_cluster.advanced.rest_endpoint
  # Extract the subdomain before the first dot after https://
  schema_registry_id = regex("^https://([^.]+)\\.", local.rest_endpoint)[0]
}

output "policy_issuer" {
  value = data.external.get-kek-policy.result["issuer"]
}

resource "azurerm_user_assigned_identity" "demo-data-contracts-bytetoeat-cc-identity" {
  name                = "${var.unique-id}-cc-identity"
  resource_group_name = data.azurerm_resource_group.resource-group.name
  location            = data.azurerm_resource_group.resource-group.location
}

resource "azurerm_role_definition" "demo-data-contracts-bytetoeat-cc-role" {
  name        = "${var.unique-id}-cc-role"
  scope       = azurerm_key_vault.demo-data-contracts-bytetoeat-keyvault-shared.id

  description = "Custom role for Confluent Schema Registry Key Vault Access to read, encrypt, and decrypt"
  permissions {
    actions = [
      "Microsoft.KeyVault/vaults/keys/read"
    ]
    not_actions = []
    data_actions = [
      "Microsoft.KeyVault/vaults/keys/encrypt/action",
      "Microsoft.KeyVault/vaults/keys/decrypt/action"
    ]
    not_data_actions = []
  }
  assignable_scopes = [azurerm_key_vault.demo-data-contracts-bytetoeat-keyvault-shared.id]
  depends_on = [ data.external.add-azure-role-assignment ]
}

resource "azurerm_role_assignment" "demo-data-contracts-bytetoeat-cc-role-assignment" {
  scope              = azurerm_key_vault.demo-data-contracts-bytetoeat-keyvault-shared.id
  role_definition_id = azurerm_role_definition.demo-data-contracts-bytetoeat-cc-role.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.demo-data-contracts-bytetoeat-cc-identity.principal_id
}

resource "azurerm_federated_identity_credential" "demo-data-contracts-bytetoeat-fc" {
  name                 = "${var.unique-id}-fc"
  resource_group_name  = data.azurerm_resource_group.resource-group.name
  audience             = ["api://AzureADTokenExchange"]
  issuer               = data.external.get-kek-policy.result["issuer"]
  subject              = "system:serviceaccount:${local.schema_registry_id}:default"
  parent_id            = azurerm_user_assigned_identity.demo-data-contracts-bytetoeat-cc-identity.id
}

resource "azurerm_key_vault" "demo-data-contracts-bytetoeat-keyvault-shared" {
  name                        = "bte-${var.unique-id}-kv-shared" # The name must begin with a letter, end with a letter or digit, and not contain consecutive hyphens.
  location                    = data.azurerm_resource_group.resource-group.location
  resource_group_name         = data.azurerm_resource_group.resource-group.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant-id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  enable_rbac_authorization   = true
  sku_name = "standard"
}

resource "azurerm_key_vault" "demo-data-contracts-bytetoeat-keyvault" {
  name                        = "bte-${var.unique-id}-kv" # The name must begin with a letter, end with a letter or digit, and not contain consecutive hyphens.
  location                    = data.azurerm_resource_group.resource-group.location
  resource_group_name         = data.azurerm_resource_group.resource-group.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant-id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  enable_rbac_authorization   = true
  sku_name = "standard"
}

# Create an Azure Key
resource "azurerm_key_vault_key" "demo-data-contracts-bytetoeat-csfle-key-shared" {
  name         = "${var.unique-id}-csfle-key-shared"
  key_vault_id = azurerm_key_vault.demo-data-contracts-bytetoeat-keyvault-shared.id
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
  depends_on = [ data.external.add-azure-role-assignment ]
}

# Create an Azure Key
resource "azurerm_key_vault_key" "demo-data-contracts-bytetoeat-csfle-key" {
  name         = "${var.unique-id}-csfle-key"
  key_vault_id = azurerm_key_vault.demo-data-contracts-bytetoeat-keyvault.id
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
  depends_on = [ data.external.add-azure-role-assignment ]
}

resource "confluent_schema_registry_kek" "cc-kek-shared" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.advanced.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.advanced.rest_endpoint
  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }
  name        = "bytetoeat-${var.unique-id}-kek-shared"
  doc         = "Azure Key Encryption Key used for CSFLE encryption"
  kms_type    = "azure-kms"
  kms_key_id  = azurerm_key_vault_key.demo-data-contracts-bytetoeat-csfle-key-shared.id
  shared      = true
  hard_delete = true

  properties = {
    "azure.tenant.id" = var.tenant-id
    "azure.client.id" = azurerm_user_assigned_identity.demo-data-contracts-bytetoeat-cc-identity.client_id
  }
}

resource "confluent_schema_registry_kek" "cc-kek" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.advanced.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.advanced.rest_endpoint
  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }
  name        = "bytetoeat-${var.unique-id}-kek"
  doc         = "Azure Key Encryption Key used for CSFLE encryption"
  kms_type    = "azure-kms"
  kms_key_id  = azurerm_key_vault_key.demo-data-contracts-bytetoeat-csfle-key.id
  shared      = false
  hard_delete = true
}

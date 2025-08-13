data "azurerm_client_config" "current" {}

data "azuread_service_principal" "current" {
  client_id = var.demo_data_contracts_bytetoeat_tf_client_id
}

data "http" "get-kek-policy" {
  url = "${data.confluent_schema_registry_cluster.advanced.rest_endpoint}/dek-registry/v1/policy"

  request_headers = {
    Authorization = "Basic ${base64encode("${confluent_api_key.env_manager_schema_registry_api_key.id}:${confluent_api_key.env_manager_schema_registry_api_key.secret}")}"
    Accept        = "application/json"
  }
}

locals {
 # Extract issuer value using regexall
  matches = regexall("--issuer\\s+([^\\s\\\\]+)", data.http.get-kek-policy.response_body)

  # Get the first capture group from the first match, or empty string if no match
  issuer = length(local.matches) > 0 ? local.matches[0][0] : ""
}

# Todo refactor to use script in tf directory
data "external" "add-azure-role-assignment" {
  program = ["${path.module}/../helper-scripts/add-azure-role-assignment.sh","${local.unique_id}"]
  depends_on = [
    azurerm_key_vault.demo_data_contracts_bytetoeat_keyvault,
    azurerm_key_vault.demo_data_contracts_bytetoeat_keyvault_shared
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

resource "azurerm_user_assigned_identity" "demo_data_contracts_bytetoeat_cc_identity" {
  name                = "${local.unique_id}-cc-identity"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = data.azurerm_resource_group.resource_group.location
}

resource "azurerm_role_definition" "demo_data_contracts_bytetoeat_cc_role" {
  name        = "${local.unique_id}-cc-role"
  scope       = azurerm_key_vault.demo_data_contracts_bytetoeat_keyvault_shared.id

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
  assignable_scopes = [azurerm_key_vault.demo_data_contracts_bytetoeat_keyvault_shared.id]
  depends_on = [ data.external.add-azure-role-assignment ]
}

resource "azurerm_role_assignment" "demo_data_contracts_bytetoeat_cc_role_assignment" {
  scope              = azurerm_key_vault.demo_data_contracts_bytetoeat_keyvault_shared.id
  role_definition_id = azurerm_role_definition.demo_data_contracts_bytetoeat_cc_role.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.demo_data_contracts_bytetoeat_cc_identity.principal_id
}

resource "azurerm_federated_identity_credential" "demo_data_contracts_bytetoeat_fc" {
  name                 = "${local.unique_id}-fc"
  resource_group_name  = data.azurerm_resource_group.resource_group.name
  audience             = ["api://AzureADTokenExchange"]
  issuer               = local.issuer
  subject              = "system:serviceaccount:${local.schema_registry_id}:default"
  parent_id            = azurerm_user_assigned_identity.demo_data_contracts_bytetoeat_cc_identity.id
}

resource "azurerm_key_vault" "demo_data_contracts_bytetoeat_keyvault_shared" {
  name                        = "bte-${local.unique_id}-kv-shared" # The name must begin with a letter, end with a letter or digit, and not contain consecutive hyphens.
  location                    = data.azurerm_resource_group.resource_group.location
  resource_group_name         = data.azurerm_resource_group.resource_group.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  enable_rbac_authorization   = true
  sku_name = "standard"
}

resource "azurerm_key_vault" "demo_data_contracts_bytetoeat_keyvault" {
  name                        = "bte-${local.unique_id}-kv" # The name must begin with a letter, end with a letter or digit, and not contain consecutive hyphens.
  location                    = data.azurerm_resource_group.resource_group.location
  resource_group_name         = data.azurerm_resource_group.resource_group.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  enable_rbac_authorization   = true
  sku_name = "standard"
}

# Create an Azure Key
resource "azurerm_key_vault_key" "demo_data_contracts_bytetoeat_csfle_key_shared" {
  name         = "${local.unique_id}-csfle-key-shared"
  key_vault_id = azurerm_key_vault.demo_data_contracts_bytetoeat_keyvault_shared.id
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
resource "azurerm_key_vault_key" "demo_data_contracts_bytetoeat_csfle_key" {
  name         = "${local.unique_id}-csfle-key"
  key_vault_id = azurerm_key_vault.demo_data_contracts_bytetoeat_keyvault.id
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

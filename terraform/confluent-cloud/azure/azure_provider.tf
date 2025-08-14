# You can have multiple `terraform` root blocks
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.27.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.3.0"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.24.0"
    }
  }
}

provider "azurerm" {
  features {
  }
  subscription_id = var.subscription_id
  client_id       = var.demo_data_contracts_bytetoeat_tf_client_id
  client_secret   = var.demo_data_contracts_bytetoeat_tf_client_secret
  tenant_id       = var.tenant_id
}

provider "azuread" {
  client_id     = var.demo_data_contracts_bytetoeat_tf_client_id
  client_secret = var.demo_data_contracts_bytetoeat_tf_client_secret
  tenant_id     = var.tenant_id
}

data "azurerm_resource_group" "resource_group" {
  name = var.resource_group
}

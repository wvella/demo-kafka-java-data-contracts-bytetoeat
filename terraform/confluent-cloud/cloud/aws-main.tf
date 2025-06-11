terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.24.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.27.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.3.0"
    }
  }
}

provider "azurerm" {
  features {
  }
  subscription_id = var.subscription-id
  client_id       = var.demo-data-contracts-bytetoeat-tf-client-id
  client_secret   = var.demo-data-contracts-bytetoeat-tf-client-secret
  tenant_id       = var.tenant-id
}

provider "azuread" {
  client_id       = var.demo-data-contracts-bytetoeat-tf-client-id
  client_secret   = var.demo-data-contracts-bytetoeat-tf-client-secret
  tenant_id       = var.tenant-id
}

data "azurerm_resource_group" "resource-group" {
  name = var.resource-group
}

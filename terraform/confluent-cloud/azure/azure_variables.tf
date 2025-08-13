variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "demo_data_contracts_bytetoeat_tf_client_id" {
  description = "Terraform App Registration Client ID"
  type        = string
}

variable "demo_data_contracts_bytetoeat_tf_client_secret" {
  description = "Terraform App Registration Client Secret"
  type        = string
}

variable "demo_data_contracts_bytetoeat_java_producer_client_id" {
  description = "Java Producer App Registration Client ID"
  type        = string
}

variable "demo_data_contracts_bytetoeat_java_producer_client_secret" {
  description = "Java Producer App Registration Client Secret"
  type        = string
}

variable "demo_data_contracts_bytetoeat_java_consumer_client_id" {
  description = "Java Consumer App Registration Client ID"
  type        = string
}

variable "demo_data_contracts_bytetoeat_java_consumer_client_secret" {
  description = "Java Consumer App Registration Client Secret"
  type        = string
}

variable "resource_group" {
  description = "The name of the Azure Resource Group"
  type        = string
}

variable "cloud" {
  description = "The Cloud"
  type        = string
}

variable "region" {
  description = "The Azure region to deploy resources into (e.g., australiaeast, eastus, westeurope)"
  type        = string
}

variable "unique-id" {
  description = "The Unique ID for the deployment, used to create unique resource names"
  type        = string
}

variable "subscription-id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "tenant-id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "demo-data-contracts-bytetoeat-tf-client-id" {
  description = "Terraform App Registration Client ID"
  type        = string
}

variable "demo-data-contracts-bytetoeat-tf-client-secret" {
  description = "Terraform App Registration Client Secret"
  type        = string
}

variable "demo-data-contracts-bytetoeat-java-producer-client-id" {
  description = "Java Producer App Registration Client ID"
  type        = string
}

variable "demo-data-contracts-bytetoeat-java-producer-client-secret" {
  description = "Java Producer App Registration Client Secret"
  type        = string
}

variable "demo-data-contracts-bytetoeat-java-consumer-client-id" {
  description = "Java Consumer App Registration Client ID"
  type        = string
}

variable "demo-data-contracts-bytetoeat-java-consumer-client-secret" {
  description = "Java Consumer App Registration Client Secret"
  type        = string
}

variable "resource-group" {
  description = "The name of the Azure Resource Group"
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription ID to enable for the Private Link Access where your VNet exists"
  type        = string
}

variable "client_id" {
  description = "The ID of the Client on Azure"
  type        = string
}

variable "client_secret" {
  description = "The Secret of the Client on Azure"
  type        = string
}

variable "tenant_id" {
  description = "The Azure tenant ID in which Subscription exists"
  type        = string
}

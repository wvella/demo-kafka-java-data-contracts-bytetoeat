variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

variable "cloud" {
  description = "The Cloud"
  type        = string
}

variable "region" {
  description = "The AWS region to deploy resources into (e.g., ap-southeast-2)"
  type        = string
}

variable "unique_id" {
  description = "The Unique ID for the deployment, used to create unique resource names"
  type        = string
}

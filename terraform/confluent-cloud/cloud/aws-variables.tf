variable "cloud" {
  description = "The Cloud"
  type        = string
}

variable "region" {
  description = "The AWS region to deploy resources into (e.g., ap-southeast-2)"
  type        = string
}

variable "unique-id" {
  description = "The Unique ID for the deployment, used to create unique resource names"
  type        = string
}

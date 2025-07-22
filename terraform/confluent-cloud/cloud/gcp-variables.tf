variable "cloud" {
  description = "The Cloud"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources into (e.g., ap-southeast-2)"
  type        = string
}

variable "unique-id" {
  description = "The Unique ID for the deployment, used to create unique resource names"
  type        = string
}


variable "gcp-project-id" {
  description = "The GCP project-id to deploy resources into"
  type        = string
}

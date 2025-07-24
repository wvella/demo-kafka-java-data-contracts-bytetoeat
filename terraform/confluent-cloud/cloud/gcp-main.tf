terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.24.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 6.8.0"
    }
  }
}

provider "google" {
  project     = var.gcp-project-id
  region      = var.region

}
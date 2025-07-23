data "http" "get-kek-policy" {
  url = "${data.confluent_schema_registry_cluster.advanced.rest_endpoint}/dek-registry/v1/policy"

  request_headers = {
    Authorization = "Basic ${base64encode("${confluent_api_key.env-manager-schema-registry-api-key.id}:${confluent_api_key.env-manager-schema-registry-api-key.secret}")}"
    Accept        = "application/json"
  }
}

locals {
  kek_policy = jsondecode(data.http.get-kek-policy.response_body)["policy"]
}


# Create Producer service account & key
resource "google_service_account" "data-contracts-bytetoeat-java-producer" {
  account_id   = "producer-${var.unique-id}"
  display_name = "demo-data-contracts producer"
}

resource "google_service_account_key" "data-contracts-bytetoeat-java-producer" {
  service_account_id = google_service_account.data-contracts-bytetoeat-java-producer.id
  public_key_type    = "TYPE_X509_PEM_FILE"
}


# Creates Consumer service account & key
resource "google_service_account" "data-contracts-bytetoeat-java-consumer" {
  account_id   = "consumer-${var.unique-id}"
  display_name = "demo-data-contracts consumer"
}

resource "google_service_account_key" "data-contracts-bytetoeat-java-consumer" {
  service_account_id = google_service_account.data-contracts-bytetoeat-java-consumer.id
  public_key_type    = "TYPE_X509_PEM_FILE"
}


# Create KMS keyring
resource "google_kms_key_ring" "demo-data-contracts-bytetoeat-csfle-keyring" {
  name     = "demo-data-contracts-bytetoeat-csfle-keyring-${var.unique-id}"
  location = var.region
  project =  var.gcp-project-id
}

# Create a key
resource "google_kms_crypto_key" "demo-data-contracts-bytetoeat-csfle-key" {
  name            = "demo-data-contracts-bytetoeat-csfle-key-${var.unique-id}"
  key_ring        = google_kms_key_ring.demo-data-contracts-bytetoeat-csfle-keyring.id
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = false
  }
}

# Create key, to be shared
resource "google_kms_crypto_key" "demo-data-contracts-bytetoeat-csfle-key-shared" {
  name            = "demo-data-contracts-bytetoeat-csfle-key-shared-${var.unique-id}"
  key_ring        = google_kms_key_ring.demo-data-contracts-bytetoeat-csfle-keyring.id
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = false
  }
}


# Create GCP custom role
resource "google_project_iam_custom_role" "demo-data-contracts-bytetoeat-custom-role" {
  role_id     = "customrole${var.unique-id}"
  title       = "demo-data-contracts-custom-role-${var.unique-id}"
  description = "Custom role for Confluent Cloud CSFLE key access"
  permissions = ["cloudkms.cryptoKeyVersions.useToDecrypt","cloudkms.cryptoKeyVersions.useToEncrypt"]
}



# Give access to the Confluent Service Account via the custom role
resource "google_project_iam_member" "project_iam" {
  project = var.gcp-project-id
  role    = google_project_iam_custom_role.demo-data-contracts-bytetoeat-custom-role.id
  member  = "serviceAccount:${local.kek_policy}"
}

# Give access to the Producer Service Account via the custom role
resource "google_project_iam_member" "producer_iam" {
  project = var.gcp-project-id
  role    = google_project_iam_custom_role.demo-data-contracts-bytetoeat-custom-role.id
  member  = "serviceAccount:${google_service_account.data-contracts-bytetoeat-java-producer.email}"
}


# Give access to the Consumer Service Account via the custom role
resource "google_project_iam_member" "consumer_iam" {
  project = var.gcp-project-id
  role    = google_project_iam_custom_role.demo-data-contracts-bytetoeat-custom-role.id
  member  = "serviceAccount:${google_service_account.data-contracts-bytetoeat-java-consumer.email}"
}


# Add shared key to Schema Registry
resource "confluent_schema_registry_kek" "cc-kek-shared" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.advanced.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.advanced.rest_endpoint
  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }
  name        = "bytetoeat-${var.unique-id}-kek-shared"
  doc         = "GCP Key Encryption Key used for CSFLE encryption"
  kms_type    = "gcp-kms"
  kms_key_id = google_kms_crypto_key.demo-data-contracts-bytetoeat-csfle-key-shared.id
  shared      = true
  hard_delete = true
}

# Add key to Schema Registry
resource "confluent_schema_registry_kek" "cc-kek" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.advanced.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.advanced.rest_endpoint
  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }
  name        = "bytetoeat-${var.unique-id}-kek"
  doc         = "GCP Key Encryption Key used for CSFLE encryption"
  kms_type    = "gcp-kms"
  kms_key_id  = google_kms_crypto_key.demo-data-contracts-bytetoeat-csfle-key.id
  shared      = false
  hard_delete = true
}

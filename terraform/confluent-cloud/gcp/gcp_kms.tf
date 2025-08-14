data "http" "get-kek-policy" {
  url = "${data.confluent_schema_registry_cluster.advanced.rest_endpoint}/dek-registry/v1/policy"

  request_headers = {
    Authorization = "Basic ${base64encode("${confluent_api_key.env_manager_schema_registry_api_key.id}:${confluent_api_key.env_manager_schema_registry_api_key.secret}")}"
    Accept        = "application/json"
  }
}

locals {
  kek_policy = jsondecode(data.http.get-kek-policy.response_body)["policy"]
}


# Create Producer service account & key
resource "google_service_account" "data_contracts_bytetoeat_java_producer" {
  account_id   = "producer-${local.unique_id}"
  display_name = "demo-data-contracts-bytetoeat-producer"
}

resource "google_service_account_key" "data_contracts_bytetoeat_java_producer" {
  service_account_id = google_service_account.data_contracts_bytetoeat_java_producer.id
  public_key_type    = "TYPE_X509_PEM_FILE"
}


# Creates Consumer service account & key
resource "google_service_account" "data_contracts_bytetoeat_java_consumer" {
  account_id   = "consumer-${local.unique_id}"
  display_name = "demo-data-contracts-bytetoeat-consumer"
}

resource "google_service_account_key" "data_contracts_bytetoeat_java_consumer" {
  service_account_id = google_service_account.data_contracts_bytetoeat_java_consumer.id
  public_key_type    = "TYPE_X509_PEM_FILE"
}


# Create KMS keyring
resource "google_kms_key_ring" "demo_data_contracts_bytetoeat_csfle_keyring" {
  name     = "demo-data-contracts-bytetoeat-csfle-keyring-${local.unique_id}"
  location = local.region
  project  = var.gcp_project_id
}

# Create a key
resource "google_kms_crypto_key" "demo_data_contracts_bytetoeat_csfle_key" {
  name            = "demo-data-contracts-bytetoeat-csfle-key-${local.unique_id}"
  key_ring        = google_kms_key_ring.demo_data_contracts_bytetoeat_csfle_keyring.id
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = false
  }
}

# Create key, to be shared
resource "google_kms_crypto_key" "demo_data_contracts_bytetoeat_csfle_key_shared" {
  name            = "demo-data-contracts-bytetoeat-csfle-key-shared-${local.unique_id}"
  key_ring        = google_kms_key_ring.demo_data_contracts_bytetoeat_csfle_keyring.id
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = false
  }
}


# Create GCP custom role
resource "google_project_iam_custom_role" "demo_data_contracts_bytetoeat_custom_role" {
  role_id     = "customrole${local.unique_id}"
  title       = "demo-data-contracts-bytetoeat-custom-role-${local.unique_id}"
  description = "Custom role for Confluent Cloud CSFLE key access"
  permissions = ["cloudkms.cryptoKeyVersions.useToDecrypt", "cloudkms.cryptoKeyVersions.useToEncrypt"]
}



# Give access to the Confluent Service Account via the custom role
resource "google_project_iam_member" "cc_project_iam" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.demo_data_contracts_bytetoeat_custom_role.id
  member  = "serviceAccount:${local.kek_policy}"
}

# Give access to the Producer Service Account via the custom role
resource "google_project_iam_member" "producer_iam" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.demo_data_contracts_bytetoeat_custom_role.id
  member  = "serviceAccount:${google_service_account.data_contracts_bytetoeat_java_producer.email}"
}


# Give access to the Consumer Service Account via the custom role
resource "google_project_iam_member" "consumer_iam" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.demo_data_contracts_bytetoeat_custom_role.id
  member  = "serviceAccount:${google_service_account.data_contracts_bytetoeat_java_consumer.email}"
}


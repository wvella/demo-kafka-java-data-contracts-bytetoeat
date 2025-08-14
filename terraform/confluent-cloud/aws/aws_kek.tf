# TODO: Refactor to confluent directory

# Add shared key to Schema Registry
resource "confluent_schema_registry_kek" "cc_kek_shared" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.advanced.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.advanced.rest_endpoint
  credentials {
    key    = confluent_api_key.env_manager_schema_registry_api_key.id
    secret = confluent_api_key.env_manager_schema_registry_api_key.secret
  }
  name        = "bytetoeat-${local.unique_id}-kek-shared"
  doc         = "AWS Key Encryption Key used for CSFLE encryption"
  kms_type    = "aws-kms"
  kms_key_id  = aws_kms_key.demo_data_contracts_bytetoeat_csfle_key_shared.arn
  shared      = true
  hard_delete = true
}

# Add unshared key to Schema Registry
resource "confluent_schema_registry_kek" "cc_kek" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.advanced.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.advanced.rest_endpoint
  credentials {
    key    = confluent_api_key.env_manager_schema_registry_api_key.id
    secret = confluent_api_key.env_manager_schema_registry_api_key.secret
  }
  name        = "bytetoeat-${local.unique_id}-kek"
  doc         = "AWS Key Encryption Key used for CSFLE encryption"
  kms_type    = "aws-kms"
  kms_key_id  = aws_kms_key.demo_data_contracts_bytetoeat_csfle_key.arn
  shared      = false
  hard_delete = true
}

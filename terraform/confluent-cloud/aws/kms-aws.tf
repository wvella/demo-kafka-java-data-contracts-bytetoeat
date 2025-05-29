resource "confluent_schema_registry_kek" "aws_kek" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.advanced.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.advanced.rest_endpoint
  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }
  name        = "aws-kek-for-csfle"
  doc         = "AWS Key Encryption Key used for CSFLE encryption"
  kms_type    = "aws-kms"
  kms_key_id  = var.aws_kms_key_arn
  shared      = true
  hard_delete = true
}

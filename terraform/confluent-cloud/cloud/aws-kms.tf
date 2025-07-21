data "aws_caller_identity" "current" {}

data "http" "get-kek-policy" {
  url = "${data.confluent_schema_registry_cluster.advanced.rest_endpoint}/dek-registry/v1/policy"

  request_headers = {
    Authorization = "Basic ${base64encode("${confluent_api_key.env-manager-schema-registry-api-key.id}:${confluent_api_key.env-manager-schema-registry-api-key.secret}")}"
    Accept        = "application/json"
  }
}

locals {
  kek_policy = jsondecode(jsondecode(data.http.get-kek-policy.response_body)["policy"])
}

resource "aws_iam_user" "data-contracts-bytetoeat-java-producer" {
  name = "demo-data-contracts-bytetoeat-${var.unique-id}-java-producer"
}

resource "aws_iam_access_key" "data-contracts-bytetoeat-java-producer" {
  user = aws_iam_user.data-contracts-bytetoeat-java-producer.name
}

resource "aws_iam_user" "data-contracts-bytetoeat-java-consumer" {
  name = "demo-data-contracts-bytetoeat-${var.unique-id}-java-consumer"
}

resource "aws_iam_access_key" "data-contracts-bytetoeat-java-consumer" {
  user = aws_iam_user.data-contracts-bytetoeat-java-consumer.name
}

resource "aws_kms_alias" "kms-key-alias-demo-data-contracts-bytetoeat-csfle-key-shared" {
  name          = "alias/demo-data-contracts-bytetoeat-csfle-key-shared-${var.unique-id}"
  target_key_id = aws_kms_key.demo-data-contracts-bytetoeat-csfle-key-shared.key_id
}

resource "aws_kms_key" "demo-data-contracts-bytetoeat-csfle-key-shared" {
  description             = "A symmetric encryption KMS key"
  enable_key_rotation     = true
  deletion_window_in_days = 20
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-shared-${var.unique-id}}"
    Statement = concat([
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ], [local.kek_policy])
  })
}

resource "aws_kms_alias" "kms-key-alias-demo-data-contracts-bytetoeat-csfle-key" {
  name          = "alias/demo-data-contracts-bytetoeat-csfle-key-${var.unique-id}"
  target_key_id = aws_kms_key.demo-data-contracts-bytetoeat-csfle-key.key_id
}

resource "aws_kms_key" "demo-data-contracts-bytetoeat-csfle-key" {
  description             = "A symmetric encryption KMS key"
  enable_key_rotation     = true
  deletion_window_in_days = 20
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-${var.unique-id}"
    Statement = [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
        "Sid": "Allow Producer and Consumer Encrypt/Decrypt",
        "Effect": "Allow",
        "Principal": {
          "AWS": [
            aws_iam_user.data-contracts-bytetoeat-java-producer.arn,
            aws_iam_user.data-contracts-bytetoeat-java-consumer.arn
          ]
        },
        "Action": [
          "kms:Encrypt",
          "kms:Decrypt"
        ],
        "Resource": "*"
      }
    ]
  })
}

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
  doc         = "AWS Key Encryption Key used for CSFLE encryption"
  kms_type    = "aws-kms"
  kms_key_id  = aws_kms_key.demo-data-contracts-bytetoeat-csfle-key-shared.arn
  shared      = true
  hard_delete = true
}

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
  doc         = "AWS Key Encryption Key used for CSFLE encryption"
  kms_type    = "aws-kms"
  kms_key_id  = aws_kms_key.demo-data-contracts-bytetoeat-csfle-key.arn
  shared      = false
  hard_delete = true
}

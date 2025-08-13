data "aws_caller_identity" "current" {}

data "http" "get_kek_policy" {
  url = "${data.confluent_schema_registry_cluster.advanced.rest_endpoint}/dek-registry/v1/policy"

  request_headers = {
    Authorization = "Basic ${base64encode("${confluent_api_key.env_manager_schema_registry_api_key.id}:${confluent_api_key.env_manager_schema_registry_api_key.secret}")}"
    Accept        = "application/json"
  }
}

locals {
  kek_policy = jsondecode(jsondecode(data.http.get_kek_policy.response_body)["policy"])
}

resource "aws_iam_user" "data_contracts_bytetoeat_java_producer" {
  name = "demo-data-contracts-bytetoeat-${local.unique_id}-java-producer"
}

resource "aws_iam_access_key" "data_contracts_bytetoeat_java_producer" {
  user = aws_iam_user.data_contracts_bytetoeat_java_producer.name
}

resource "aws_iam_user" "data_contracts_bytetoeat_java_consumer" {
  name = "demo-data-contracts-bytetoeat-${local.unique_id}-java-consumer"
}

resource "aws_iam_access_key" "data_contracts_bytetoeat_java_consumer" {
  user = aws_iam_user.data_contracts_bytetoeat_java_consumer.name
}

resource "aws_kms_alias" "kms_key_alias_demo_data_contracts_bytetoeat_csfle_key_shared" {
  name          = "alias/demo-data-contracts-bytetoeat-csfle-key-shared-${local.unique_id}"
  target_key_id = aws_kms_key.demo_data_contracts_bytetoeat_csfle_key_shared.key_id
}

resource "aws_kms_key" "demo_data_contracts_bytetoeat_csfle_key_shared" {
  description             = "A symmetric encryption KMS key"
  enable_key_rotation     = true
  deletion_window_in_days = 20
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-shared-${local.unique_id}"
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

resource "aws_kms_alias" "kms_key_alias_demo_data_contracts_bytetoeat_csfle_key" {
  name          = "alias/demo-data-contracts-bytetoeat-csfle-key-${local.unique_id}"
  target_key_id = aws_kms_key.demo_data_contracts_bytetoeat_csfle_key.key_id
}

resource "aws_kms_key" "demo_data_contracts_bytetoeat_csfle_key" {
  description             = "A symmetric encryption KMS key"
  enable_key_rotation     = true
  deletion_window_in_days = 20
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-${local.unique_id}"
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
            aws_iam_user.data_contracts_bytetoeat_java_producer.arn,
            aws_iam_user.data_contracts_bytetoeat_java_consumer.arn
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
# app_manager service account: Used to create other Terraform resources

// 'app_manager' service account is required in this configuration to create 'raw.recipes' topic and assign roles
// to 'app_producer' and 'app_consumer' service accounts.
resource "confluent_service_account" "app_manager" {
  display_name = "app_manager-${var.unique_id}"
  description  = "Service account to manage 'restaurant' Kafka cluster"
}

resource "confluent_role_binding" "app_manager_kafka_cluster_admin" {
  principal   = "User:${confluent_service_account.app_manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.standard.rbac_crn
}

resource "confluent_api_key" "app_manager_kafka_api_key" {
  display_name = "app_manager_kafka_api_key-${var.unique_id}"
  description  = "Kafka API Key that is owned by 'app_manager' service account"
  owner {
    id          = confluent_service_account.app_manager.id
    api_version = confluent_service_account.app_manager.api_version
    kind        = confluent_service_account.app_manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.bytetoeat.id
    }
  }

  # The goal is to ensure that confluent_role_binding.app_manager_kafka_cluster_admin is created before
  # confluent_api_key.app_manager_kafka_api_key is used to create instances of
  # confluent_kafka_topic, confluent_kafka_acl resources.

  # 'depends_on' meta-argument is specified in confluent_api_key.app_manager_kafka_api_key to avoid having
  # multiple copies of this definition in the configuration which would happen if we specify it in
  # confluent_kafka_topic, confluent_kafka_acl resources instead.
  depends_on = [
    confluent_role_binding.app_manager_kafka_cluster_admin
  ]
}

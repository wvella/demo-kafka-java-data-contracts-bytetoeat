# app_producer service account: Used to produce to 'raw.recipes' and 'raw.orders' topics
# * Kafka and SR API Keys

# Topic RBAC Roles:
# * DeveloperWrite on raw.recipes topic
# * DeveloperWrite on raw.orders topic
# * DeveloperWrite on raw.recipes DLQ topic
# * DeveloperWrite on raw.orders DLQ topic

# Schema Registry RBAC Roles:
# * DeveloperWrite on Schema Registry (all subjects)
# * DeveloperWrite and DeveloperRead on Schema Registry shared key
# * DeveloperWrite and DeveloperRead on Schema Registry key (unshared)

resource "confluent_service_account" "app_producer" {
  display_name = "app_producer-${var.unique_id}"
  description  = "Service account to produce to 'raw.recipes' topic of 'restaurant' Kafka cluster"
}

resource "confluent_api_key" "app_producer_kafka_api_key" {
  display_name = "app_producer_kafka_api_key-${var.unique_id}"
  description  = "Kafka API Key that is owned by 'app_producer' service account"
  owner {
    id          = confluent_service_account.app_producer.id
    api_version = confluent_service_account.app_producer.api_version
    kind        = confluent_service_account.app_producer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.bytetoeat.id
    }
  }
}

resource "confluent_api_key" "app_producer_schema_registry_api_key" {
  display_name = "app_producer_schema_registry_api_key-${var.unique_id}"
  description  = "Schema Registry API Key that is owned by 'app_producer' service account"
  owner {
    id          = confluent_service_account.app_producer.id
    api_version = confluent_service_account.app_producer.api_version
    kind        = confluent_service_account.app_producer.kind
  }

  managed_resource {
    id          = data.confluent_schema_registry_cluster.advanced.id
    api_version = data.confluent_schema_registry_cluster.advanced.api_version
    kind        = data.confluent_schema_registry_cluster.advanced.kind

    environment {
      id = confluent_environment.bytetoeat.id
    }
  }
}

# Topic permissions
resource "confluent_role_binding" "app_producer_developer_recipes_write" {
  principal   = "User:${confluent_service_account.app_producer.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.raw_recipes.topic_name}"
}

resource "confluent_role_binding" "app_producer_developer_orders_write" {
  principal   = "User:${confluent_service_account.app_producer.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.raw_orders.topic_name}"
}

resource "confluent_role_binding" "app_producer_developer_recipes_write_dlq" {
  principal   = "User:${confluent_service_account.app_producer.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.raw_recipes_dlq.topic_name}"
}

resource "confluent_role_binding" "app_producer_developer_orders_write_dlq" {
  principal   = "User:${confluent_service_account.app_producer.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.raw_orders_dlq.topic_name}"
}

# Schema Registry subject permissions
resource "confluent_role_binding" "app_producer_schema_registry_api_key_developer_write" {
  principal   = "User:${confluent_service_account.app_producer.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/subject=*"
}

# Schema Registry DEK Registry key permissions
resource "confluent_role_binding" "app_producer_schema_registry_api_key_developer_write_kek" {
  principal   = "User:${confluent_service_account.app_producer.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/kek=${confluent_schema_registry_kek.cc_kek.name}"
}

resource "confluent_role_binding" "app_producer_schema_registry_api_key_developer_read_kek" {
  principal   = "User:${confluent_service_account.app_producer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/kek=${confluent_schema_registry_kek.cc_kek.name}"
}

resource "confluent_role_binding" "app_producer_schema_registry_api_key_developer_write_kek_shared" {
  principal   = "User:${confluent_service_account.app_producer.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/kek=${confluent_schema_registry_kek.cc_kek_shared.name}"
}

resource "confluent_role_binding" "app_producer_schema_registry_api_key_developer_read_kek_shared" {
  principal   = "User:${confluent_service_account.app_producer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/kek=${confluent_schema_registry_kek.cc_kek_shared.name}"
}

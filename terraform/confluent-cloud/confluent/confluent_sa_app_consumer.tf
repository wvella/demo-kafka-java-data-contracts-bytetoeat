# app_consumer service account: Used to consume from 'raw.recipes' and 'raw.orders' topics
# * Kafka and SR API Keys

# Topic RBAC Roles:
# * DeveloperRead on raw.recipes topic and consumer group
# * DeveloperRead on raw.orders topic and consumer group

# Schema Registry RBAC Roles:
# * DeveloperRead on Schema Registry (all subjects)
# * DeveloperRead on Schema Registry shared key
# * DeveloperRead on Schema Registry key (unshared)

resource "confluent_service_account" "app_consumer" {
  display_name = "app_consumer-${var.unique_id}"
  description  = "Service account to consume from 'raw.recipes' topic of 'restaurant' Kafka cluster"
}

resource "confluent_api_key" "app_consumer_kafka_api_key" {
  display_name = "app_consumer_kafka_api_key-${var.unique_id}"
  description  = "Kafka API Key that is owned by 'app_consumer' service account"
  owner {
    id          = confluent_service_account.app_consumer.id
    api_version = confluent_service_account.app_consumer.api_version
    kind        = confluent_service_account.app_consumer.kind
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

resource "confluent_api_key" "app_consumer_schema_registry_api_key" {
  display_name = "app_consumer_schema_registry_api_key-${var.unique_id}"
  description  = "Schema Registry API Key that is owned by 'app_consumer' service account"
  owner {
    id          = confluent_service_account.app_consumer.id
    api_version = confluent_service_account.app_consumer.api_version
    kind        = confluent_service_account.app_consumer.kind
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

// Note that in order to consume from a topic, the principal of the consumer ('app_consumer' service account)
// needs to be authorized to perform 'READ' operation on both Topic and Group resources:
resource "confluent_role_binding" "app_consumer_developer_recipes_read_from_topic" {
  principal   = "User:${confluent_service_account.app_consumer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.raw_recipes.topic_name}"
}

resource "confluent_role_binding" "app_consumer_developer_recipes_read_from_group" {
  principal   = "User:${confluent_service_account.app_consumer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/group=java-recipes-consumer-*"
}

resource "confluent_role_binding" "app_consumer_developer_orders_read_from_topic" {
  principal   = "User:${confluent_service_account.app_consumer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.raw_orders.topic_name}"
}

resource "confluent_role_binding" "app_consumer_developer_orders_read_from_group" {
  principal   = "User:${confluent_service_account.app_consumer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/group=java-orders-consumer-*"
}

# Schema Registry subject permissions
resource "confluent_role_binding" "app_consumer_schema_registry_api_key_developer" {
  principal   = "User:${confluent_service_account.app_consumer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/subject=*"
}

# Schema Registry DEK Registry key permissions
resource "confluent_role_binding" "app_consumer_schema_registry_api_key_developer_read_kek_shared" {
  principal   = "User:${confluent_service_account.app_consumer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/kek=${confluent_schema_registry_kek.cc_kek_shared.name}"
}

resource "confluent_role_binding" "app_consumer_schema_registry_api_key_developer_read_kek" {
  principal   = "User:${confluent_service_account.app_consumer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/kek=${confluent_schema_registry_kek.cc_kek.name}"
}
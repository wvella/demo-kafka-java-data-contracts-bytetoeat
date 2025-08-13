
resource "confluent_environment" "bytetoeat" {
  display_name = "byte-to-eat-${var.unique_id}"

  stream_governance {
    package = "ADVANCED"
  }
}

data "confluent_schema_registry_cluster" "advanced" {
  environment {
    id = confluent_environment.bytetoeat.id
  }

  depends_on = [
    confluent_kafka_cluster.standard
  ]
}


# Update the config to use a cloud provider and region of your choice.
# https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_kafka_cluster
resource "confluent_kafka_cluster" "standard" {
  display_name = "restaurant-kafka-cluster-${var.unique_id}"
  availability = "SINGLE_ZONE"
  cloud        = var.cloud
  region       = var.region
  standard {}
  environment {
    id = confluent_environment.bytetoeat.id
  }
}

// api key for schema registry is required to create and manage schemas in the schema registry.
// the api key is owned by the 'env_manager' service account.
resource "confluent_service_account" "env_manager" {
  display_name = "env_manager-${var.unique_id}"
  description  = "Service account to manage the 'byte-to-eat' environment"
}

resource "confluent_role_binding" "env_manager_kafka_cluster_admin" {
  principal   = "User:${confluent_service_account.env_manager.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.bytetoeat.resource_name
}

resource "confluent_api_key" "env_manager_schema_registry_api_key" {
  display_name = "env_manager-schema-registry-api-key-${var.unique_id}"
  description  = "Schema Registry API Key that is owned by 'env_manager' service account"
  owner {
    id          = confluent_service_account.env_manager.id
    api_version = confluent_service_account.env_manager.api_version
    kind        = confluent_service_account.env_manager.kind
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

resource "confluent_role_binding" "app_producer_schema_registry_api_key_developer_write" {
  principal   = "User:${confluent_service_account.app_producer.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/subject=*"
}

resource "confluent_role_binding" "app_consumer_schema_registry_api_key_developer" {
  principal   = "User:${confluent_service_account.app_consumer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/subject=*"
}

resource "confluent_role_binding" "app_producer_schema_registry_api_key_developer_read_kek_shared" {
  principal   = "User:${confluent_service_account.app_producer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/kek=${confluent_schema_registry_kek.cc_kek_shared.name}"
}

resource "confluent_role_binding" "app_producer_schema_registry_api_key_developer_read_kek" {
  principal   = "User:${confluent_service_account.app_producer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/kek=${confluent_schema_registry_kek.cc_kek.name}"
}

resource "confluent_role_binding" "app_producer_schema_registry_api_key_developer_write_kek" {
  principal   = "User:${confluent_service_account.app_producer.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/kek=${confluent_schema_registry_kek.cc_kek.name}"
}

resource "confluent_role_binding" "app_producer_schema_registry_api_key_developer_write_kek_shared" {
  principal   = "User:${confluent_service_account.app_producer.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/kek=${confluent_schema_registry_kek.cc_kek_shared.name}"
}

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

resource "confluent_role_binding" "env_manager_resource_owner_kek" {
  principal   = "User:${confluent_service_account.env_manager.id}"
  role_name   = "ResourceOwner"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/kek=${confluent_schema_registry_kek.cc_kek.name}"
}

resource "confluent_role_binding" "env_manager_resource_owner_kek_shared" {
  principal   = "User:${confluent_service_account.env_manager.id}"
  role_name   = "ResourceOwner"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/kek=${confluent_schema_registry_kek.cc_kek_shared.name}"
}

resource "confluent_api_key" "app_consumer_schema_registry_api_key" {
  display_name = "app_consumer_schema_registry_api_key-${var.unique_id}"
  description  = "Schema Registry API Key that is owned by 'app-consumer' service account"
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

// 'app-manager' service account is required in this configuration to create 'raw.recipes' topic and assign roles
// to 'app-producer' and 'app-consumer' service accounts.
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
  description  = "Kafka API Key that is owned by 'app-manager' service account"
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

  # The goal is to ensure that confluent_role_binding.app-manager-kafka-cluster-admin is created before
  # confluent_api_key.app-manager-kafka-api-key is used to create instances of
  # confluent_kafka_topic, confluent_kafka_acl resources.

  # 'depends_on' meta-argument is specified in confluent_api_key.app-manager-kafka-api-key to avoid having
  # multiple copies of this definition in the configuration which would happen if we specify it in
  # confluent_kafka_topic, confluent_kafka_acl resources instead.
  depends_on = [
    confluent_role_binding.app_manager_kafka_cluster_admin
  ]
}

resource "confluent_kafka_topic" "raw_recipes" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  topic_name    = "raw.recipes"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_api_key.id
    secret = confluent_api_key.app_manager_kafka_api_key.secret
  }
}

resource "confluent_kafka_topic" "raw_recipes_dlq" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  topic_name    = "raw.recipes.dlq"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_api_key.id
    secret = confluent_api_key.app_manager_kafka_api_key.secret
  }
}

resource "confluent_kafka_topic" "raw_orders" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  topic_name    = "raw.orders"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_api_key.id
    secret = confluent_api_key.app_manager_kafka_api_key.secret
  }
}

resource "confluent_kafka_topic" "raw_orders_dlq" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  topic_name    = "raw.orders.dlq"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_api_key.id
    secret = confluent_api_key.app_manager_kafka_api_key.secret
  }
}

resource "confluent_kafka_topic" "enriched_orders" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  topic_name    = "enriched_orders"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_api_key.id
    secret = confluent_api_key.app_manager_kafka_api_key.secret
  }
}

resource "confluent_service_account" "app_consumer" {
  display_name = "app_consumer-${var.unique_id}"
  description  = "Service account to consume from 'raw.recipes' topic of 'restaurant' Kafka cluster"
}

resource "confluent_api_key" "app_consumer_kafka_api_key" {
  display_name = "app_consumer_kafka_api_key-${var.unique_id}"
  description  = "Kafka API Key that is owned by 'app-consumer' service account"
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

resource "confluent_service_account" "app_producer" {
  display_name = "app_producer-${var.unique_id}"
  description  = "Service account to produce to 'raw.recipes' topic of 'restaurant' Kafka cluster"
}

resource "confluent_api_key" "app_producer_kafka_api_key" {
  display_name = "app_producer_kafka_api_key-${var.unique_id}"
  description  = "Kafka API Key that is owned by 'app-producer' service account"
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

// Note that in order to consume from a topic, the principal of the consumer ('app-consumer' service account)
// needs to be authorized to perform 'READ' operation on both Topic and Group resources:
resource "confluent_role_binding" "app_consumer_developer_recipes_read_from_topic" {
  principal   = "User:${confluent_service_account.app_consumer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.raw_recipes.topic_name}"
}

resource "confluent_role_binding" "app_consumer_developer_recipes_read_from_group" {
  principal = "User:${confluent_service_account.app_consumer.id}"
  role_name = "DeveloperRead"
  // The existing value of crn_pattern's suffix (group=confluent_cli_consumer_*) are set up to match Confluent CLI's default consumer group ID ("confluent_cli_consumer_<uuid>").
  // https://docs.confluent.io/confluent-cli/current/command-reference/kafka/topic/confluent_kafka_topic_consume.html
  // Update it to match your target consumer group ID.
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/group=java-recipes-consumer-*"
}
resource "confluent_role_binding" "app_consumer_developer_orders_read_from_topic" {
  principal   = "User:${confluent_service_account.app_consumer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.raw_orders.topic_name}"
}

resource "confluent_role_binding" "app_consumer_developer_orders_read_from_group" {
  principal = "User:${confluent_service_account.app_consumer.id}"
  role_name = "DeveloperRead"
  // The existing value of crn_pattern's suffix (group=confluent_cli_consumer_*) are set up to match Confluent CLI's default consumer group ID ("confluent_cli_consumer_<uuid>").
  // https://docs.confluent.io/confluent-cli/current/command-reference/kafka/topic/confluent_kafka_topic_consume.html
  // Update it to match your target consumer group ID.
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/group=java-orders-consumer-*"
}

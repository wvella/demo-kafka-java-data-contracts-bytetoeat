# env_manager service account: Used to create and manage other Terraform resources
# * Kafka and SR API Keys

# Environment RBAC Roles:
# * EnvironmentAdmin on Environment

# Schema Registry RBAC Roles:
# * ResourceOwner on Schema Registry shared key
# * ResourceOwner on Schema Registry key (unshared)

# TODO: Validate we actually need the ResourceOwner roles (might be possible to just use EnvironmentAdmin)

resource "confluent_service_account" "env_manager" {
  display_name = "env_manager-${var.unique_id}"
  description  = "Service account to manage the 'byte-to-eat' environment"
}

resource "confluent_api_key" "env_manager_kafka_api_key" {
  display_name = "env_manager-kafka-api-key-${var.unique_id}"
  description  = "Kafka API Key that is owned by 'env_manager' service account"
  owner {
    id          = confluent_service_account.env_manager.id
    api_version = confluent_service_account.env_manager.api_version
    kind        = confluent_service_account.env_manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.bytetoeat.id
    }
  }

  depends_on = [
    confluent_role_binding.env_manager_kafka_cluster_admin
  ]
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

resource "confluent_role_binding" "env_manager_kafka_cluster_admin" {
  principal   = "User:${confluent_service_account.env_manager.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.bytetoeat.resource_name
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

# app_manager_flink Service Account: Used to manage Flink resources
# * Flink API Key

# FlinkDeveloper Role (for entire environment)

# Transaction Roles
# DeveloperRead and DeveloperWrite on Flink transactions

# Assigner Role (assign statements runner service account to compute pool)

resource "confluent_service_account" "app_manager_flink" {
  display_name = "app_manager_flink-${var.unique_id}"
  description  = "Service account that has full access to Flink resources in an environment"
}

resource "confluent_api_key" "app_manager_flink_api_key" {
  display_name = "app_manager_flink_api_key-${var.unique_id}"
  description  = "Flink API Key that is owned by 'app_manager_flink' service account"
  owner {
    id          = confluent_service_account.app_manager_flink.id
    api_version = confluent_service_account.app_manager_flink.api_version
    kind        = confluent_service_account.app_manager_flink.kind
  }
  managed_resource {
    id          = data.confluent_flink_region.flink_region.id
    api_version = data.confluent_flink_region.flink_region.api_version
    kind        = data.confluent_flink_region.flink_region.kind
    environment {
      id = confluent_environment.bytetoeat.id
    }
  }

  depends_on = [
    confluent_role_binding.app_manager_flink_developer,
    confluent_role_binding.app_manager_flink_transaction_id_developer_read,
    confluent_role_binding.app_manager_flink_transaction_id_developer_write
  ]
}

// https://docs.confluent.io/cloud/current/access-management/access-control/rbac/predefined-rbac-roles.html#flinkdeveloper
resource "confluent_role_binding" "app_manager_flink_developer" {
  principal   = "User:${confluent_service_account.app_manager_flink.id}"
  role_name   = "FlinkDeveloper"
  crn_pattern = confluent_environment.bytetoeat.resource_name
}

// Note: these role bindings (app_manager_flink_transaction_id_developer_read, app_manager_flink_transaction_id_developer_write)
// are not required for running this example, but you may have to add it in order
// to create and complete transactions.
// https://docs.confluent.io/cloud/current/flink/operate-and-deploy/flink-rbac.html#authorization
resource "confluent_role_binding" "app_manager_flink_transaction_id_developer_read" {
  principal   = "User:${confluent_service_account.app_manager_flink.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/transactional-id=_confluent-flink_*"
}

resource "confluent_role_binding" "app_manager_flink_transaction_id_developer_write" {
  principal   = "User:${confluent_service_account.app_manager_flink.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/transactional-id=_confluent-flink_*"
}

// https://docs.confluent.io/cloud/current/access-management/access-control/rbac/predefined-rbac-roles.html#assigner
// https://docs.confluent.io/cloud/current/flink/operate-and-deploy/flink-rbac.html#submit-long-running-statements
resource "confluent_role_binding" "app_manager_flink_assigner" {
  principal   = "User:${confluent_service_account.app_manager_flink.id}"
  role_name   = "Assigner"
  crn_pattern = "${data.confluent_organization.confluent.resource_name}/service-account=${confluent_service_account.statements_runner.id}"
}
locals {
  enriched_table_name  = "enriched_orders"
}

// Service account to perform a task within Confluent Cloud, such as executing a Flink statement
resource "confluent_service_account" "statements_runner" {
  display_name = "statements_runner-${var.unique_id}"
  description  = "Service account for running Flink Statements in the 'restaurants' Kafka cluster"
}

resource "confluent_role_binding" "statements_runner_environment_admin" {
  principal   = "User:${confluent_service_account.statements_runner.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.bytetoeat.resource_name
}

resource "confluent_role_binding" "statements_runner_recipes_developer_read" {
  principal   = "User:${confluent_service_account.statements_runner.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.raw_recipes.topic_name}"
}

resource "confluent_role_binding" "statements_runner_orders_developer_read" {
  principal   = "User:${confluent_service_account.statements_runner.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.raw_orders.topic_name}"
}

resource "confluent_role_binding" "statements_runner_enriched_orders_developer_write" {
  principal   = "User:${confluent_service_account.statements_runner.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${local.enriched_table_name}"
}

// Service account that owns Flink API Key
resource "confluent_service_account" "app_manager_flink" {
  display_name = "app_manager_flink-${var.unique_id}"
  description  = "Service account that has full access to Flink resources in an environment"
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
  principal = "User:${confluent_service_account.app_manager_flink.id}"
  role_name = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/transactional-id=_confluent-flink_*"
 }

resource "confluent_role_binding" "app_manager_flink_transaction_id_developer_write" {
  principal = "User:${confluent_service_account.app_manager_flink.id}"
  role_name = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/transactional-id=_confluent-flink_*"
}

// https://docs.confluent.io/cloud/current/access-management/access-control/rbac/predefined-rbac-roles.html#assigner
// https://docs.confluent.io/cloud/current/flink/operate-and-deploy/flink-rbac.html#submit-long-running-statements
resource "confluent_role_binding" "app_manager_flink_assigner" {
  principal   = "User:${confluent_service_account.app_manager_flink.id}"
  role_name   = "Assigner"
  crn_pattern = "${data.confluent_organization.confluent.resource_name}/service-account=${confluent_service_account.statements_runner.id}"
}
data "confluent_flink_region" "flink_region" {
  cloud  = var.cloud
  region = var.region
}
resource "confluent_api_key" "app_manager_flink_api_key" {
  display_name = "app-manager-flink-api-key-${var.unique_id}"
  description  = "Flink API Key that is owned by 'app-manager-flink' service account"
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

# https://docs.confluent.io/cloud/current/flink/get-started/quick-start-cloud-console.html#step-1-create-a-af-compute-pool
resource "confluent_flink_compute_pool" "flink_compute_pool" {
  display_name = "flink-compute-pool-${var.unique_id}"
  cloud        = var.cloud
  region       = var.region
  max_cfu      = 10
  environment {
    id = confluent_environment.bytetoeat.id
  }
  depends_on = [
    confluent_role_binding.statements_runner_environment_admin,
    confluent_role_binding.app_manager_flink_assigner,
    confluent_role_binding.app_manager_flink_developer,
    confluent_api_key.app_manager_flink_api_key,
  ]
}
resource "confluent_flink_statement" "enrich_orders" {
  organization {
    id = data.confluent_organization.confluent.id
  }
  environment {
    id = confluent_environment.bytetoeat.id
  }
  compute_pool {
    id = confluent_flink_compute_pool.flink_compute_pool.id
  }
  principal {
    id = confluent_service_account.statements_runner.id
  }
  # https://docs.confluent.io/cloud/current/flink/reference/example-data.html#marketplace-database
  statement = file("statements/enriched-orders.sql")
  properties = {
    "sql.current-catalog"  = confluent_environment.bytetoeat.display_name
    "sql.current-database" = confluent_kafka_cluster.standard.display_name
    "sql.state-ttl" = "86400000" # 1 day in milliseconds
  }
  rest_endpoint = data.confluent_flink_region.flink_region.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_flink_api_key.id
    secret = confluent_api_key.app_manager_flink_api_key.secret
  }
  depends_on = [
    confluent_kafka_topic.raw_orders,
    confluent_kafka_topic.raw_recipes,
    confluent_kafka_topic.enriched_orders
  ]

}
resource "confluent_flink_statement" "alter_watermark" {
  organization {
    id = data.confluent_organization.confluent.id
  }
  environment {
    id = confluent_environment.bytetoeat.id
  }
  compute_pool {
    id = confluent_flink_compute_pool.flink_compute_pool.id
  }
  principal {
    id = confluent_service_account.statements_runner.id
  }
  statement = file("statements/alter-watermark.sql")
  properties = {
    "sql.current-catalog"  = confluent_environment.bytetoeat.display_name
    "sql.current-database" = confluent_kafka_cluster.standard.display_name
  }
  rest_endpoint = data.confluent_flink_region.flink_region.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_flink_api_key.id
    secret = confluent_api_key.app_manager_flink_api_key.secret
  }
  depends_on = [
    confluent_kafka_topic.enriched_orders,
    confluent_schema.enriched_orders_value
  ]

}

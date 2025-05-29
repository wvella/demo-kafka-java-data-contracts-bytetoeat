locals {
  enriched_table_name  = "enriched_orders"
}

// Service account to perform a task within Confluent Cloud, such as executing a Flink statement
resource "confluent_service_account" "statements-runner" {
  display_name = "statements-runner"
  description  = "Service account for running Flink Statements in the 'restaurants' Kafka cluster"
}

resource "confluent_role_binding" "statements-runner-environment-admin" {
  principal   = "User:${confluent_service_account.statements-runner.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.bytetoeat.resource_name
}

resource "confluent_role_binding" "statements-runner-orders-developer-read" {
  principal   = "User:${confluent_service_account.statements-runner.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.raw_recipes.topic_name}"
}

resource "confluent_role_binding" "statements-runner-recipes-developer-read" {
  principal   = "User:${confluent_service_account.statements-runner.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.raw_orders.topic_name}"
}

resource "confluent_role_binding" "statements-runner-enriched-orders-developer-write" {
  principal   = "User:${confluent_service_account.statements-runner.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${local.enriched_table_name}"
}

// Service account that owns Flink API Key
resource "confluent_service_account" "app-manager-flink" {
  display_name = "app-manager-flink"
  description  = "Service account that has full access to Flink resources in an environment"
}

// https://docs.confluent.io/cloud/current/access-management/access-control/rbac/predefined-rbac-roles.html#flinkdeveloper
resource "confluent_role_binding" "app-manager-flink-developer" {
  principal   = "User:${confluent_service_account.app-manager-flink.id}"
  role_name   = "FlinkDeveloper"
  crn_pattern = confluent_environment.bytetoeat.resource_name
}

// Note: these role bindings (app-manager-flink-transaction-id-developer-read, app-manager--flinktransaction-id-developer-write)
// are not required for running this example, but you may have to add it in order
// to create and complete transactions.
// https://docs.confluent.io/cloud/current/flink/operate-and-deploy/flink-rbac.html#authorization
resource "confluent_role_binding" "app-manager-flink-transaction-id-developer-read" {
  principal = "User:${confluent_service_account.app-manager-flink.id}"
  role_name = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/transactional-id=_confluent-flink_*"
 }

resource "confluent_role_binding" "app-manager-flink-transaction-id-developer-write" {
  principal = "User:${confluent_service_account.app-manager-flink.id}"
  role_name = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/transactional-id=_confluent-flink_*"
}

// https://docs.confluent.io/cloud/current/access-management/access-control/rbac/predefined-rbac-roles.html#assigner
// https://docs.confluent.io/cloud/current/flink/operate-and-deploy/flink-rbac.html#submit-long-running-statements
resource "confluent_role_binding" "app-manager-flink-assigner" {
  principal   = "User:${confluent_service_account.app-manager-flink.id}"
  role_name   = "Assigner"
  crn_pattern = "${data.confluent_organization.Confluent.resource_name}/service-account=${confluent_service_account.statements-runner.id}"
}
data "confluent_flink_region" "flink-region" {
  cloud  = local.cloud
  region = local.region
}
resource "confluent_api_key" "app-manager-flink-api-key" {
  display_name = "app-manager-flink-api-key"
  description  = "Flink API Key that is owned by 'app-manager-flink' service account"
  owner {
    id          = confluent_service_account.app-manager-flink.id
    api_version = confluent_service_account.app-manager-flink.api_version
    kind        = confluent_service_account.app-manager-flink.kind
  }
  managed_resource {
    id          = data.confluent_flink_region.flink-region.id
    api_version = data.confluent_flink_region.flink-region.api_version
    kind        = data.confluent_flink_region.flink-region.kind
    environment {
      id = confluent_environment.bytetoeat.id
    }
  }

  depends_on = [
    confluent_role_binding.app-manager-flink-developer,
    confluent_role_binding.app-manager-flink-transaction-id-developer-read,
    confluent_role_binding.app-manager-flink-transaction-id-developer-write
  ]
}

# https://docs.confluent.io/cloud/current/flink/get-started/quick-start-cloud-console.html#step-1-create-a-af-compute-pool
resource "confluent_flink_compute_pool" "flink_compute_pool" {
  display_name = "flink-compute-pool"
  cloud        = local.cloud
  region       = local.region
  max_cfu      = 10
  environment {
    id = confluent_environment.bytetoeat.id
  }
  depends_on = [
    confluent_role_binding.statements-runner-environment-admin,
    confluent_role_binding.app-manager-flink-assigner,
    confluent_role_binding.app-manager-flink-developer,
    confluent_api_key.app-manager-flink-api-key,
  ]
}
resource "confluent_flink_statement" "enrich-orders" {
  organization {
    id = data.confluent_organization.Confluent.id
  }
  environment {
    id = confluent_environment.bytetoeat.id
  }
  compute_pool {
    id = confluent_flink_compute_pool.flink_compute_pool.id
  }
  principal {
    id = confluent_service_account.statements-runner.id
  }
  # https://docs.confluent.io/cloud/current/flink/reference/example-data.html#marketplace-database
  statement = file("./statements/enriched-orders.sql")
  properties = {
    "sql.current-catalog"  = confluent_environment.bytetoeat.display_name
    "sql.current-database" = confluent_kafka_cluster.standard.display_name
  }
  rest_endpoint = data.confluent_flink_region.flink-region.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-flink-api-key.id
    secret = confluent_api_key.app-manager-flink-api-key.secret
  }
  depends_on = [
    confluent_kafka_topic.raw_orders,
    confluent_kafka_topic.raw_recipes,
    confluent_kafka_topic.enriched_orders
  ]

}
resource "confluent_flink_statement" "alter-watermark" {
  organization {
    id = data.confluent_organization.Confluent.id
  }
  environment {
    id = confluent_environment.bytetoeat.id
  }
  compute_pool {
    id = confluent_flink_compute_pool.flink_compute_pool.id
  }
  principal {
    id = confluent_service_account.statements-runner.id
  }
  statement = file("./statements/alter-watermark.sql")
  properties = {
    "sql.current-catalog"  = confluent_environment.bytetoeat.display_name
    "sql.current-database" = confluent_kafka_cluster.standard.display_name
  }
  rest_endpoint = data.confluent_flink_region.flink-region.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-flink-api-key.id
    secret = confluent_api_key.app-manager-flink-api-key.secret
  }
  depends_on = [
    confluent_kafka_topic.enriched_orders,
    confluent_schema.enriched-orders-value
  ]

}

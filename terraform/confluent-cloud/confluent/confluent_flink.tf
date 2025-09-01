# Flink Base Resources
# * compute pool
# * two statements:
#   * enrich_orders
#   * alter_watermark

locals {
  enriched_table_name = "enriched_orders"
}

data "confluent_flink_region" "flink_region" {
  cloud  = var.cloud
  region = var.region
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
    "sql.state-ttl"        = "86400000" # 1 day in milliseconds
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

# statements_runner Service Account: Used to run Flink statements

# Environment Admin Role

# TODO: See if we actually need these roles (EnvironmentAdmin may be sufficient)
# DeveloperRead on raw.recipes topic
# DeveloperRead on raw.orders topic
# DeveloperWrite on enriched_orders topic

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

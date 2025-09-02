# Confluent Cloud Topics
# * 6 topics:
#   * raw.recipes
#   * raw.recipes.dlq
#   * raw.orders
#   * raw.orders.dlq
#   * enriched_orders
#   * dev.orders

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

resource "confluent_kafka_topic" "dev_orders" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  topic_name    = "dev.orders"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_api_key.id
    secret = confluent_api_key.app_manager_kafka_api_key.secret
  }
}

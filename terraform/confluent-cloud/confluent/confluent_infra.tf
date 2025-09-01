# Core Confluent Cloud infrastructure
# * environment: byte-to-eat-XYZ
# * advanced stream governance enabled
# * standard kafka cluster (in relevant cloud and region)

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

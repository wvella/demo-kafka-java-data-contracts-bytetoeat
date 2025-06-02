resource "confluent_schema" "raw_recipes-value" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.advanced.id
  }
  rest_endpoint      = data.confluent_schema_registry_cluster.advanced.rest_endpoint
  subject_name       = "raw.recipes-value"
  format             = "AVRO"
  schema             = file("../../../byte-to-eat-v1/src/main/resources/avro/schema-raw.recipe-value.avsc")
  recreate_on_update = false
  hard_delete        = true

  // additional metadata
  metadata {
    properties = {
      "owner" : "Gordon Ramsay",
      "email" : "gordon.ramsay@bytetoeat.com",
      "application.major.version" : "1"
    }
  }

  // additional rules:
  ruleset {
    // START Data Quality Rules
    domain_rules {
      name       = "require_more_than_one_ingredient"
      doc        = "Check the ingredients list has more than 1 ingredient"
      kind       = "CONDITION"
      type       = "CEL"
      mode       = "WRITE" // validated during write
      expr       = "size(message.ingredients) > 1"
      on_failure = "DLQ"
      on_success = "NONE"
      params = {
        "dlq.topic" : "raw.recipes.dlq"
      }
    }
    // END Data Quality Rules
    // START Data Transformation Rules
    domain_rules {
      name = "transform_recipe_name_to_valid_recipe_id"
      doc  = "Transform the name of a recipe to a valid id"
      kind = "TRANSFORM"
      type = "CEL_FIELD"
      mode = "WRITE" // validated during write
      // Lowercases everything, Removes extra spaces, Joins words with hyphens, Adds the id-recipe- prefix
      expr       = "name == 'recipe_id' ; 'id-recipe-' + value.lowerAscii().split(' ').filter(w, w != '').join('-')"
      on_failure = "DLQ"
      on_success = "NONE"
      params = {
        "dlq.topic" : "raw.recipes.dlq"
      }
    }
    // END Data Transformation Rules
  }

  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }

  // This shouldn't be required, but TF doesn't fully respect the dependency graph for Role Bindings and Tags
  depends_on = [
    confluent_role_binding.env-manager-kafka-cluster-admin
  ]

}

resource "confluent_schema" "raw_orders-value" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.advanced.id
  }
  rest_endpoint      = data.confluent_schema_registry_cluster.advanced.rest_endpoint
  subject_name       = "raw.orders-value"
  format             = "AVRO"
  schema             = file("../../../byte-to-eat-v1/src/main/resources/avro/schema-raw.order-value.avsc")
  recreate_on_update = false
  hard_delete        = true

  // additional metadata
  metadata {
    properties = {
      "owner" : "Gordon Ramsay",
      "email" : "gordon.ramsay@bytetoeat.com",
      "application.major.version" : "1"
    }
  }
  // additional rules:
  ruleset {
    // START Data Transformation Rules
    domain_rules {
      name = "transform_recipe_name_to_valid_recipe_id"
      doc  = "Transform the name of a recipe to a valid id"
      kind = "TRANSFORM"
      type = "CEL_FIELD"
      mode = "WRITE" // validated during write
      // Lowercases everything, Removes extra spaces, Joins words with hyphens, Adds the id-recipe- prefix
      expr       = "name == 'recipe_id' ; 'id-recipe-' + value.lowerAscii().split(' ').filter(w, w != '').join('-')"
      on_failure = "DLQ"
      on_success = "NONE"
      params = {
        "dlq.topic" : "raw.recipes.dlq"
      }
    }
    // END Data Transformation Rules
    // START Data Encryption Rules
    domain_rules {
      name   = "encrypt_pii"
      doc    = "Encrypt all fields which are tagged with PII"
      kind   = "TRANSFORM"
      type   = "ENCRYPT"
      mode   = "WRITEREAD"
      tags   = [confluent_tag.pii.name]
      params = {
        "encrypt.kek.name" = confluent_schema_registry_kek.cc-kek-shared.name
      }
      on_failure = "ERROR,NONE"
    }
    // END Data Encryption Rules
  }
  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }

  // This shouldn't be required, but TF doesn't fully respect the dependency graph for Role Bindings and Tags
  depends_on = [
    confluent_role_binding.env-manager-kafka-cluster-admin
  ]

}

resource "confluent_tag" "pii" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.advanced.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.advanced.rest_endpoint
  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }

  name        = "PII"
  description = "PII tag"

}

resource "confluent_schema" "enriched-orders-value" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.advanced.id
  }
  rest_endpoint      = data.confluent_schema_registry_cluster.advanced.rest_endpoint
  subject_name       = "enriched_orders-value"
  format             = "AVRO"
  schema             = file("../../../byte-to-eat-v1/src/main/resources/avro/schema-enriched_orders-value.avsc")
  recreate_on_update = false
  hard_delete        = true

  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }

  // This shouldn't be required, but TF doesn't fully respect the dependency graph for Role Bindings and Tags
  depends_on = [
    confluent_role_binding.env-manager-kafka-cluster-admin
  ]

}

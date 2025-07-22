# 🍝 Byte to Eat: A Streaming Kitchen Data Contracts Demo

Welcome to **Byte to Eat**, the tastiest way to explore **Data Contracts** in action!
This demo simulates a restaurant kitchen running on **Confluent Cloud**, showcasing how **data contracts** work to manage recipe and order events.

## 👨‍🍳 What’s on the Menu?

This project demonstrates **4 key capabilities of Data Contracts**:

1. **Data Quality Rules** – Ensuring only valid recipes and orders get into the kitchen.
2. **Data Transformation Rules** – Ensuring data is in the right format before cooking.
3. **Schema Migration Rules** – Evolving schemas while ensuring no recipe goes bad.
4. **Data Encryption Rules** – Keeping pii information safe.

### 🍲 How It Works

- **Recipe Producer**: Sends recipe details, including ingredients, steps, and chef info to the Kafka topic in Confluent Cloud.
- **Order Producer**: Simulates customer orders referencing recipes by their `recipe_id`.
- **Kafka Consumers**: Consume orders and recipes, validating and transforming the data based on Avro schemas.
- **Schema Registry**: Ensures proper validation and schema management for the recipes and orders.

#### Demo Architecture
![demo-architecture](byte-to-eat-demo-architecture.png)

#### Demo Recording
See the `demo-recording-480p.mp4` file in the directory


### 🔧 Built With

- **Java**: Kafka Producers & Consumers
- **Confluent Cloud**: The data streaming platform
- **Confluent Schema Registry**: Manages Data Contracts
- **Flink**: To join the Recipe and Order events
- **Avro**: Used to define the Schema



### 🚀 Demo Deployment



1. **Clone the Repo**

2. **Setup Variables for Terraform**
   1. Create a `terraform.tfvars` in the `terraform/confluent-cloud/cloud` directory with the following contents:

      ``` env
      confluent_cloud_api_key = "<<confluent_cloud_api_key_for_terraform>>"
      confluent_cloud_api_secret = "<<confluent_cloud_api_secret_for_terraform>>"
      ```

      Note: For **AWS**, you need to set the following environment variables:
      ``` env
      export AWS_ACCESS_KEY_ID="anaccesskey"
      export AWS_SECRET_ACCESS_KEY="asecretkey"
      ```

       Note: For **Azure**, you need to first login via the Azure CLI:
      ``` env
      az login
      ```


3. **Deploy the Demo**
   1. `cd terraform/confluent-cloud/main`
   2. Run `./1-demo-deploy.sh [cloud] [region]`. This script will deploy all the resources in Confluent Cloud and produce a Spaghetti Bolognese recipe to the topic. 🍝 Yum!
4. **Demo Cleanup**
   1. Run `./demo-destroy.sh [cloud] [region]`.

### Optional Demo Flow Steps
   1. **PrePreparation**
      1. Open VSCode
      2. Ensure Docker is running
      3. Open `ProducerAvroRecipes.java`
      4. Open `data-governance.tf`
      5. Log into Confluent Cloud
      6. Open `schema-raw.recipe-value-v2.avsc`
      7. Open 4 Terminal Windows and `cd demo-kafka-java-data-contracts-bytetoeat`:
         1. Window 1: V1 Producer (White Background)
         2. Window 2: V2 Producer (Black Background)
         3. Window 3: V1 Consumer (White Background)
         4. Window 4: V2 Consumer (Black Background)
   2. **Data Quality Rules**
      1. Show `require_more_than_one_ingredient` rule definition in Terraform `data-governance.tf` / Confluent Cloud UI.
      2. Demonstrate by trying to produce a recipe that violates the rule by running:
         1. `CD
         2. Set `LIST_ALL_INGREDIENTS=false` in `byte-to-eat-v1-docker-producer-recipes/docker-compose.yml`.
         3. `make up SERVICE=byte-to-eat-v1-docker-producer-recipes` in the `terraform/confluent-cloud/main` directory.
      3. Show the bad message ending up in the `raw.recipes.dlq` topic.
      4. Set `LIST_ALL_INGREDIENTS=true` in `byte-to-eat-v1-docker-consumer-recipes/docker-compose.yml`.
   3. **Data Transformation Rules**
      1. Show `transform_recipe_name_to_valid_recipe_id` rule definition in Terraform `data-governance.tf` / Confluent Cloud UI.
      2. Show the recipe id in the Java Code `ProducerAvroRecipes.java` in the `byte-to-eat-v1-docker-producer-recipes` directory.
      3. Show how the recipe ID is transformed when it's written to the `raw.recipe` topic via the Data Transformation rule.
   4. **Data Encryption Rules**
      1. Key Shared with Confluent
          1. Show the `Orders` Data Contract in the Confluent Cloud UI. Orders have some PII tags.
          2. Show the `ProducerAvroRecipes.java` application. There is no Code to do the encryption, it just imports the `kafka-schema-rules` dependency.
          3. Show `encrypt_pii` rule definition in the Confluent Cloud UI.
          4. Show the Key Encryption Keys definition under `Stream Governance` -> `Schema Registry` -> `Encryption Keys`.
          5. Show the `raw.orders` topic to see the `customer_address` and `pii` field encrypted.
          6. In the Confluent Cloud UI, add another `pii` tag to `customer_name` show the schema is instant. No code changes.
          7. Show the `raw.orders` Topic in the Confluent Cloud UI to show the `customer_name` field is now encrypted.
          8. **Bonus:** The consumer can only decrypt the field because it has access to the Key Encryption Key. Remove the access via the Confluent Cloud UI and the field won't be decrypted.
          9. **Bonus:** Flink is joining the `Orders` and `Recipes` together, and the encrypted field will be carried through.
      2. Key Not Shared with Confluent
         1. Same as *Key Shared with Confluent* above, except you need credentials configured in the applications in order to access the KMS.
   5. **Schema Migration Rules**
      1. In the Confluent Cloud UI, show the current version of the `raw.recipe-value` Data Contract which has `application.major.version` set to 1.
      2. Show `schema-raw.recipe-value-v2.avsc` which now has the `chef_first_name` and `chef_last_name` as seperate fields. This would be a breaking change.
      3. Run `helper-scripts/register-migration-rules.sh` to register the new Data Contract and Migration Rules. Show `migration_rules.json`.
      4. Start the V2 producer `make up SERVICE=byte-to-eat-v2-docker-producer-recipes`
      5. Start the V2 consumer `make up SERVICE=byte-to-eat-v2-docker-consumer-recipes`
      6. Show the new `raw.recipe-value` Data Contract in the Confluent Cloud UI. `application.major.version` is now set to 2.
      7. Show the `split_chef_first_and_last_name` and `join_chef_first_and_last_name` migration rules in the Confluent Cloud UI.
      8. Start up the V1 producer in Window 1 `make logs SERVICE=byte-to-eat-v1-docker-producer-recipes`.
      9. Start up the V1 consumer is Window 2 `make logs SERVICE=byte-to-eat-v1-docker-consumer-recipes`. Observer the V1 and V2 consumer view of the data.
      10. Start up the V2 producer in Window 3 `make logs SERVICE=byte-to-eat-v2-docker-producer-recipes`.
      11. Start up the V2 consumer is Window 4 `make logs SERVICE=byte-to-eat-v2-docker-consumer-recipes`. Observer the V1 and V2 consumer view of the data.


### General Notes

- To generate the effective POM: `mvn help:effective-pom -Doutput=effective-pom.xml`
- To generate the Java Class from an AVRO Schema: `mvn generate-sources`

## 🛠️ Requirements & Prerequisites

Before running this demo, make sure you have the following installed and configured:

### 🐳 Docker & Docker Compose
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (includes Docker Compose)
- Ensure Docker is running

### ☕ Java & Maven
- Java 11 or later (Java 17+ recommended)
- [Maven](https://maven.apache.org/) for building Java projects

### 🌍 Terraform
- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) (v1.0+ recommended)

### 🧰 jq
- [jq](https://stedolan.github.io/jq/) for JSON manipulation in shell scripts

### 🛠️ GNU Make
- [Make](https://www.gnu.org/software/make/) for running Makefile targets

### ☁️ Cloud Provider Account
- **AWS**, **Azure**, or **GCP** (Coming Soon!) account (choose only one)
- Credentials and access configured for Terraform
- Cloud CLI (if deploying into Azure)

---

> 💡 **Tip:**
> Most dependencies can be installed via [Homebrew](https://brew.sh/) on macOS:
> ```
> brew install --cask docker
> brew install openjdk maven terraform jq make
> ```

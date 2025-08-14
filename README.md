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

#### Managed Confluent Cloud Components:

- **Kafka Cluster**: Confluent Cloud cluster, through which all data flows.
- **Schema Registry**: Ensures proper validation and schema management for the recipes and orders, and stores various rules.
- **Flink**: Consumes `raw.orders` and enriches them with the latest recipe from `raw.recipes`, and produces the result to `enriched_orders` topic.

#### Client Applications (run as local Docker containers):

- **Order Producer**: Simulates customer orders referencing recipes by their `recipe_id`, produces to `raw.orders`.
- **Order Consumer**: Consumes orders from `raw.orders`
- **Recipe Producer**: Sends a single recipe, including ingredients, steps, and chef info to the Kafka topic `raw.recipes` in Confluent Cloud, then terminates.
- **Recipe Consumer**: Consume recipes from `raw.recipes`

#### Demo Overview

Prior to running the demo, set up the infrastructure for the demo and start these client applications (and Flink job, etc.):
   * Order Producer
   * Order Consumer
   * Recipe Producer (v1)
   * Recipe Consumer (v1)

The demo follows these high-level steps:

1. **Explanation**: Provide an overview of data flow through the provisioned infrastructure
1. **Data Quality Rule (`raw.recipes`)**: Show how a data quality rule can prevent semantically incorrect data from landing in Kafka topic.
   
   The `raw.recipes` topic has a rule that must include multiple ingredients; invalid recipes will end up in a dead letter queue (`raw.recipes.dlq`)
1. **Data Transformation Rule (`raw.recipes`)**:  Show how a data transformation rule can modify data before it lands in a Kafka topic.
   
   Both the `raw.orders` and `raw.recipes` topics have a data transformation rule that does three things to the `recipe_id` field:
      * Replace spaces with dashes
      * Converts to lower case
      * Prefixes the recipe with `id-recipe`
1. **Data Encryption Rule (`raw.orders` and `raw.recipes`)**: Shows how Client-Side Field Level Encryption (CSFLE) can be used to encrypt fields tagged with specific properties
   * The `raw.orders` topic has a rule that encrypts the fields tagged as `PII`
   * Each order initially has two fields tagged as `PII`: `customer_address` and `ccn` (Credit Card Number)
   * In the demo, we add a `PII` tag to an existing field (`customer_name`) and show how new messages are automatically encrypted.
1. **Schema Migration Rules (`raw.recipes`)**: Shows how a rule can handle breaking schema changes
   * In Version 1 of the Recipes producer and consumer, we have field `chef_name`; this field is split into `chef_first_name` and `chef_last_name` in Version 2 of the applications.
   * v1 and v2 of both the Recipe Producer and Recipe Consumer are able to handle both versions of the data, where the schema migration rule automatically updates the field on the fly.

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

## 🚀 Demo Deployment

1. **Clone the Repo**

   ```bash
   git clone https://github.com/wvella/demo-kafka-java-data-contracts-bytetoeat.git
   ```

1. **Set up credentials for Terraform**
   1. (Optional) Create a `local` directory in the repo root directory, and create a `terraform.tfvars` in the `./local` directory with the following contents:

      ```shell
      mkdir -p local
      ```

      ```shell
      # ./local/terraform.tfvars
      confluent_cloud_api_key = "<<confluent_cloud_api_key_for_terraform>>"
      confluent_cloud_api_secret = "<<confluent_cloud_api_secret_for_terraform>>"
      ```

      _If you don't specify Confluent Cloud credentials, you'll be prompted for them during the deployment process_

   1. Set up cloud-provider specific credentials
      
      **AWS**: Set the following environment variables:

         ```shell
         export AWS_ACCESS_KEY_ID="anaccesskey"
         export AWS_SECRET_ACCESS_KEY="asecretkey"
         # If using ephemeral credentials, also need a token
         export AWS_SESSION_TOKEN="xyz"
         ```

      **Azure**: Login via the Azure CLI, and follow the prompts to authenticate to Azure.

         ```shell
         az login
         ```

      **GCP**: Login via the GCP CLI, and follow the prompts to authenticate to GCP.

         ```shell
         gcloud auth application-default login
         ```

      _GCP also requires a project-id, provided on the command-line (see below)._

1. **Deploy the Demo**

   From the main directory, run the deployment script. This script will deploy all the resources in Confluent Cloud and produce a Spaghetti Bolognese recipe to the topic. 🍝 Yum!
   
   **AWS** or **Azure**
      
   ```shell
   ./1-demo-deploy.sh [cloud] [region]
   ```

   **GCP** (provide a project ID)
   
   ```shell
   ./1-demo-deploy.sh [cloud] [region] [gcp-project-id]
   ```

1. **Run the Demo!**

   See instructions below, in [Demo Walkthrough](#demo-walkthrough)

1. **Demo Cleanup**

   #### **AWS** or **Azure**
      
   ```shell
   ./demo-destroy.sh [cloud] [region]
   ```

   #### **GCP** (provide a project ID)

   ```shell
   ./demo-destroy.sh [cloud] [region] [gcp-project-id]
   ```

## Demo Walkthrough

1. **Demo Preparation**
   1. Open a browser tab to Confluent Cloud (and log in)

   1. In a terminal, ensure Docker is running

   1. _(Optional)_ Open VS Code in the root of the cloned git repo (these commands can be run in the VS Code built-in terminal)

      1. Open `ProducerAvroRecipes.java`

         ```shell
         code ./byte-to-eat-v1-docker-producer-recipes/src/main/java/io/confluent/wvella/demo/datacontractsv1/ProducerAvroRecipes.java
         ```

      1. Open `data-governance.tf`

         ```shell
         code ./terraform/confluent-cloud/cloud/data-governance.tf
         ```

      1. Open `schema-raw.recipe-value-v1.avsc` and `schema-raw.recipe-value-v2.avsc` (in `byte-to-eat-v2-docker-consumer-recipes/src/main/resources/avro/`)

         ```shell
         code ./byte-to-eat-v1-docker-producer-recipes/src/main/resources/avro/schema-raw.recipe-value.avsc
         code ./byte-to-eat-v2-docker-producer-recipes/src/main/resources/avro/schema-raw.recipe-value-v2.avsc
         ```


   1. Open 4 Terminal Windows to compare the v1 and v2 versions of the Recipe Producer/Consumer:
      1. Window 1: V1 Producer (White Background)
      1. Window 2: V2 Producer (Black Background)
      1. Window 3: V1 Consumer (White Background)
      1. Window 4: V2 Consumer (Black Background)

1. **Data Quality Rules**

   1. In the Confluent Cloud UI, navigate to the `raw.recipes` topic and display the Data Contract rule `require_more_than_one_ingredient` 
   
      _Alternately, navigate to "Stream Governance" > "Total data contracts" > "raw.recipes-value" > "Rules"_

   1. Reconfigure the recipe producer to send an invalid message
      
      1. Edit `./byte-to-eat-v1-docker-producer-recipes/docker-compose.yml` with:


         ```yaml
               - LIST_ALL_INGREDIENTS=false
         ```

         _If using the CLI, this file can be access directly via the symlink `recipe-configuration.yaml`. For example, open this file in **vim** with `vi recipe-configuration.yaml`_

      1. Restart the (v1) recipe producer

         ```bash
         ./helper-scripts/start-recipe-producer.sh
         ```

   1. Look at the logs for the new producer with this:

      ```bash
      docker logs producer-reipes
      ```

   1. In the Confluent Cloud UI, show the invalid message ending up in the `raw.recipes.dlq` topic.
   
   1. Undo the change to `recipe-configuration.yaml` (`./byte-to-eat-v1-docker-producer-recipes/docker-compose.yml`), and re-deploy:

         ```shell
         ./helper-scripts/start-recipe-producer.sh
         ```

1. **Data Transformation Rules**
   1. In the Confluent Cloud UI, navigate to the `raw.recipes` topic and display the Data Contract rule `transform_recipe_name_to_valid_recipe_id` 
   
      _Alternately, navigate to "Stream Governance" > "Total data contracts" > "raw.recipes-value" > "Rules"_

   1. Look at the unmodified recipe being produced by running this command:

      ```bash
      docker logs producer-recipes
      ```

   1. Show how the recipe ID is transformed when it's written to the `raw.recipe` topic via the Data Transformation rule.

   1. Alternately, look at the recipe (`recipe_id` field) in the recipe consumer application:

      ```bash
      docker logs consumer-recipes
      ```

1. **Data Encryption Rules**
   1. Key Shared with Confluent
         1. Show the `raw.orders` Data Contract in the Confluent Cloud UI. Orders have some PII tags.
         1. Show the `ProducerAvroRecipes.java` application. There are no code changes required to enable encryption; just import the relevant packages following the Confluent documentation.
         1. Show `encrypt_pii` rule definition in the Confluent Cloud UI.
         1. Show the Key Encryption Keys definition under `Stream Governance` -> `Schema Registry` -> `Encryption Keys`.
         1. Show the `raw.orders` topic to see the `customer_address` and `pii` field encrypted.
         1. In the Confluent Cloud UI, add another `pii` tag to `customer_name` show the schema is instant. No code changes.
         1. Show the `raw.orders` Topic in the Confluent Cloud UI to show the `customer_name` field is now encrypted.
         1. **Bonus:** The consumer can only decrypt the field because it has access to the Key Encryption Key. Remove the access via the Confluent Cloud UI and the field won't be decrypted.
         1. **Bonus:** Flink is joining the `Orders` and `Recipes` together, and the encrypted field will be carried through.
   1. _(Optional)_ Key Not Shared with Confluent
      1. Same as *Key Shared with Confluent* above, except you need credentials configured in the applications in order to access the KMS.

1. **Schema Migration Rules**

   1. In the Confluent Cloud UI, show the current version of the `raw.recipe-value` Data Contract which has `application.major.version` set to 1.

   1. Compare v1 and v2 of the recipe schema (`schema-raw.recipe-value.avsc` and `schema-raw.recipe-value-v2.avsc`)

      * In version 1, see the field `chef_name`
      * In version 2, see the fields `chef_first_name` and `chef_last_name`
      * This would normally be considered a breaking change.

   1. Run `helper-scripts/register-migration-rules.sh` to register the new Data Contract and Migration Rules. Show `migration_rules.json`.

      ```shell
      ./helper-scripts/register-migration-rules.sh
      ```

   1. Start the V2 version of the recipe applications

      ```shell
      ./helper-scripts/start-recipe-v2.sh
      ```

   1. Show the new `raw.recipe-value` Data Contract in the Confluent Cloud UI. Notice that `application.major.version` is now set to 2.

   1. Show the `split_chef_first_and_last_name` and `join_chef_first_and_last_name` migration rules in the Confluent Cloud UI.

   1. Look at logs for the four recipe applications:

      1. View logs for the V1 producer in Window 1:

         ```shell
         docker logs producer-recipes
         ```

      1. View logs for the V1 consumer is Window 2.

         ```shell
         docker logs consumer-recipes
         ```

      1. View logs for the V2 producer in Window 3

         ```shell
         docker logs producer-recipes-v2
         ```

      1. View logs for the V2 consumer is Window 4

         ```shell
         docker logs consumer-recipes-v2
         ```

      1. Compare the output data for the different versions of the application

1. Once the demo is complete, clean up your resources following the instructions in [Demo Cleanup](#demo-cleanup)

## Demo Cleanup

   #### **AWS** or **Azure**
      
   ```shell
   ./demo-destroy.sh [cloud] [region]
   ```

   #### **GCP** (provide a project ID)

   ```shell
   ./demo-destroy.sh [cloud] [region] [gcp-project-id]
   ```

## General Notes

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
- **AWS**, **Azure**, or **GCP** account (choose only one)
- Credentials and access configured for Terraform
- Cloud CLI (if deploying into Azure or GCP)

---

> 💡 **Tip:**
> Most dependencies can be installed via [Homebrew](https://brew.sh/) on macOS:
> ```
> brew install --cask docker
> brew install openjdk maven terraform jq make
> ```

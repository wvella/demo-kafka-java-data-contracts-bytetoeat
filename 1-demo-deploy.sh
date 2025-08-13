#!/usr/bin/env bash

# Is run from root directory
BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Variables
TERRAFORM_BASE_DIR="${BASE_DIR}/terraform/confluent-cloud" # Update this to the directory containing your Terraform configuration
TERRAFORM_WORKING_DIR="${BASE_DIR}/local"
HELPER_SCRIPTS_DIR="${BASE_DIR}/helper-scripts"

echo $HELPER_SCRIPTS_DIR

CLOUD="$1"
REGION="$2"
GCP_PROJECT_ID="$3"

if [[ "$CLOUD" != "aws" && "$CLOUD" != "azure" && "$CLOUD" != "gcp" ]]; then
  echo "Usage: $0 [aws|azure|gcp] <region> [<gcp-project-id>]"
  exit 1
fi

if [[ -z "$REGION" ]]; then
  echo "Usage: $0 [aws|azure|gcp] <region> [<gcp-project-id>]"
  echo "Error: Region must be specified as the second argument."
  exit 1
fi

# GCP also requires a project-id.
if [[ -z "$GCP_PROJECT_ID" && "$CLOUD" = "gcp" ]]; then
  echo "Usage: $0 [gcp] <region> <gcp-project-id>"
  echo "Error: GCP project-id must be specified as the third argument."
  exit 1
fi

mkdir -p ${TERRAFORM_WORKING_DIR}/avro

cp -rvp ${TERRAFORM_BASE_DIR}/confluent/* ${TERRAFORM_WORKING_DIR}
cp -rvp ${TERRAFORM_BASE_DIR}/${CLOUD}/* ${TERRAFORM_WORKING_DIR}
cp -rvp ${BASE_DIR}/byte-to-eat-v1-docker-producer-recipes/src/main/resources/avro/schema-raw.recipe-value.avsc ${TERRAFORM_WORKING_DIR}/avro/schema-raw.recipe-value.avsc
cp -rvp ${BASE_DIR}/byte-to-eat-v1-docker-producer-orders/src/main/resources/avro/schema-raw.order-value.avsc ${TERRAFORM_WORKING_DIR}/avro/schema-raw.order-value.avsc
cp -rvp ${BASE_DIR}/byte-to-eat-v1-docker-producer-orders/src/main/resources/avro/schema-enriched_orders-value.avsc ${TERRAFORM_WORKING_DIR}/avro/schema-enriched_orders-value.avsc


# Initialize Terraform
echo "Initializing Terraform..."
terraform -chdir="${TERRAFORM_WORKING_DIR}" init


if [ $? -ne 0 ]; then
  echo "Error: Terraform initialization failed."
  exit 1
fi

# Build var-file arguments
VAR_FILES=()

# terraform.auto.tfvars is always loaded
if [ -f "${TERRAFORM_WORKING_DIR}/terraform.tfvars" ]; then
  VAR_FILES+=("-var-file=terraform.tfvars")
  echo "Using variable file: terraform.tfvars"
fi

cd ${TERRAFORM_WORKING_DIR}

# Only one cloud can be selected; run cloud-specific prerequisites if needed
if [[ "$CLOUD" == "azure" ]]; then
  echo "🔵 Azure selected: running create-azure-apps.sh for region $REGION..."
  ${HELPER_SCRIPTS_DIR}/create-azure-apps.sh "$REGION"
  if [ $? -ne 0 ]; then
    echo "Error: create-azure-apps.sh failed."
    exit 1
  fi
elif [[ "$CLOUD" == "aws" ]]; then
  echo "🟢 AWS selected: running create-aws-apps.sh for region $REGION..."
  ${HELPER_SCRIPTS_DIR}/create-aws-apps.sh "$REGION"
  if [ $? -ne 0 ]; then
    echo "Error: create-aws-apps.sh failed."
    exit 1
  fi
elif [[ "$CLOUD" == "gcp" ]]; then
  echo "🟡 GCP selected: running /create-gcp-apps.sh for region $REGION & project $GCP_PROJECT_ID..."
  ${HELPER_SCRIPTS_DIR}/create-gcp-apps.sh "$REGION" "$GCP_PROJECT_ID"
  if [ $? -ne 0 ]; then
    echo "Error: create-gcp-apps.sh failed."
    exit 1
  fi
fi

# Run terraform apply
echo "Running terraform apply..."
terraform -chdir="${TERRAFORM_WORKING_DIR}" apply "${VAR_FILES[@]}" -auto-approve
if [ $? -ne 0 ]; then
  echo "Error: Terraform apply failed."
  exit 1
fi

echo "Terraform apply completed successfully."


# Run microservices
echo "Running microservices ..."

# Makefile is in the root directory
cd ${BASE_DIR}

RECIPE_SCRIPT="${BASE_DIR}/0-run.sh"

if [ -f "$RECIPE_SCRIPT" ]; then
  "$RECIPE_SCRIPT"
else
  echo "Error: $RECIPE_SCRIPT not found."
  exit 1
fi

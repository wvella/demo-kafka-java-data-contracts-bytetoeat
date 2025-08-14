#!/bin/bash

# TODO: pick up cloud and region from local directory

# Is run from root directory
BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Variables
TERRAFORM_WORKING_DIR="${BASE_DIR}/local"
DELETE_SUBJECT_SCRIPT="${BASE_DIR}/helper-scripts/delete-subject.sh" # Path to the delete-subject.sh script
DELETE_AZURE_SCRIPT="${BASE_DIR}/helper-scripts/delete-azure-apps.sh" # Path to the delete-azure-apps.sh script
DOWN_SCRIPT="${BASE_DIR}/0-down.sh"
CLOUD="${1}"
REGION="${2}"
GCP_PROJECT_ID="${3}"

# If cloud is not set, check if it is in the terraform working directory
if [[ "$CLOUD" != "aws" && "$CLOUD" != "azure" && "$CLOUD" != "gcp" ]]; then
  if [[ -f "${TERRAFORM_WORKING_DIR}/cloud" ]]; then
    CLOUD=$(cat "${TERRAFORM_WORKING_DIR}/cloud")
  else
    echo "Usage: $0 [aws|azure|gcp] <region> [<gcp-project-id>]"
    exit 1
  fi
fi

# If region is not set, check if it is in the terraform working directory
if [[ -z "${REGION}" ]] && [[ -f "${TERRAFORM_WORKING_DIR}/region" ]]; then
  REGION=$(cat "${TERRAFORM_WORKING_DIR}/region")
fi

# If GCP project id is not set, check if it is in the terraform working directory
if [[ -z "${GCP_PROJECT_ID}" ]] && [[ -f "${TERRAFORM_WORKING_DIR}/gcp_project_id" ]]; then
  GCP_PROJECT_ID=$(cat "${TERRAFORM_WORKING_DIR}/gcp_project_id")
fi

TFVARS_FILE="${TERRAFORM_WORKING_DIR}/$CLOUD-terraform-secret.auto.tfvars"

if [[ -z "${REGION}" ]]; then
  echo "Usage: $0 [aws|azure|gcp] <region> [<gcp-project-id>]"
  echo "Error: Region must be specified as the second argument."
  exit 1
fi

# GCP also requires a project-id.
if [[ -z "${GCP_PROJECT_ID}" && "${CLOUD}" = "gcp" ]]; then
  echo "Usage: $0 [gcp] <region> <gcp-project-id>"
  echo "Error: GCP project-id must be specified as the third argument."
  exit 1
fi


# Extract unique_id from the tfvars file
if [[ ! -f "${TFVARS_FILE}" ]]; then
  echo "❌ ${TFVARS_FILE} not found."
  exit 1
fi

UNIQUE_ID=$(grep '^unique_id' "${TFVARS_FILE}" | sed 's/.*= *"\(.*\)"/\1/')

if [[ -z "${UNIQUE_ID}" ]]; then
  echo "❌ unique_id not found in ${TFVARS_FILE}."
  exit 1
fi

# Stopping microservices
echo "Stopping microservices ..."
if [ -f "${DOWN_SCRIPT}" ]; then
  bash "${DOWN_SCRIPT}"
else
  echo "Error: ${DOWN_SCRIPT} not found."
  exit 1
fi


# Call delete-subject.sh to delete the subject
if [ -f "${DELETE_SUBJECT_SCRIPT}" ]; then
  echo "Running delete-subject.sh to delete the subject..."
  bash "${DELETE_SUBJECT_SCRIPT}"
  if [ $? -ne 0 ]; then
    echo "Error: delete-subject.sh failed. Aborting Terraform destroy."
    exit 1
  fi
else
  echo "Error: delete-subject.sh not found at ${DELETE_SUBJECT_SCRIPT}. Aborting."
  exit 1
fi

# Wait for 2 minutes to ensure the subject is deleted before proceeding
echo "Waiting for 2 minutes to ensure the subject is deleted..."
#sleep 120

# Run terraform destroy
echo "Running terraform destroy..."
terraform -chdir="${TERRAFORM_WORKING_DIR}" destroy -auto-approve
if [ $? -ne 0 ]; then
  echo "Error: Terraform destroy failed."
  exit 1
fi

echo "Terraform destroy completed successfully."

# Cleanup Terraform state files
cd "${TERRAFORM_WORKING_DIR}"
echo "Cleaning up Terraform state files..."
rm -f terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl
rm -rf .terraform/

# Cleanup Terraform files
echo "Cleaning up command and cloud-specific Terraform files..."
rm -f *.tf *.tfvars

# Clean up the statements
echo "Cleaning up the statements..."
rm -rf statements

if [[ "$CLOUD" == "azure" ]]; then
  # Call delete-azure-apps.sh to delete the azure resource groups and apps
  if [ -f "$DELETE_AZURE_SCRIPT" ]; then
    echo "Running delete-azure-apps.sh to delete the subject..."
    bash "$DELETE_AZURE_SCRIPT" "$UNIQUE_ID"
    if [ $? -ne 0 ]; then
      echo "Error: delete-azure-apps.sh failed. Aborting Terraform destroy."
      exit 1
    fi
  else
    echo "Error: delete-azure-apps.sh not found at $DELETE_AZURE_SCRIPT. Aborting."
    exit 1
  fi
fi

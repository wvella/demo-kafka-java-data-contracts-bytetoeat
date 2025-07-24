#!/bin/bash
# Variables
TERRAFORM_DIR="." # Update this to the directory containing your Terraform configuration

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

# Remove cloud-specific files from the current directory (not subdirectories)
find ../tf-working/ -maxdepth 1 -type f \( -name "*aws*" -o -name "*azure*" -o -name "*gcp*" \) ! -name "$CLOUD-terraform-secret.auto.tfvars" -exec rm -f {} +

# Copy common files (files that do NOT contain any cloud name)
for f in ../cloud/*; do
  if [[ -f "$f" && "$f" != *aws* && "$f" != *azure* && "$f" != *gcp* ]]; then
    cp "$f" ../tf-working/
  fi
done

# Copy Flink statement files
cp -r ../cloud/statements ../tf-working/

# Copy selected cloud's files into the current directory
for f in ../cloud/*$CLOUD*; do
  if [[ -f "$f" ]]; then
    cp "$f" ../tf-working/
  fi
done
mv "../tf-working/$CLOUD-outputs.tf" "../tf-working/outputs.tf"
echo "Applying Terraform to $CLOUD."
cd ../tf-working || { echo "Error: Could not change to tf-working directory."; exit 1; }

# Initialize Terraform
echo "Initializing Terraform..."
terraform -chdir="$TERRAFORM_DIR" init
if [ $? -ne 0 ]; then
  echo "Error: Terraform initialization failed."
  exit 1
fi

# Build var-file arguments
VAR_FILES=()

# terraform.auto.tfvars is always loaded
if [ -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
  VAR_FILES+=("-var-file=terraform.tfvars")
  echo "Using variable file: terraform.tfvars"
fi

# Only one cloud can be selected; run cloud-specific prerequisites if needed
if [[ "$CLOUD" == "azure" ]]; then
  echo "🔵 Azure selected: running create-azure-apps.sh for region $REGION..."
  ../main/helper-scripts/create-azure-apps.sh "$REGION"
  if [ $? -ne 0 ]; then
    echo "Error: create-azure-apps.sh failed."
    exit 1
  fi
elif [[ "$CLOUD" == "aws" ]]; then
  echo "🟢 AWS selected: running create-aws-apps.sh for region $REGION..."
  ../main/helper-scripts/create-aws-apps.sh "$REGION"
  if [ $? -ne 0 ]; then
    echo "Error: create-aws-apps.sh failed."
    exit 1
  fi
elif [[ "$CLOUD" == "gcp" ]]; then
  echo "🟡 GCP selected: running /create-gcp-apps.sh for region $REGION & project $GCP_PROJECT_ID..."
  ../main/helper-scripts/create-gcp-apps.sh "$REGION" "$GCP_PROJECT_ID"
fi

# Run terraform apply
echo "Running terraform apply..."
terraform -chdir="$TERRAFORM_DIR" apply "${VAR_FILES[@]}" -auto-approve
if [ $? -ne 0 ]; then
  echo "Error: Terraform apply failed."
  exit 1
fi

echo "Terraform apply completed successfully."

# Run microservices
echo "Running microservices ..."
cd ../main
RECIPE_SCRIPT="0-run.sh"

if [ -f "$RECIPE_SCRIPT" ]; then
  ./"$RECIPE_SCRIPT"
else
  echo "Error: $RECIPE_SCRIPT not found."
  exit 1
fi

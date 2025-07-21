#!/bin/bash
# Variables
TERRAFORM_DIR="." # Update this to the directory containing your Terraform configuration

CLOUD="$1"
REGION="$2"

if [[ "$CLOUD" != "aws" && "$CLOUD" != "azure" && "$CLOUD" != "gcp" ]]; then
  echo "Usage: $0 [aws|azure|gcp] <region>"
  exit 1
fi

if [[ -z "$REGION" ]]; then
  echo "Usage: $0 [aws|azure|gcp] <region>"
  echo "Error: Region must be specified as the second argument."
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
# Set up Python virtual environment
if [ -d "my-tf-venv" ]; then
  echo "Virtual environment 'my-tf-venv' already exists."
else
  python3 -m venv my-tf-venv
  if [ -d "my-tf-venv" ]; then
    source my-tf-venv/bin/activate
    pip install -r ../main/helper-scripts/requirements.txt
    echo "Virtual environment 'my-tf-venv' created and 'requests' installed."
  else
    echo "Failed to create virtual environment 'my-tf-venv'."
  fi
fi

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

for cloud in aws azure gcp; do
  if [ -f "$TERRAFORM_DIR/terraform-$cloud.tfvars" ]; then
    VAR_FILES+=("-var-file=terraform-$cloud.tfvars")
    echo "Using variable file: terraform-$cloud.tfvars"
    break
  fi
done

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
  echo "🟡 GCP selected: (placeholder) run your GCP prerequisites script here..."
  # ./create-gcp-resources.sh
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

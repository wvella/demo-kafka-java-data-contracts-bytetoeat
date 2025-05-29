#!/bin/bash
# Variables
TERRAFORM_DIR="." # Update this to the directory containing your Terraform configuration

# Step 0: Set up Python virtual environment
if [ -d "my-tf-venv" ]; then
  echo "Virtual environment 'my-tf-venv' already exists."
else
  python3 -m venv my-tf-venv
  if [ -d "my-tf-venv" ]; then
    source my-tf-venv/bin/activate
    pip install requests
    echo "Virtual environment 'my-tf-venv' created and 'requests' installed."
  else
    echo "Failed to create virtual environment 'my-tf-venv'."
  fi
fi

# Step 1: Initialize Terraform
echo "Initializing Terraform..."
terraform -chdir="$TERRAFORM_DIR" init
if [ $? -ne 0 ]; then
  echo "Error: Terraform initialization failed."
  exit 1
fi

# Step 2: Build var-file arguments
VAR_FILES=()

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

# Step 3: Run terraform apply
echo "Running terraform apply..."
terraform -chdir="$TERRAFORM_DIR" apply "${VAR_FILES[@]}" -auto-approve
if [ $? -ne 0 ]; then
  echo "Error: Terraform apply failed."
  exit 1
fi

echo "Terraform apply completed successfully."

# Step 4: Create a recipe
echo "Running recipe creation..."
cd ../../byte-to-eat-v1/
RECIPE_SCRIPT="run-producer-recipe.sh"

if [ -f "$RECIPE_SCRIPT" ]; then
  echo "Running run-producer-recipe.sh to create the first recipe..."
  bash "$RECIPE_SCRIPT"
  if [ $? -ne 0 ]; then
    echo "Error: run-producer-recipe.sh failed. Aborting Terraform apply."
    exit 1
  fi
else
  echo "Error: run-producer-recipe.sh not found at $RECIPE_SCRIPT. Aborting."
  exit 1
fi

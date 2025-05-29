#!/bin/bash
# Variables
TERRAFORM_DIR="." # Update this to the directory containing your Terraform configuration
DELETE_SUBJECT_SCRIPT="./delete-subject.sh" # Path to the delete-subject.sh script

CLOUD="$1"
if [[ "$CLOUD" != "aws" && "$CLOUD" != "azure" && "$CLOUD" != "gcp" ]]; then
  echo "Usage: $0 [aws|azure|gcp]"
  exit 1
fi

# Step 1: Call delete-subject.sh to delete the subject
if [ -f "$DELETE_SUBJECT_SCRIPT" ]; then
  echo "Running delete-subject.sh to delete the subject..."
  bash "$DELETE_SUBJECT_SCRIPT"
  if [ $? -ne 0 ]; then
    echo "Error: delete-subject.sh failed. Aborting Terraform destroy."
    exit 1
  fi
else
  echo "Error: delete-subject.sh not found at $DELETE_SUBJECT_SCRIPT. Aborting."
  exit 1
fi

# Wait for 2 minutes to ensure the subject is deleted before proceeding
echo "Waiting for 2 minutes to ensure the subject is deleted..."
sleep 120

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

# Step 3: Run terraform destroy
echo "Running terraform destroy..."
terraform -chdir="$TERRAFORM_DIR" destroy "${VAR_FILES[@]}" -auto-approve
if [ $? -ne 0 ]; then
  echo "Error: Terraform destroy failed."
  exit 1
fi

echo "Terraform destroy completed successfully."

# Step 4: Cleanup Terraform state files
echo "Cleaning up Terraform state files..."
rm -f terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl
rm -rf .terraform/

# Step 5: Cleanup Terraform files
echo "Cleaning up command and cloud-specific Terraform files..."
rm -f *.tf *.tfvars

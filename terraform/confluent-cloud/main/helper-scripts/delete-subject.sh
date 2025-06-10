#!/bin/bash
# Variables
TERRAFORM_DIR="../tf-working"
SR_URL=$(terraform -chdir="$TERRAFORM_DIR" output -raw schema-registry-url)
SR_API_KEY=$(terraform -chdir="$TERRAFORM_DIR" output -raw env-manager-schema-registry-api-key)
SR_API_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw env-manager-schema-registry-api-secret)

# Read the unique-id value from azure-terraform-secret.auto.tfvars
UNIQUE_ID=$(grep '^unique-id' ../tf-working/azure-terraform-secret.auto.tfvars | awk -F'=' '{gsub(/"/, "", $2); print $2}' | xargs)

# This is required because we create a new version of the Schema in the same Subject outside of Terraform, using the REST API.
SUBJECTS=("raw.recipes-value" "raw.orders-value" "enriched_orders-value") # Add more subjects as needed

for SUBJECT in "${SUBJECTS[@]}"; do
    # Soft delete the subject
    echo "Performing soft delete for subject: $SUBJECT"
    #curl --silent -u "$SR_API_KEY:$SR_API_SECRET" -X DELETE "$SR_URL/subjects/$SUBJECT" | jq .
    curl --silent -u "$SR_API_KEY:$SR_API_SECRET" -X DELETE "$SR_URL/dek-registry/v1/keks/bytetoeat-$UNIQUE_ID-kek/deks/$SUBJECT?algorithm=AES256_GCM&permanent=false" | jq 'select(.error_code != 40470)' # Suppress error if there is no KEK for the subject
    curl --silent -u "$SR_API_KEY:$SR_API_SECRET" -X DELETE "$SR_URL/dek-registry/v1/keks/bytetoeat-$UNIQUE_ID-kek-shared/deks/$SUBJECT?algorithm=AES256_GCM&permanent=false" | jq 'select(.error_code != 40470)'

    # Hard delete the subject
    echo "Performing hard delete for subject: $SUBJECT"
    #curl --silent -u "$SR_API_KEY:$SR_API_SECRET" -X DELETE "$SR_URL/subjects/$SUBJECT?permanent=true" | jq .
    curl --silent -u "$SR_API_KEY:$SR_API_SECRET" -X DELETE "$SR_URL/dek-registry/v1/keks/bytetoeat-$UNIQUE_ID-kek/deks/$SUBJECT?algorithm=AES256_GCM&permanent=true" | jq 'select(.error_code != 40470)'
    curl --silent -u "$SR_API_KEY:$SR_API_SECRET" -X DELETE "$SR_URL/dek-registry/v1/keks/bytetoeat-$UNIQUE_ID-kek-shared/deks/$SUBJECT?algorithm=AES256_GCM&permanent=true" | jq 'select(.error_code != 40470)'

    echo "Subject $SUBJECT has been soft deleted and hard deleted."
done

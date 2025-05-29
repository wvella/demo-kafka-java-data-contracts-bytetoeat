#!/bin/bash
# Variables
TERRAFORM_DIR="."
SR_URL=$(terraform -chdir="$TERRAFORM_DIR" output -raw schema-registry-url)
SR_API_KEY=$(terraform -chdir="$TERRAFORM_DIR" output -raw env-manager-schema-registry-api-key)
SR_API_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw env-manager-schema-registry-api-secret)

# This is required because we create a new version of the Schema in the same Subject outside of Terraform, using the REST API.
SUBJECTS=("raw.recipes-value" "raw.orders-value" "enriched_orders-value") # Add more subjects as needed

for SUBJECT in "${SUBJECTS[@]}"; do
    # Soft delete the subject
    echo "Performing soft delete for subject: $SUBJECT"
    curl --silent -u "$SR_API_KEY:$SR_API_SECRET" -X DELETE "$SR_URL/subjects/$SUBJECT" | jq .
    curl --silent -u "$SR_API_KEY:$SR_API_SECRET" -X DELETE "$SR_URL/dek-registry/v1/keks/aws-kek-for-csfle/deks/$SUBJECT?algorithm=AES256_GCM&permanent=false" | jq .

    # Hard delete the subject
    echo "Performing hard delete for subject: $SUBJECT"
    curl --silent -u "$SR_API_KEY:$SR_API_SECRET" -X DELETE "$SR_URL/subjects/$SUBJECT?permanent=true" | jq .
    curl --silent -u "$SR_API_KEY:$SR_API_SECRET" -X DELETE "$SR_URL/dek-registry/v1/keks/aws-kek-for-csfle/deks/$SUBJECT?algorithm=AES256_GCM&permanent=true" | jq .

    echo "Subject $SUBJECT has been soft deleted and hard deleted."
done

#!/bin/bash
# Variables
TERRAFORM_DIR="./local"
SR_URL=$(terraform -chdir="$TERRAFORM_DIR" output -raw schema_registry_url)
SR_API_KEY=$(terraform -chdir="$TERRAFORM_DIR" output -raw env_manager_schema_registry_api_key)
SR_API_SECRET=$(terraform -chdir="$TERRAFORM_DIR" output -raw env_manager_schema_registry_api_secret)

# Read the unique_id value from [aws|azure|gcp]-terraform-secret.auto.tfvars
UNIQUE_ID=$(grep '^unique_id' ${TERRAFORM_DIR}/*-terraform-secret.auto.tfvars | awk -F'=' '{gsub(/"/, "", $2); print $2}' | xargs)

# This is required because we create a new version of the Schema in the same Subject outside of Terraform, using the REST API.
SUBJECTS=("raw.recipes-value" "raw.orders-value" "enriched_orders-value") # Add more subjects as needed

mkdir -p ${TERRAFORM_DIR}/subjects

for SUBJECT in "${SUBJECTS[@]}"; do
    echo "Deleting subject: ${SUBJECT}"

    > ${TERRAFORM_DIR}/subjects/${SUBJECT}
    
    # Get all versions (including deleted)
    curl \
        -u "${SR_API_KEY}:${SR_API_SECRET}" \
        "${SR_URL}/subjects/${SUBJECT}/versions" \
            | jq -r '.[]' | tee -a ${TERRAFORM_DIR}/subjects/${SUBJECT}
    
    curl \
        -u "${SR_API_KEY}:${SR_API_SECRET}" \
        "${SR_URL}/subjects/${SUBJECT}/versions?deleted=true" \
            | jq -r '.[]' | tee -a ${TERRAFORM_DIR}/subjects/${SUBJECT}

    for VERSION in $(cat ${TERRAFORM_DIR}/subjects/${SUBJECT});
    do 
        echo "Deleting version ${VERSION} of ${SUBJECT}"

        curl \
            -X DELETE \
            -u "${SR_API_KEY}:${SR_API_SECRET}" \
            "${SR_URL}/subjects/${SUBJECT}/versions/${VERSION}"

        curl \
            -X DELETE \
            -u "${SR_API_KEY}:${SR_API_SECRET}" \
            "${SR_URL}/subjects/${SUBJECT}/versions/${VERSION}?permanent=true"
    done
done

for SUBJECT in "${SUBJECTS[@]}"; do
    # Soft delete the subject
    echo "Performing soft delete on KEK for subject: $SUBJECT"
    #curl --silent -u "$SR_API_KEY:$SR_API_SECRET" -X DELETE "$SR_URL/subjects/$SUBJECT" | jq .
    curl --silent -u "${SR_API_KEY}:${SR_API_SECRET}" -X DELETE "${SR_URL}/dek-registry/v1/keks/bytetoeat-${UNIQUE_ID}-kek/deks/${SUBJECT}?algorithm=AES256_GCM&permanent=false" | jq 'select(.error_code != 40470)' # Suppress error if there is no KEK for the subject
    curl --silent -u "${SR_API_KEY}:${SR_API_SECRET}" -X DELETE "${SR_URL}/dek-registry/v1/keks/bytetoeat-${UNIQUE_ID}-kek-shared/deks/${SUBJECT}?algorithm=AES256_GCM&permanent=false" | jq 'select(.error_code != 40470)'

    # Hard delete the subject
    echo "Performing hard delete on KEKfor subject: $SUBJECT"
    #curl --silent -u "$SR_API_KEY:$SR_API_SECRET" -X DELETE "$SR_URL/subjects/$SUBJECT?permanent=true" | jq .
    curl --silent -u "${SR_API_KEY}:${SR_API_SECRET}" -X DELETE "${SR_URL}/dek-registry/v1/keks/bytetoeat-${UNIQUE_ID}-kek/deks/${SUBJECT}?algorithm=AES256_GCM&permanent=true" | jq 'select(.error_code != 40470)'
    curl --silent -u "${SR_API_KEY}:${SR_API_SECRET}" -X DELETE "${SR_URL}/dek-registry/v1/keks/bytetoeat-${UNIQUE_ID}-kek-shared/deks/${SUBJECT}?algorithm=AES256_GCM&permanent=true" | jq 'select(.error_code != 40470)'

    echo "Subject $SUBJECT has been soft deleted and hard deleted."
done

#!/bin/bash

source ../shared/.env.sh
source ../shared/setup.sh

source .env.sh

echo "Checking if the container app job $JOB_NAME exists..."
names=$(az containerapp job list --resource-group=$RESOURCE_GROUP --query "[].name" -o tsv)
if [[ $names == *"$JOB_NAME"* ]]; then
    echo "DELETING.. Job $JOB_NAME already exists in $names."
    az containerapp job delete --name $JOB_NAME --resource-group $RESOURCE_GROUP --yes
fi

az containerapp job create \
    --name $JOB_NAME --resource-group $RESOURCE_GROUP --environment $ENVIRONMENT_NAME \
    --trigger-type "Event" \
    --replica-timeout 1800 --replica-retry-limit 0 --replica-completion-count 1 --parallelism 1 \
    --image $JOB_IMAGE \
    --registry-server $JOB_REGISTRY_SERVER \
    --registry-identity $JOB_REGISTRY_IDENTITY \
    --cpu "0.25" --memory "0.5Gi" \
    --min-executions 0 \
    --max-executions 1 \
    --scale-rule-name "blob" \
    --scale-rule-type "azure-blob" \
    --scale-rule-metadata "blobContainerName=$BLOB_CONTAINER_NAME" "blobCount=1" \
    --scale-rule-auth "connection=connection-string-secret" \
    --secrets "connection-string-secret=$STORAGE_CONNECTION_STRING" \
    --env-vars \
      "MOUNT_PATH=$MOUNT_PATH" \
      "AZURE_STORAGE_CONNECTION_STRING=secretref:connection-string-secret" \
      "SOURCE_CONTAINER_NAME=requests" \
      "WORKING_CONTAINER_NAME=processing" \
      "COMPLETED_CONTAINER_NAME=completed" \
      "ARM_USE_MSI=$ARM_USE_MSI" \
      "ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID" \
      "ARM_TENANT_ID=$ARM_TENANT_ID" \
      "ARM_CLIENT_ID=$ARM_CLIENT_ID"

# show the job yaml
az containerapp job show \
  --name $JOB_NAME \
  --resource-group $RESOURCE_GROUP \
  --output yaml > job.yaml

# az containerapp job update \
#   --name $JOB_NAME \
#   --resource-group $RESOURCE_GROUP \
#   --yaml job.yaml \
#   --output table
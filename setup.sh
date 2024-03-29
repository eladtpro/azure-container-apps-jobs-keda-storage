#!/bin/bash

# Source the environment variables
source ./env.sh

echo "Checking if the resource group $RESOURCE_GROUP exists..."
if az group exists --name $RESOURCE_GROUP; then
    echo "Resource group $RESOURCE_GROUP already exists."
else
  az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION \
    --query "properties.provisioningState"
fi


if true; then
  echo "Creating $AZURE_STORAGE_ACCOUNT"
  az storage account create --name $STORAGE_ACCOUNT_NAME --location "$location" --resource-group $RESOURCE_GROUP --sku $STORAGE_ACCOUNT_SKU

  # Set the storage account key as an environment variable. 
  AZURE_STORAGE_KEY=$(az storage account keys list -g $RESOURCE_GROUP -n $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)

  echo "Creating $share"
  az storage share create --name $STORAGE_SHARE_NAME --account-name $STORAGE_ACCOUNT_NAME

  # Create a directory in the share.
  echo "Creating $directory in $share"
  az storage directory create --share-name $STORAGE_SHARE_NAME --name $STORAGE_SHARE_DIRECTORY_NAME
else
  echo "Storage account $STORAGE_ACCOUNT_NAME already exists."
fi

echo "Checking if the container app env $ENVIRONMENT_NAME exists..."
name="$(az containerapp env show --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP --query name)"
if [[ -z "$name" ]]; then
  az containerapp env create \
    --name $ENVIRONMENT_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --logs-workspace-id $LOGS_WORKSPACE_ID \
    --logs-workspace-key $LOGS_WORKSPACE_KEY \
    --query "properties.provisioningState"

  echo "Setting the storage account $STORAGE_ACCOUNT_NAME for the environment $ENVIRONMENT_NAME..."
  az containerapp env storage set --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP \
    --storage-name $STORAGE_SHARE_NAME \
    --azure-file-account-name $STORAGE_ACCOUNT_NAME \
    --azure-file-account-key $STORAGE_ACCOUNT_KEY \
    --azure-file-share-name $STORAGE_SHARE_NAME \
    --access-mode ReadWrite
else
    echo "Environment $name already exists."
fi

echo "Checking if the container app job $JOB_NAME exists..."
names=$(az containerapp job list --resource-group=$RESOURCE_GROUP --query "[].name" -o tsv)
if [[ $names == *"$JOB_NAME"* ]]; then
    echo "Job $JOB_NAME already exists in $names."
else
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
        "COMPLETED_CONTAINER_NAME=completed"
        "ARM_USE_MSI=$ARM_USE_MSI"
        "ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID"
        "ARM_TENANT_ID=$ARM_TENANT_ID"
        "ARM_CLIENT_ID=$ARM_CLIENT_ID"
fi

# show the job yaml
az containerapp job show \
  --name $JOB_NAME \
  --resource-group $RESOURCE_GROUP \
  --output yaml > job.yaml

# az ad sp create-for-rbac 
#   --name $JOB_NAME --role contributor \
#   --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
#   --json-auth

RESOURCE_GROUP="azure-container-apps"
LOCATION="westeurope"
STORAGE_ACCOUNT_NAME="stcontainerappsmount"
STORAGE_ACCOUNT_KEY="<STORAGE_ACCOUNT_KEY>"
STORAGE_SHARE_NAME="acamountedshare"
JOB_NAME="opentofu"
ENVIRONMENT_NAME="env-container-apps-environment"
BLOB_CONTAINER_NAME="opentofu-requests"
STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=https;AccountName=stcontainerappsmount;AccountKey=XeJQgBRPEttJ13oLEOKpc68GTeLBPORgErrSH0ubesK9W5pk6deUaqciXKb1zM1c/GbXkeSjDXYI+ASt4ndHXQ==;EndpointSuffix=core.windows.net"
SUBSCRIPTION_ID=977171a9-6bfd-49c4-a496-018d3312466e


# create a resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --query "properties.provisioningState"

  # create an environment
az containerapp env create \
  --name $ENVIRONMENT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --query "properties.provisioningState"

az containerapp env storage set --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP \
    # --storage-name $STORAGE_ACCOUNT_NAME \
    --azure-file-account-name $STORAGE_ACCOUNT_NAME \
    --azure-file-account-key $STORAGE_ACCOUNT_KEY \
    --azure-file-share-name $STORAGE_SHARE_NAME \
    --access-mode ReadWrite

# create a job
az containerapp job create \
    --name $JOB_NAME --resource-group $RESOURCE_GROUP --environment $ENVIRONMENT_NAME \
    --trigger-type "Event" \
    --replica-timeout 1800 --replica-retry-limit 0 --replica-completion-count 1 --parallelism 1 \
    --image debian:latest \
    --cpu "0.25" --memory "0.5Gi" \
    --min-executions 0 \
    --max-executions 1 \
    --scale-rule-name "blob" \
    --scale-rule-type "azure-blob" \
    --scale-rule-metadata "blobContainerName=$BLOB_CONTAINER_NAME" "blobCount=1" \
    --scale-rule-auth "connection=connection-string-secret" \
    --secrets "connection-string-secret=$STORAGE_CONNECTION_STRING"

# show the job yaml
az containerapp job show \
  --name $JOB_NAME \
  --resource-group $RESOURCE_GROUP \
  --output yaml > job.yaml


# update the job mounted volumes
# https://learn.microsoft.com/en-us/azure/container-apps/storage-mounts-azure-files?tabs=bash#create-the-storage-mount
az containerapp job update \
  --name $JOB_NAME \
  --resource-group $RESOURCE_GROUP \
  --yaml job.yaml \
  --output table


  az ad sp create-for-rbac --name $JOB_NAME --role contributor \
                            --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
                            --json-auth

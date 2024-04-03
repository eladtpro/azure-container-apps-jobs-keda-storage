# Check if the resource group exists
if az group exists --name $RESOURCE_GROUP; then
  echo "Resource group $RESOURCE_GROUP already exists."
else
  echo "Creating resource group $RESOURCE_GROUP"
    az group create \
      --name $RESOURCE_GROUP \
      --location $LOCATION \
      --query "properties.provisioningState"
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
else
    echo "Environment $ENVIRONMENT_NAME already exists."
fi

if az storage account show --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP > /dev/null 2>&1; then
  echo "Storage account $STORAGE_ACCOUNT_NAME already exists."
  STORAGE_ACCOUNT_KEY=$(az storage account keys list -g $RESOURCE_GROUP -n $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)
  STORAGE_CONNECTION_STRING=$(az storage account show-connection-string --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP --query connectionString)
else
  echo "Creating $AZURE_STORAGE_ACCOUNT"
  az storage account create --name $STORAGE_ACCOUNT_NAME --location "$location" --resource-group $RESOURCE_GROUP --sku $STORAGE_ACCOUNT_SKU

  # Set the storage account key as an environment variable. 
  STORAGE_ACCOUNT_KEY=$(az storage account keys list -g $RESOURCE_GROUP -n $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)
  STORAGE_CONNECTION_STRING=$(az storage account show-connection-string --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP --query connectionString)
  echo "Creating $share"
  az storage share create --name $STORAGE_SHARE_NAME --account-name $STORAGE_ACCOUNT_NAME

  # Create a directory in the share.
  echo "Creating $directory in $share"
  az storage directory create --share-name $STORAGE_SHARE_NAME --name $STORAGE_SHARE_DIRECTORY_NAME
fi

echo "Checking if the storage account $STORAGE_ACCOUNT_NAME is set..."
name="$(az containerapp env storage show --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP --storage-name $STORAGE_SHARE_NAME --query name)"
if [[ -z "$name" ]]; then
  echo "Setting the storage account $STORAGE_ACCOUNT_NAME for the environment $ENVIRONMENT_NAME..."
  az containerapp env storage set --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP \
    --storage-name $STORAGE_SHARE_NAME \
    --azure-file-account-name $STORAGE_ACCOUNT_NAME \
    --azure-file-account-key $STORAGE_ACCOUNT_KEY \
    --azure-file-share-name $STORAGE_SHARE_NAME \
    --access-mode ReadWrite
else
    echo "storage account $STORAGE_ACCOUNT_NAME already set."
fi

# az ad sp create-for-rbac 
#   --name containerapps-jobs-github \
#   --role Contributor \
#   --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerRegistry/registries/$JOB_REGISTRY_NAME \
#   --sdk-auth

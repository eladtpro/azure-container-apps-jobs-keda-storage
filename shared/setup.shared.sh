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

# az ad sp create-for-rbac 
#   --name containerapps-jobs-github \
#   --role Contributor \
#   --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerRegistry/registries/$JOB_REGISTRY_NAME \
#   --sdk-auth

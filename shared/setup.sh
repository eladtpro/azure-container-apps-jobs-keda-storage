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
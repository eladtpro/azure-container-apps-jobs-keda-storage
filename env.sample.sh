LOCATION="westeurope"
STORAGE_ACCOUNT_NAME="<storage_account_name>"
STORAGE_ACCOUNT_KEY="<storage_account_key>"
STORAGE_SHARE_NAME="<storage_share_name>"
STORAGE_ACCOUNT_SKU="Standard_LRS"
STORAGE_SHARE_NAME="acamountedshare"
STORAGE_SHARE_DIRECTORY_NAME="acamountedshare"
JOB_NAME="opentofu"
JOB_IMAGE="<registry_name>.azurecr.io/opentofu:latest"
JOB_REGISTRY_SERVER="<registry_name>.azurecr.io"
JOB_REGISTRY_IDENTITY="system" #"/subscriptions/<subscription_id>/resourceGroups/<resource_group>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<identity_name>"
ENVIRONMENT_NAME="env-container-apps-environment"
LOGS_WORKSPACE_ID="<logs_workspace_id>"
LOGS_WORKSPACE_KEY="<logs_workspace_key>"
BLOB_CONTAINER_NAME="requests"
STORAGE_CONNECTION_STRING="<storage_connection_string>"
SUBSCRIPTION_ID=<subscription_id>
MOUNT_PATH=/var/requests
# opentofu manged identity
ARM_USE_MSI=true
ARM_SUBSCRIPTION_ID=159f2485-xxxx-xxxx-xxxx-xxxxxxxxxxxx
ARM_TENANT_ID=72f988bf-xxxx-xxxx-xxxx-xxxxxxxxxxxx
ARM_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx # only necessary for user assigned identity
ARM_MSI_ENDPOINT=$MSI_ENDPOINT # only necessary when the msi endpoint is different than the well-known one
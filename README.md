
# Container Apps Jobs
Azure Container Apps jobs enable you to run containerized tasks that execute for a finite duration and exit. You can use jobs to perform tasks such as data processing, machine learning, or any scenario where on-demand processing is required.

Container apps and jobs run in the same [environment](https://learn.microsoft.com/en-us/azure/container-apps/environment), allowing them to share capabilities such as networking and logging.


![Diagram](/assets/container-app-job-diagram.png)




### Variables
```
RESOURCE_GROUP="azure-container-apps"
LOCATION="westeurope"
ENVIRONMENT_NAME="env-container-apps-environment"
JOB_NAME="opentofu"
BLOB_CONTAINER_NAME="requests"
BLOB_CONNECTION_STRING="<QUEUE_CONNECTION_STRING>"
```


## Create a resource group
```
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --query "properties.provisioningState"
```

## Create a containerapp environment
```
az containerapp env create \
  --name $ENVIRONMENT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --query "properties.provisioningState"
```

## Create a job

The job will run with 0.25 CPU and 0.5Gi memory. The job will run a maximum of 10 times and will not run if there are no blobs in the container. The job will run for a maximum of 30 minutes and will not retry if it fails. The job will run only one instance at a time.

> Use KEDA [Azure Blob Storage](https://keda.sh/docs/1.4/scalers/azure-storage-blob/) scaler to scale the job based on the number of blobs in the specified container. The job will scale up when the number of blobs in the container increases and scale down when the number of blobs decreases.
> Use [debian:latest](https://hub.docker.com/_/debian) as the image for the job. 


## run setup.sh

```
az containerapp job create \
    --name $JOB_NAME --resource-group $RESOURCE_GROUP --environment $ENVIRONMENT_NAME \
    --trigger-type "Event" \
    --replica-timeout 1800 --replica-retry-limit 0 --replica-completion-count 1 --parallelism 1 \
    --image debian:latest \
    --cpu "0.25" --memory "0.5Gi" \
    --min-executions "0" \
    --max-executions "10" \
    --scale-rule-name "blob" \
    --scale-rule-type "azure-blob" \
    --scale-rule-metadata "blobContainerName=$BLOB_CONTAINER_NAME" "blobCount=1" \
    --scale-rule-auth "connection=connection-string-secret" \
    --secrets "connection-string-secret=$BLOB_CONNECTION_STRING"
```


## OpenTofu standalone installation
https://opentofu.org/docs/intro/install/standalone/



## debian file systen structure
A Debian system is organized along the Filesystem Hierarchy Standard (FHS). This standard defines the purpose of each directory.
https://www.debian.org/doc/manuals/debian-handbook/sect.filesystem-hierarchy.en.html


## Attaching log analytics workspace to container apps - REPLACE IMAGE
![Log Analithics Workspace Key](/assets/log-analytics-workspace-keys.png)


## KEDA Scalers: Azure Blob Storage
https://keda.sh/docs/2.13/scalers/
https://keda.sh/docs/1.4/scalers/azure-storage-blob/


## python image:
https://hub.docker.com/_/python/tags


## setting opentofu provider manged identity login
Before you can create a resource with a managed identity and then assign an RBAC role, your account needs sufficient permissions. You need to be a member of the account Owner role, or have Contributor plus User Access Administrator roles.
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/managed_service_identity



---


Jobs in Azure Container Apps
https://learn.microsoft.com/en-us/azure/container-apps/jobs?tabs=azure-cli
https://learn.microsoft.com/en-us/azure/container-apps/jobs?tabs=azure-cli#event-driven-jobs


Set scaling rules in Azure Container Apps
https://learn.microsoft.com/en-us/azure/container-apps/scale-app?pivots=azure-cli
https://learn.microsoft.com/en-us/azure/container-apps/scale-app?pivots=azure-cli#custom


KEDA Scalers: Azure Blob Storage
https://keda.sh/docs/2.13/scalers/azure-storage-blob/




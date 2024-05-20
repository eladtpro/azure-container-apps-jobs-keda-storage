
# Elevate your IaC by running containerized OpenTofu jobs with Azure Container Apps Jobs
In this tutorial, you will learn how to create a job in Azure Container Apps. You will create a job that runs a containerized task that processes blobs in an Azure Storage container. The job will run when a new blob is added to the container and will scale based on the number of blobs in the container.

Azure Container Apps jobs enable you to run containerized tasks that execute for a finite duration and exit. You can use jobs to perform tasks such as data processing, machine learning, or any scenario where on-demand processing is required.

Container apps and jobs run in the same [environment](https://learn.microsoft.com/en-us/azure/container-apps/environment), allowing them to share capabilities such as networking and logging.


## Prerequisites
- An Azure subscription. If you don't have an Azure subscription, create a [free account](https://azure.microsoft.com/free).
- An Azure Container Registry. If you don't have an Azure Container Registry, create one by following the instructions in the [Create a container registry](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-get-started-portal) article.
- An Azure Log Analytics workspace. If you don't have an Azure Log Analytics workspace, create one by following the instructions in the [Create a Log Analytics workspace](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/quick-create-workspace) article.


## Scenario explained
![Diagram](/assets/diagram.png)
In the diagram above, the job is triggered by an event when a new configuration message is added to the Azure Service Bus queue. The job runs a containerized task that processes the blob. The job scales based on the number of messages in the queue. The job runs for a maximum of 10 times and will not run if there are no pending items in the queue. The job runs for a maximum of 30 minutes and will not retry if it fails. The job runs only one instance at a time.

## Environment setup

### Setting the shared variables
Set the following variables to use throughout the tutorial. Replace the placeholder values with your own values.


```
RESOURCE_GROUP="azure-container-app-jobs"
LOCATION="eastus"
JOB_REGISTRY_NAME="<registry_name>"
JOB_REGISTRY_SERVER="<registry_name>.azurecr.io"
JOB_REGISTRY_IDENTITY="system"
JOB_REGISTRY_USERNAME="<registry_username>"
JOB_REGISTRY_PASSWORD="<registry_password>"
ENVIRONMENT_NAME="env-container-jobs"
LOGS_WORKSPACE_ID="<LOGS_WORKSPACE_ID>"
LOGS_WORKSPACE_KEY="<LOGS_WORKSPACE_KEY>"
SUBSCRIPTION_ID=00000000-0000-0000-0000-000000000000
STORAGE_ACCOUNT_NAME="stcontainerappsmount"
STORAGE_ACCOUNT_SKU="Standard_LRS"
STORAGE_SHARE_NAME="acamountedshare"
STORAGE_SHARE_DIRECTORY_NAME="acamountedshare"
MOUNT_PATH=/var/requests
```

Log analytics + container registry -> manual


az acr login with --expose-token
https://learn.microsoft.com/en-us/azure/container-registry/container-registry-authentication?tabs=azure-cli#az-acr-login-with---expose-token


## create Application - App Registration
> **Note**: The following command creates an app registration with the name containerapps-jobs-github. The command also assigns the Contributor role to the app registration on the specified resource group. Replace the value of the --scopes parameter with the resource group where you want to create the entity.
> the permissions are scoped to the resource group level. The app registration has the Contributor role on the specified resource group. The command also creates a service principal and assigns the Contributor role to the service principal on the specified resource group.
> Push image to Azure Container Registry, Deploy Container App Job to Azure Container Apps.


```
# create an entity on the resource group level
az ad sp create-for-rbac --name containerapps-jobs-github --role Contributor --scopes /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP} --json-auth
```

## create log analytics workspace



## update volumes:

```
az containerapp job update --name opentofu-dotnet-queue --resource-group azure-container-app-jobs --yaml job.yaml
```

```
  template:
    containers:
    - env:
      - name: MOUNT_PATH
        value: /var/requests
      - name: AZURE_SERVICE_BUS_CONNECTION_STRING
        secretRef: connection-string-secret
      - name: SERVICE_BUS_REQUESTS_QUEUE_NAME
        value: requests
      - name: PROCESS_WAIT_MS
        value: '10000'
      image: acrjobs.azurecr.io/opentofu-dotnet-queue:latest
      name: opentofu-dotnet-queue
      volumeMounts:
      - volumeName: mounted-azure-file-volume
        mountPath: /var/requests
      resources:
        cpu: 0.25
        ephemeralStorage: ''
        memory: 0.5Gi
    initContainers: null
    volumes:
    - name: mounted-azure-file-volume
      storageName: acamountedshare
      storageType: AzureFile
  workloadProfileName: Consumption


```

## Github action
push image 
az acr build --image opentofu:latest --registry ${{ vars.CONTAINER_REGISTRY }} --resource-group ${{ vars.RESOURCE_GROUP }} --file ./Dockerfile ./app/


### Variables
```
RESOURCE_GROUP="azure-container-app-jobs"
LOCATION="eastus"
ENVIRONMENT_NAME="env-container-jobs"
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

## REGISTRY USERNAME & PASSWORD


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


## Use dive to test docker image

[Dive - github](https://github.com/wagoodman/dive)

[Dive](https://github.com/wagoodman/dive/raw/main/.data/demo.gif)



---


Jobs in Azure Container Apps
https://learn.microsoft.com/en-us/azure/container-apps/jobs?tabs=azure-cli
https://learn.microsoft.com/en-us/azure/container-apps/jobs?tabs=azure-cli#event-driven-jobs


Set scaling rules in Azure Container Apps
https://learn.microsoft.com/en-us/azure/container-apps/scale-app?pivots=azure-cli
https://learn.microsoft.com/en-us/azure/container-apps/scale-app?pivots=azure-cli#custom


KEDA Scalers: Azure Blob Storage
https://keda.sh/docs/2.13/scalers/azure-storage-blob/




#!/bin/bash

# update the job mounted volumes
# https://learn.microsoft.com/en-us/azure/container-apps/storage-mounts-azure-files?tabs=bash#create-the-storage-mount
az containerapp job update \
  --name $JOB_NAME \
  --resource-group $RESOURCE_GROUP \
  --yaml job.yaml \
  --output table
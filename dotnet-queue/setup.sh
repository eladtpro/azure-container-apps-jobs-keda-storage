#!/bin/bash

source ../shared/.env.sh
source ../shared/setup.sh

source .env.sh

# create a job
az containerapp job create \
    --name $JOB_NAME --resource-group $RESOURCE_GROUP --environment $ENVIRONMENT_NAME \
    --trigger-type "Event" \
    --replica-timeout 1800 --replica-retry-limit 0 --replica-completion-count 1 --parallelism 1 \
    --image debian:latest \
    --cpu "0.25" --memory "0.5Gi" \
    --min-executions 0 \
    --max-executions 1 \
    --scale-rule-name "queue" \
    --scale-rule-type "azure-servicebus" \
    --scale-rule-metadata "namespace=$SERVICE_BUS_NAMESPACE" "queueName=$SERVICE_BUS_QUEUE_NAME" "queueLength=1" \
    --scale-rule-auth "connection=connection-string-secret" \
    --secrets "connection-string-secret=$SERVICE_BUS_CONNECTION_STRING" \
    --env-vars \
      "AZURE_SERVICE_BUS_CONNECTION_STRING=secretref:connection-string-secret"


# show the job yaml
az containerapp job show \
  --name $JOB_NAME \
  --resource-group $RESOURCE_GROUP \
  --output yaml > job.yaml


# # update the job mounted volumes
# az containerapp job update \
#   --name $JOB_NAME \
#   --resource-group $RESOURCE_GROUP \
#   --yaml job.yaml \
#   --output table

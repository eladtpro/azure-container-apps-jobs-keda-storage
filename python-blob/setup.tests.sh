#!/bin/bash

# Source the environment variables
source ./env.sh

echo "Checking if the container app env $ENVIRONMENT_NAME exists..."
name="$(az containerapp env show --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP --query name)"
if [[ -z "$name" ]]; then
    echo "XXXXX Creating the environment $ENVIRONMENT_NAME..."
else
    echo "Environment $name already exists."
fi

echo "Checking if the blob container $JOB_NAME exists..."
names=$(az containerapp job list --resource-group=$RESOURCE_GROUP --query "[].name" -o tsv)
if [[ $names == *"$JOB_NAME"* ]]; then
    echo "Job $names already exists."
else
    echo "XXXXX Creating the job $JOB_NAME..."
fi
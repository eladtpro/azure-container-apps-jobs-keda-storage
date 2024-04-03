

@minLength(3)
@maxLength(24)
@description('Provide a prefix for the name for the resources. Use only lower case letters and numbers. The name must be unique across Azure.')
param prefix string = 'azure-container-app-jobs${uniqueString(resourceGroup().id)}'

targetScope = 'subscription'


@description('Name of the resource group to create.')
param rgName string

@description('Azure Region the resource group will be created in.')
param rgLocation string = deployment().location

resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: rgLocation
}
param storageAccountType string = 'Standard_LRS'

@description('The storage account location.')
param location string = resourceGroup().location

@description('The name of the storage account')
param storageAccountName string = 'store${uniqueString(resourceGroup().id)}'

resource sa 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {}
}

output storageAccountName string = storageAccountName
output storageAccountId string = sa.id

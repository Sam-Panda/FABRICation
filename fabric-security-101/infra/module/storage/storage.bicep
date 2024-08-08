param location string
param name string
param resourceTags object 
param vnetId string
param subnetID string
var blobPEName = 'blobpep${name}'


resource storage 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  location: location
  name: name
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: resourceTags
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false     
    isHnsEnabled: true
    publicNetworkAccess: 'Disabled'   
  }
}

module blobStoragePrivateEndpoint '../network/storagePE.bicep' = {
  name: blobPEName
  params: {
    location: location
    groupId: 'dfs'
    privateEndpointName: blobPEName
    privateDnsZoneName: 'blobDnsZone'
    storageAcountName: name
    resourceTags: resourceTags
    storageAccountId: storage.id
    vnetId: vnetId
    subnetId: subnetID
  }
  dependsOn: [
    storage
  ]
}



// output filePrivateEndpointId string = fileStoragePrivateEndpoint.name
output storageId string = storage.id
output name string = name
output key string = storage.listKeys().keys[0].value
output blobPEOutputId string = blobStoragePrivateEndpoint.outputs.privateEndpointId


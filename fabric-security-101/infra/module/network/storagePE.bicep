param privateEndpointName string
param groupId string
param location string
param vnetId string
param subnetId string
param storageAccountId string
param resourceTags object 
param privateDnsZoneName string
param storageAcountName string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: privateEndpointName
  location: location
  tags: resourceTags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: [
            groupId
          ]
        }
      }
    ]
  }
}

module dnsZone '../Dns/StorageDnsZone.bicep' = {
  name: privateDnsZoneName
  params: {
    vnetId: vnetId
    groupId: groupId
    privateEndpointName: privateEndpointName
    storageName: storageAcountName
    resourceTags: resourceTags    
  }
  dependsOn: [
    privateEndpoint
  ]
}

output privateEndpointId string = privateEndpoint.id
output dnsZoneId string = dnsZone.outputs.dnsZoneId
output dnsZoneGroupId string = dnsZone.outputs.dnsZoneGroupId
output vnetLinksId string = dnsZone.outputs.vnetLinksLink


param resourceTags object 
param vnetId string
param privateEndpointName string
param groupId string
param storageName string 
param standardDomain string = 'windows.net'
param domain string = 'privatelink.${groupId}.core.${standardDomain}'
var zoneGroupName = 'dzg${groupId}'

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: domain
  location: 'global'
  tags: resourceTags  
}

resource vnetLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${domain}/${uniqueString(vnetId)}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
  dependsOn: [
    dnsZone
  ]
}

module DnsZoneGroup './StorageDnsZoneGroups.bicep' = {
  name: zoneGroupName
  params: {
    storageName: storageName
    groupId: groupId
    privateDnsZoneId: dnsZone.id
    privateEndpointName: privateEndpointName
  }
  dependsOn: [
    vnetLinks
  ]
}

output dnsZoneId string = dnsZone.id
output vnetLinksLink string = vnetLinks.id
output dnsZoneGroupId string = DnsZoneGroup.outputs.dnsZoneGroupId

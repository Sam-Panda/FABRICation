
param privateDnsZoneId string
param privateEndpointName string
param groupId string
param storageName string

resource DnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  name: '${privateEndpointName}/default'
  properties: {
    privateDnsZoneConfigs: [
      {      
        name: '${storageName}-${groupId}-core-windows-net'
        properties: {
          privateDnsZoneId: privateDnsZoneId          
        }
      }
    ]
  }
}

output dnsZoneGroupId string = DnsZoneGroup.id

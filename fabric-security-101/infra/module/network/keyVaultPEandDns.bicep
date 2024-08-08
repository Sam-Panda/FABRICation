param keyVaultName string
param location string
param subnetResourceId string
param keyvaultResourceId string
param virtualNetworkResourceId string



var privateEndpointName = 'MyKeyVaultPrivateEndpoint'
var privateDnsZoneName = 'privatelink.vaultcore.azure.net'
var privateEndpointDnsConfigFqdn = '${keyVaultName}.privatelink.vaultcore.azure.net'


resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: keyvaultResourceId
          groupIds: [
            'vault'
          ]
        }
      }
    ]
    subnet: {
      id: subnetResourceId
    }
    customDnsConfigs: [
      {
        fqdn: privateEndpointDnsConfigFqdn
      }
    ]
  }

resource privateDnsZoneGroup 'privateDnsZoneGroups' = {
    name: 'vault-private-dns-zone-group'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: privateDnsZoneName
          properties: {
            privateDnsZoneId: privateDnsZone.id
          }
        }
      ]
    }
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  
  resource virtualNetworkLink 'virtualNetworkLinks' = {
    name: 'link_to_vnet'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: virtualNetworkResourceId
      }
    }
  }
}

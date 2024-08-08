param location string
param vnetName string
param resourceTags object 
param vnetAddressSpace string


@description('CIDR range for the paas subnet..')
param paasSubnetName string
param paasSubnetCidr string


@description('CIDR range for the misc subnet..')
param miscSubnetName string
param miscSubnetCidr string



resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: vnetName
  location: location
  tags: resourceTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    subnets: [
      {
        name: miscSubnetName
        properties: {
          addressPrefix: miscSubnetCidr
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: paasSubnetName
        properties: {
          addressPrefix: paasSubnetCidr
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'

        }
      }
    ]
  }
}

output vnetId string = vnet.id
output miscSubnetId string = '${vnet.id}/subnets/${miscSubnetName}'
output paasSubnetId string = '${vnet.id}/subnets/${paasSubnetName}'

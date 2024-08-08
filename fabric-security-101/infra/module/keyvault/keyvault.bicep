param keyVaultName string
param location string
@secure()
param sqlAdministratorLoginsecretName string
@secure()
param sqlAdministratorLoginsecretValue string
@secure()
param sqlAdministratorLoginPasswordsecretName string
@secure()
param sqlAdministratorLoginPasswordsecretValue string
param roleAssignmentPrincipalObjectId string
param virtualNetworkResourceId string
param subnetResourceId string

var privateEndpointName = 'MyKeyVaultPrivateEndpoint'
var privateDnsZoneName = 'privatelink.vaultcore.azure.net'
var privateEndpointDnsConfigFqdn = '${keyVault.name}.privatelink.vaultcore.azure.net'

var keyVaultSecretsUserRoleDefinitionId = '00482a5a-887f-4fb3-b363-3b7fe8e74483'

resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    enableRbacAuthorization: true
    tenantId: tenant().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

module keyVaultPEandDns '../network/keyVaultPEandDns.bicep' = {
  name: 'keyVaultPEandDns'
  params: {
    keyVaultName: keyVaultName
    location: location
    subnetResourceId: subnetResourceId
    keyvaultResourceId: keyVault.id
    virtualNetworkResourceId: virtualNetworkResourceId
  }
}

resource secret1 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  parent: keyVault
  name: sqlAdministratorLoginsecretName
  properties: {
    value: sqlAdministratorLoginsecretValue
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  parent: keyVault
  name: sqlAdministratorLoginPasswordsecretName
  properties: {
    value: sqlAdministratorLoginPasswordsecretValue
  }
}

resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(keyVaultSecretsUserRoleDefinitionId, roleAssignmentPrincipalObjectId, keyVault.id)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleDefinitionId)
    principalId: roleAssignmentPrincipalObjectId
    principalType: 'user'
  }
}

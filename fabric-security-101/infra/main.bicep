
targetScope = 'subscription'

@description('Tags for all resources.')
param resourceTags object = {
  Application: 'databroicks-test'
  CostCenter: 'Az'  
  Environment: 'Development - Fabric data security 101'
  Owner: 'sapa@microsoft.com'
}

param resourceGroupName string = ''
param environmentName string = ''
param location string = ''

param sqlAdministratorLogin string

@secure()
param sqlAdministratorLoginPassword string

param sqlServerName string = ''
param sqldatbaseName string = ''

@secure()
param roleAssignmentPrincipalObjectId string = ''


var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var vnetAddressSpace = '10.50.0.0/16'
var paasSubnetCidr = '10.50.1.0/24'
var paasSubnetName = 'paas-subnet'
var miscSubnetCidr = '10.50.2.0/24'
var miscSubnetName = 'misc-subnet'
var _sqlServerName = !empty(sqlServerName) ? sqlServerName : '${abbrs.sqlServers}${resourceToken}-${environmentName}'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${resourceToken}-${environmentName}'
  location: location
  tags: resourceTags
}

module vnet './module/network/vnet.bicep' = {
  scope: rg
  name: 'vnet'
  params: {
    location: location
    vnetName: '${abbrs.resourcesVnet}-${resourceToken}-${environmentName}'
    resourceTags: resourceTags
    vnetAddressSpace: vnetAddressSpace
    paasSubnetName: paasSubnetName
    paasSubnetCidr: paasSubnetCidr
    miscSubnetName: miscSubnetName
    miscSubnetCidr: miscSubnetCidr
  }
}

// Storage account 

module storage './module/storage/storage.bicep' = {
  scope: rg
  name: 'storage'
  params: {
    location: location
    name: '${abbrs.storageStorageAccounts}${resourceToken}${environmentName}'
    resourceTags: resourceTags
    vnetId: vnet.outputs.vnetId
    subnetID: vnet.outputs.paasSubnetId
  }
}

// storage account 2

// module storage2 './module/storage/storage.bicep' = {
//   scope: rg
//   name: 'storage2'
//   params: {
//     location: location
//     name: '${abbrs.storageStorageAccounts}${resourceToken}${environmentName}2'
//     resourceTags: resourceTags
//     vnetId: vnet.outputs.vnetId
//     subnetID: vnet.outputs.paasSubnetId
//   }
// }

//sql server

module sqlserver './module/SQLserver/sqlserver.bicep' = {
  scope: rg
  name: 'sqlserver'
  params: {
    location: location
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorLoginPassword
    vnetId: vnet.outputs.vnetId
    subnetId: vnet.outputs.paasSubnetId
    sqlServerName: _sqlServerName
    sqlDatabaseName: '${_sqlServerName}/sample-db'
    privateEndpointName: '${abbrs.sqlServers}${resourceToken}-${environmentName}-pe'
    

  }
}


//keyvault

module keyvault './module/keyvault/keyvault.bicep' = {
  scope: rg
  name: 'keyvault'
  params: {
    keyVaultName: '${abbrs.keyVaultVaults}${resourceToken}-${environmentName}'
    location: location
    sqlAdministratorLoginsecretName: 'sql-admin-login'
    sqlAdministratorLoginsecretValue: sqlAdministratorLogin
    sqlAdministratorLoginPasswordsecretName: 'sql-admin-password'
    sqlAdministratorLoginPasswordsecretValue: sqlAdministratorLoginPassword
    roleAssignmentPrincipalObjectId: roleAssignmentPrincipalObjectId
    virtualNetworkResourceId: vnet.outputs.vnetId
    subnetResourceId: vnet.outputs.paasSubnetId
  }
}

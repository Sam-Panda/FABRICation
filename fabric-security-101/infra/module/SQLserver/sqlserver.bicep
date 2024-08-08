@description('The administrator username of the SQL logical server')
param sqlAdministratorLogin string

@description('The administrator password of the SQL logical server.')
@secure()
param sqlAdministratorLoginPassword string



@description('Location for all resources.')
param location string = resourceGroup().location

param vnetId  string
param subnetId string
param sqlServerName string
param sqlDatabaseName string
param privateEndpointName string


resource sqlServer 'Microsoft.Sql/servers@2021-11-01-preview' = {
  name: sqlServerName
  location: location
  tags: {
    displayName: sqlServerName
  }
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    version: '12.0'
    publicNetworkAccess: 'Disabled'
  }
}

resource database 'Microsoft.Sql/servers/databases@2021-11-01-preview' = {
  name: sqlDatabaseName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  tags: {
    displayName: sqlDatabaseName
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 104857600
    sampleName: 'AdventureWorksLT'
  }
  dependsOn: [
    sqlServer
  ]
}

module sqlPEandDns '../network/sqlPEandDns.bicep' = {
  name: 'sqlPEandDns'
  params: {
    location: location
    vnetId: vnetId
    subnetId: subnetId
    SQLServerResourceID: sqlServer.id
    privateEndpointName: privateEndpointName
    SqlServerName: sqlServerName
    groupId: 'sqlServer'
  }
  dependsOn: [
    sqlServer
  ]
}

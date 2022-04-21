/* INPUT */
param clientName string
param appName string
param envName string
@secure()
param databaseAdminPassword string

/* Paramètres fixes */
param vnetResourceGroupName string = 'UL-RES'
param vnetName string = 'SWRE-VNET'
param location string = 'canadaeast'

/* Noms dynamiques des ressources */
param resourceGroupName string = '${toLower(clientName)}-${toLower(appName)}-${toLower(envName)}-maj'
param storageAccountName string = '${toLower(clientName)}${toLower(appName)}${toLower(envName)}stk'

/* Resources réutilisées */
param aspName string = '${toLower(clientName)}-${toLower(envName)}-asp'
param databaseServerName string = '${toLower(clientName)}-${toLower(envName)}-db'
param databaseName string = resourceGroupName
param databaseAdminUser string = 'administrateur'

@allowed([
  'demo_umami'
  'standard'
  'minimal'
])
param drupalProfile string

param drupalUsername string
@secure()
param drupalPassword string

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: resourceGroupName
  location: location
}

module networkModule 'network.bicep' = {
  scope: resourceGroup(vnetResourceGroupName)
  name: 'vnet'
  params: {
    aspName : aspName
    location: location
    vnetName: vnetName
  }  
}

module storageModule 'storage.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'storage'
  params: {
    location: location
    storageAccountName: storageAccountName
  }  
  dependsOn: [
    rg
  ]
}

module securestorageModule 'secure-storage.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'secure-storage'
  params: {
    location: location
    storageAccountName: storageAccountName
    privateEndpointSubnetId: networkModule.outputs.subnetPEId  
    storagePrivateDnsId: networkModule.outputs.storagePrivateDnsId
  }
  dependsOn: [
    storageModule
    networkModule
  ]
}

module appserviceModule 'appservice.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'appservice'
  params: {
    drupalProfile: drupalProfile
    location: location
    storageAccountName: storageAccountName
    aspName: aspName
    appName: resourceGroupName
    databaseServerName: databaseServerName
    databaseName: databaseName
    databaseAdminUser: databaseAdminUser
    databaseAdminPassword: databaseAdminPassword
    appServiceSubnetId: networkModule.outputs.subnetAppsId
    drupalPassword: drupalPassword
    drupalUsername: drupalUsername
  }  
  dependsOn: [
    securestorageModule
    networkModule
  ]
}

module databaseModule 'database.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'database'
  params: {
    location: location
    databaseServerName: databaseServerName
    databaseName: databaseName
    databaseAdminUser: databaseAdminUser
    databaseAdminPassword: databaseAdminPassword
    privateEndpointSubnetId: networkModule.outputs.subnetPEId   
    databasePrivateDnsId: networkModule.outputs.databasePrivateDnsId 
  }
  dependsOn: [
    networkModule
  ]
}

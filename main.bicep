/*
Déploiement d'une instance de l'offre de service Majuscule du SWRE

Pour lancer : az deployment sub create --location canadaeast --template-file main.bicep

Des questions seront posées

*/


/* INPUT */
param clientName string
param appName string
@allowed([
  'pr'
  'ap'
])
param envName string
@secure()
param databaseAdminPassword string
@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
param storageAccountSku string


/* Paramètres fixes */
param vnetResourceGroupName string = 'UL-RES'
param vnetName string = 'SWRE-VNET'
param location string = 'canadaeast'

/* Noms dynamiques des ressources */
param fullAppName string = '${toLower(clientName)}-${toLower(appName)}-${toLower(envName)}-maj'
param commonResouceGroupName string = 'swre-maj-${toLower(envName)}'
param storageAccountName string = '${toLower(clientName)}${toLower(appName)}${toLower(envName)}stk'

/* Resources réutilisées */
param aspName string = 'swre-maj-${toLower(envName)}-asp'
param databaseServerName string = 'swre-maj-${toLower(envName)}-db'
param databaseName string = fullAppName
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
  name: fullAppName
  location: location
}

resource rgMaj 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: commonResouceGroupName
  location: location
}

module networkModule 'network.bicep' = {
  scope: resourceGroup(vnetResourceGroupName)
  name: 'vnet'
  params: {
    location: location
    vnetName: vnetName
    envName: envName
  }  
}

module storageModule 'storage.bicep' = {
  scope: resourceGroup(fullAppName)
  name: 'storage'
  params: {
    location: location
    storageAccountName: storageAccountName
    storageAccountSku: storageAccountSku
  }  
  dependsOn: [
    rg
  ]
}

module securestorageModule 'secure-storage.bicep' = {
  scope: resourceGroup(fullAppName)
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

module appserviceplanModule 'appserviceplan.bicep' = {
  scope: resourceGroup(commonResouceGroupName)
  name: 'appservice'
  params: {
    location: location
    aspName: aspName
  }  
  dependsOn: [
    securestorageModule
  ]
}

module appserviceModule 'appservice.bicep' = {
  scope: resourceGroup(fullAppName)
  name: 'appservice'
  params: {
    drupalProfile: drupalProfile
    location: location
    storageAccountName: storageAccountName
    aspPlanId: appserviceplanModule.outputs.aspPlanId
    appName: fullAppName
    databaseServerName: databaseServerName
    databaseName: databaseName
    databaseAdminUser: databaseAdminUser
    databaseAdminPassword: databaseAdminPassword
    appServiceSubnetId: networkModule.outputs.subnetAppsId
    drupalPassword: drupalPassword
    drupalUsername: drupalUsername
  }  
  dependsOn: [
    appserviceplanModule
    networkModule
    databaseModule
  ]
}

module databaseModule 'database.bicep' = {
  scope: resourceGroup(commonResouceGroupName)
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

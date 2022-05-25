param location string
param vnetName string
param envName string

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
       addressPrefixes: [
        '10.200.192.0/19'
       ]
    }
    subnets: [
      {
        name: 'swre-maj-private-endpoints-ap'
        properties: {
          addressPrefix: '10.200.192.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'swre-maj-appservice-ap'
        properties: {
          addressPrefix: '10.200.193.0/24'
          delegations: [
            {
              name: 'Microsoft.Web/serverfarms'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
        }
      }
      {
        name: 'swre-maj-private-endpoints-pr'
        properties: {
          addressPrefix: '10.200.194.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'swre-maj-appservice-pr'
        properties: {
          addressPrefix: '10.200.195.0/24'
          delegations: [
            {
              name: 'Microsoft.Web/serverfarms'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
        }
      }
    ]    
  }
}

resource databaseprivatedns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.mariadb.database.azure.com'
  location: 'global'
  resource vnetLink 'virtualNetworkLinks' = {
    name: 'mariadb-link'
    location: 'global'
    properties: {
      virtualNetwork: {
        id: vnet.id
      }
      registrationEnabled: false
    }
  }
}

resource storageprivatedns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.file.core.windows.net'
  location: 'global'
  resource vnetLink 'virtualNetworkLinks' = {
    name: 'storage-file-link'
    location: 'global'
    properties: {
      virtualNetwork: {
        id: vnet.id
      }
      registrationEnabled: false
    }
  }
}

output vnetId string = vnet.id

output subnetPEId string = envName == 'pr' ? vnet.properties.subnets[0].id : vnet.properties.subnets[2].id
output subnetAppsId string = envName == 'ap' ? vnet.properties.subnets[1].id : vnet.properties.subnets[3].id

output databasePrivateDnsId string = databaseprivatedns.id
output storagePrivateDnsId string = storageprivatedns.id


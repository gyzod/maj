param location string
param storageAccountName string
param privateEndpointSubnetId string
param storagePrivateDnsId string

resource storage 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Premium_LRS'
  }
  kind: 'FileStorage'
  properties: {
    publicNetworkAccess: 'Disabled'
  }    
    
  resource fileService 'fileServices' = {
    name: 'default'

    resource dbcert 'shares' = {
      name: 'dbcert'
    }

    resource drupal 'shares' = {
      name: 'drupal'
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${storageAccountName}-file-pe'
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'file'
        properties: {
          groupIds: [
            'file'
          ]
          privateLinkServiceId: storage.id
        }
      }
    ]
  }

  resource storageprivatednsGroup 'privateDnsZoneGroups' = {
    name: 'file'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'file'
          properties: {
            privateDnsZoneId: storagePrivateDnsId
          }
        }
      ]
    }
  }
}

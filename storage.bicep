param location string
param storageAccountName string
param storageAccountSku string

resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSku
  }

  properties: {
    largeFileSharesState: 'Enabled'
  }
 
  //kind: 'FileStorage' ou 'StorageV2' selon le SKU
  kind: ((storageAccountSku == 'Premium_LRS') ? 'FileStorage' :  'StorageV2')
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

resource uploadRootCert 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'deployscript-upload-file'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.30.0'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: storage.name
      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: storage.listKeys().keys[0].value
      }
    ]
    scriptContent: 'curl -o dbcert.crt.pem https://cacerts.digicert.com/DigiCertGlobalRootG2.crt.pem && az storage file upload --source dbcert.crt.pem -s dbcert'
  }
}

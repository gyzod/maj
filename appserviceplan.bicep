param location string
param aspName string

resource aspPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: aspName
  location: location  
  sku: {
    name: 'S1'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

output aspPlanId string = aspPlan.id

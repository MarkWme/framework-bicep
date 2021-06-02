param location string = resourceGroup().location
param functionRuntime string = 'node'

param namePrefix string = 'app'
param nameSuffix string = uniqueString(resourceGroup().id)

var appName = '$(namePrefix)$(nameSuffix)'

resource appsvc 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appName
  location: location
  kind: 'functionApp'
  sku {
    
  }
}

// Function App

resource fn 'Microsoft.Web/sites@2020-06-01' = {
  name: appName
  location: location
  kind: 'functionApp'
  properties: {
    enabled: true
    
  }
}
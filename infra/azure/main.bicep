@description('Base name used to derive resource names (e.g., fncastdotnet).')
param baseName string

@description('Deployment location; defaults to the resource group location.')
param location string = resourceGroup().location

@description('Operating system for Function App: linux or windows')
@allowed([ 'linux', 'windows' ])
param osType string = 'linux'

@description('DOTNET-ISOLATED runtime version for Linux (e.g., 8.0)')
param dotnetVersion string = '8.0'

// Consumption plan for Functions
resource plan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${baseName}-plan'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

// Storage account required by Functions
resource sa 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: toLower('${baseName}sa${uniqueString(resourceGroup().id)}')
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

var storageKey = listKeys(sa.id, '2023-01-01').keys[0].value
var storageConn = 'DefaultEndpointsProtocol=https;AccountName=${sa.name};AccountKey=${storageKey};EndpointSuffix=${environment().suffixes.storage}'

// Application Insights for monitoring (optional but recommended)
resource ai 'Microsoft.Insights/components@2022-06-15' = {
  name: '${baseName}-appi'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

// Function App (Windows, Consumption)
resource func 'Microsoft.Web/sites@2022-03-01' = {
  name: '${baseName}-func'
  location: location
  kind: osType == 'linux' ? 'functionapp,linux' : 'functionapp'
  properties: {
    serverFarmId: plan.id
    reserved: osType == 'linux'
    siteConfig: {
      // For Linux consumption, set DOTNET-ISOLATED runtime version
      linuxFxVersion: osType == 'linux' ? 'DOTNET-ISOLATED|' + dotnetVersion : null
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: storageConn
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${ai.properties.InstrumentationKey}'
        }
      ]
    }
  }
}

@description('Whether to provision a custom Event Grid topic.')
param deployTopic bool = true

resource topic 'Microsoft.EventGrid/topics@2022-06-15' = if (deployTopic) {
  name: '${baseName}-topic'
  location: location
  properties: {
    inputSchema: 'EventGridSchema'
    publicNetworkAccess: 'Enabled'
  }
}

@description('Outputs for convenience')
output functionAppName string = func.name
output functionAppUrl string = 'https://${func.name}.azurewebsites.net'
output eventGridTopicName string = deployTopic ? topic.name : ''
output eventGridTopicEndpoint string = deployTopic ? topic.properties.endpoint : ''

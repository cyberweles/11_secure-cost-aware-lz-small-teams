targetScope = 'resourceGroup'

@description(' Log Analytics Workspace name')
param lawName string

@description('Azure region, e.g. westeurope')
param location string

@description('Tags to apply')
param tags object

@description('Log Analytics workspace SKU')
// PerGB2018 = pay-per-GB ingestion model (no commitment tiers).
// Chosen for small teams and sandbox environments to keep costs predictable at low volume.
@allowed([
  'PerGB2018'
])
param skuName string = 'PerGB2018'

@description('Data retention in days')
@minValue(30)
@maxValue(730)
param retentionInDays int

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: lawName
  location: location
  tags: tags
  properties: {
    retentionInDays: retentionInDays
    sku: {
      name: skuName
    }
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

output workspaceName string = law.name
output workspaceId string = law.id
output customerId string = law.properties.customerId

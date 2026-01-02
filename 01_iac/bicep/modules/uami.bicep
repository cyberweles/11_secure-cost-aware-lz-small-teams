targetScope = 'resourceGroup'

@description('User Assigned Managed Identity name')
param name string

@description('Azure location')
param location string

@description('Tags')
param tags object

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

output identityId string = uami.id
output principalId string = uami.properties.principalId
output clientId string = uami.properties.clientId
output identityName string = uami.name

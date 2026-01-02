targetScope = 'subscription'

@description('Policy assignment name (must be unique at scope)')
param assignmentName string

@description('Policy definition id to assign')
param policyDefinitionId string

@description('Azure location for policy assignment metadata (e.g. westeurope)')
param location string

@description('Tag name to require')
param tagName string

@description('Required tag value')
param tagValue string

@allowed([
  'Deny'
  'Audit'
  'Disabled'
])
@description('Policy effect')
param effect string = 'Deny'

resource pa 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: assignmentName
  location: location
  properties: {
    displayName: assignmentName
    policyDefinitionId: policyDefinitionId
    parameters: {
      tagName: { value: tagName }
      tagValue: { value: tagValue }
      effect: { value: effect }
    }
  }
}

output policyAssignmentId string = pa.id

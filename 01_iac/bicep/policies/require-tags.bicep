targetScope = 'subscription'

@description('Policy assignment name (unique within the scope)')
param assignmentName string

@description('Location for the policy assignment (rqeuired for managed identity if used; safe to always set)')
param location string = 'westeurope'

@description('Tags required by policy (e.g. owner, costCenter, env)')
param requiredTagNames array

@description('Optional: if true, tries to enforce tag values (not only presence). Start with false')
param enforceValues bool = false

@description('Optional: expected values (used only when enforceValues=true)')
param expectedTagValues object = {}

var policyDefId = '/providers/Microsoft.Authorization/policyDefinitions/RequireTagAndItsValue'

resource requireTagsAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: assignmentName
  location: location
  properties: {
    displayName: 'Require tags (cwsbx)'
    policyDefinitionId: policyDefId
    parameters: {
      tagName: {
        value: requiredTagNames[0]
      }
      // NOTE: Build-in policy "RequireTagAndItsValue" accepts ONE tag at a time.
      // So we will call this module multiple times from main.bicep (one per tag).
      tagValue: enforceValues ? { value: string(expectedTagValues[requiredTagNames[0]]) } : { value: '' }
    }
  }
}


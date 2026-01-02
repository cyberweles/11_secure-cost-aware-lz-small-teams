targetScope = 'subscription'

@description('Policy definition name (unique at subscription scope)')
param policyName string

@description('Display name')
param displayName string = 'Require tag and its value'

var rule = loadJsonContent('./require-tag-value.rule.json')

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: policyName
  properties: {
    policyType: 'Custom'
    mode: 'All'
    displayName: displayName
    description: 'Requires a specific tag and enforces its value.'
    parameters: {
      tagName: { type: 'String' }
      tagValue: { type: 'String' }
      effect: {
        type: 'String'
        allowedValues: [
          'Deny'
          'Audit'
          'Modify'
          'Disabled'
        ]
        defaultValue: 'Deny'
      }
    }
    policyRule: rule
  }
}

output policyDefinitionId string = policyDef.id

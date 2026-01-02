targetScope = 'resourceGroup'

@description('Action Group name')
param name string

@description('Location (use global for action groups)')
param location string = 'global'

@description('Tags')
param tags object

@description('Receiver email')
param email string

resource ag 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    groupShortName: 'cwsbx'
    enabled: true
    emailReceivers: [
      {
        name: 'primary'
        emailAddress: email
        useCommonAlertSchema: true
      }
    ]
  }
}

output actionGroupId string = ag.id
output actionGroupName string = ag.name

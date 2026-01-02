targetScope = 'subscription'

@description('Budget name (resource name)')
param name string

@description('Monthly budget amount')
param amount int

@description('Action Group resource IDs to notify')
param actionGroupIds array

@description('Action Group resource IDs to notify')
param contactEmails array

@description('Budget start date (RFC3339). Default: first day of current month 00:00:00Z')
param startDate string = utcNow('yyyy-MM-01T00:00:00Z')

@description('Budget end date (RFC3339)')
param endDate string = '2099-12-31T00:00:00Z'


resource budget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: name
  scope: subscription()
  properties: {
    category: 'Cost'
    amount: amount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
      endDate: endDate
    }
    notifications: {
      Actual_GreaterThan_80_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: contactEmails
        contactGroups: actionGroupIds
      }
      Actual_GreaterThan_100_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: contactEmails
        contactGroups: actionGroupIds
      }
    }
  }
}

output budgetName string = budget.name
output budgetId string = budget.id
output budgetStartDate string = startDate

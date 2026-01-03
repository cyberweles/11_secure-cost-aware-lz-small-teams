using '../../bicep/main.bicep'

// Purpose: Dev/sandbox values:
// prefix=cwsbx (cyberweles sandbox), location=westeurope,
// tags including owner/costCenter,
// smaller limits.

param prefix = 'cwsbx'
param env = 'dev'
param location = 'westeurope'

param tags = {
  owner: 'cyberweles'
  costCenter: 'sandbox'
  env: 'dev'
}

param logAnalyticsEnabled = true
param logAnalyticsRetentionInDays = 30
param activityLogToLawEnabled = true

param costControlEnabled = true
param budgetAmountEur = 25
param budgetNotifyEmail = 'placeholder@example.com'
param budgetStartDate = '2025-12-01T00:00:00Z'

param policyBaselineEnabled = true
param policyName = 'cwsbx-dev-weu-pd-require-tag-value-01'

param networkingEnabled = true
param vnetAddressPrefix = '10.11.0.0/16'
param subnetSharedPrefix = '10.11.1.0/24'
param subnetPrivatePrefix = '10.11.2.0/24'

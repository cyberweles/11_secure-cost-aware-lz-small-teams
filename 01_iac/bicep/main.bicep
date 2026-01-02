// Purpose: Subscription-scope orchestrator (foundation).
// - Creates core RG
// - Deploys monitoring baseline (LAW + Activity Log -> LAW)
// - Deploys cost control (Action Group + Subscription Budget)
// - Deploys governance baseline:
//   A) require tags to exist (owner, costCenter, env)
//   B) enforce tag values (owner=cyberweles, costCenter=sandbox, env=<env>)

targetScope = 'subscription'

/* =========================
   1) GLOBAL INPUTS
   ========================= */

@description('Project prefix (e.g. cwsbx)')
param prefix string

@allowed([
  'dev'
  'prod'
])
@description('Deployment environment (drives naming + tag values).')
param env string

@description('Azure region (e.g. westeurope).')
param location string

@description('Mandatory tags applied to all resources (must include owner, costCenter, env).')
param tags object

/* =========================
   2) FEATURE TOGGLES
   ========================= */

@description('Enable Log Analytics Workspace.')
param logAnalyticsEnabled bool

@description('LAW retention (days).')
param logAnalyticsRetentionInDays int

@description('Enable subscription Activity Log forwarding to LAW (auditing).')
param activityLogToLawEnabled bool

@description('Enable cost control (Action Group + subscription budget).')
param costControlEnabled bool

@description('Monthly budget amount in EUR.')
param budgetAmountEur int

@description('Email used for budget notifications (placeholder allowed).')
param budgetNotifyEmail string

@description('Budget start date in RFC3339, e.g. 2026-01-01T00:00:00Z')
param budgetStartDate string

@description('Enable policy baseline (tags required + tag values enforced).')
param policyBaselineEnabled bool

@description('Policy definition name (unique)')
param policyName string

@description('Enable networking baseline (VNet + 2 subnets + NSG).')
param networkingEnabled bool

@description('VNet address space, e.g. 10.11.0.0/16')
param vnetAddressPrefix string

@description('Shared subnet prefix, e.g. 10.11.1.0/24')
param subnetSharedPrefix string

@description('Private subnet prefix, e.g. 10.12.2.0/24')
param subnetPrivatePrefix string

/* =========================
   3) NAMING
   ========================= */

var locationShort = location == 'westeurope' ? 'weu' : location
var baseName = '${prefix}-${env}-${locationShort}'

// Core RG
var rgCoreName = '${baseName}-rg-core'

// Monitoring
var lawName = '${baseName}-law-01'
var activityLogDiagName = '${baseName}-diag-activitylog-01'

// Cost control
var actionGroupName = '${baseName}-ag-budget-01'
var actionGroupId = resourceId(subscription().subscriptionId, rgCore.name, 'Microsoft.Insights/actionGroups', actionGroupName)
var budgetName = '${baseName}-budget-01'

// Governance (policy names)
var requireTagValuePolicyId = subscriptionResourceId('Microsoft.Authorization/policyDefinitions', policyName)

// Custom policy definition (require tag + enforce value) + assignments
var pdRequireTagValueName = '${baseName}-pd-require-tag-value-01'
var paRequireOwnerName = '${baseName}-pa-require-owner'
var paRequireCostCenterName = '${baseName}-pa-require-costcenter'
var paRequireEnvName = '${baseName}-pa-require-env'

// Networking
var vnetName = '${baseName}-vnet-01'
var nsgName = '${baseName}-nsg-default-01'

// Identity
var uamiOpsName = '${baseName}-uami-ops-01'

// Deterministic resourceId UAMI
var uamiId = resourceId(
  'Microsoft.ManagedIdentity/userAssignedIdentities',
  uamiOpsName
)
// roleDefinitionId (Reader / MonitoringReader )
var roleReaderId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'acdd72a7-3385-48ef-bd42-f606fba81ae7' // Reader
  )
var roleMonitoringReaderId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '43d0d8ad-25c7-4714-9337-8ba259a9fe05' // Monitoring Reader
)

/* =========================
   4) CORE RESOURCE GROUP
   ========================= */

resource rgCore 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: rgCoreName
  location: location
  tags: tags
}

/* =========================
   5) MONITORING BASELINE
   ========================= */

// 5.1 Log Analytics Workspace (in core RG)
module law './modules/law.bicep' = if (logAnalyticsEnabled) {
  name: 'mod-law-${env}'
  scope: rgCore
  params: {
    lawName: lawName
    location: location
    tags: tags
    retentionInDays: logAnalyticsRetentionInDays
  }
}

// Existing reference to LAW (safe for subscription-scope resources, no BCP318)
resource lawRef 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = if (logAnalyticsEnabled) {
  name: lawName
  scope: rgCore
}

// 5.2 Subscription Activity Log -> LAW (diagnostic setting at subscription scope)
resource subActivityLogDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (logAnalyticsEnabled && activityLogToLawEnabled) {
  name: activityLogDiagName
  scope: subscription()
  properties: {
    workspaceId: lawRef.id
    logs: [
      { category: 'Administrative', enabled: true }
      { category: 'Security', enabled: true }
      { category: 'ServiceHealth', enabled: true }
      { category: 'Alert', enabled: true }
      { category: 'Recommendation', enabled: true }
      { category: 'Policy', enabled: true }
      { category: 'Autoscale', enabled: true }
      { category: 'ResourceHealth', enabled: true }
    ]
  }
}

/* =========================
   6) COST CONTROL
   ========================= */

// 6.1 Action Group (email) in core RG
module agBudget './modules/actionGroupEmail.bicep' = if (costControlEnabled) {
  name: 'mod-ag-budget-${env}'
  scope: rgCore
  params: {
    name: actionGroupName
    location: 'global'
    tags: tags
    email: budgetNotifyEmail
  }
}

// 6.2 Subscription Budget (subscription scope)
module budget './modules/budgetMonthly.bicep' = if (costControlEnabled) {
  name: 'mod-budget-${env}'
  scope: subscription()
  params: {
    name: budgetName
    amount: budgetAmountEur
    startDate: budgetStartDate
    actionGroupIds: [
      actionGroupId
    ]
    contactEmails: [
      budgetNotifyEmail
    ]
  }
}

/* =========================
   7) GOVERNANCE BASELINE
   ========================= */

// 7.1 Create/ensure policy definition exists once
module pdRequireTagValue './policies/require-tag-value.bicep' = if (policyBaselineEnabled) {
  name: 'mod-pd-require-tag-value-${env}'
  scope: subscription()
  params: {
    policyName: pdRequireTagValueName
    displayName: 'Require tag and enforce its value'
    // NOTE: tagName/tagValue/effect are parameters inside the definition;
    // we don't pass them here (they are provided at assignment time).
    // If your require-tag-value.bicep currently REQUIRES tagName/tagValue/effect as params,
    // remove them from that module and keep them only as "parameters:" inside policy definition.
  }
}

// 7.2 Assignments (pass tagName/tagValue/effect to assignment module)
module paOwner './policies/assign-require-tag-value.bicep' = {
  name: 'mod-pa-owner-${env}'
  scope: subscription()
  params: {
    assignmentName: paRequireOwnerName
    policyDefinitionId: requireTagValuePolicyId
    location: location
    tagName: 'owner'
    tagValue: 'cyberweles'
    effect: 'Deny'
  }
}

module paCostCenter './policies/assign-require-tag-value.bicep' = {
  name: 'mod-pa-costcenter-${env}'
  scope: subscription()
  params: {
    assignmentName: paRequireCostCenterName
    policyDefinitionId: requireTagValuePolicyId
    location: location
    tagName: 'costCenter'
    tagValue: 'sandbox'
    effect: 'Deny'
  }
}

module paEnv './policies/assign-require-tag-value.bicep' = {
  name: 'mod-pa-env-${env}'
  scope: subscription()
  params: {
    assignmentName: paRequireEnvName
    policyDefinitionId: requireTagValuePolicyId
    location: location
    tagName: 'env'
    tagValue: env
    effect: 'Deny'
  }
}

/* =========================
   8) NETWORKING BASELINE
   ========================= */

module net './modules/vnetNsg.bicep' = if (networkingEnabled) {
  name: 'mod-net-${env}'
  scope: rgCore
  params: {
    vnetName: vnetName
    nsgName: nsgName
    location: location
    tags: tags
    vnetAddressPrefix: vnetAddressPrefix
    subnetSharedPrefix: subnetSharedPrefix
    subnetPrivatePrefix: subnetPrivatePrefix
  }
}

/* =========================
   9) IDENTITY BASELINE
   ========================= */

resource raUamiReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, uamiId, roleReaderId)
  scope: subscription()
  properties: {
    roleDefinitionId: roleReaderId
    principalId: uamiOps.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

resource raUamiMonitoringReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, uamiId, roleMonitoringReaderId)
  scope: subscription()
  properties: {
    roleDefinitionId: roleMonitoringReaderId
    principalId: uamiOps.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

module uamiOps './modules/uami.bicep' = {
  name: '${baseName}-uami-ops'
  scope: resourceGroup(rgCoreName)
  params: {
    name: uamiOpsName
    location: location
    tags: tags
  }
}

/* =========================
   10) OUTPUTS (ops / verify)
   ========================= */

output coreRgName string = rgCore.name
output coreRgId string = rgCore.id

output outLawName string = logAnalyticsEnabled ? law!.outputs.workspaceName : ''
output outLawId string = logAnalyticsEnabled ? law!.outputs.workspaceId : ''

output outActivityLogDiagName string = (logAnalyticsEnabled && activityLogToLawEnabled) ? subActivityLogDiag.name : ''

output outBudgetName string = costControlEnabled ? budgetName : ''
output outActionGroupName string = costControlEnabled ? actionGroupName : ''

output outVnetName string = networkingEnabled ? vnetName: ''
output outNsgName string = networkingEnabled ? nsgName : ''

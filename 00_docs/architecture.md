# Architecture (v1)

This repository deploys a **minimal subscription baseline** for small teams / sandboxes.

## Scope
- **Subscription scope** orchestrator: `01_iac/bicep/main.bicep`
- **Core resource group**: `cwsbx-<env>-weu-rg-core`
- Modules are deployed either at:
  - subscription scope (policy assignments, budget, diagnostic settings), or
  - RG scope (LAW, Action Group, VNet/NSG, UAMI)

## Components

### Foundation
- Resource Group (core)
- Naming + mandatory tags (`owner`, `costCenter`, `env`)

### Governance (Policy baseline)
- Custom policy definition: require a tag and enforce its value
- Assignments at subscription scope:
  - enforce `owner`
  - enforce `costCenter`
  - enforce `env`

### Observability
- Log Analytics Workspace (LAW) in core RG
- Subscription Activity Log → LAW (diagnostic setting)
- Retention set for sandbox usage (30 days in dev)

### Cost Control (FinOps-lite)
- Action Group (email)
- Subscription budget (monthly) with notifications (80% / 100%)

### Networking baseline
- VNet + 2 subnets (`snet-shared`, `snet-private`)
- Default NSG associated to both subnets (secure-by-default inbound)

### Identity baseline
- One User Assigned Managed Identity (UAMI) in core RG
- Subscription-scope RBAC:
  - Reader
  - Monitoring Reader

## Verification
`02_ops/scripts/verify.sh <env>` checks existence + key settings for:
- RG, tags, LAW + retention, diag setting, budget, policy assignments,
- VNet/NSG/subnets association,
- UAMI + RBAC role assignments.

# Modules index

This folder contains RG-scoped building blocks used by the subscription orchestrator (`main.bicep`).

## Included modules
- `law.bicep` — Log Analytics Workspace (retention, tags)
- `actionGroupEmail.bicep` — Action Group with email receiver
- `budgetMonthly.bicep` — Subscription budget (monthly)
- `vnetNsg.bicep` — VNet + subnets + NSG + association
- `uami.bicep` — User Assigned Managed Identity (UAMI)

## Design rule
Modules are kept small and deterministic:
- naming comes from the orchestrator
- tags always passed from the orchestrator

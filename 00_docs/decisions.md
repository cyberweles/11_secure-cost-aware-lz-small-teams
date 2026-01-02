# Decisions (v1)

## Why subscription-scope orchestration
We deploy a baseline that must apply to the whole subscription:
- policy assignments
- budgets
- subscription diagnostic settings

So `main.bicep` targets **subscription** and delegates RG resources to modules.

## Naming convention
Pattern:
`<prefix>-<env>-<regionShort>-<resource>-<nn>`

Example:
`cwsbx-dev-weu-law-01`

Reasons:
- deterministic and readable
- supports multiple environments
- easy CLI filtering

## Tagging baseline
Mandatory tags:
- `owner`
- `costCenter`
- `env`

Reasons:
- accountability (owner)
- FinOps allocation (costCenter)
- environment hygiene (env)

## Governance baseline (policy)
We keep policy baseline minimal:
- enforce presence and expected values for `owner`, `costCenter`, `env`
- effect: `Deny`

Reason:
- prevents untagged / mis-tagged resources early (clean sandbox governance)

## Observability baseline
- LAW retention: 30 days (sandbox-appropriate)
- Subscription Activity Log forwarded to LAW

Reason:
- minimal audit trail without heavy tooling (no Sentinel/Defender here)

## Cost control baseline
- monthly budget with 80% and 100% notifications

Reason:
- practical guardrail for labs/small teams to prevent cost surprises

## Networking baseline
- single VNet, two subnets, default NSG, no inbound rules opened

Reason:
- gives a “real landing zone feel” without complexity
- secure-by-default posture for sandboxes

## Identity baseline
- one UAMI for ops/platform use
- RBAC: Reader + Monitoring Reader on subscription

Reason:
- clean identity story without managing AAD groups/users in IaC

## Environments
- DEV: deployed and verified
- PROD: parameter scaffold only (not deployed yet)

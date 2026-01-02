# Threat model (mini, v1)

## Context
This is a **sandbox / small-team baseline** for Azure subscriptions.
Goal is to prevent common hygiene failures, not to build enterprise security.

## Assets we care about
- subscription governance (policies, RBAC)
- cost exposure (budget)
- audit trail (Activity Log -> LAW)
- baseline network isolation (VNet + NSG)

## Main risks
- uncontrolled cost growth
- accidental deployment of untagged resources (hard to allocate/clean up)
- missing audit logs during incident investigation
- overly permissive networking (inbound exposure)
- overly permissive access (RBAC drift)

## Controls in this repo
- Tag enforcement policies (Deny)
- Budget notifications (80% / 100%)
- Activity Log forwarded to LAW
- Default NSG associated to subnets (no inbound opened)
- UAMI with minimal read roles (Reader + Monitoring Reader)

## Out of scope (intentionally)
- Defender for Cloud / Sentinel
- workload-level controls (WAF, private endpoints, app identity)
- advanced egress control (Azure Firewall / NAT rules)
- full IAM governance (groups, PIM, break-glass)

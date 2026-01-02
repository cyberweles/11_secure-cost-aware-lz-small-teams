# 11_secure-cost-aware-lz-small-teams

## Why this project exists

A minimal Azure Landing Zone (subscription scope) for small teams / sandboxes, focused on:
- governance (tags & policies),
- observability (Active Logs),
- cost control (budget),
- repeatable deploy & verification (CLI-first).
This is **not** a full enterprise landing zone - it is a **clean**, realistic baseline you would actually deploy for small internal teams or labs.

## What gets deployed

**Foundation**
- Resource Group: `cwsbx-<env>-weu-rg-core`
- Standardized naming & tagging (`owner`, `env`, `costCenter`)

**Governance**
- Custom Azure Policies:
  - required tags
  - enforced tag values (`owner`, `env`, `costCenter`)
- Policy assignments at subscription scope

**Observability**
- Log Analytics Workspace
- Subscription Activity Log -> Log Analytics
- Retention: 30 days (sandbox-appropriate)

**Cost Control (FinOps-lite)**
- Subscription budget (25 EUR)
- Notifications at 80% and 100% (Action Group)

## Project structure

.  
├── 00_docs/        # Architecture notes & decisions  
├── 01_iac/         # Bicep (subscription-scope orchestrator + modules)  
├── 02_ops/         # deploy / verify / destroy scripts  
├── 03_ci/          # CI validation (bicep build)  
└── 04_examples/    # Usage / test examples

## Prerequisites

- Azure CLI
- Logged-in Azure account
- Active Azure subscription

```bash
az login
az account set --subscription <SUBSCRIPTION_ID>
```

## Quickstart

```bash
bash ./02_ops/scripts/deploy.sh dev
```

## Verify

```bash
bash ./02_ops/scripts/verify.sh dev
```

## Destroy

```bash
bash ./02_ops/scripts/destroy.sh dev
```

## What `verify.sh` checks

- Azure CLI access
- Core Resource Group (existence, region)
- Required tags and expexted values
- Log Analytics Workspace (location, retention)
- Activity Log diagnostic setting (subscription -> LAW)
- Subscription budget (amout & notifications)
- Policy assignments (tag enforcement)

A successful run ends with:
```csharp
[OK] VERIFY PASSED
```

## Design goals

- CLI-first (no portal clicking)
- Idempotent deployments
- Minimal but enforceable governance
- Low-cost sandbox baseline
- Easy to extend with networking, identity, or security controls

## Scope & limitations

- Designed for small teams / sandbox environmtents
- No workload networking yet (added in next step)
- No application resources deployed
- No advanced security tooling (Defender, Sentinel, etc.)

## Author

Bartosz Cuzytek  
(Cloud Engineering / Security-focused learning project)
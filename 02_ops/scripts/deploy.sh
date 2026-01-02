#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Purpose: One command deploy (subscription-scope),
# picks env param file, ensure RG/what's needed,
# runs `az deployment sub create`.

ENV="${1:-dev}"

echo "==> Deploying environment: $ENV"

az deployment sub create \
  --name "cwsbx-${ENV}-foundation" \
  --location westeurope \
  --template-file 01_iac/bicep/main.bicep \
  --parameters 01_iac/params/${ENV}/main.bicepparam

  echo "==> Deployment completed"
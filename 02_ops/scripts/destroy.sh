#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Purpose: Clean teardown routine:
# removes RGs and related resources in correct order.
# Keeps the sandbox cheap.

ENV="${1:-dev}"

BASE="cwsbx-${ENV}-weu"
RG_NAME="${BASE}-rg-core"

echo "==> Deleting Resource Group: ${RG_NAME}"
az group delete --name "${RG_NAME}" --yes --no-wait

echo "==> Sandbox teardown started"
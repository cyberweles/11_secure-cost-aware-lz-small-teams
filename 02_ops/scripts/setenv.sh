#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------
# Project 11 - environment bootstrap                   
# Source this file: source ./02_ops/scripts/setenv.sh  
# -----------------------------------------------------

# ---- basic project context ----
export ENV="${ENV:-dev}"

export PREFIX="cwsbx"
export REGION="westeurope"
export REGION_SHORT="weu"

# ---- subscription (explicit, no guessing) ----
export SUB_ID="$(az account show --query id -o tsv)"

# ---- resource groups (aligned with IaC naming) ----
export RG_CORE="${PREFIX}-${ENV}-${REGION_SHORT}-rg-core"

# ---- sanity checks ----
echo "==> Environment loaded"
echo "ENV=${ENV}"
echo "SUB_ID=${SUB_ID}"
echo "RG_CORE=${RG_CORE}"
echo

# Hard fail if RG does not exist (prevents silent empty -g "")
az group show -n "${RG_CORE}" >/dev/null

echo "[V] Resource group exists - ready to work"
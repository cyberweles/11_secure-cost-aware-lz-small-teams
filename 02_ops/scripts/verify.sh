#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Purpose: Post-deploy checks:
# - RG exists + location
# - required tags + values
# - Log Analytics Workspace exists + retention
# - Subscription Activity Log diagnostic setting -> LAW
# - Subscription Budget exists + amount + notifications

ENV="${1:-dev}"

# ---- constants (project decisions) ----
PREFIX="cwsbx"
LOCATION="westeurope"
LOCATION_SHORT="weu"

# ---- expected tags (agreed) ----
EXPECTED_OWNER="cyberweles"
EXPECTED_COSTCENTER="sandbox"
EXPECTED_ENV="${ENV}"

# ---- OPTIONAL checks toggles (set to true/false) ----
CHECK_LAW="true"
CHECK_ACTIVITYLOG_DIAG="true"
CHECK_BUDGET="true"

# ---- expected LAW settings ----
EXPECTED_LAW_RETENTION_DAYS="30"

# ---- expected budget settings ----
EXPECTED_BUDGET_AMOUNT="25.0"

# ---- naming ----
BASE_NAME="${PREFIX}-${ENV}-${LOCATION_SHORT}"
RG_CORE="${BASE_NAME}-rg-core"
LAW_NAME="${BASE_NAME}-law-01"
ACTIVITYLOG_DIAG_NAME="${BASE_NAME}-diag-activitylog-01"
BUDGET_NAME="${BASE_NAME}-budget-01"

fail() { echo "[ERROR] $*" >&2; exit 1; }
ok()   { echo "[OK] $*"; }

echo "==> Verifying environment: ${ENV}"
echo "RG core: ${RG_CORE}"
echo

# 1) Azure CLI ready + logged in
command -v az >/dev/null 2>&1 || fail "Azure CLI (az) not found in PATH."
az account show >/dev/null 2>&1 || fail "Not logged in. Run: az login."
ok "Azure CLI ready + logged in"

# 2) RG exists
az group show -n "${RG_CORE}" >/dev/null 2>&1 || fail "Resource group not found: ${RG_CORE}"
ok "Resource group exists: ${RG_CORE}"

# 3) Location check
RG_LOCATION="$(az group show -n "${RG_CORE}" --query location -o tsv)"
[[ "${RG_LOCATION}" == "${LOCATION}" ]] || fail "RG location mismatch. expected='${LOCATION}', got='${RG_LOCATION}'"
ok "RG location OK: ${RG_LOCATION}"

# 4) Tags present + values correct
get_tag() {
  local key="$1"
  az group show -n "${RG_CORE}" --query "tags.${key}" -o tsv 2>/dev/null || true
}

TAG_OWNER="$(get_tag owner)"
TAG_COSTCENTER="$(get_tag costCenter)"
TAG_ENV="$(get_tag env)"

[[ -n "${TAG_OWNER}" ]] || fail "Missing tag: owner"
[[ -n "${TAG_COSTCENTER}" ]] || fail "Missing tag: costCenter"
[[ -n "${TAG_ENV}" ]] || fail "Missing tag: env"
ok "Required tags exist (owner, costCenter, env)"

[[ "${TAG_OWNER}" == "${EXPECTED_OWNER}" ]] || fail "Tag owner mismatch. expected='${EXPECTED_OWNER}', got='${TAG_OWNER}'"
[[ "${TAG_COSTCENTER}" == "${EXPECTED_COSTCENTER}" ]] || fail "Tag costCenter mismatch. expected='${EXPECTED_COSTCENTER}', got='${TAG_COSTCENTER}'"
[[ "${TAG_ENV}" == "${EXPECTED_ENV}" ]] || fail "Tag env mismatch. expected='${EXPECTED_ENV}', got='${TAG_ENV}'"
ok "Tag values OK (owner='${TAG_OWNER}', costCenter='${TAG_COSTCENTER}', env='${TAG_ENV}')"

# 5) (optional) LAW checks
if [[ "${CHECK_LAW}" == "true" ]]; then
  az monitor log-analytics workspace show -g "${RG_CORE}" -n "${LAW_NAME}" >/dev/null 2>&1 \
    || fail "LAW not found: ${LAW_NAME} in RG: ${RG_CORE}"
  ok "LAW exists: ${LAW_NAME}"

  LAW_LOCATION="$(az monitor log-analytics workspace show -g "${RG_CORE}" -n "${LAW_NAME}" --query location -o tsv)"
  [[ "${LAW_LOCATION}" == "${LOCATION}" ]] || fail "LAW location mismatch. expected='${LOCATION}', got='${LAW_LOCATION}'"
  ok "LAW location OK: ${LAW_LOCATION}"

  LAW_RETENTION="$(az monitor log-analytics workspace show -g "${RG_CORE}" -n "${LAW_NAME}" --query retentionInDays -o tsv)"
  [[ "${LAW_RETENTION}" == "${EXPECTED_LAW_RETENTION_DAYS}" ]] || fail "LAW retention mismatch. expected='${EXPECTED_LAW_RETENTION_DAYS}', got='${LAW_RETENTION}'"
  ok "LAW retention OK: ${LAW_RETENTION} days"
fi

# 6) Subscription Activity Log diagnostic setting -> LAW
if [[ "${CHECK_ACTIVITYLOG_DIAG}" == "true" ]]; then
  az monitor diagnostic-settings subscription show --name "${ACTIVITYLOG_DIAG_NAME}" >/dev/null 2>&1 \
    || fail "Subscription diagnostic setting not found: ${ACTIVITYLOG_DIAG_NAME}"
  ok "Subscription diagnostic setting exists: ${ACTIVITYLOG_DIAG_NAME}"

  EXPECTED_WORKSPACE_ID="$(az monitor log-analytics workspace show -g "${RG_CORE}" -n "${LAW_NAME}" --query id -o tsv)"
  ACTUAL_WORKSPACE_ID="$(az monitor diagnostic-settings subscription show --name "${ACTIVITYLOG_DIAG_NAME}" --query workspaceId -o tsv)"

  [[ "${ACTUAL_WORKSPACE_ID}" == "${EXPECTED_WORKSPACE_ID}" ]] \
    || fail "ActivityLog diag workspaceId mismatch. expected='${EXPECTED_WORKSPACE_ID}', got='${ACTUAL_WORKSPACE_ID}'"
  ok "ActivityLog diag points to correct LAW"
fi

# 7) Subscription Budget (Cost Control) — use ARM API (stable) instead of az consumption (preview)
EXPECTED_BUDGET_NOTIF_80="actual_GreaterThan_80_Percent"
EXPECTED_BUDGET_NOTIF_100="actual_GreaterThan_100_Percent"

if [[ "${CHECK_BUDGET}" == "true" ]]; then
  SUB_ID="$(az account show --query id -o tsv 2>/dev/null)" || fail "Cannot read subscription id (az account show)."
  [[ -n "${SUB_ID}" ]] || fail "Subscription id is empty."

  BUDGET_URL="https://management.azure.com/subscriptions/${SUB_ID}/providers/Microsoft.Consumption/budgets/${BUDGET_NAME}?api-version=2023-05-01"

  # budget exists?
  az rest -m get -u "${BUDGET_URL}" >/dev/null 2>&1 \
    || fail "Subscription budget not found: ${BUDGET_NAME}"
  ok "Subscription budget exists: ${BUDGET_NAME}"

  # amount check (string compare; ARM returns 25.0)
  ACTUAL_AMOUNT="$(az rest -m get -u "${BUDGET_URL}" --query properties.amount -o tsv 2>/dev/null || true)"
  [[ -n "${ACTUAL_AMOUNT}" ]] || fail "Budget amount could not be read (empty)."

  [[ "${ACTUAL_AMOUNT}" == "${EXPECTED_BUDGET_AMOUNT}" ]] \
    || fail "Budget amount mismatch. expected='${EXPECTED_BUDGET_AMOUNT}', got='${ACTUAL_AMOUNT}'"
  ok "Budget amount OK: ${ACTUAL_AMOUNT} EUR"

  # notifications check — ensure both keys exist
  NOTIF_KEYS="$(az rest -m get -u "${BUDGET_URL}" --query "keys(properties.notifications)" -o tsv 2>/dev/null || true)"
  [[ -n "${NOTIF_KEYS}" ]] || fail "Budget notifications keys could not be read (empty)."

  echo "${NOTIF_KEYS}" | grep -Fq "${EXPECTED_BUDGET_NOTIF_80}"  || fail "Missing budget notification: ${EXPECTED_BUDGET_NOTIF_80}"
  echo "${NOTIF_KEYS}" | grep -Fq "${EXPECTED_BUDGET_NOTIF_100}" || fail "Missing budget notification: ${EXPECTED_BUDGET_NOTIF_100}"
  ok "Budget notifications OK (80%, 100%)"
fi

# 8) Policy assignment exists (require tags: owner, costCenter, env)
POLICY_ASSIGNMENTS=(
  "${BASE_NAME}-pa-require-owner"
  "${BASE_NAME}-pa-require-costcenter"
  "${BASE_NAME}-pa-require-env"
)

for pa in "${POLICY_ASSIGNMENTS[@]}"; do
  az policy assignment show --name "${pa}" >/dev/null 2>&1 \
    || fail "Policy assignment not found: ${pa}"
  ok "Policy assignment exists: ${pa}"
done

# 9) Networking
# ---- networking toggles ----
CHECK_NETWORKING="true"

# ---- expected networking ----
VNET_NAME="${BASE_NAME}-vnet-01"
NSG_NAME="${BASE_NAME}-nsg-default-01"

if [[ "${CHECK_NETWORKING}" == "true" ]]; then
  az network vnet show -g "${RG_CORE}" -n "${VNET_NAME}" >/dev/null 2>&1 \
    || fail "VNet not found: ${VNET_NAME}"
  ok "VNet exists: ${VNET_NAME}"

  az network nsg show -g "${RG_CORE}" -n "${NSG_NAME}" >/dev/null 2>&1 \
    || fail "NSG not found: ${NSG_NAME}"
  ok "NSG exists: ${NSG_NAME}"

  # subnet exists + has NSG association
  for SN in "snet-shared" "snet-private"; do
    az network vnet subnet show -g "${RG_CORE}" --vnet-name "${VNET_NAME}" -n "${SN}" >/dev/null 2>&1 \
      || fail "Subnet not found: ${SN}"
    NSG_ID="$(az network vnet subnet show -g "${RG_CORE}" --vnet-name "${VNET_NAME}" -n "${SN}" --query "networkSecurityGroup.id" -o tsv)"
    [[ -n "${NSG_ID}" ]] || fail "Subnet has no NSG associated: ${SN}"
    ok "Subnet OK + NSG associated: ${SN}"
  done
fi

# 10) Identity
# ---- UAMI exists ----
UAMI_NAME="${BASE_NAME}-uami-ops-01"

UAMI_PRINCIPAL_ID=$(az identity show -g "${RG_CORE}" -n "${UAMI_NAME}" --query principalId -o tsv 2>/dev/null) \
 || fail "UAMI not found: ${UAMI_NAME}"
ok "UAMI exists: ${UAMI_NAME}"

# ---- RBAC on subscription (Reader + Monitoring Reader)
az role assignment list --assignee "${UAMI_PRINCIPAL_ID}" --scope "/subscriptions/${SUB_ID}" \
  --query "[?roleDefinitionName=='Reader'] | length(@)" -o tsv | grep -q '^1$' \
  || fail "RBAC missing: Reader on subscription for UAMI"
ok "RBAC OK: Reader on subscription"

az role assignment list --assignee "${UAMI_PRINCIPAL_ID}" --scope "/subscriptions/${SUB_ID}" \
  --query "[?roleDefinitionName=='Monitoring Reader'] | length(@)" -o tsv | grep -q '^1$' \
  || fail "RBAC missing: Monitoring Reader on subscription for UAMI"
ok "RBAC OK: Monitoring Reader on subscription"

echo
ok "VERIFY PASSED"
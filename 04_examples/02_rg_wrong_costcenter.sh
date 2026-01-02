#!/usr/bin/env bash
# Expected: DENY (wrong costCenter value)

az group create \
  -n rg-test-wrong-costcenter \
  -l westeurope \
  --tags owner=cyberweles env=dev costCenter=wrong

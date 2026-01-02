#!/usr/bin/env bash
# Expected: SUCCESS

az group create \
  -n rg-test-correct-tags \
  -l westeurope \
  --tags owner=cyberweles env=dev costCenter=sandbox

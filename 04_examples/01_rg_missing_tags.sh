#!/usr/bin/env bash
# Expected: DENY (missing mandatory tags)

az group create \
  -n rg-test-missing-tags \
  -l westeurope

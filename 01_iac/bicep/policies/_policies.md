# Policies (v1)

This repo uses a minimal governance baseline focused on **mandatory tags**.

## Policy definition
- `require-tag-value.bicep` (+ `require-tag-value.rule.json`)
  - custom policy definition: requires a tag and enforces its expected value
  - effect used in assignments: `Deny`

## Assignments
- `assign-require-tag-value.bicep` assigns the definition at subscription scope:
  - owner = `cyberweles`
  - costCenter = `sandbox`
  - env = `<env>`

## Notes
- Keep the baseline intentionally small (sandbox hygiene).
- Avoid adding more policies unless they are truly baseline-level.

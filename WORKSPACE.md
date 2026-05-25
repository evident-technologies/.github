# .github Org Meta-Repo

## What this repository contains

Organization-level governance artifacts for Evident Technologies:

- Reusable CI workflow templates (`.github/workflows/templates/`)
- Governance drift detection (`.github/workflows/governance-drift.yml`)
- Central version manifest (`versions.json`)
- Org profile and community health files

## How to operate this system

```bash
# Check environment health
./scripts/doctor.sh

# Validate org-level artifacts
./scripts/bootstrap.sh
```

## Architecture

- `.github/workflows/templates/` — reusable workflow templates consumed by other repos
- `.github/workflows/governance-drift.yml` — daily scheduled org governance audit
- `versions.json` — central version governance manifest
- `scripts/` — operational verbs (bootstrap, doctor)

## Boundaries

- This repo does NOT contain product code
- This repo does NOT have a package.json or build step
- Workflow templates are consumed via `uses:` in downstream repos
- Changes to templates have cross-repo blast radius — PR review required
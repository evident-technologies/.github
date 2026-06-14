# Verify

How to confirm this repository is in a healthy operational state.

## Quick verification

```bash
./scripts/doctor.sh
```

## Full verification

```bash
./scripts/bootstrap.sh
```

## Doctor output contract

```
doctor_version=1
git=X.X.X
gh=X.X.X
node=vXX.X.X
git_status=clean|dirty|unavailable
versions_json=present|missing
workflow_templates=N
drift_detection=active|missing
repo_posture=org-governance
```

Exit 0 = healthy: `git`, `gh`, and `node` are present, `git_status=clean`, `versions_json=present`, and `drift_detection=active`. Exit 1 = remediation required.

## Cross-repo impact

Changes to workflow templates or versions.json affect all downstream consumers.
Always check blast radius before merging.
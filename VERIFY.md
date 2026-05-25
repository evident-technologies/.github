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
git_status=clean|dirty
versions_json=present|missing
workflow_templates=N
drift_detection=active|missing
repo_posture=org-governance
```

Exit 0 = healthy. Exit 1 = remediation required.

## Cross-repo impact

Changes to workflow templates or versions.json affect all downstream consumers.
Always check blast radius before merging.
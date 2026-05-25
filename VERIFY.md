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

`doctor.sh` is a diagnostic, non-gating check. Exit 0 means the script ran and produced status output; exit 1 means the script could not complete successfully.
Remediation is determined from the reported fields above (for example: missing `gh` or `node`, `git_status=dirty`, `versions_json=missing`, or `drift_detection=missing`), not from exit 0 alone.

## Cross-repo impact

Changes to workflow templates or versions.json affect all downstream consumers.
Always check blast radius before merging.
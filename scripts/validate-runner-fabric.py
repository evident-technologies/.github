#!/usr/bin/env python3
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
fabric=json.loads((ROOT/"governance/runner-fabric.json").read_text())
admission=json.loads((ROOT/"governance/runner-admission.json").read_text())

if fabric.get("schema_version") != 1 or admission.get("schema_version") != 1:
    raise SystemExit("runner policy schema_version must be 1")

classes=fabric["workload_classes"]
required={"portable","shared_ci","ci_primary_qualification","ci_secondary_qualification","platform_deploy"}
if set(classes) != required:
    raise SystemExit(f"unexpected workload classes: {sorted(set(classes)^required)}")

shared=classes["shared_ci"]["selector"]
for label in ("self-hosted","Linux","X64","evident-ci","ci","no-private-evidence"):
    if label not in shared:
        raise SystemExit(f"shared_ci missing {label}")

for q in ("ci_primary_qualification","ci_secondary_qualification"):
    if classes[q].get("production_authority"):
        raise SystemExit(f"{q} cannot have production authority")

deploy=classes["platform_deploy"]
if deploy.get("exact_runner_identity") != "et-ws-02-deploy":
    raise SystemExit("deploy identity drift")
if deploy.get("repository_allowlist") != ["evident-technologies/platform"]:
    raise SystemExit("deploy repository scope drift")

runner_ids=[r["id"] for r in fabric["runners"]]
if len(runner_ids) != len(set(runner_ids)):
    raise SystemExit("duplicate runner id")
for r in fabric["runners"]:
    if r["id"] != "et-ws-02-deploy" and r.get("production_authority"):
        raise SystemExit(f"CI runner {r['id']} has production authority")

admitted={x["repository"] for x in fabric["self_hosted_repository_admission"]}
desired=set(admission["runner_group_desired_state"]["repositories"])
if admitted != desired:
    raise SystemExit("runner group desired-state repositories differ from fabric admission")

if fabric["default_for_other_repositories"].get("self_hosted_access") is not False:
    raise SystemExit("default repository admission must deny self-hosted")

print("org-runner-fabric-validation: PASS")
print(f"admitted_repositories={len(admitted)} runners={len(runner_ids)} classes={len(classes)}")

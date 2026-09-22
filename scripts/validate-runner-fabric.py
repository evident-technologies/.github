#!/usr/bin/env python3
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
impl=json.loads((ROOT/"governance/runner-fabric.json").read_text())
pointer=json.loads((ROOT/"governance/runner-admission.json").read_text())

if impl.get("schema_version") != 1 or pointer.get("schema_version") != 1:
    raise SystemExit("runner implementation schema_version must be 1")

authority=impl.get("authority",{})
if authority.get("repository") != "evident-technologies/evident-runtime":
    raise SystemExit("Runtime must remain runner desired-state authority")
if authority.get("commit") != "65cc779fb9cc5a3035105184272ca358362e6395":
    raise SystemExit("Runtime runner authority pin drift")
if impl.get("no_local_policy_authority") is not True:
    raise SystemExit(".github must not claim runner desired-state authority")
if pointer.get("local_admission_authority") is not False:
    raise SystemExit(".github admission pointer must be non-authoritative")

shared=impl["workload_selectors"]["org_ci"]
expected=["self-hosted","Linux","X64","evident-ci","ci","no-private-evidence"]
if shared != expected:
    raise SystemExit("org-ci selector drift")

for q in ("ci_primary_qualification","ci_secondary_qualification"):
    selector=impl["workload_selectors"][q]
    if "ci-primary" not in selector and "ci-secondary" not in selector:
        raise SystemExit(f"{q}: qualification label missing")

if "platform-deploy" not in impl.get("production_rule",""):
    raise SystemExit("production reusable-workflow prohibition missing")

print("org-runner-implementation-validation: PASS")
print("authority=evident-technologies/evident-runtime")

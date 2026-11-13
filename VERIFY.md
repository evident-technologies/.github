# Verification

Run these checks from the repository root. They inspect source without installing hooks, dispatching
workflows, publishing packages, or deploying products.

```bash
python3 scripts/validate-runner-fabric.py
python3 scripts/verify-public-source.py
bash -n scripts/ship.sh
git diff --check
```

The public-source verifier checks Markdown destinations, JSON, SVG structure and resource
restrictions, image dimensions, brand manifests and fingerprints, candidate contrast, and
preservation of automation against the recorded reconstruction baseline. Python 3 is required. YAML
checks additionally need PyYAML; unavailable tooling is reported explicitly.

```bash
bash scripts/ship.sh check
shellcheck -S warning scripts/ship.sh
```

The legacy `ship` helper checks changed files. Its regex scanner is incomplete and may print
matching content; run it after a private exposure review. Its `check` subcommand does not commit or
push. See [script behavior](scripts/README.md).

## Markdown style

The repository enables the standard Markdown lint rules with a 100-character prose source limit.
Tables, headings, and code examples are exempt from line length so exact paths and commands remain
usable. This source formatting policy does not assert mobile or assistive-technology conformance.

Run the pinned Markdown linter against the exact public inventory:

```bash
python3 - <<'PYLINT'
import json
import subprocess
from pathlib import Path

audit = json.loads(Path("docs/documentation-audit.json").read_text())
paths = [item["path"] for item in audit["documents"]]
subprocess.run([
    "npx", "--yes", "markdownlint-cli@0.50.0",
    "--config", ".markdownlint.json", *paths,
], check=True)
PYLINT
```

## Manual and provider verification

Inspect rendered Markdown, mobile and desktop wrapping, alternative text, and light/dark assets.
Inspect candidate marks at 16, 24, 48, and 128 pixels. An XML parse does not establish visual
quality, trademark clearance, accessibility conformance, or founder approval.

Check public destinations with bounded requests. Record redirects, forbidden responses, and
inaccessible pages individually. HTTP success proves reachability at that time, not a working form
or product entitlement.

Use `actionlint` where available. Nested workflow templates and archived examples are source
material, not callable top-level entry points. Live runner groups, reusable-workflow access,
environments, and credentials require verification through their authorized owners before
operational enforcement can be claimed.

Record exact commands, revision, failures, skips, and manual limits in the [reconstruction
review](docs/RECONSTRUCTION-REVIEW.md). Missing historical bootstrap, doctor, and version-manifest
files are not prerequisites for the commands above.

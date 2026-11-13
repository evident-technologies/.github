# Organization reconstruction review

Status: review proposal, not publication approval. This change extends the service-focused direction
in [draft PR #28](https://github.com/evident-technologies/.github/pull/28) on its existing branch.
It does not create a competing identity PR. The baseline is
`743fc9ca2136ed0187f2730d5a736ba7fd88bae9`, based on `4ad51c023b4dd87e25d7668708268e4e7423ba7e`.

## Finite acceptance checklist

| Outcome | Evidence and current state |
| --- | --- |
| Inspect every tracked source | 61 baseline files inventoried; all 13 original Markdown documents and every proposed guide individually reviewed |
| Coherent public company scope | Profile, root guide, company/status and service documents distinguish projects from development |
| Preserve governance | Policy differences proposed explicitly; CODEOWNERS, workflow bytes, runner contracts, action pins, and operational scripts retained |
| Original editable identity | Two candidate families and comparison board; fingerprints and approval status recorded |
| Dependency-safe retirement | No assets removed; external consumers and replacement approval remain open |
| Private exposure review | Private baseline audit completed; restricted details excluded from public artifacts; security follow-up required |
| Verification | Exact results recorded below; unavailable visual/provider evidence remains open |
| One review route | Existing PR #28; founder acceptance, final identity choice, and release remain pending |

## Current governance and scope reconciliation

The owner-selected positioning is “Clear systems. Accountable technology.” The current canonical
Kernel differed from the local copy; authenticated current architecture and engineering source was
used for comparison. Private governance records were not published or installed as a new public
constitution. [The complete Markdown audit](DOCUMENTATION-AUDIT.md) records each document's purpose,
classification, treatment, source basis, and acceptance criteria.

The branch-lifecycle and organization reconciliation extension uses a separate private ledger.
Repository discovery uses the current GitHub API, not a historical count. Other repositories receive
no documentation edits through this PR. The current task branch and worktree remain active and must
be retained until the required review, merge, preservation, and cleanup conditions are verified.

## Change scope

[Tracked-source classification](../docs/source-inventory.json) covers the baseline. [Brand source
inventory](../brand/source-inventory.json) preserves asset fingerprints. The profile uses a
typographic company heading while candidate approval is pending. Existing logo files remain at their
paths. No emoji, stock artwork, new remote fonts, or package dependencies are introduced.

[Policy review](POLICY-REVIEW.md) identifies proposed authority-sensitive language changes. Public
prose removes operational examples and unsupported enforcement claims without changing the preserved
source contracts. The [separate scanner PR](https://github.com/evident-technologies/.github/pull/27)
remains independent.

## Verification record

| Check | Result |
| --- | --- |
| `python3 scripts/verify-public-source.py` | PASS: Markdown destinations/headings and audit inventory, JSON, YAML structure, SVG restrictions, PNG headers, manifests, fingerprints, contrast, and preserved source contracts |
| `python3 scripts/validate-runner-fabric.py` | PASS: existing pinned implementation invariants |
| `bash scripts/ship.sh check` | PASS: legacy change-based gates |
| `bash -n scripts/ship.sh` | PASS: shell syntax |
| `shellcheck -S warning scripts/ship.sh` | PASS: existing script |
| `git diff --check` | PASS after removing trailing whitespace |
| Markdown lint | PASS: `markdownlint` v0.50.0, all 21 public Markdown documents, declared 100-character prose policy |
| Adverse verifier fixtures | PASS: eleven cases: valid snapshot and ten rejected failures covering broken links, SVG events, asset drift, workflow drift, missing alt, low contrast with matching hashes, baseline-fingerprint tampering, incomplete baseline and Markdown inventories, and missing owner-selected positioning |
| Public Markdown URLs | PASS: all ten company/repository destinations returned HTTP 200 on November 13, 2026; forms were not submitted |
| Visual source checks | PASS within [documented local rendering limits](VISUAL-REVIEW.md); all 24 SVGs rendered and three PNGs decoded |
| Workflow semantic lint | `actionlint` v1.7.12: PASS on all ten top-level workflows using exact custom labels from the existing contract; FAIL on the full 18-file source set because a preserved nested historical template has shell syntax errors. Diagnostics remain private; source was not weakened or suppressed |
| Private baseline audit | Complete for 61 starting files; security follow-up remains required |
| Organization code search | No external matches returned for three selected asset/package references; incomplete search is not proof of no consumers |
| GitHub desktop/mobile rendering | UNVERIFIED: official external Chrome connection unavailable |
| Live provider observation | Partial read-only observation: main protection and read-default workflow token confirmed; runner-group metadata captured privately. Reusable-access endpoint unavailable. Current Runtime reconciliation, caller credentials, and product environment protections remain UNVERIFIED. No settings changed |

No application build or type-check applies to this documentation-and-vector repository. No live
runner, deployment, or package-publication check is implied. The changed-file manifest is
[change-manifest.json](change-manifest.json).

## Approval and dependency holds

Founder approval must identify a candidate or reject both. Manager review must accept policy
revisions. Before any legacy retirement, review consumers beyond this repository, including cached
URLs, copied assets, package exports, corporate site identity, and provider branding. Public URL
reachability does not establish those dependencies.

Current admission reconciliation, workflow callability, caller credential scopes, and product
environment protections require their existing owners; read-only group metadata is not proof of
every execution boundary. Private security follow-up and GitHub rendered review remain required
before declaring publication readiness.

## Rollback

Retain the baseline revision and source fingerprints. Revert the reconstruction commit through
protected review if needed; no history rewrite is required. No old logo path or CSS variable is
removed, so this proposal does not require a downstream asset migration. A later approved
replacement must record each consumer's prior and new pin and its restoration procedure. Merge,
package release, avatar changes, deployment, and production configuration are outside this review's
execution.

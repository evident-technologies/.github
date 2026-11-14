# Verify source and releases

Verification should identify exactly what was checked and what remains unknown. A matching hash
proves byte identity, not safety, truth, ownership, legal admissibility, or fitness for a particular
use.

## Identify source

Start from the [Evident Technologies organization](https://github.com/evident-technologies) and the
intended repository. Confirm the owner, project, default branch, status, and license. Record a full
commit SHA rather than relying on a mutable branch or tag.

For an existing local checkout, inspect without pulling or resetting:

```bash
git remote -v
git status --short
git rev-parse HEAD
git worktree list
```

Compare the full SHA with the repository's commit page. A GitHub Verified badge concerns the
signature on that commit; it does not certify the product, authorship rights, or the contents of a
downloaded binary.

## Assess a release before use

1. Confirm the release belongs to the intended repository and identify its tag's resolved commit,
   release notes, platform, maturity, supported versions, known limitations, and license.
2. Download only the artifact named by that release. If the publisher supplies a SHA-256 checksum,
   calculate the artifact's digest and compare the exact value and filename using the release's
   instructions. On Fedora, `sha256sum <artifact-file>` computes a digest; `sha256sum -c
<checksum-file>` checks a supplied manifest. Replace placeholders with reviewed filenames.
3. A checksum distributed with the same artifact is not independent authentication. Verify
   signatures against a trusted, independently established key where the release provides them.
4. If the release provides GitHub artifact attestations, use its documented verification command and
   expected repository, workflow identity, and source revision. For example, `gh attestation verify
<artifact-file> --repo <owner/repository>` verifies against the specified repository. Inspect the
   returned source identity and commit; do not assume attestations exist for every release. See
   [GitHub's verification
   instructions](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations).
5. Stop if provenance disagrees or required verification evidence is missing. Report the discrepancy
   privately if it is security sensitive.

Reproducibility is a separate claim. It requires documented inputs, dependencies, toolchain,
environment, build steps, and comparison criteria. Do not claim a reproducible build from a checksum
alone. Hardware and physical deliverables additionally need the applicable inspection, safety, and
acceptance evidence.

## Repository source checks

Run from the repository root; these checks do not publish or deploy:

```bash
python3 scripts/validate-runner-fabric.py
python3 scripts/verify-public-source.py
python3 scripts/test-issue-forms.py
python3 scripts/test-static-shell.py
bash -n scripts/ship.sh
shellcheck -S warning scripts/ship.sh
git diff --check
```

The static-shell regressions validate callable routing, read-only token scope, fixed portable
runners, absence of secret/environment forwarding, and an offline synthetic npm install/lint/build.
They do not attest a deployed product or an unknown downstream caller.

The source verifier checks the public Markdown inventory, headings, relative destinations, JSON,
YAML, SVG restrictions, PNG headers, manifests, fingerprints, contrast, and preserved controls.
The three intentionally revised issue forms have separate field, ID, required privacy-consent,
and private-routing checks. Missing PyYAML is reported, not counted as a pass. Markdownlint 0.50.0
uses `.markdownlint.json` and `docs/documentation-audit.json`; only `img` HTML is allowed for the
existing sized mark. No package installation is required by the commands above.

The existing `ship check` helper is a separate change-based check. Inspect its effects and private
exposure before use; it does not substitute for source checks or permission to commit/push.

## Check this repository

There is no root application package or application build. The active `Validate Governance` workflow
checks that `SECURITY.md`, `WORKSPACE.md`, `VERIFY.md`, `CODE_OF_CONDUCT.md`, and `CONTRIBUTING.md`
exist. That check does not establish legal sufficiency, working email, safe software, or release
approval.

For documentation changes, check Markdown, local links and anchors, existing asset paths, public
destinations, issue-form YAML, and JSON syntax. Compare preserved asset bytes and review the exact
diff for private content. Changes to reusable workflows, action pins, or runner contracts require
additional consumer and policy review.

The older doctor/bootstrap instructions referenced scripts and `versions.json` absent from the
inspected source; do not treat those commands as a current health check. Do not run commit, push,
install, sync, or deployment helpers merely to verify documentation.

Record test versions, commands, results, source SHA, observation time, skipped checks, and
limitations. For CI, include run URL, job ID, assigned runner, conclusion, and failures. Local
success does not replace required protected-branch checks.

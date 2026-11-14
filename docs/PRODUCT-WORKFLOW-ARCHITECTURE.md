# Product and workflow responsibilities

Each product repository owns its source, lockfile, tests, build outputs, release history, deployment
environment, and rollback. This organization repository owns reusable mechanisms and public policy
defaults. It does not own product deployments or grant access to private infrastructure.

## Workflow sources

| Source | Intended role |
| --- | --- |
| `.github/workflows/static-shell.yml` | Callable npm static-build compatibility wrapper; fixed portable runner, read-only token, no secret/environment forwarding |
| `.github/workflows/static-site-ci.yml` | Product-owned install, checks, and build; no deployment |
| `.github/workflows/verify-lint.yml` | Reusable lint entry point |
| `.github/workflows/verify-governance.yml` | Reusable governance source checks; warnings are not enforcement |
| `.github/workflows/security-secret-scan.yml` | Reusable secret-scanner source; qualification tracked separately |
| `.github/workflows/cloudflare-pages-release.yml` | Existing release mechanism requiring separate owner and security qualification |
| `.github/workflows/templates/` | Reference templates; nested files are not callable workflow entry points |
| `.github/workflows/_archive/` | Historical source; not an active top-level workflow |

Callers must use a reviewed full commit SHA. A mutable branch or assumed tag is not a release pin.
No copy-ready production caller is supplied here because its repository, environment, credentials,
and admission must first be qualified.

## Verify before adoption

Inspect the exact workflow revision, inputs, shell interpolation, permissions, dependency
installation, artifact provenance, runner class, and caller trust. Match installation and test
commands to the product's lockfile and package metadata. Never pass production credentials to an
untrusted build.

Read the actual YAML: documentation describes the intended boundary and cannot attest that source or
provider settings enforce it. Reusable-workflow access, required checks, secret availability, and
environment protection are separate qualifications. The [runner boundary](RUNNER-FABRIC.md) remains
controlling for scheduling.

The scanner correction in [draft PR #27](https://github.com/evident-technologies/.github/pull/27) is
a separate change. This identity reconstruction does not duplicate or supersede it.

## Changes and rollback

Before changing a consumer, identify its exact source revision and dependencies, validate synthetic
fixtures, and preserve the prior pin. Product extraction or migration requires its own
authorization, acceptance, and source-to-destination provenance. Merge approval does not authorize
production release.

## Static-shell compatibility entry point

`static-shell.yml` remains a zero-input callable workflow. It now delegates to the existing
`static-site-ci.yml` at the same source revision, using Node.js 22, npm, `npm ci`, `npm run lint`,
`npm run build`, and output `dist/index.html`. The Node.js version and npm commands follow the old
static-app template; the output contract is now explicit. Callers with different requirements
should use the general static-site CI entry point and supply its documented inputs.

The wrapper fixes the runner to `ubuntu-24.04` and permissions to `contents: read`; it forwards no
secrets and selects no deployment environment. Runner admission and the static-site implementation
remain unchanged. No deployed system or private record is needed to verify this routing.

The old nested `templates/static-ci-app.yml` is retained as historical source. It is not a callable
workflow location and its missing version-manifest, monorepo scripts, and deployment placeholder
are not activated. Syntax lint alone did not detect the nested-call restriction; the source guard
and regression tests explicitly reject it. See [GitHub's reusable workflow location
requirements](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows).

# Product and workflow responsibilities

Each product repository owns its source, lockfile, tests, build outputs, release history, deployment environment, and rollback. This organization repository owns reusable mechanisms and public policy defaults. It does not own product deployments or grant access to private infrastructure.

## Workflow sources

| Source | Intended role |
| --- | --- |
| `.github/workflows/static-site-ci.yml` | Product-owned install, checks, and build; no deployment |
| `.github/workflows/verify-lint.yml` | Reusable lint entry point |
| `.github/workflows/verify-governance.yml` | Reusable governance source checks; warnings are not enforcement |
| `.github/workflows/security-secret-scan.yml` | Reusable secret-scanner source; qualification tracked separately |
| `.github/workflows/cloudflare-pages-release.yml` | Existing release mechanism requiring separate owner and security qualification |
| `.github/workflows/templates/` | Reference templates; nested files are not callable workflow entry points |
| `.github/workflows/_archive/` | Historical source; not an active top-level workflow |

Callers must use a reviewed full commit SHA. A mutable branch or assumed tag is not a release pin. No copy-ready production caller is supplied here because its repository, environment, credentials, and admission must first be qualified.

## Verify before adoption

Inspect the exact workflow revision, inputs, shell interpolation, permissions, dependency installation, artifact provenance, runner class, and caller trust. Match installation and test commands to the product's lockfile and package metadata. Never pass production credentials to an untrusted build.

Read the actual YAML: documentation describes the intended boundary and cannot attest that source or provider settings enforce it. Reusable-workflow access, required checks, secret availability, and environment protection are separate qualifications. The [runner boundary](RUNNER-FABRIC.md) remains controlling for scheduling.

The scanner correction in [draft PR #27](https://github.com/evident-technologies/.github/pull/27) is a separate change. This identity reconstruction does not duplicate or supersede it.

## Changes and rollback

Before changing a consumer, identify its exact source revision and dependencies, validate synthetic fixtures, and preserve the prior pin. Product extraction or migration requires its own authorization, acceptance, and source-to-destination provenance. Merge approval does not authorize production release.

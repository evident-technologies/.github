# Evident Organization Runner Fabric

This repository is the organization-level source of truth for **runner classes
and repository admission**. Runtime records desired placement and observed
fleet state; individual repositories define their jobs; this policy defines
which compute classes those jobs may request.

## Core rule

Ordinary CI targets capabilities, not machines:

```yaml
runs-on: [self-hosted, Linux, X64, evident-ci, ci, no-private-evidence]
```

Both `aspire-physical-ci` and `et-ws-02-fabric` belong to that shared pool.
GitHub may schedule an admitted workload on either runner.

The `ci-primary` and `ci-secondary` labels are reserved for qualification,
capacity tests and failover proof. Application workflows should not pin to them.

## Why this is better

- adding/replacing a CI machine does not require rewriting every repository;
- ordinary jobs automatically gain two-node capacity and failover;
- a failed/offline machine reduces capacity instead of changing workflow
  semantics;
- new repositories cannot execute on founder-owned hardware until explicitly
  admitted;
- production authority remains outside the shared CI pool.

## Repository tiers

**Portable/default.** Every repository may use GitHub-hosted runners for safe,
lightweight checks. New repositories start here.

**Self-hosted CI admitted.** Only repositories listed in
`governance/runner-fabric.json` and in the corresponding GitHub runner group
may use the `evident-ci` pool.

**Production deployment.** Production is not a higher CI tier. It is a
different security principal. The current Platform promotion identity is
`et-ws-02-deploy`, exact-name guarded and environment-scoped.

## Runtime relationship

`evident-runtime` owns desired fleet placement, service/provider topology,
costs and recovery. It should import or reference this organization runner
contract rather than invent runner labels independently.

Runtime may say **where** a class is expected to run. It does not grant a
repository permission to schedule on that class.

## Platform relationship

Platform owns build/test/deploy workflows. Credential-free jobs should migrate
toward the shared selector. Runner-specific labels belong only in runner
qualification workflows.

Production workflows must continue to verify exact raw runner identity before
credentials or mutating commands are available.

## Ops relationship

`evident-ops` may observe runner health, reconcile desired/actual admission
and prepare execution receipts. Merely being the operator repository does not
grant it Platform production credentials.

## Fairness and capacity

With two shared CI runners, repositories should use workflow-level concurrency
to collapse superseded work. Long-running/nightly tasks should use explicit
timeouts and should not occupy both qualification lanes by default.

Duplicate execution across primary and secondary is used for qualification, not
for every ordinary CI job. Ordinary CI load-balances across the shared pool.

## Failure behavior

If both self-hosted CI runners are unavailable, jobs requiring the shared pool
remain queued. They do not silently fall back to hosted compute if doing so
would change trust, network, filesystem or cost assumptions.

Portable policy/metadata checks should normally have a GitHub-hosted path so
pull requests can still report meaningful failures while the private fleet is
unavailable.

## Security invariants

- no private evidence on any GitHub Actions runner;
- no production credentials on CI;
- no wildcard or prefix-based deploy authorization;
- no repository gets self-hosted access merely because it exists in the org;
- runner group membership is reconciled against
  `governance/runner-admission.json`;
- secrets remain environment/repository scoped and are never represented by
  value in Git.

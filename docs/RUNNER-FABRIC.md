# Evident Organization Runner Fabric — Workflow Implementation

The canonical **desired-state authority** for runner pools and repository
admission is `evident-technologies/evident-runtime`.

This `.github` repository implements reusable workflow mechanics and safe
organization scheduling defaults. It must not create a second runner-policy
authority.

Pinned Runtime authority for this implementation:

- commit: `65cc779fb9cc5a3035105184272ca358362e6395`
- pools: `inventory/runner-pools.json`
- admission: `inventory/repository-runner-admission.json`

## Scheduling model

Ordinary self-hosted CI is capability-based:

```yaml
runs-on: [self-hosted, Linux, X64, evident-ci, ci, no-private-evidence]
```

Any runner that Runtime admits to the `org-ci` pool may satisfy that job.
Physical host names therefore disappear from ordinary CI workflows.

`ci-primary` and `ci-secondary` are qualification-only labels.

## Defaults

Active repositories default to portable GitHub-hosted CI. Self-hosted access is
allowed only when both conditions are true:

1. Runtime admits the repository to the requested pool.
2. GitHub runner-group access is configured to match that Runtime record.

Neither condition alone is sufficient.

## Production boundary

Production deployment is deliberately **not** exposed as a generic organization
reusable workflow. Platform production remains exact-identity guarded by the
Platform repository and its environment-scoped credentials.

That prevents an otherwise-safe reusable workflow from accidentally turning
repository membership into production authority.

## Capacity behavior

The shared `org-ci` selector lets GitHub load-balance ordinary CI across
`aspire-physical-ci` and `et-ws-02-fabric`.

Dual execution on both machines is reserved for qualification/failover proof;
it is not the default for every test. This preserves capacity and avoids paying
the compute cost of duplicate work without security benefit.

## Failure behavior

Portable policy/metadata checks should remain available even if the private
fleet is offline. Jobs whose trust/tooling/cost assumptions require `org-ci`
queue rather than silently changing execution class.

No GitHub Actions runner may process private evidence.

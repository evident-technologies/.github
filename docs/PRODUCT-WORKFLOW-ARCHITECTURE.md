# Product-Owned Workflow Architecture

## Boundary rule

Each production product repository owns its source, lockfile, tests, build output,
release history, deployment environment, and rollback history.

The organization `.github` repository owns reusable workflow mechanisms and
policy defaults. It does not own product source or product deployment targets.

## Reusable workflows

- `.github/workflows/static-site-ci.yml`
  - verifies one product repository
  - receives product-owned commands and output paths
  - does not deploy
  - does not receive production credentials

- `.github/workflows/cloudflare-pages-release.yml`
  - builds an immutable artifact from the caller repository
  - writes repository-and-commit provenance
  - verifies SHA-256 before publishing
  - deploys under the caller's product environment
  - verifies the served repository, commit, and content marker

## Caller example: CI

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  verify:
    uses: evident-technologies/.github/.github/workflows/static-site-ci.yml@<full-commit-sha>
    with:
      package-manager: pnpm
      install-command: pnpm install --frozen-lockfile --ignore-scripts
      lint-command: pnpm lint
      test-command: pnpm test
      build-command: pnpm build
      output-path: dist
      runs-on: '["self-hosted","aspire","no-private-evidence"]'
```

## Caller example: release

```yaml
name: Release

on:
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  release:
    uses: evident-technologies/.github/.github/workflows/cloudflare-pages-release.yml@<full-commit-sha>
    with:
      target-id: product-id
      cloudflare-project: product-project
      production-url: https://product.example
      verification-path: /
      verification-marker: Product Marker
      output-path: dist
      package-manager: pnpm
      install-command: pnpm install --frozen-lockfile --ignore-scripts
      build-command: pnpm build
      build-runs-on: '["self-hosted","aspire","no-private-evidence"]'
      deploy-runs-on: '["self-hosted","aspire","aspire-physical"]'
      environment: production-product-id
    secrets:
      CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
      CLOUDFLARE_ACCOUNT_ID: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
```

Callers must pin reusable workflows to a reviewed full commit SHA. Product
repositories must not call the mutable `main` ref for production deployment.

## Identity separation

- Matrix5 / repository owner authorizes merges and environment changes.
- Build runners receive source and synthetic fixtures, but no deployment secret.
- The physical deployment runner receives only the immutable release artifact and
  product-scoped deployment credentials.
- Evidence volumes are never available to GitHub Actions.

## Extraction sequence

1. Establish product-owned CI and release callers.
2. Confirm preview and production provenance.
3. Transfer DNS and environment ownership.
4. Remove the product from the platform workspace and deploy manifest.
5. Remove stale shared-package and registry coupling.
6. Preserve a migration record containing source commit and destination commit.

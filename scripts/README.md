# scripts/

Operator scripts for Evident Technologies. This directory currently contains a
single, self-contained tool.

## `ship.sh` — local inner-loop runner (ASPIRE worker)

Commit good changes often, and resolve CI gates **locally** before pushing, so
GitHub Actions becomes a backstop rather than the place you discover problems.

### Purpose
- Surface what changed (tracked + untracked, with sizes).
- Run the same gates GitHub Actions runs, locally.
- Drive a clean conventional commit and a mirror-first push.
- Refuse to push when a gate fails.

### Install
```bash
./scripts/ship.sh install          # adds `ship` alias + a per-repo pre-commit gate hook
sudo apt-get install -y shellcheck # optional: enables the shell-lint gate
```

### Commands
| Command | Action |
|---|---|
| `ship status` | tracked diff + untracked files, sized, >50MB flagged |
| `ship check` | run local CI gates (below); exits non-zero on failure |
| `ship commit` | stage + conventional commit (`-m "<msg>"` or interactive; `-a` stages all) |
| `ship push` | mirror-first push (`mirror` remote if present, then `origin`, with retry) |
| `ship` | `check → commit → push`; aborts on any gate failure |
| `ship deploy` | runs repo-local `./scripts/deploy.sh`; **refuses prod targets** |
| `ship install` | alias + pre-commit gate hook |

### Gates (mirror existing GitHub Actions)
- Secret-bearing **paths** (`.env`, `*.pem`, private keys, `.wrangler/`).
- Secret **patterns** in staged + unstaged diffs **and** untracked files
  (regex kept in lockstep with `.github/workflows/security-secret-scan.yml`).
- Oversized blobs (>50 MB).
- Governance-artifact presence (`SECURITY.md`, `CODE_OF_CONDUCT.md`,
  `CONTRIBUTING.md`) — only enforced when `.github/workflows/validate.yml` exists.
- `shellcheck` on changed `*.sh` (skipped with a warning if not installed).
- `npm run lint` / `npm run build` when the repo declares them.

### Mutation surfaces (what it changes on your machine)
- **`~/.bashrc`** — `ship install` appends one `alias ship=...` line.
- **`<repo>/.git/hooks/pre-commit`** — `ship install` writes a hook that runs
  `ship check` before each commit.
- **Git history of the current repo** — `ship commit` / `ship push` create and
  push commits on the current branch.
- Does **not** use `sudo`, does not modify workflows or branch protection, does
  not touch files outside the current repo (except the `~/.bashrc` alias line).

### Rollback
- Remove the alias: delete the `alias ship=...` line from `~/.bashrc`.
- Remove the hook: `rm <repo>/.git/hooks/pre-commit`.
- Undo a local commit before push: `git reset --soft HEAD~1`.
- `ship` makes no other persistent changes.

### Known limitations
- Secret-pattern matching is regex-based (same patterns as the Actions
  workflow); it is a guardrail, not a guarantee — it will not catch novel or
  obfuscated secret formats.
- The Node lint/build gate only runs when `package.json` declares those scripts.
- `ship deploy` only works if the target repo provides `./scripts/deploy.sh`;
  it hard-refuses `prod`/`production`/`live` targets by policy (the worker has
  no production deploy authority).
- The mirror-first push only pushes to a remote literally named `mirror` if one
  exists; otherwise it pushes `origin` only.

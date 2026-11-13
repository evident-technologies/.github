# Repository workspace

This public repository belongs to Evident Technologies LLC. It contains the organization profile,
community policies, brand source, workflow mechanisms, and runner-governance pointers. Start with
the [repository guide](README.md).

## Source ownership

| Path | Responsibility |
| --- | --- |
| `profile/` | GitHub organization introduction |
| `brand/` | Existing identity assets and unapproved candidates |
| Root policies | Contributions, conduct, disclosure, and inquiry routing |
| `.github/` | Issue forms, CODEOWNERS, review guidance, and Actions source |
| `governance/` | Workflow implementation contracts and authority pointers |
| `docs/` | Company scope and repository responsibilities |
| `scripts/` | Local checking helper and source validators |

Product repositories own their source, dependencies, releases, and rollback. This repository does
not host private client records or product deployments.

## Working safely

Inspect branch, HEAD, worktrees, and dirty paths before editing. Preserve existing work and use the
established Evident lane and checkpoint controls. Keep one worktree, branch, and reviewable PR for
the agreed objective. Review exact paths before staging.

Run [VERIFY.md](VERIFY.md) from the repository root. There is no root application package or
application build. Brand package metadata does not establish package publication.

## Authority boundaries

CODEOWNERS and protected review govern acceptance in this repository. Supported community health
files can supply defaults to repositories without their own file of that type. They do not supply an
inherited license or CODEOWNERS rule. See [GitHub’s default-file
behavior](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file).
Documentation grants no runner access, credentials, environment approval, or deployment permission.
See the [runner boundary](docs/RUNNER-FABRIC.md).

Commit, push, workflow dispatch, merge, and deployment are separate actions. Use only those
authorized for the current task. Keep restricted findings and private operational records outside
Git and public Actions output.

## Human authority and automation

Repository access and authentication do not establish organizational decision authority or access to
a particular resource. Contribution credit does not establish ownership, membership, or release
permission. Models and automation assist only within the permitted scope; they do not approve
consequential actions. A passing build is verification evidence, not release approval.

Founder-reserved decisions use the applicable recorded authorization and review procedure. A
document, checklist, tool result, or unsigned metadata record cannot create authority. Existing
permissions remain bounded by their subject and conditions; changed scope requires a fresh check. No
security control is waived because enforcement is missing or defective.

The corporate architecture direction is one company, one Platform, one Trust Spine, and many
products. Current canonical source was compared privately for this review. Its monorepo-specific
instructions are not copied into this repository as a new constitution. Review proposed policy
changes through the existing owner and protected PR process.

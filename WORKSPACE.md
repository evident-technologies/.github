# Repository workspace

This repository maintains public organization metadata and reusable workflow mechanisms. Product
repositories retain their own application source, dependencies, releases, deployment environments,
and rollback history.

| Path | Contents |
| --- | --- |
| `profile/README.md` | Organization introduction displayed by GitHub |
| `profile/assets/` and `brand/` | Existing identity assets and supporting metadata |
| Root community files | Participation, conduct, security, and inquiry routing |
| `.github/ISSUE_TEMPLATE/` | Public non-sensitive report forms and routing |
| `.github/PULL_REQUEST_TEMPLATE.md` | Review prompts |
| `.github/workflows/` | Workflow mechanisms; callable workflows must use GitHub-supported top-level entry points |
| `governance/` | Runner implementation contracts and Runtime authority pointers |
| `docs/` | Public guidance and workflow documentation |
| `scripts/` | Existing operator helpers; inspect effects before execution |
| `action-pins.json` | Action reference map; see [format and limitations](docs/ACTION-PINS.md) |

## Work safely

Inspect the remote, full commit, branch, dirty paths, registered worktrees, current PRs, and
applicable source instructions before editing. Preserve recovery checkouts and existing writers'
work. Use the established isolated lane for the task and review exact changed paths before staging.
Do not automatically pull, reset, clean, or rewrite history.

Use the [verification guide](VERIFY.md). There is no root application package or application build.
Do not assume `versions.json`, doctor, bootstrap, workspace-sync, or shortcut-install scripts exist.
Workflow files beneath `templates/` are source examples, not callable reusable workflow entry points
at that nested path. Existing workflow documentation requires its own currentness review before
operational use.

## Boundaries

Supported community health files may supply defaults to repositories without their own override.
They do not automatically install instructions, licenses, CODEOWNERS, workflows, or runner
permissions in other repositories. Links to the organization policy use explicit repository URLs so
inherited guidance reaches the intended document.

Runtime owns runner admission and desired state; this repository implements workflow mechanisms and
does not widen admission. Consult current observations and applicable admission before substantial
builds or CI. Keep deployment identities separate from CI and keep private evidence, legal records,
and credentials outside public GitHub and Actions.

A check, document, model, tool response, or ability to access a repository cannot grant authority to
commit, push, merge, dispatch workflows, deploy, change accounts, or handle restricted data. Follow
the authorization and review for the actual task. Preserve rollback and provenance records; resolve
conflicts through the existing owner.

## Human authority and automation

Access, authentication, resource authorization, decision authority, contribution credit, and
ownership are distinct. Models and automation assist within the permitted scope; they do not adopt
policy or approve consequential actions. No control is waived because enforcement is missing or
defective. The company direction remains one Platform, one Trust Spine, and many products; this
public repository does not create another authority system.

# Repository scripts

Run these commands from the repository root. Use these source checks within the existing approved
development lane.

## Source checks

```bash
python3 scripts/validate-runner-fabric.py
python3 scripts/test-runner-contract.py
python3 scripts/verify-public-source.py
bash -n scripts/ship.sh
```

The runner validator checks the pinned local implementation contract. It does not read live
admission or GitHub group settings. The public-source verifier checks documentation, assets,
manifests, contrast, and protected-file preservation. See [VERIFY.md](../VERIFY.md).

The runner-contract regressions require the existing PyYAML test dependency. They execute the
workflow's actual shell qualification steps against synthetic current, legacy, foreign and
deployment identities, plus platform and private-evidence denials. They do not dispatch a job or
attest live runner assignment, group access, admission or deployment authority.

## Legacy ship helper

`scripts/ship.sh` is retained for compatibility. Use its explicit read/check subcommands only within
an authorized lane:

```bash
bash scripts/ship.sh status
bash scripts/ship.sh check
```

`check` examines changed-file paths, bounded secret patterns, file sizes, governance-file presence,
changed shell scripts where ShellCheck is available, and root package scripts where declared. It
does not mirror every Actions workflow or prove repository-wide safety. Matching secret content may
be printed; complete a private review first.

Other subcommands mutate state: `install` edits shell configuration and a Git hook; `commit` may
offer to stage all files; `push` contacts configured remotes; the default command checks, commits,
and pushes. `deploy` invokes a repository deployment script when present. These commands do not gain
authority from their names or local target checks.

Do not use the default command for this reconstruction. Follow exact-path review and separate
authorization for staging, commits, pushes, hooks, and deployment. Preserve existing hooks and
checkpoint work before any approved replacement.

## Tool availability

There is no repository bootstrap or workspace-sync script here. On Fedora, use the existing approved
toolchain and request missing tools through its owner. Do not copy historical package-install
commands or install dependencies merely to make a documentation check appear green.

# Polyglot CI R1

## Purpose and ownership

R1 supplies a reusable verification mechanism and opt-in engineering profiles. Product repositories
retain their source, package manager, dependency graph, test commands, release decisions and
database migration owner. A profile describes a reviewable verification contract; it does not enable
a workflow, admit a runner, provision infrastructure or certify an implementation.

The [profile catalog](../governance/engineering-profiles.json) is advisory data. It is not executed
or used to discover projects automatically. Core means a supported planning priority, not a
requirement to introduce every language into each product. Existing source and maintenance needs
come first.

The callable entry point is
[`polyglot-ci.yml`](../.github/workflows/polyglot-ci.yml).
The existing [runner boundary](RUNNER-FABRIC.md),
[contribution requirements](../CONTRIBUTING.md) and [verification guide](../VERIFY.md) remain applicable.

## Technology taxonomy

| Category | Examples and intended meaning |
| --- | --- |
| General-purpose languages | TypeScript, JavaScript, Python, C#, Rust; Go selectively; Kotlin/Java conditionally; C/C++ for specialized requirements |
| Query and automation languages | SQL for the actual database dialect; Bash for bounded shell workflows |
| Web presentation languages | HTML and SVG markup, and CSS styling; these need rendered and interaction checks as applicable |
| Runtimes and execution targets | Node.js, CPython, .NET, JVM, browsers and native executables; a language choice does not prove runtime compatibility |
| Package/dependency managers | npm, pnpm, uv or an existing pip lock workflow, NuGet, Cargo, Go modules, Gradle/Maven and an existing C/C++ dependency owner |
| Build and check tools | TypeScript compiler, MSBuild, test runners, CMake/Ninja, linters and schema validators |
| Application libraries and frameworks | React is a UI library; Astro, Vue, Svelte, ASP.NET Core, FastAPI and Django occupy application/UI layers with their own contracts |
| Data and infrastructure | PostgreSQL, a managed database service, containers, CI runners and hosting platforms are operational dependencies, not programming languages |
| Contract formats | OpenAPI, JSON Schema and repository-owned data schemas describe interfaces; they do not confer identity or permission |

Select a framework through the owning product's existing architecture and current upstream support.
Do not replace a working service, database, identity contract or package manager to fit a profile.

## Reusable workflow contract

R1 is callable through `workflow_call`; it adds no schedule. A caller pins the reusable workflow to
a reviewed full commit SHA and provides reviewed commands from its own source. GitHub documents
[workflow reuse and permission limits][workflow-reuse].

| Input | Contract |
| --- | --- |
| `platform` | `linux` (default), `windows` or `macos`; maps to `ubuntu-24.04`, `windows-2025` or `macos-15` |
| `node-version`, `npm-version` | Optional exact numeric three-part versions; selecting npm requires an explicit Node version |
| `python-version`, `dotnet-version`, `go-version`, `rust-toolchain` | Optional exact numeric three-part CPython, .NET SDK, Go or stable Rust versions |
| `working-directory` | Existing repository-relative directory; default `.`; must resolve inside the checkout |
| `install-command` | Optional reviewed product installation command; an empty value skips this step |
| `verify-command` | Required product verification command; must produce useful bounded receipts |
| `artifact-path` | Explicit repository-relative output below `artifacts/` or `reports/`; default `artifacts/ci` |
| `artifact-name` | Unique caller-job slug; platform and run attempt are appended |

Commands run in Bash with error and pipeline failure propagation. Product commands must therefore
work in that shell on each selected platform; an OS label alone is not portability evidence. A
subdirectory's command must still write reports to the repository-relative artifact location.
The workflow retains accepted artifacts for seven days, excludes hidden files and rejects symlinks.
The caller must bound output size and sanitize reports before upload.

The workflow uses `contents: read`, does not persist checkout credentials, declares no caller secret
inputs, forwards no deployment environment and provides no deploy or publication operation. The
standard GitHub workflow token still exists with the declared read-only scope. Executable build and
test code is not a sandbox: never construct commands from issue text, PR titles or other untrusted
data. Authentication, dependency egress and package lifecycle scripts still require product review.

Runtime remains the owner of self-hosted admission. R1 accepts only the three fixed GitHub-hosted
classes. Current self-hosted admission is not established by this work, and no machine identity is a
public configuration example.

Python setup does not choose a Python package manager. R1 does not automatically install pnpm, uv,
a JDK, Gradle, CMake, a database, browsers or a container engine. A product must supply and verify
any required tool through its approved installation path. Rust setup requires existing `rustup`,
selects the exact requested stable toolchain and installs rustfmt/clippy. RustSec tooling, if
selected, remains a separately pinned product dependency.

## Version and dependency policy

Choose a supported stable release that matches the product's compatibility needs. Verify support,
maintenance, security advisories and end-of-support dates from upstream before adopting or updating
a pin. Record the observation date and URL. Use release policies such as
[Node.js support][node-support], [.NET support][dotnet-support] and
[PostgreSQL support][postgres-support]; a version listed in this document is not a permanent support
claim.

Pin the resolved runtime, package/build manager and direct check tooling. Preserve the committed
transitive dependency graph. Update pins through a reviewed source change with meaningful
regression evidence; do not select `latest`, wildcard versions or prereleases silently. A numeric
pin's syntax alone does not establish that it exists, is supported or is safe.

Keep each dependency scope's actual manager. A repository can contain npm-owned recipes beside a
pnpm-owned workspace, but the boundaries must be explicit. Do not create a competing lockfile or
regenerate locks during verification. Missing or inconsistent required locks fail admission.
Installation can write its local environment/cache; that does not authorize changing source locks.

| Existing owner | Required reproducibility behavior |
| --- | --- |
| npm | Existing `package.json` and `package-lock.json` or shrinkwrap; `npm ci` fails when the manifest and lock disagree [rather than repairing the lock][npm-ci] |
| pnpm | Existing manifest, applicable workspace file and `pnpm-lock.yaml`; use `pnpm install --frozen-lockfile` [with mismatch failure][pnpm-install] |
| uv | Existing `pyproject.toml` and `uv.lock`; `uv sync --locked` checks consistency; `--frozen` skips that freshness check and is not a substitute [for this gate][uv-locking] |
| Existing pip workflow | Fully pinned, hashed requirements and the existing owner command; do not migrate to uv as a side effect of CI |
| .NET/NuGet | Exact SDK policy in `global.json`, owned solution/projects and deliberately adopted `packages.lock.json`; [restore in locked mode][dotnet-restore] |
| Cargo | `Cargo.toml`, committed `Cargo.lock` and exact stable toolchain; [`--locked` fails on missing or changed resolution][cargo-test] |
| Go modules | Preserve `go.mod`, `go.sum` and any adopted vendor tree; choose module-readonly or vendor mode explicitly, and verify the files remain unchanged [under the owner contract][go-modules] |
| Gradle | Verify the wrapper and distribution checksum; adopt dependency locks and strict dependency verification; do not write new locks in CI [without a reviewed change][gradle-locking] |
| C/C++ | Preserve the existing compiler/build/dependency owner and its pinned graph; use committed configure/build/test [presets where adopted][cmake-presets] |

## Profile selection and meaningful acceptance

The catalog gives concrete command examples with prerequisites. They are templates for an opted-in
product, not assertions that a script or manifest exists in every repository. A product binds each
selected gate to an existing command, complete dependency scope, output directory and expected
test inventory. Missing required tools, fixtures, scripts or test discovery must fail or report
`BLOCKED`; they must not become a successful empty test run.

| Profile | Minimum useful acceptance |
| --- | --- |
| JavaScript/TypeScript | Syntax plus selected compiler/type gates; nonzero discovered behavior tests; required build/export checks; unchanged source locks; a compiler invocation alone is not runtime behavior evidence |
| Python | Declared interpreter/manager and locked dependencies; selected static checks plus actual positive and failure-path tests; no accidental imports from an unrelated environment |
| C#/.NET | Locked restore, build and discovered tests for the owned solution; API/client contract and serialization tests where relevant; record the actual SDK and target framework |
| Rust | Format, clippy, locked build/test selection, integration and documentation tests as applicable; explicit feature sets; no claim that one target qualifies every architecture |
| SQL/PostgreSQL | Real disposable test database with the selected version/extensions; migration replay and history checks; least-privileged role, cross-client denial, session/grant revocation and concurrent stale-write tests |
| Bash | Syntax and lint for an explicit file inventory, then synthetic behavior/exit-code tests; do not run maintenance commands against a workstation or production host as a lint step |
| HTML/CSS/SVG | Markup/style and asset checks, semantic structure, keyboard/focus behavior and applicable rendered layouts; automated checks do not establish complete accessibility conformance |
| Go, selective | Verified module graph, static analysis and discovered tests; race/build targets only where supported and explicitly selected |
| JVM/Kotlin, conditional | Existing JDK/framework need, verified wrapper, dependency locks and tests; R1 adds no automatic JDK setup |
| C/C++, specialized | A concrete native/interoperability requirement, pinned compiler/dependencies, build/tests and applicable sanitizers; unsupported targets remain unqualified |

For SQL, never substitute a production URL or repair the production migration ledger to obtain a
green build. A disposable test service and its credentials are created within the opted-in job.
An embedded emulator or one shared connection does not establish independent PostgreSQL connection,
transaction or concurrent-write behavior. Verify the actual owner migration directory and replay
portability before selecting pending migrations.

### Contract checks

Pin the adopted [OpenAPI][openapi] and [JSON Schema][json-schema] versions and validator/generator
dependencies. Check required fields, unknown-field behavior, serialization limits, generated-source
drift and compatibility expectations. Exercise authenticated operations with valid and invalid
sessions, exact resource grants, another client's denial, revocation and stale revisions. Schema
annotations, organization membership and UI visibility are not authorization evidence.

Contract failures must preserve the rejected input or a safe synthetic reproducer and identify the
failed operation. Report actual response/status and storage effects. A mocked client test does not
replace a server/database boundary test.

### Browser checks

Opt in when the change affects rendered behavior. Use pinned test packages and matching browser
binaries, declared viewport/browser coverage, synthetic data and a bounded test-server lifetime.
[Playwright's CI guidance][playwright-ci] distinguishes dependency/browser installation from test
execution. Keep the selected package manager; do not fetch an unpinned fallback test runner.

Assert navigation, keyboard order, focus recovery, invalid/error/loading states and the affected
responsive layout. Inspect actual browser zoom if claiming zoom qualification. Retain sanitized
screenshots or traces only where useful, within artifact limits. Browser presence, a screenshot or a
static HTML export alone is not a passing user workflow.

### Containers and security

A container profile requires an actual container-capable selected runner, reviewed build context,
pinned base image, test-only network/storage and image-level smoke tests. Use build/test operations
without registry credentials or pushing. [Docker's CI examples][docker-ci] also include publication
paths; those are outside R1. A successful image build is not a deployed service check.

Security checks are selected by the product's risk: secret detection, dependency advisories, static
analysis, authorization regression tests and container inspection where applicable. Pin tools and
record rules/advisory-database versions, scope, freshness, network disclosure and exceptions.
Scanner failure or missing coverage is not “no vulnerabilities.” Keep detailed private findings
out of public logs; report bounded summaries and existing private disclosure routes.

Private CodeQL entitlement is unverified. [GitHub's code-scanning terms][code-scanning] distinguish
public use and licensed private use. R1 neither enables a paid feature nor grants
`security-events: write`. Any CodeQL or SARIF-upload adoption needs its own verified entitlement,
scope, permissions and owner workflow.

## Execution evidence

Each opted-in caller records its product scope, exact source/toolchain pins and selected targets
in its own repository. Keep private inventory and detailed run evidence within that product's
approved audience. This public catalog asserts no executed language or platform qualification.

Exact local/CI receipts establish what actually ran. Adding a setup input or documenting a profile
is not qualification. Tests, type checks, compiled artifacts and their execution retain distinct
evidence.

A useful receipt records the event and checked-out commits, PR head/base when relevant, selected
profile/platform, actual tool versions, manifest/lock digests before and after, exact command and
exit status, test counts, skipped/blocked checks and artifact digests. An overall pass requires all
selected required gates to pass. Cleanup, cancelled tests or a failed command must not overwrite a
failure with a successful receipt. Local and hosted runs are separate observations.

## Cadence and adoption

Cadence is chosen explicitly by each product owner with a cost and data budget. This catalog and
the reusable workflow enable no nightly, weekly or monthly jobs.

| Owner-selected occasion | Possible bounded work |
| --- | --- |
| Relevant change/PR | Selected syntax/type checks, unit/contract regressions and the affected build |
| Explicit extended run | Browser matrix, real database integration, container smoke or additional OS/architecture coverage |
| Optional recurring review | Dependency/support review and security-database refresh with a named owner and time budget |
| Optional periodic recovery review | Restore/replay, clean rebuild and artifact provenance comparison in disposable environments |

Start with the smallest relevant profile, pin the reusable workflow's reviewed full SHA, and retain
the product's current test/build entry points. Confirm the expected tests really run and prove a
representative failure propagates before making a new check required. Branch protection, CI
entitlement, runner admission and production release remain separate owner-controlled settings.

[workflow-reuse]: https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations
[node-support]: https://nodejs.org/en/about/previous-releases
[dotnet-support]: https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core
[postgres-support]: https://www.postgresql.org/support/versioning/
[npm-ci]: https://docs.npmjs.com/cli/v11/commands/npm-ci/
[pnpm-install]: https://pnpm.io/cli/install
[uv-locking]: https://docs.astral.sh/uv/concepts/projects/sync/
[dotnet-restore]: https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-restore
[cargo-test]: https://doc.rust-lang.org/cargo/commands/cargo-test.html
[go-modules]: https://go.dev/ref/mod
[gradle-locking]: https://docs.gradle.org/current/userguide/dependency_locking.html
[cmake-presets]: https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html
[openapi]: https://spec.openapis.org/oas/latest.html
[json-schema]: https://json-schema.org/specification
[playwright-ci]: https://playwright.dev/docs/ci
[docker-ci]: https://docs.docker.com/build/ci/github-actions/
[code-scanning]: https://docs.github.com/en/code-security/concepts/code-scanning/code-scanning

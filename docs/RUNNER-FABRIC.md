# Runner governance boundary

This repository implements organization workflow mechanisms. The existing Runtime owner remains the
desired-state authority for runner pools and repository admission. The local [implementation
contract](../governance/runner-fabric.json) and [authority
pointer](../governance/runner-admission.json) record the pinned source; they do not grant access.

## Scheduling and admission

Portable GitHub-hosted CI is the default for active repositories. Self-hosted execution requires
both current Runtime admission for the requested pool and matching GitHub runner-group access.
Neither a label, organization membership, a copied template, nor this document grants admission.

Ordinary admitted CI uses the shared capability selector. Qualification selectors are reserved for
qualification and failover checks. Physical machine identity is not a public workflow example or an
authorization mechanism.

## Production separation

CI identity and deployment identity remain separate. Generic organization workflows must not expose
production execution to arbitrary callers. Product owners retain responsibility for exact repository
identity, protected environments, product-scoped credentials, approvals, immutable artifacts, and
rollback.

Source files alone cannot prove current GitHub group access or environment protections. Verify those
controls through their existing owners before execution. Private evidence is never an Actions
workload.

## Observations and failure behavior

Runner observations are sampled. Idle means available capacity; stale or missing observations mean
unknown. Do not infer complete fleet utilization or queue coverage. Record repository, immutable
revision, workflow/run URL, job ID, assigned runner, result, and blockers for actual CI work.

Portable metadata checks may run without private fleet access. Workloads requiring an admitted
execution class must queue or hold rather than silently change class. This public repository creates
no automatic dispatch loop, enrollment authority, or duplicate runner controller.

Run the [source validator](../scripts/validate-runner-fabric.py) to check the pinned implementation
contract. A pass proves those local invariants only, not live policy enforcement.

[GitHub runner-group
policies](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/manage-access)
are separate from community defaults. Verify their current configuration rather than inferring
access from repository documentation.

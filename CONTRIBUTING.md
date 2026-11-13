# Contributing

**Owner:** Evident Technologies LLC. **Status:** Proposed revision for Manager review; the published
policy and signed agreements remain controlling until adopted.

## Participation and authorization

External code contributions are not accepted. Do not submit unsolicited implementations or
confidential material. Non-sensitive defects and bounded proposals may use the receiving
repository's issue forms. A report does not authorize implementation, promise compensation, or
establish employment, access, or ownership.

Authorized contributors must have the agreements required by the published policy before committing
work: an NDA, an intellectual property assignment agreement, and a contractor or employment
agreement with indemnification. The actual signed agreements govern ownership, scope, compensation,
responsibilities, and liability; this guide does not supply or amend them. Direct engagement
inquiries to [hello@evidtech.com](mailto:hello@evidtech.com).

Read the receiving repository's current instructions, contribution terms, and license. A permissive
dependency license does not open company-owned material for contributions, and this default does not
override component rights or an expressly adopted repository-specific contribution policy.

## Before changing source

1. Inspect the remote, exact commit, branch, working changes, other worktrees, and existing PRs.
   Preserve original history and other writers' work. Use the established isolated lane for the agreed
   task.
2. Confirm authorization and review requirements for the exact paths and actions. CODEOWNERS
   identifies requested reviewers; technical access is not approval to merge, release, deploy, or
   change permissions.
3. Keep case records, personal information, credentials, privileged materials, and private
   infrastructure outside public GitHub and Actions. Use synthetic fixtures. Do not upload customer
   material as a reproduction.
4. Preserve documented determinism requirements. The published policy requires identical output from
   identical input in analysis pipelines. Do not narrow that requirement through editorial changes;
   identify conflicts or exceptions for explicit Manager review.
5. Obtain explicit written Manager approval before bypassing hash verification, audit logging,
   custody controls, or evidence-integrity contracts. Obtain the required approval for Lumen prompt
   templates, payment configuration, production database migrations, or CI/CD definitions.
6. Describe what changed, why, downstream effects, tests actually run, limitations, and recovery
   steps. Use [verification
   guidance](https://github.com/evident-technologies/.github/blob/main/VERIFY.md) and the PR template.
   Mark inapplicable checks honestly.

## Rights, attribution, and dependencies

Submit only material you are authorized to contribute under the applicable signed agreements.
Identify original authors, upstream URLs and exact revisions, licenses, required notices,
modifications, and any restrictions. Disclose material AI assistance and verify its outputs,
citations, dependencies, and rights before submission. AI output is not proof of authorship or
clearance.

Do not remove copyright or attribution notices or claim company ownership of third-party work. Do
not introduce a new license, assignment, CLA, or rights waiver through a checkbox or PR description.
Resolve incompatible or unclear terms before inclusion. See [licensing
guidance](https://github.com/evident-technologies/.github/blob/main/docs/LICENSING.md).

## Reports and review

Report vulnerabilities privately under
[SECURITY.md](https://github.com/evident-technologies/.github/blob/main/SECURITY.md). For other
private matters use
[SUPPORT.md](https://github.com/evident-technologies/.github/blob/main/SUPPORT.md). Public issues
may describe non-sensitive defects and proposals where permitted, using an exact revision and
synthetic examples. Review and response timing are discretionary.

Follow the [Code of
Conduct](https://github.com/evident-technologies/.github/blob/main/CODE_OF_CONDUCT.md). Keep fixes
focused and preserve provenance. Passing checks provide evidence for review; acceptance and
consequential actions require their own authorized process.

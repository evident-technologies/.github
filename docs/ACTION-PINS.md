# Action pins: observed format and limitations

The existing `action-pins.json` is retained byte for byte. Its observed format is a JSON object
mapping action identifiers to objects containing `sha` and `tag` strings. There are 18 entries. Each
observed SHA is 40 lowercase hexadecimal characters.

No formal JSON Schema, updater, or executable consumer of this file was found in the inspected
repository. Several workflow comments say actions are pinned according to the manifest, but a
comment is not enforcement. The map must not be described as a lockfile automatically applied by
GitHub or a verified organization-wide allowlist.

The SHA in each workflow's `uses:` line determines the action actually selected. Compare those lines
with the manifest when reviewing a workflow. A tag is a human-readable reference and may move;
confirm its resolved upstream commit and action path before updating it. A valid SHA format alone
proves neither that a commit exists nor that its code is appropriate.

Seven action identifiers have workflow references differing from the manifest: `actions/checkout`,
`actions/setup-node`, `pnpm/action-setup`, `actions/attest-build-provenance`,
`actions/upload-artifact`, `actions/download-artifact`, and `cloudflare/wrangler-action`. The
`codeql-action/*` keys need namespace/path review before treating them as GitHub action identities.
Some manifest entries are unused here. These are review questions, not grounds to invent new keys or
rewrite workflows during a public documentation refresh.

Any later machine validator or schema needs an explicit consumer contract, owner review, migration
plan, and consumer tests. This proposal adds documentation only and does not claim upstream pins
were upgraded or security-audited.

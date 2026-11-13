# Security policy

**Owner:** Evident Technologies LLC, New Jersey, United States.

**Revision status:** Editorial modernization proposed for Manager review. Reporting boundaries and
disclosure targets are retained from the policy effective June 12, 2026.

## Scope

This policy applies to public repositories and software surfaces maintained by Evident Technologies
LLC. Current public and production-facing surfaces are eligible for reporting. Older prototypes,
archives, experiments, and generated artifacts may not receive active remediation unless they affect
a current surface. If uncertain, report privately.

Public documentation does not disclose private architecture, provider configuration, deployment
topology, credentials, client information, or operational runbooks. Repository visibility is not
authorization to test private systems.

## Report privately

Send reports to [security@evidtech.com](mailto:security@evidtech.com) with the subject `[SECURITY]`
and a brief description. GitHub private vulnerability reporting may also be used where enabled. The
company does not operate a public bug bounty.

Do not report vulnerabilities through public issues, PRs, discussions, social media, public
comments, or public proof-of-concept releases.

Include the affected surface and revision, safe reproduction steps, potential impact, and contact
details if follow-up or credit is desired. Screenshots, logs, and proofs of concept can help, but do
not send credentials, private keys, client records, personal information, privileged material, or
third-party data. Describe sensitive circumstances at a high level first and wait for transfer
instructions.

## Research boundaries

- Do not access, copy, retain, modify, delete, or disclose another party's data.
- Do not bypass authorization beyond minimal proof-of-concept verification.
- Do not perform denial-of-service, social engineering, or physical testing.
- Do not exfiltrate credentials, secrets, records, or files.
- Do not test third-party systems without written authorization.
- Do not interfere with production, users, investigations, legal matters, or records under review.
- Do not publish exploit details before coordinated remediation.

If sensitive data is encountered accidentally, stop, do not retain or share it, and report what
happened through the private security address.

## Coordinated disclosure

Reports are triaged according to severity, exploitability, affected surface, exposure, and impact on
integrity, confidentiality, availability, or trust.

| Step | Good-faith target |
| --- | --- |
| Acknowledge receipt | Within 3 business days |
| Initial triage | Within 10 business days |
| Remediation plan or status | As appropriate to severity and complexity |
| Public disclosure | After remediation or an agreed timeline |

These targets are not guaranteed deadlines. Changes affecting records, identity, access controls, or
audit history may require additional time. Private workspaces, authentication, authorization,
sessions, credentials, cross-tenant or cross-workspace exposure, record integrity, exports, review
history, personal information, and public disclosure of private operational details may require
heightened handling.

Do not disclose a vulnerability publicly until the company confirms remediation or agrees to a
timeline. Disclosure may be delayed to protect users, records, infrastructure, and remediation work.

## Safe harbor

Evident Technologies LLC does not intend to pursue legal action against researchers who act in good
faith and comply with this policy. Good-faith research means reporting privately and promptly,
avoiding access to or retention of another party's data, avoiding disruption, limiting exploitation
to necessary verification, and allowing a reasonable opportunity to investigate and remediate before
public disclosure.

Safe harbor does not apply to malicious activity, extortion, unauthorized data access or retention,
disclosure before coordination, service disruption, social engineering, or activity outside this
policy's boundaries.

## Contact and terms

Security: [security@evidtech.com](mailto:security@evidtech.com). Legal notices:
[legal@evidtech.com](mailto:legal@evidtech.com). Other inquiries:
[operations@evidtech.com](mailto:operations@evidtech.com).

This policy provides no legal advice, representation, forensic certification, evidentiary guarantee,
court-acceptance guarantee, or professional-service commitment. It creates no attorney-client,
professional-services, fiduciary, employment, or contractor relationship and no entitlement to
compensation.

The company may revise this policy. The version in the relevant repository's default branch is the
published version. Proposed editorial changes and policy questions appear in the [policy
review](docs/POLICY-REVIEW.md).

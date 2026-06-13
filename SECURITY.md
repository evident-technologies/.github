# Security Policy — Evident Technologies LLC

**Effective Date:** 2026-06-12
**Governing Entity:** Evident Technologies LLC, a New Jersey Limited Liability Company

---

## Purpose

Evident Technologies LLC builds software for accountable records, evidence organization, chronology review, provenance tracking, and operational integrity.

Security reports are handled through private, coordinated disclosure.

This policy exists to provide a clear reporting path without exposing internal architecture, deployment details, provider choices, client data, operational workflows, or security controls.

---

## Scope

This policy applies to public repositories and software surfaces maintained by Evident Technologies LLC.

Public materials may reference Evident Technologies products, documentation, demonstrations, and related software surfaces. Specific implementation details, service wiring, deployment topology, provider configuration, private workflows, security controls, and operational runbooks are intentionally not disclosed in this policy.

When in doubt, report privately first.

---

## Reporting a Vulnerability

Evident Technologies LLC does not operate a public bug bounty program.

Security vulnerabilities should be reported privately.

**Email:** `security@evidtech.com`
**Subject:** `[SECURITY] <brief description>`

If GitHub private vulnerability reporting is enabled for a repository, it may also be used. Otherwise, use the email above.

Do **not** report security vulnerabilities through public GitHub issues, pull requests, discussions, social media posts, public comments, or public proof-of-concept releases.

---

## What to Include

A useful report should include:

* A brief description of the issue
* The affected repository, URL, package, or product surface
* Steps to reproduce, if safe to provide
* Potential impact
* Screenshots, logs, or proof-of-concept details where appropriate
* Your contact information if you want follow-up or credit

Do not include secrets, private keys, tokens, client records, personal data, privileged material, or third-party data in the report unless absolutely necessary to explain the issue.

If sensitive material is involved, describe the situation at a high level first and wait for instructions.

---

## Research Boundaries

Do not:

* Access, copy, retain, modify, delete, or disclose data that is not yours
* Attempt to bypass authorization beyond minimal proof-of-concept verification
* Perform denial-of-service testing
* Perform social engineering
* Perform physical security testing
* Exfiltrate secrets, tokens, credentials, records, or files
* Test third-party systems without written authorization
* Publish exploit details before coordinated remediation
* Interfere with production systems, active users, investigations, legal matters, or records under review

If you accidentally access sensitive data, stop immediately, do not retain or share it, and report what happened to `security@evidtech.com`.

---

## Coordinated Disclosure

Evident Technologies LLC follows a private, coordinated disclosure process.

Good-faith reports will be reviewed and triaged based on severity, exploitability, affected surface, exposure, and potential impact to record integrity, confidentiality, availability, or user trust.

Expected process:

| Step                              | Target                                    |
| --------------------------------- | ----------------------------------------- |
| Acknowledge receipt               | Within 3 business days                    |
| Initial triage                    | Within 10 business days                   |
| Remediation plan or status update | As appropriate to severity and complexity |
| Coordinated public disclosure     | Only after remediation or agreed timing   |

These are good-faith targets, not guaranteed deadlines.

Some issues may require additional time to remediate safely, especially where changes could affect records, audit history, identity, access control, or operational integrity.

---

## Sensitive Issue Categories

Some reports may require heightened handling even if they do not fit neatly into a standard severity score.

Examples include:

* Unauthorized access to private records or restricted workspaces
* Weaknesses affecting authentication, authorization, or session handling
* Exposure of secrets, tokens, credentials, or private configuration
* Integrity issues affecting source records, derived records, logs, exports, or review history
* Cross-tenant or cross-workspace data exposure
* Unsafe handling of personally identifiable information
* Public disclosure of private operational details

Reports in these categories should be submitted privately and handled with extra care.

---

## Safe Harbor

Evident Technologies LLC does not intend to pursue legal action against researchers who act in good faith and comply with this policy.

Good-faith research means:

1. You report the issue privately and promptly
2. You avoid accessing or retaining data that is not yours
3. You do not disrupt systems or users
4. You do not exploit the issue beyond what is necessary to verify it
5. You give Evident Technologies LLC a reasonable opportunity to investigate and remediate before public disclosure

This safe harbor does not apply to malicious activity, extortion, unauthorized data access, data retention, public disclosure before coordination, disruption of services, social engineering, or activity outside the boundaries of this policy.

---

## Supported Surfaces

The current public and production-facing software surfaces maintained by Evident Technologies LLC are eligible for security reporting.

Older prototypes, archived materials, dormant experiments, generated artifacts, and historical references may not receive active remediation unless they affect a current public or production-facing surface.

If you are unsure whether something is supported, report it privately.

---

## Public Disclosure

Do not publicly disclose a vulnerability until Evident Technologies LLC has confirmed remediation or agreed to a disclosure timeline.

Public disclosure may be delayed where immediate publication could expose users, records, infrastructure, or ongoing remediation efforts to unnecessary risk.

---

## Contact

| Channel              | Address                                                     |
| -------------------- | ----------------------------------------------------------- |
| Security disclosures | [`security@evidtech.com`](mailto:security@evidtech.com)     |
| Legal notices        | [`legal@evidtech.com`](mailto:legal@evidtech.com)           |
| General inquiries    | [`operations@evidtech.com`](mailto:operations@evidtech.com) |

---

## Legal Notice

Evident Technologies LLC is a software company.

Nothing in this policy constitutes legal advice, legal representation, forensic certification, evidentiary guarantees, court acceptance guarantees, or professional services.

This policy does not create an attorney-client relationship, professional-services relationship, fiduciary relationship, employment relationship, contractor relationship, or entitlement to compensation.

Evident Technologies LLC may revise this policy at any time.

The current version is the version published in the default branch of the relevant repository.

---

<p align="center">
  <sub>
    Evident Technologies LLC · New Jersey, United States
  </sub>
</p>

<p align="center">
  <sub>
    Private reports. Coordinated fixes. No public exploit theater.
  </sub>
</p>

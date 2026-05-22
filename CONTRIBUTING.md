# Contributing to Evident Technologies

**Effective Date:** 2026-05-22
**Governing Entity:** Evident Technologies LLC, a New Jersey Limited Liability Company
**Policy Owner:** Devon Tyler Barber, Manager

---

## This Is a Proprietary Platform

Evident Technologies LLC operates a **closed, proprietary software platform** for court-grade evidence processing and legal-technology services. The repositories under this organization are the exclusive intellectual property of Evident Technologies LLC.

**External contributions are not accepted.** This organization does not operate as an open-source project. Pull requests, issues, and forks from parties not under a signed agreement with Evident Technologies LLC will be closed without review.

This policy is not a courtesy — it is a legal and forensic integrity requirement. See the reasoning below.

---

## Why Contributions Are Restricted

### Forensic Integrity

Evident ICU processes evidence that may be introduced in litigation, administrative proceedings, and criminal defense. Every line of code that touches the evidence pipeline, hash verification, chain-of-custody logging, or audit trail must be traceable to an identified, vetted, and contractually bound individual.

Unvetted contributions create:

- Unauditable code lineage — a defense attorney's first target
- Potential nondeterminism in evidence processing — grounds for admissibility challenge
- IP ownership ambiguity — a material defect in any insurance, financing, or acquisition transaction

### Intellectual Property Chain of Title

All work product in this codebase must vest unambiguously in Evident Technologies LLC. Contributions from parties without a signed IP assignment agreement create partial ownership claims that cloud title and impair the LLC's ability to:

- Obtain professional liability (E&O) and cyber liability insurance
- Raise debt or equity financing
- Execute licensing or acquisition agreements

---

## Who May Contribute

Contributions are accepted exclusively from individuals who have executed **all three** of the following agreements with Evident Technologies LLC prior to any commit:

| Agreement                                                  | Purpose                                                                                                                                   |
| ---------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| **Non-Disclosure Agreement (NDA)**                         | Protects confidentiality of source code, client data, case strategy, and proprietary methodology                                          |
| **Intellectual Property Assignment Agreement**             | All work product, inventions, and improvements created during the engagement vest in Evident Technologies LLC on creation, not on payment |
| **Contractor / Employment Agreement with Indemnification** | Establishes scope, compensation, and personal liability protection under the LLC umbrella                                                 |

Engagement without these agreements signed is not authorized. Code committed without these agreements signed is a violation of the contributor's obligations and does not create ownership or compensation rights.

### How to Inquire

If you are a developer, attorney, or consultant interested in a formal engagement:

**Email:** `hello@evidtech.com`
**Subject:** `Contributor Inquiry — [Your Name / Firm]`

Inquiries are reviewed at the Manager's discretion. Evident Technologies LLC is under no obligation to enter into an engagement with any party.

---

## Reporting Bugs and Issues

### Security Vulnerabilities

Do not open public issues for security findings. See [SECURITY.md](./SECURITY.md) for the coordinated disclosure process.

### Non-Security Issues

If you are a **licensed client** of Evident ICU and have encountered a product defect:

- Contact your account representative, or
- Email `support@evidtech.com` with reproduction steps and your account identifier

If you are a member of the public and have identified a defect in a publicly accessible surface, you may open a GitHub issue with the `[bug]` label. Issues that reveal internal implementation details, case data, or proprietary logic will be immediately closed and the reporter notified.

---

## Authorized Contributor Obligations

Authorized contributors (those with signed agreements) must additionally:

1. **Never commit case data, PII, or privileged materials** — even as test fixtures or comments
2. **Never disable or bypass hash verification, audit logging, or chain-of-custody controls** without the Manager's explicit written approval
3. **Never introduce nondeterministic processing** in any pipeline stage — all analysis must produce identical output from identical input
4. **Follow the coding standards** documented in `_ai/CONVENTIONS.md` within the relevant repository
5. **Obtain approval before modifying** Lumen prompt templates, Stripe product configuration, Supabase migrations in production, or CI/CD pipeline definitions
6. **Report security concerns** to `security@evidtech.com` — not to the general issue tracker

Violation of any of these obligations is grounds for immediate termination of the engagement and may give rise to legal liability.

---

## No License Granted

Nothing in this repository, its documentation, or any communication from Evident Technologies LLC constitutes a license to use, reproduce, modify, distribute, sublicense, or create derivative works from any code, content, or intellectual property in this organization.

Viewing this repository does not grant any rights. Forking this repository does not grant any rights. The presence of code in a public repository does not constitute a dedication to the public domain.

---

## Contact

| Channel              | Address                                                 |
| -------------------- | ------------------------------------------------------- |
| General inquiries    | [`hello@evidtech.com`](mailto:hello@evidtech.com)       |
| Security disclosures | [`security@evidtech.com`](mailto:security@evidtech.com) |
| Legal matters        | [`legal@evidtech.com`](mailto:legal@evidtech.com)       |

---

_This policy is subject to revision. The current version is the version published in the default branch of this repository. Nothing herein constitutes legal advice._

---

<div align="center">

<img src="https://raw.githubusercontent.com/Evident-Technologies/.github/main/profile/assets/evident-mark.svg" alt="Evident Technologies" width="56" height="56" />

**Evident Technologies LLC** — New Jersey, United States

_Court-grade evidence processing for everyone._

[evidtech.com](https://evidtech.com) · [evident.icu](https://evident.icu) · [@Evident-Technologies](https://github.com/Evident-Technologies)

</div>

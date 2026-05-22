# Security Policy — Evident Technologies LLC

**Effective Date:** 2026-05-22  
**Governing Entity:** Evident Technologies LLC, a New Jersey Limited Liability Company  
**Policy Owner:** Devon Tyler Barber, Manager

---

## Scope

This policy applies to all software, infrastructure, APIs, and services operated by Evident Technologies LLC, including but not limited to:

- **Evident ICU** — court-grade eDiscovery and evidence processing platform (`evident.icu`, `evident-icu.com`)
- **Evident Desktop** — .NET MAUI desktop client
- **Satellite applications** — civic and legal-tech tools hosted under the Evident Technologies umbrella
- All supporting infrastructure: authentication, billing, storage, CI/CD pipelines, and third-party integrations

---

## Reporting a Vulnerability

Evident Technologies operates a **private, coordinated disclosure** program. We do not operate a public bug bounty.

### How to Report

Submit all security vulnerability reports to:

**Email:** `security@evidtech.com`  
**Subject line:** `[SECURITY] <brief description>`

Encrypt sensitive reports using our PGP key (available on request).

**Do not** open a public GitHub issue, pull request, or discussion thread for any security finding. Public disclosure before remediation may compromise active legal proceedings, evidence integrity, or client data.

### What to Include

A high-quality report includes:

- Description of the vulnerability and affected component
- Steps to reproduce (proof of concept if applicable)
- Potential impact assessment
- Your name and contact information (optional but appreciated)
- Whether you are a security researcher, client, or other party

---

## Response Commitments

| Milestone | Target SLA |
|-----------|-----------|
| Acknowledgment of receipt | 48 business hours |
| Initial severity assessment | 5 business days |
| Remediation timeline communicated | 10 business days |
| Critical (CVSS ≥ 9.0) patch deployed | 7 calendar days |
| High (CVSS 7.0–8.9) patch deployed | 30 calendar days |
| Medium / Low | Scheduled release cycle |
| Disclosure coordination with reporter | Before any public statement |

These timelines represent good-faith targets. Complex vulnerabilities affecting evidence integrity or chain of custody may require additional time to remediate without disrupting active legal matters.

---

## Evidence Integrity — Heightened Sensitivity

Evident ICU is deployed in legal proceedings. A subset of vulnerabilities carry heightened severity beyond standard CVSS scoring:

| Category | Examples | Heightened Risk |
|----------|----------|-----------------|
| **Chain of custody tampering** | Hash manipulation, audit log injection | May render evidence inadmissible |
| **Evidence file mutation** | Bypass of immutability controls | Forensic defensibility compromised |
| **Unauthorized case access** | Auth bypass, IDOR across cases | Attorney-client privilege breach |
| **Audit log suppression** | Log deletion, log forgery | Due process violation |
| **PII / case data exfiltration** | Client names, docket numbers, legal strategy | OPRA / attorney ethics exposure |

Reports in these categories will be treated as **Critical priority** regardless of CVSS score and escalated to legal counsel immediately upon verification.

---

## Out of Scope

The following are explicitly out of scope for this security program:

- Denial-of-service attacks against production systems
- Social engineering of Evident Technologies staff or contractors
- Physical security testing
- Automated scanning without prior written authorization
- Testing against systems you do not own or have explicit written permission to test
- Accessing, modifying, or retaining any client case data encountered during research

Researchers who access client case data during testing must immediately cease testing, not retain any data, and report the access to `security@evidtech.com` as part of their disclosure.

---

## Legal Safe Harbor

Evident Technologies LLC will not pursue legal action against security researchers who:

1. Discover and report vulnerabilities in good faith under this policy
2. Do not access, retain, or disclose client case data, PII, or privileged legal materials
3. Do not disrupt production services or ongoing legal proceedings
4. Do not exploit vulnerabilities beyond proof-of-concept verification
5. Provide Evident Technologies a reasonable opportunity to remediate before any public disclosure

This safe harbor does not extend to researchers who violate items 1–5 above, or to malicious actors, competitors, or parties engaged in active litigation with Evident Technologies LLC or its clients.

---

## Supported Versions

| Product | Supported |
|---------|-----------|
| Evident ICU (current production) | ✅ |
| Evident ICU (prior minor release) | ✅ Security fixes only |
| Evident ICU (older releases) | ❌ Upgrade required |
| Evident Desktop (current release) | ✅ |
| Satellite apps (current deployment) | ✅ |

---

## Data Handling

Evident Technologies processes data that may include:

- Legal case documents and evidentiary materials
- Body-worn camera footage and metadata
- Attorney work product and privileged communications (via client uploads)
- Personally identifiable information of parties to litigation

All security disclosures that involve client data will be handled in accordance with applicable New Jersey and federal law, including notification obligations where required.

---

## Contact

**Security disclosures:** `security@evidtech.com`  
**General inquiries:** `hello@evidtech.com`  
**Legal matters:** `legal@evidtech.com`  

Evident Technologies LLC  
New Jersey, United States

---

*Nothing in this policy constitutes legal advice or creates an attorney-client relationship. This policy is subject to revision without prior notice. The current version is the version published in the default branch of this repository.*

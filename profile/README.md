# Evident Technologies

**Court-grade evidence processing for everyone.**

We build governed software for legal practitioners who cannot access Relativity-class tools — eDiscovery, chain-of-custody infrastructure, and AI-assisted litigation workflows at a price point that works for solo practices, small firms, and public defenders.

---

## Flagship: Evident ICU

Evident ICU is a court-grade eDiscovery and evidence processing platform built for New Jersey legal practitioners and beyond.

| Surface | |
| --- | --- |
| [evident.icu](https://evident.icu) | Live application — intake, pipeline, export |
| [evident-icu.com](https://evident-icu.com) | Platform overview |
| [docs.evident.icu](https://docs.evident.icu) | Technical documentation |

**What it does:**

- Immutable evidence intake with SHA-256 integrity verification at every stage
- 16-stage AI-assisted processing pipeline (transcription, OCR, metadata, redaction, export)
- Append-only chain-of-custody audit log — court-defensible by design
- Deterministic, reproducible outputs — identical input produces identical output
- Structured provenance for every derivative artifact
- Export packages prepared for downstream review and production

---

## Engineering Principles

| Principle | Implementation |
| --- | --- |
| Immutable originals | Source evidence is never overwritten or mutated |
| Cryptographic verification | SHA-256 hashing at ingest, processing, and export |
| Append-only records | Audit and custody events are permanent historical records |
| Deterministic processing | Reproducible outputs across all environments and runs |
| Structured provenance | Derivatives retain full reference relationships to source material |
| Accessibility by default | WCAG 2.1 AA — a system requirement, not a finishing layer |
| Security-conscious design | Privacy-aware engineering, disciplined trust boundaries, least-privilege |

---

## Stack

| Layer | Technology |
| --- | --- |
| Frontend | Eleventy 3.1 · Tailwind 4 · Alpine.js · React 19 + Vite |
| API | Express 5.1 · Node.js 22 · CommonJS |
| Database | Supabase PostgreSQL · Row-Level Security |
| Evidence Pipeline | Python 3.11+ · Whisper · Tesseract · ExifTool · pyannote |
| Desktop | .NET 10 · MAUI Blazor Hybrid |
| Billing | Stripe Subscriptions |
| Deploy | Fly.io · Cloudflare Pages · Cloudflare Workers |
| Signing | Ed25519 SSH signed commits |

---

## Ecosystem

| Domain | Role |
| --- | --- |
| [evidtech.com](https://evidtech.com) | Umbrella organization |
| [evident.icu](https://evident.icu) | Evident ICU — live application |
| [evident-icu.com](https://evident-icu.com) | Platform informational surface |
| [docs.evident.icu](https://docs.evident.icu) | Developer and operator documentation |

---

## Contributions

We accept contributions that strengthen **reliability, transparency, determinism, and operational clarity**.

- Signed commits are preferred
- Deterministic behavior is prioritized over convenience
- Audit-sensitive code paths require disciplined review
- Sensitive operational details must not be disclosed in public channels

Guidance lives in each repository's `CONTRIBUTING.md`.

---

## Security

If you identify a potential vulnerability, use responsible disclosure. Do not post sensitive operational details in public issues or discussions.

Systems handling evidence workflows are built around integrity verification, append-only history, traceable events, and reproducible processing.

For responsible disclosure: [security@evidtech.com](mailto:security@evidtech.com)

---

## Legal

Nothing published here constitutes legal advice, legal representation, forensic certification, or evidentiary guarantees. All materials are provided for informational and technical purposes only. Users are responsible for evaluating legal and regulatory requirements applicable to their use cases.

---

<div align="center">

Disciplined systems for accountable records. Built for access to justice.

[evidtech.com](https://evidtech.com) · [evident.icu](https://evident.icu) · [@Evident-Technologies](https://github.com/Evident-Technologies)

</div>

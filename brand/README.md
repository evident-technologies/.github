# Evident Technologies LLC — Institutional Brand System

Primary parent-company identity for **EVIDENT TECHNOLOGIES** — a legal-technology
and evidence-infrastructure company. The system is designed for enterprise
profiles, legal documents, invoices, footer compliance, GitHub organization
avatars, Stripe branding, and PDF letterheads.

This is the **parent-company** identity. The flagship product (*Evident ICU*)
carries its own product mark under `../profile/assets/`.

> Use the full parent-company name **EVIDENT TECHNOLOGIES**. Do not use "EVIDTECH".

---

## The mark

A modern institutional shield carrying three integrated signals:

| Element | Meaning |
|---|---|
| Shield field | Protection, durability, custody |
| Inner hairline frame | Procedural structure |
| Ledger / record lines | The record, document geometry, provenance |
| Verification check (gold) | Integrity, verification, attestation |

The geometry is intentionally simple so it survives reduction to a 16 px favicon
and a single-ink compliance seal.

---

## Assets

| File | Use |
|---|---|
| `evident-technologies-brandboard.svg` / `.png` | Full brand board (overview / reference) |
| `evident-technologies-logo-primary.svg` | Primary horizontal lockup — light/ivory surfaces |
| `evident-technologies-logo-reversed.svg` | Reversed lockup — navy / dark surfaces |
| `evident-technologies-logo-mono.svg` | Monochrome lockup — documents, invoices, print |
| `evident-technologies-icon.svg` | Color shield mark (transparent) |
| `evident-technologies-icon-mono.svg` | Monochrome shield mark (`currentColor`) |
| `evident-technologies-icon-512.png` | Raster avatar / app icon (512 px) |
| `evident-technologies-favicon-32.png` | Raster favicon (32 px) |

All vector files use a `viewBox`, so they scale to any size without loss.

### Monochrome behaviour

The monochrome lockup and icon use `fill`/`stroke="currentColor"`. They inherit
the surrounding text color — black on white for court filings and invoices, and
white when reversed on dark. No gradients are used anywhere in the system, so the
marks survive PDF/A, fax, and archival print.

---

## Color palette

| Token | Hex | Role |
|---|---|---|
| Deep Navy | `#15294C` | Primary — authority, wordmark |
| Black-Blue | `#0A1525` | Depth, dark surfaces, body text |
| Slate Gray | `#5B6573` | Secondary text, rules, dividers |
| Constitutional Ivory | `#F4EFE3` | Ground, paper, reversed wordmark |
| Muted Gold | `#BF9F4E` | Restrained accent — verification only |

Gold is an accent, not a fill. Reserve it for the verification check and thin
rules; never set large areas in gold.

---

## Typography

- **Typeface:** Inter, with a `system-ui` fallback chain.
- **Wordmark:** uppercase, weight 700 for `EVIDENT`, weight 500 for
  `TECHNOLOGIES`, letter-spacing roughly **+6 to +10**.
- **Headings:** 600 / 700 · **Body & UI:** 400 / 500.

---

## Clear space & minimum size

- **Clear space:** keep padding around the lockup of at least the height of the
  shield's inner frame on all sides.
- **Minimum sizes:** lockup ≥ 140 px wide; standalone shield ≥ 16 px.
- Do not recolor the mark outside the palette, stretch it, add effects, rotate
  it, or place the color mark on low-contrast backgrounds — use the reversed or
  monochrome variant instead.

---

These are canonical institutional assets. Changes should go through governance
review before deployment on public or client-facing surfaces.

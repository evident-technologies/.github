# Corporate identity source

Owner: Evident Technologies LLC. Existing artwork is preserved for compatibility; no verified
founder approval record for a permanent replacement was found in this repository's inspected source
and history. A public website displaying a seal does not supply its editable source or approval
lineage.

The company identity spans engineering, design, software, contracting-related workflows, and digital
infrastructure. Product names such as FORGE and ICU sit beneath that corporate identity. They do not
define a second company.

## Review the proposed directions

[Editable identity candidates](candidates/README.md) offer two original geometric directions, each
with light, dark, monochrome, and lockup sources. They are **unapproved**. Neither candidate is
activated in the organization profile, an avatar, a package release, or a client surface. The public
profile uses a text heading and retains a legacy footer mark while artwork approval is unresolved.
That retained mark does not constitute approval of either candidate or a permanent corporate identity.

## Existing asset inventory

All files below are retained. REPLACE means a future candidate needs approval and dependency review;
it does not authorize deletion.

| Source | Classification | Review concern |
| --- | --- | --- |
| `evident-technologies-logo-primary.svg` | REPLACE | Existing corporate shield and live-text lockup |
| `evident-technologies-logo-reversed.svg` | REPLACE | Existing dark lockup with opaque ground |
| `evident-technologies-logo-stacked.svg` | REPLACE | Existing stacked live-text lockup |
| `evident-technologies-logo-mono.svg` | REPLACE | Existing monochrome live-text lockup |
| `evident-technologies-wordmark.svg` | REPLACE | Gold text needs context-specific contrast review |
| `evident-technologies-icon.svg` | REPLACE | Detailed shield needs small-size visual review |
| `evident-technologies-icon-mono.svg` | REPLACE | Single-color outline variant |
| `evident-technologies-brandboard.svg` | REPLACE | Historical positioning and unsupported approval wording |
| `evident-technologies-brandboard.png` | REPLACE | Historical raster board; retain alongside vector source |
| `evident-technologies-construction.svg` | REPLACE | Historical geometry claims are design assertions, not verified measurements |
| `evident-technologies-usage-icons.svg` | KEEP | Existing decorative source; no certification implied |
| `evident-technologies-icon-512.png` | REPLACE | Historical avatar export |
| `evident-technologies-favicon-32.png` | REPLACE | Historical favicon export |
| `../profile/assets/evident-mark.svg` | REPLACE | Legacy product shield, distinct from corporate identity |
| `../profile/assets/evident-wordmark.svg` | REPLACE | Legacy ICU positioning and font dependency |
| `../profile/assets/evident-wordmark-mono.svg` | REPLACE | Contains live text despite conflicting flattened-path comments |
| `brand.css` | REWRITE | Malformed duplicate preamble repaired; existing variable names and values retained |
| `tokens.json` | REWRITE | Existing values retained; unverified schema claim removed |
| `manifest.json` | REWRITE | Compatibility keys retained; approval and publication claims qualified |
| `package.json` | KEEP | Metadata only; `UNLICENSED` is not an open-source license or proof of publication |

## Typography, color, and embedding

Existing text lockups depend on installed fonts; no font files are bundled. A `viewBox` permits
scaling but does not prove legibility. `currentColor` follows the SVG document's own context; an SVG
loaded with an external `img` does not inherit the host page's text color. Use an explicit reversed
asset when needed.

The existing palette remains navy `#15294C`, black-blue `#0A1525`, slate `#5B6573`, ivory `#F4EFE3`,
and gold `#BF9F4E`. Gold on light surfaces is decorative, not normal body text or the only indicator
of a state. Color names such as “verified” do not prove record integrity. Candidate contrast pairs
are checked separately.

No external font, CDN import, or npm installation is needed to inspect these sources. Historical
manifest URL fields remain for compatibility, not as endorsed mutable production dependencies.
Prefer approved, immutable source references and verify consumer behavior. Do not assume the package
version or a release tag exists remotely.

## Rights, provenance, and retirement

Existing SVG comments assert company ownership; this audit cannot establish the full rights chain or
trademark clearance. Preserve those originals and source history. Third-party font and component
terms remain separate. New candidate geometry is authored for this review without stock artwork,
external images, embedded fonts, or copied marks. No reuse license or founder approval is invented.

[Source fingerprints](source-inventory.json) record the existing brand bytes and observed history.
[Candidate provenance](candidates/manifest.json) records generated source and approval status.
Hashes identify bytes; they do not establish legal rights.

**Exact assets removed in this proposal: none.** Before any retirement, approve the replacement,
inventory consumers across the organization and public integrations, verify new paths and immutable
pins, test light/dark and narrow layouts, and retain the prior revision for rollback. Local absence
of references cannot prove that external consumers do not exist.

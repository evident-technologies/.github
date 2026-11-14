# Public information and confidential disclosure

**Status: proposed for Company review.** This document does not adopt policy, grant access or
establish a new security authority. Existing Company governance and Platform authorization remain
controlling. Classification and actual recipient authorization are separate requirements.

## Proposed classification mapping

| Label | Intended disclosure |
| --- | --- |
| PUBLIC | Exact material approved for public distribution |
| CLIENT_CONFIDENTIAL | Named authorized client recipients within applicable executed terms |
| COMPANY_INTERNAL | Authorized Company operations |
| RESTRICTED_ENGINEERING | Approved technical recipients with a documented operational need |
| SECRET | Approved secret-management mechanisms; never an ordinary client disclosure package |

These proposed names require mapping to the existing owner's adopted classifications before
operational use. Unknown, missing, expired or conflicting classification stops disclosure; it does
not default to PUBLIC. A signed agreement does not grant every client access to every Company record.

## Public engineering and private implementation

Public material should explain verified capabilities, limitations, interfaces, support, source
verification, lawful disclosures and applicable rights. General engineering concepts, programming
languages, frameworks and correctly distributed license notices are not confidential merely because
they are technical.

Protect material with an established confidentiality basis or concrete disclosure risk, including
restricted designs, non-public estimating methods, private customer or personnel records, privileged
automation, operational secrets and sensitive infrastructure details. Do not publish sensitive
detection dictionaries, private prompts, client inventories or operational endpoints in this public
repository. Use generic contracts and synthetic examples.

Browser-accessible bundles, configuration, serialized state and source maps are disclosed to their
audience. Keep credentials and confidential backend logic on appropriately authorized private or
server-side surfaces. Minification, obfuscation, disabled source maps and hidden controls do not
establish confidentiality. Public errors require sanitized responses, while private diagnostics and
API fields require appropriate recipient authorization.

## Review before disclosure

The existing source/security owner must review the exact bytes, intended audience, classification,
rights, required notices and delivery method. Non-public client disclosure also requires verified
recipient identity, an applicable executed agreement or approved legal basis, legitimate need,
human approval, redaction, an attributable version record, access-controlled delivery, and retention,
revocation and correction handling under the governing agreement.

Do not disclose live credentials, authentication secrets or unrelated third-party confidential
material because a requester is a signed client. Preserve disclosures required by controlling law,
applicable licenses and actual executed agreements. See [licensing and notices](LICENSING.md).

## Scanner limits and publication holds

Credential scanning and proprietary-information review are distinct controls. A clean credential
scan does not approve classification or establish the absence of all confidential information.
Separate review must cover actual compiled assets, API/header/error captures, archives, source maps,
documentation, public CI diagnostics and any proposed application or assistant output.

Missing inputs, unsupported content, scanner crashes, unavailable rules or incomplete inspection
stop the affected publication. Safe reports identify rule, source location and remediation without
printing sensitive matches. False-positive dispositions require exact scope, current human review
and revalidation after relevant changes; they must not silently disable protection.

This proposal does not claim the exposure gate, runtime output interception, organization-wide
secret scanning or push protection is operational. Existing owners must qualify each integration
and its real execution before making that claim. Report exposures privately under
[the security policy](../SECURITY.md); do not reproduce sensitive values in public reports.

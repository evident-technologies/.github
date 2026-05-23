<!--
  Evident Technologies LLC — institutional pull request template.

  This repository operates under controlled institutional governance. Pull
  requests are reviewed by the LLC's authorized reviewers under CODEOWNERS.
  External pull requests are not accepted; see CONTRIBUTING.md.
-->

## Summary

<!-- One paragraph. State the change, not the motivation. Reserve motivation for "Rationale". -->

## Rationale

<!-- The operational, technical, or governance reason this change exists. -->

## Scope and blast radius

- **Repositories or packages affected:**
- **Downstream consumers:**
- **Reversibility:** <!-- additive / reversible / destructive — state explicitly -->

## Verification

<!-- Deterministic verification performed before requesting review. -->

- [ ] Local build passes
- [ ] Lint passes with zero warnings
- [ ] Type-check passes with zero errors
- [ ] Tests pass (existing and new)
- [ ] Manual verification performed where automation is insufficient

**Verification commands run:**

```
<!-- exact commands -->
```

## Rollback plan

<!-- Concrete rollback steps. If rollback is non-trivial, state why and how the change is gated. -->

## Governance checklist

- [ ] Change does not modify governance, security, or legal documents without Manager review
- [ ] Change does not alter audit, custody, or evidence-integrity surfaces without explicit approval
- [ ] Change does not introduce new external dependencies without disclosure
- [ ] Change does not weaken branch protection, CODEOWNERS, or required CI status
- [ ] Secrets, credentials, and personally identifying information are absent from the diff

## Related

<!-- Linked issues, prior PRs, or governance records. Use plain references; do not auto-close issues unless intentional. -->

# Adversarial review: repository contracts and R3 coverage

- **Date:** 2026-08-05
- **Mode:** Single-model adversarial review; no independent external model or
  Replit agent was available in this execution environment.
- **Artifacts:** behavioural eval contract, documentation inventory validator,
  Packer contract validator, historical-plan lifecycle changes, and R3 policy
  adoption.

## Contract under review

The change must prevent documentation drift and placeholder-driven Packer use
without creating a second ESXi safety policy, implying that mock checks prove a
real host, or allowing an R3 procedure to bypass exact sources, tests, approval,
backup, or out-of-band recovery.

## Findings and disposition

| Finding | Classification | Disposition |
|---|---|---|
| A visual README tree is too brittle to be the enforced inventory. | Valid and actionable | Use `docs/inventory.txt` as the machine contract; keep `docs/index.md` human-oriented. |
| Requiring every model overlay in the prose index would increase context and maintenance noise. | Valid trade-off | Inventory every overlay path, but prose-index only the profile/contract entry points. |
| A validator that rejects placeholders in committed examples would make safe templates impossible to store. | Valid and actionable | Split static reviewed-skeleton validation from local `--vars` preflight. |
| The Packer templates still are not end-to-end builds. | Valid and actionable | State this as an explicit contract, document required unattended-media wiring, and block claims of standalone support. Do not pretend CI syntax validation is a successful install. |
| A local Packer variable file could opt into insecure TLS silently. | Valid and actionable | Require `ALLOW_PACKER_INSECURE_TLS=1` for an explicit, temporary exception. |
| Behavioural evals can become vague prose that always passes. | Valid and actionable | Require unique IDs, minimum assertion counts, and named safety-critical coverage. |
| Historical plan content could be lost by replacing the root files. | Valid and actionable | Keep the original blobs recoverable through Git history, add a lifecycle record under `docs/design-history/`, and replace roots with explicit redirects. |
| A new R3 runbook could satisfy Markdown and inventory checks while remaining operationally unsafe. | Valid and actionable | Record in ADR-0002 and contributor rules that materially changed R3 guidance requires sources, regression tests, and adversarial findings disposition. |
| The review is not independent because the same model authored and reviewed the change. | Valid limitation | Label the review mode honestly and leave independent human/cross-model review as a pull-request responsibility. |

## Stop condition

No unresolved finding changes the chosen architecture. The remaining material
limitations—mock-only validation, reviewed-skeleton Packer examples, and the
single-model review—are explicit and must not be represented as production or
lab proof.

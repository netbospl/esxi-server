# ADR-0002: Keep one canonical R0–R3 risk and consent model

- **Status:** Accepted
- **Date:** 2026-08-05

## Context

Task references, child skills, model overlays, and harness adapters can drift if
each redefines approval, rollback, or destructive-operation policy.

## Decision

`SKILL.md` is the sole definition of R0–R3. References and child skills may add
task-specific preflight checks but must link to, not redefine, the canonical
risk classes. Model overlays adapt reasoning only.

New or materially changed R3 guidance also requires exact-version source
verification, regression tests, and a documented adversarial review.

## Consequences

- Approval language remains consistent across the repository.
- Thin overlays stay small and cannot weaken safety gates.
- Reviewers can test one canonical contract instead of reconciling duplicates.

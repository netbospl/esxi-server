# ADR-0003: Enforce documentation lifecycle and behavioural evaluations in CI

- **Status:** Accepted
- **Date:** 2026-08-05

## Context

A repository can pass syntax and lint checks while its index omits live files,
historical plans look active, or the skill no longer produces the intended
safety behaviour.

## Decision

Maintain `docs/inventory.txt` as the machine-checked inventory for references,
canonical skills, overlays, validators, regression tests, and Packer templates.
Mark historical root documents with explicit lifecycle status, retain their
original revisions in Git history, and record current authority under
`docs/design-history/`. Maintain runner-neutral behavioural prompts in `evals/`
and validate their safety-critical coverage in CI.

## Consequences

- Adding or removing a tracked surface requires an inventory update.
- Historical plans remain available without misleading current agents.
- Behavioural regressions can be compared across skill revisions and models.

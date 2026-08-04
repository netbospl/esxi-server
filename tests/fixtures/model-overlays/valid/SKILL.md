---
name: example-model-overlay
description: Use when the example model handles a previously observed task-specific reasoning failure.
---

# Example model overlay

**Canonical parent:** [`parent.md`](parent.md)
**Model profile:** [`model.md`](model.md)
**Load order:** root → canonical parent → model profile → optional harness → this overlay

## Scope boundaries

This overlay adapts reasoning only. The canonical parent owns commands, risk,
approval, rollback, and verification.

## Adaptation

Keep observed facts separate from hypotheses and request one discriminator at a
time when evidence is incomplete.

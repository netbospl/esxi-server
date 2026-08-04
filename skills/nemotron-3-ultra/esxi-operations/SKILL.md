---
name: nemotron-3-ultra-esxi-operations
description: Use when Nemotron 3 Ultra is handling a general ESXi task after the canonical root policy and task reference have been selected.
---

# Nemotron 3 Ultra ESXi operations overlay

**Canonical parent:** [`../../../SKILL.md`](../../../SKILL.md), followed by the
single task reference chosen by its router.

**Model profile:** [`../model-profile.md`](../model-profile.md)

**Load order:** root policy → canonical task reference/skill → model profile →
optional Hermes adapter → this overlay.

## Scope boundaries

This overlay adds reasoning structure only. It owns no command, API route,
risk classification, approval, rollback, or verification rule. On conflict or
missing parent context, ignore this overlay.

## Adaptation

Maintain a compact ledger with four blocks:

1. Fresh facts: exact target, build, transport/trust state, task object, and
   relevant capacity/power/network state.
2. Hypotheses: two or three distinct explanations, each tied to observed
   evidence and an explicit uncertainty.
3. Next discriminator: one bounded R0 check from the canonical reference.
4. Change gate: parent risk class, exact target, approval state, rollback,
   abort condition, and post-change evidence.

Batch independent read-only observations only when that preserves clear source
and timestamp attribution. After compaction, interruption, approval expiry, or
a tool result that changes state, refresh the ledger from current evidence.
Never infer success from a plausible narrative.

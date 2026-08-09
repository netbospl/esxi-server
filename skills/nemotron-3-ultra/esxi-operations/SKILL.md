---
name: nemotron-3-ultra-esxi-operations
description: Use when Nemotron 3 Ultra is handling a general ESXi task after one canonical task module has been selected.
---

# Nemotron 3 Ultra ESXi operations overlay

**Canonical parent:** [`../../../SKILL.md`](../../../SKILL.md)

**Model profile:** [`../model-profile.md`](../model-profile.md)

**Load order:** root policy → canonical parent/task module → model profile → overlay.

## Scope boundaries

Reasoning only. Commands, endpoints, risk, approval, rollback, and verification come from the canonical parent/task module.

## Adaptation

Maintain four compact blocks: fresh facts, competing hypotheses, next bounded R0 discriminator, and change gate. Keep only exact IDs and volatile state relevant to the task. Batch independent read-only checks only when source/time attribution stays clear.

After compaction, interruption, approval expiry, transport recovery, or state change, refresh affected facts from current evidence. Never infer success from narrative coherence.

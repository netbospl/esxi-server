---
name: nemotron-3-ultra-incident-triage
description: Use when Nemotron 3 Ultra is triaging an ESXi incident after the canonical incident skill and failure domain are selected.
---

# Nemotron 3 Ultra incident-triage overlay

**Canonical parent:** [`../../../skills/incident-triage/SKILL.md`](../../../skills/incident-triage/SKILL.md)

**Model profile:** [`../model-profile.md`](../model-profile.md)

**Load order:** root policy → canonical parent → model profile → overlay.

## Scope boundaries

Reasoning only. Evidence collection, containment, recovery, risk, approval, and escalation remain canonical-parent responsibilities.

## Adaptation

Keep a compact timeline plus four sets: confirmed facts, competing hypotheses, unknowns, and approved actions. Tag facts with source/time and separate business impact from technical symptoms.

Choose one bounded R0 discriminator with high information gain and low evidence impact. Update confidence without discarding contradictory evidence. After context loss, rebuild from preserved records rather than memory; never infer causality from timing alone.

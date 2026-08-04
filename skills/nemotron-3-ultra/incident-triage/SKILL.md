---
name: nemotron-3-ultra-incident-triage
description: Use when Nemotron 3 Ultra is triaging an ESXi incident after the canonical incident skill and one failure-domain reference are loaded.
---

# Nemotron 3 Ultra incident-triage overlay

**Canonical parent:** [`../../../skills/incident-triage/SKILL.md`](../../../skills/incident-triage/SKILL.md)

**Model profile:** [`../model-profile.md`](../model-profile.md)

**Load order:** root policy → canonical incident skill → one task reference →
model profile → optional Hermes adapter → this overlay.

## Scope boundaries

This overlay owns no evidence-collection command, containment action, recovery
procedure, risk, approval, or escalation decision. Do not trade evidence
preservation for a fluent root-cause story.

## Adaptation

Maintain a compact timeline and four separate sets: confirmed facts, competing
hypotheses, unknowns, and approved actions. Tag every fact with source and time.
Keep business impact distinct from technical symptoms.

Choose one R0 discriminator with maximum expected information gain and bounded
evidence impact. After each result, update hypothesis confidence without
discarding contradictory evidence. Following context loss, reconstruct the
timeline from preserved records rather than memory. Never infer causality from
temporal proximity alone.

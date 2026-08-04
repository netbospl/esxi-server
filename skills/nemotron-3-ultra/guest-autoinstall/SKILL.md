---
name: nemotron-3-ultra-guest-autoinstall
description: Use when Nemotron 3 Ultra is preparing an unattended guest installation after the canonical guest-install reference and exact template variant are loaded.
---

# Nemotron 3 Ultra guest autoinstall overlay

**Canonical parent:** [`../../../references/guest-os-autoinstall.md`](../../../references/guest-os-autoinstall.md)

**Model profile:** [`../model-profile.md`](../model-profile.md)

**Load order:** root policy → canonical guest-install reference → model profile
→ optional Hermes adapter → this overlay.

## Scope boundaries

This overlay does not define deployment commands, answer-file syntax, guest
credentials, disk selection, network attachment, risk, approval, or rollback.
Use only repository-validated templates and canonical helpers.

## Adaptation

Build a compatibility tuple before planning: guest product/version, firmware,
partition mode, virtual hardware, controller types, install ISO, exact answer
file variant, datastore, disk target, and initial network isolation. Mark every
unresolved placeholder or secret source explicitly.

Separate local media generation and validation from ESXi deployment. Treat the
generated artifact as untrusted until offline validation passes. Reserve
context for destructive disk semantics, first-boot identity, and duplicate
network/machine identifiers. A successful VM power-on is not proof that the
installation selected the intended disk or completed safely.

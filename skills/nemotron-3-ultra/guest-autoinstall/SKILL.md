---
name: nemotron-3-ultra-guest-autoinstall
description: Use when Nemotron 3 Ultra is preparing an unattended guest installation after the canonical guest-install reference is loaded.
---

# Nemotron 3 Ultra guest autoinstall overlay

**Canonical parent:** [`../../../references/guest-os-autoinstall.md`](../../../references/guest-os-autoinstall.md)

**Model profile:** [`../model-profile.md`](../model-profile.md)

**Load order:** root policy → canonical parent → model profile → overlay.

## Scope boundaries

Reasoning only. The parent owns deployment actions, answer-file syntax, credentials, disk/network selection, risk, approval, and rollback.

## Adaptation

Keep one compatibility tuple: guest/version, firmware, partition mode, virtual hardware/controllers, install media, answer-file variant, datastore, disk target, and initial network isolation. Mark unresolved placeholders or secret sources.

Separate local media generation/validation from ESXi deployment. Preserve context for destructive disk semantics, first-boot identity, and duplicate machine/network identifiers. Power-on alone is not proof that the intended disk or unattended installation completed safely.

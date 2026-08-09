---
name: nemotron-3-ultra-stable-ssh-shell
description: Use when Nemotron 3 Ultra needs persistent remote state or deterministic recovery on a verified compatible management or guest host, never directly on ESXi.
---

# Nemotron 3 Ultra stable shell overlay

**Canonical parent:** [`../../../skills/stable-ssh-shell/SKILL.md`](../../../skills/stable-ssh-shell/SKILL.md)

**Model profile:** [`../model-profile.md`](../model-profile.md)

**Load order:** root policy → canonical parent → model profile → overlay.

## Scope boundaries

Reasoning only. The parent owns transport, persistence, completion markers, credentials, risk, approval, and recovery. Direct ESXi remains restricted/one-shot.

## Adaptation

Track transport state separately from remote process state. At checkpoints retain target identity, verified trust state, selected parent mode, session identifier when applicable, last proven completion marker, relevant environment assumptions, and whether work may still be running.

After transport/context loss, recover observation first. Never replay an operation until the parent protocol proves it did not complete. If capability or identity changes, downgrade safely or stop.

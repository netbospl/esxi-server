---
name: nemotron-3-ultra-stable-ssh-shell
description: Use when Nemotron 3 Ultra needs persistent remote state or deterministic recovery on a verified compatible management or guest host, never directly on ESXi.
---

# Nemotron 3 Ultra stable shell overlay

**Canonical parent:** [`../../../skills/stable-ssh-shell/SKILL.md`](../../../skills/stable-ssh-shell/SKILL.md)

**Model profile:** [`../model-profile.md`](../model-profile.md)

**Load order:** root policy → canonical stable-shell skill and task reference →
model profile → optional Hermes adapter → this overlay.

## Scope boundaries

This overlay defines no transport command, persistence mechanism, marker
protocol, credential rule, risk, approval, or recovery action. Direct ESXi
remains restricted and one-shot. pfSense remains a router/firewall boundary.

## Adaptation

Track transport state separately from remote process state. At each checkpoint
record target identity, verified host-key state, selected parent mode, remote
session identifier if applicable, last proven completion marker, current
directory/environment assumptions, and whether an operation may still be
running.

After loss of transport or context, recover observation first. Never replay an
operation until the parent protocol proves it did not complete. If the target
cannot support the selected mode or identity changes, downgrade to a supported
mode or stop.

---
name: nemotron-3-ultra-private-guest-shell
description: Use when Nemotron 3 Ultra must reason about reaching a private guest through an approved pfSense boundary after the canonical private-guest skill is loaded.
---

# Nemotron 3 Ultra private guest shell overlay

**Canonical parent:** [`../../../skills/private-guest-shell/SKILL.md`](../../../skills/private-guest-shell/SKILL.md)

**Model profile:** [`../model-profile.md`](../model-profile.md)

**Load order:** root policy → canonical parent → model profile → overlay.

## Scope boundaries

Reasoning only. The parent owns routes, firewall rules, credentials, tunnels, transport, risk, approval, and persistence mode.

## Adaptation

Model two independent trust layers: approved outer route, then final guest identity/credential. Record which layer each failure belongs to; boundary identity never proves guest identity.

Prefer the canonical VPN path, then an approved dedicated jump host. Keep any recovery mapping visibly scoped with owner, expiry, source, destination, cleanup verification, and rollback. After context or transport loss, revalidate both layers before continuing.

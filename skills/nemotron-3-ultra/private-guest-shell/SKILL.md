---
name: nemotron-3-ultra-private-guest-shell
description: Use when Nemotron 3 Ultra must reason about reaching a private guest through an approved pfSense boundary after the canonical private-guest skill is loaded.
---

# Nemotron 3 Ultra private guest shell overlay

**Canonical parent:** [`../../../skills/private-guest-shell/SKILL.md`](../../../skills/private-guest-shell/SKILL.md)

**Model profile:** [`../model-profile.md`](../model-profile.md)

**Load order:** root policy → canonical private-guest skill and network
reference → model profile → optional Hermes adapter → this overlay.

## Scope boundaries

This overlay defines no route, firewall rule, credential, tunnel, transport
command, risk, approval, or persistence mode. pfSense is never converted into
a general bastion or persistence host.

## Adaptation

Model access as two independent trust layers: the approved outer route through
the boundary, then the final guest's credential and verified host key. Record
which layer each failure belongs to and do not reuse boundary identity as proof
of guest identity.

Prefer the canonical VPN path, then an approved dedicated jump host. Keep any
time-limited recovery mapping visibly scoped with owner, expiry, source,
destination, cleanup verification, and rollback. After context or transport
loss, revalidate both layers before continuing.

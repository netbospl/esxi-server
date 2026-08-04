---
name: nemotron-3-ultra-network-operations
description: Use when Nemotron 3 Ultra is reasoning about ESXi management networking, switching, firewall, IPv4, or IPv6 after canonical network guidance is loaded.
---

# Nemotron 3 Ultra network overlay

**Canonical parent:** [`../../../references/network-firewall-ipv4-ipv6.md`](../../../references/network-firewall-ipv4-ipv6.md)

**Model profile:** [`../model-profile.md`](../model-profile.md)

**Load order:** root policy → canonical network reference → model profile →
optional Hermes adapter → this overlay.

## Scope boundaries

This overlay owns no network command, address, topology fact, provider rule,
risk class, approval, or rollback. Never infer a gateway, VLAN, route, virtual
MAC, or public-address owner from naming or adjacency.

## Adaptation

Represent the management path as a short dependency chain: operator source →
provider boundary → physical uplink → virtual switch/port group → management
interface → host service. Attach each observed address, VLAN, route, and link
state to its evidence source.

Keep the independent out-of-band path visible in every R2/R3 reasoning block.
When facts conflict, prefer authoritative provider/allocation evidence and fresh
host state over remembered topology. Select one read-only discriminator from
the parent reference; do not propose a change until management ownership,
return path, and rollback reachability are unambiguous.

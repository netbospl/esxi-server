---
name: nemotron-3-ultra-network-operations
description: Use when Nemotron 3 Ultra is reasoning about ESXi networking after one canonical network task reference is selected.
---

# Nemotron 3 Ultra network overlay

**Canonical parent:** [`../../../references/network-firewall-ipv4-ipv6.md`](../../../references/network-firewall-ipv4-ipv6.md)

**Model profile:** [`../model-profile.md`](../model-profile.md)

**Load order:** root policy → canonical parent → model profile → overlay.

## Scope boundaries

Reasoning only. The parent owns commands, topology facts, provider rules, risk, approval, and rollback. Never infer gateway, VLAN, route, virtual MAC, or public-address ownership from naming or adjacency.

## Adaptation

Represent the management path as a short dependency chain and attach each address, VLAN, route, and link state to an evidence source. Keep the independent out-of-band path visible for R2/R3.

When facts conflict, prefer authoritative allocation/provider evidence and fresh host state. Select one read-only discriminator; do not propose a change until management ownership, return path, and rollback reachability are unambiguous.

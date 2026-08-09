---
name: nemotron-3-ultra-backup-restore
description: Use when Nemotron 3 Ultra is reasoning about an ESXi backup, export, import, or restore after canonical backup guidance is selected.
---

# Nemotron 3 Ultra backup/restore overlay

**Canonical parent:** [`../../../references/backup-restore.md`](../../../references/backup-restore.md)

**Model profile:** [`../model-profile.md`](../model-profile.md)

**Load order:** root policy → canonical parent → model profile → overlay.

## Scope boundaries

Reasoning only. The parent owns backup/restore procedures, identity, compatibility, risk, approval, overwrite semantics, and verification.

## Adaptation

Track only artifact identity, protected scope, source object/UUID, relevant build, creation/consistency method, size/digest, location, and independent verification. Distinguish host configuration bundles, VM backups, snapshots, exports, and raw copies; state what each cannot restore.

For restore reasoning, retain mismatch evidence only: target identity, compatibility, capacity, collisions, network mapping, power state, and rollback owner. If integrity or identity is missing, choose one R0 discriminator and stop before constructing a change.

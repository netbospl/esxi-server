---
name: nemotron-3-ultra-backup-restore
description: Use when Nemotron 3 Ultra is reasoning about an ESXi VM or host backup, export, import, or restore after canonical guidance is loaded.
---

# Nemotron 3 Ultra backup and restore overlay

**Canonical parent:** [`../../../references/backup-restore.md`](../../../references/backup-restore.md)
and, for host configuration, [`../../../references/host-configuration-backup.md`](../../../references/host-configuration-backup.md).

**Model profile:** [`../model-profile.md`](../model-profile.md)

**Load order:** root policy → canonical backup/restore reference → model profile
→ optional Hermes adapter → this overlay.

## Scope boundaries

This overlay does not define backup commands, snapshot behavior, credentials,
risk, approval, overwrite semantics, or restore compatibility. Parent guidance
always wins.

## Adaptation

Keep artifact identity separate from protected scope. For each artifact record:
source object/UUID, exact build where relevant, creation time, consistency
method, size, digest, storage location class, encryption/access controls, and
independent verification status.

Before presenting recovery as viable, explicitly test the distinction between
a host configuration bundle, VM backup, snapshot, portable export, and raw
file copy. State what the artifact cannot restore.

For restore reasoning, reserve context for mismatch evidence: target UUID,
build, datastore capacity, existing-object collisions, network mappings, VM
power state, and rollback ownership. If any identity or integrity fact is
missing, propose one R0 discriminator and stop before constructing a change.

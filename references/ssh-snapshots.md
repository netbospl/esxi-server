# SSH snapshots

Start with [`../SKILL.md`](../SKILL.md). Use only with a trusted SSH path.

Before planning a snapshot action, freshly resolve VM identity, inspect power state, datastore free space, and the complete snapshot tree:

```bash
: "${VMID:?set from fresh verified inventory}"
vim-cmd vmsvc/get.snapshot "$VMID"
```

A snapshot is not a backup. Creation still requires the root change gate and enough datastore headroom.

For an approved short-lived snapshot, use guarded values and confirm syntax on the exact build:

```bash
: "${SNAPSHOT_NAME:?approved snapshot name is required}"
: "${SNAPSHOT_DESCRIPTION:=approved short-lived rollback point}"
vim-cmd vmsvc/snapshot.create \
  "$VMID" "$SNAPSHOT_NAME" "$SNAPSHOT_DESCRIPTION" 0 0
```

Revert, remove, remove-all, and consolidation can be service- or data-impacting R2/R3 work. Select snapshot identity from a fresh tree; never assume an ID. Load `backup-restore.md` only when backup/recovery semantics are actually part of the decision.

After any approved action, re-read the tree and datastore state; verify application/data integrity separately when applicable.

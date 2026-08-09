# SSH datastore and storage inspection

Start with [`../SKILL.md`](../SKILL.md). Use this module for storage discovery over an already trusted SSH path.

Use read-only structured queries as needed:

```bash
esxcli --formatter=csv storage filesystem list
esxcli --formatter=csv storage vmfs extent list
esxcli --formatter=csv storage core device list
```

Before any storage-related change, record the exact datastore/device UUID, mounted state, capacity/free space, dependencies, affected VMs, current paths, and rollback/recovery path. Never select a target by an ambiguous display name alone.

For upload/download or overwrite semantics, load `file-transfers.md`. For VM import/export, load `vm-import-export.md`. For backup/restore semantics, load the relevant backup reference only when required by the current operation.

Deletion, unmount/removal, formatting, extent manipulation, or disk wipe can cause data loss and falls under the root R2/R3 gate. Do not include destructive commands merely as examples.

Verify resulting mount/capacity/path state with a fresh read-only query.

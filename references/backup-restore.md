# Backup and restore

Use this guidance for backups, restores, exports, and rollback preparation on standalone ESXi.

## Before any backup or restore

- Confirm the target VM, datastore, and file path.
- Check datastore free space.
- Check VM power state.
- Confirm whether a snapshot, export, or file copy is being used as the rollback mechanism.
- Ask for approval before any restore that overwrites data or changes VM state.

## Backup patterns

Common backup patterns include:

- VM export to OVF/OVA
- datastore file copy
- snapshot only as a short-lived staging mechanism, not as a long-term backup
- guest-aware backup tooling when the user has already approved it

Snapshot creation is not the same as a backup. Snapshots can grow quickly and should be kept short-lived.

## Restore patterns

Before restoring, record:

- the original datastore path
- the original VM name and inventory state
- the expected post-restore power state
- any network mapping that may need to be recreated

Prefer a restore path that can be reversed. If the restore will overwrite an existing file or VM, stop and obtain explicit approval naming the exact target.

## Verification

After a backup or restore, verify:

- file size or checksum, if practical
- VM registration and power state
- datastore free space after the operation
- whether the rollback path is still available

## Rollback notes

If a restore fails halfway, do not assume the partial result is safe to reuse. Re-check the datastore, VM inventory, and snapshot state before trying again.

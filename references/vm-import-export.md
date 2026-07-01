# VM import and export

Use this guide for OVF, OVA, and VMDK import/export work on standalone ESXi.

## Before importing or exporting

- Confirm the VM name, datastore, and destination path.
- Check datastore free space.
- Confirm the target network mapping.
- Record the original object path or inventory name for rollback.
- Ask for approval before overwriting an existing VM or datastore object.

## Import patterns

Common import paths include:

- `ovftool` when available locally
- REST `/folder/` or OVF deployment endpoints when they are supported on the target version
- datastore browser uploads for the raw files that the import consumes

Use host-specific datastore and portgroup names from a local profile, not from the generic skill.

## Export patterns

Common export paths include:

- `ovftool` export from the inventory path
- datastore file copies for raw VMDKs and related artifacts
- REST or browser download endpoints when appropriate

## Verification

After an import or export, verify:

- file size or checksum when practical
- inventory registration
- VM power state
- network attachment
- datastore free space

## Rollback notes

If an import fails, stop before retrying blindly. Re-check the datastore path, file completeness, and network mapping first.

# ESXi file transfer reference

Start from [`../SKILL.md`](../SKILL.md) for policy, approval rules, and local-profile conventions.

Use datastore names from a local profile or an approved plan. Do not hardcode real host-specific datastore names into generic documentation.

## Preconditions

Before uploading or restoring anything, verify:

- target datastore free space
- target path
- whether overwrite would occur
- whether the requested transfer is read-only or destructive

## HTTP datastore browser examples

```bash
curl --fail --show-error -T /local/path/to/file.iso \
  "https://$ESXI_HOST/folder/isos/file.iso?dcPath=ha-datacenter&dsName=<transfer-datastore>" \
  -u "$ESXI_USER:$ESXI_PASS"

curl --fail --show-error -o /local/output/file.vmdk \
  "https://$ESXI_HOST/folder/myvms/file.vmdk?dcPath=ha-datacenter&dsName=<vm-datastore>" \
  -u "$ESXI_USER:$ESXI_PASS"
```

These `-u` examples are intentionally simple. Do not log or share commands that contain real passwords.

## Browsing datastore contents

```bash
curl --fail --show-error "https://$ESXI_HOST/folder?dcPath=ha-datacenter&dsName=<vm-datastore>" \
  -u "$ESXI_USER:$ESXI_PASS"
```

This `/folder` listing path is a practical first check for standalone ESXi when the Host Client is reachable but REST session creation fails. A `200` response with an HTML listing confirms that credentials and datastore-browser access work; it does not prove that vCenter-style REST endpoints are available.

## OVF / OVA import and export

```bash
ovftool \
  --noSSLVerify \
  --acceptAllEulas \
  --name="my-imported-vm" \
  --datastore=<vm-datastore> \
  --network="<portgroup>" \
  /local/path/to/vm.ova \
  "vi://$ESXI_USER:$ESXI_PASS@$ESXI_HOST"
```

Import and export are approval-gated when they overwrite or create inventory objects. Capture the original path, name, and network mapping before making changes.

## SCP examples

```bash
scp -i "$ESXI_SSH_KEY" \
  -o UserKnownHostsFile="$ESXI_KNOWN_HOSTS" \
  -o StrictHostKeyChecking=yes \
  /local/file.iso \
  "$ESXI_USER@$ESXI_HOST:/vmfs/volumes/<transfer-datastore>/isos/file.iso"
```

## Tips

- Verify file size after upload.
- Compare checksums when practical.
- Prefer a dedicated transfer datastore if the local profile provides one.
- Use `--progress-bar` or a checksum step for large or important files.
- If SSH/SFTP auth is flaky, prefer the HTTPS `/folder/` endpoint instead of repeating retries.
- If SSH port 22 is closed or unreachable, do not retry SCP/SFTP loops. Use the HTTPS Host Client or `/folder/` endpoint and record SSH as unavailable for the session.

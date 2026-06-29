# ESXi File Transfer Reference

Covers uploading and downloading ISOs, OVFs, VMDKs, and other files to/from ESXi datastores.

Start from [`../SKILL.md`](../SKILL.md) for safety rules and environment conventions. Check datastore free space before uploads, restores, OVF/OVA imports, or VMDK transfers.

Default target for transfers: **`backup_nfs41`** (100 GB NFS volume, purpose-built for this use case).
Large VM disk files go to **`datastore1`** (3.37 TB free VMFS6).

---

## Upload a File to a Datastore (HTTP PUT)

ESXi exposes datastore contents over HTTPS at:
```
https://$ESXI_HOST/folder/<path>?dcPath=ha-datacenter&dsName=<datastore-name>
```

### Upload an ISO

Before uploading, verify the target directory and available space on `backup_nfs41`.

```bash
curl -sk -T /local/path/to/ubuntu.iso \
  "https://$ESXI_HOST/folder/isos/ubuntu.iso?dcPath=ha-datacenter&dsName=backup_nfs41" \
  -u "$ESXI_USER:$ESXI_PASS"
```

### Upload a VMDK

Before uploading, verify available space on `datastore1` and confirm the VMDK will not overwrite an existing disk.

```bash
curl -sk -T /local/path/to/disk.vmdk \
  "https://$ESXI_HOST/folder/uploads/disk.vmdk?dcPath=ha-datacenter&dsName=datastore1" \
  -u "$ESXI_USER:$ESXI_PASS"
```

Notes:
- The folder path in the URL is relative to the datastore root. Create subdirectories as needed.
- For large files, add `--limit-rate` or monitor with `--progress-bar`.
- Authentication here uses HTTP basic auth (`-u`), not the session token.

---

## Download a File from a Datastore (HTTP GET)

```bash
curl -sk -o /local/output/file.vmdk \
  "https://$ESXI_HOST/folder/myvms/disk.vmdk?dcPath=ha-datacenter&dsName=datastore1" \
  -u "$ESXI_USER:$ESXI_PASS"
```

---

## Browse Datastore Contents

```bash
# List root of a datastore
curl -sk \
  "https://$ESXI_HOST/folder?dcPath=ha-datacenter&dsName=datastore1" \
  -u "$ESXI_USER:$ESXI_PASS"

# List a specific subdirectory
curl -sk \
  "https://$ESXI_HOST/folder/isos/?dcPath=ha-datacenter&dsName=backup_nfs41" \
  -u "$ESXI_USER:$ESXI_PASS"
```

---

## Deploy an OVF/OVA

For standalone ESXi 7.0, use `ovftool` (VMware's CLI tool) or the vSphere REST API OVF deploy endpoint.

Preflight: check datastore free space, confirm target port group, and prefer `PG-RESTRICTED` unless the imported VM requires external access.

### Using ovftool (if installed locally)

```bash
ovftool \
  --noSSLVerify \
  --acceptAllEulas \
  --name="my-imported-vm" \
  --datastore=datastore1 \
  --network="VM Network" \
  /local/path/to/vm.ova \
  "vi://$ESXI_USER:$ESXI_PASS@$ESXI_HOST"
```

### Using the REST API

```bash
# Step 1: Create OVF deployment target
DEPLOY_TARGET=$(curl -sk -X POST \
  "https://$ESXI_HOST/api/vcenter/ovf/library-item?action=deploy" \
  -H "vmware-api-session-id: $SESSION" \
  -H "Content-Type: application/json" \
  -d '{
    "deployment_spec": {
      "name": "my-vm",
      "accept_all_EULA": true,
      "default_datastore_id": "datastore-NNN",
      "network_mappings": [{ "key": "VM Network", "value": "network-NNN" }]
    },
    "target": { "resource_pool_id": "resgroup-NNN" }
  }')
```

OVF deploy via REST is complex on standalone ESXi 7 (no Content Library). Prefer `ovftool` when available.

---

## Export a VM as OVF/OVA

```bash
ovftool \
  --noSSLVerify \
  "vi://$ESXI_USER:$ESXI_PASS@$ESXI_HOST/ha-datacenter/vm/my-vm-name" \
  /local/export/my-vm.ova
```

---

## SCP via SSH (for files already on the host)

To move files between datastores or copy config files:

```bash
# Copy file from local machine into ESXi datastore path
scp -i $ESXI_SSH_KEY -o StrictHostKeyChecking=no \
  /local/file.iso \
  $ESXI_USER@$ESXI_HOST:/vmfs/volumes/backup_nfs41/isos/file.iso

# Copy from ESXi to local
scp -i $ESXI_SSH_KEY -o StrictHostKeyChecking=no \
  $ESXI_USER@$ESXI_HOST:/vmfs/volumes/datastore1/myvm/myvm.vmdk \
  /local/backup/myvm.vmdk
```

---

## Tips

- Always verify a transfer completed by checking file size on the datastore after upload.
- ISO files belong in `backup_nfs41/isos/` by convention — keeps `datastore1` clean for VM working files.
- VMDK flat files can be very large; prefer SCP or `curl` with `--progress-bar` for visibility on large uploads.
- When the ESXi host is under load, file transfers will slow down — schedule large transfers during off-hours if VMs are active.

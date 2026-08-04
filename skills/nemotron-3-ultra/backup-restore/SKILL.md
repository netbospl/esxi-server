---
name: nemotron-3-ultra-backup-restore
description: "Nemotron-optimized ESXi backup and restore operations: structured capability probing, datastore space verification, export/import patterns, and validation gates. Use when running on Nemotron 3 Ultra 550B A55B and performing ESXi backup/restore tasks."
---

# Nemotron 3 Ultra — Backup & Restore Operations

## Scope

Model-specific tuning for the **NVIDIA Nemotron 3 Ultra 550B A55B** running in Hermes. This sub-skill wraps the model-agnostic `esxi-server` skill with Nemotron-optimized patterns for ESXi backup and restore operations.

**Parent skill:** [`../../../SKILL.md`](../../../SKILL.md) — load it first. This variant only adds Nemotron-specific guidance; all core procedures, task router, and references remain in the parent.

**Reference:** [`../../../references/backup-restore.md`](../../../references/backup-restore.md) — load for command syntax and working rules.

**Related:** [`../../../references/host-configuration-backup.md`](../../../references/host-configuration-backup.md) for host config backup/restore.

## Nemotron Model Profile

Load [`../model-profile.md`](../model-profile.md). The active Hermes context
limit—not the published model ceiling—controls batching and disclosure.

## Backup/Restore-Specific Reasoning Protocol

Apply the **Multi-Step Reasoning Protocol** from the parent skill to every backup/restore task:

```text
FACTS:
- ESXi version/build, target VM (name, UUID, VMID), power state, RAM, disk layout
- Datastore: name, UUID, free space (bytes), type (VMFS/NFS)
- Capability probe: SSH PASS, REST PARTIAL/BLOCKED
- Backup method: VM export (OVF/OVA), datastore file copy, snapshot staging
- Restore target: new VM registration or overwrite existing (requires approval)

HYPOTHESES (2-3 distinct, with evidence):
1. Root cause/outcome hypothesis with supporting fact
2. Alternative hypothesis with supporting fact
3. Less likely but possible hypothesis

NEXT R0 CHECK:
- Exactly ONE read-only command to discriminate hypotheses

CHANGE GATE (before any R1-R3):
- RISK CLASS: R1 (export) / R2 (restore to new VM) / R3 (overwrite/restore with data loss risk)
- TARGET: Exact object (VMID, datastore path, backup file)
- CHANGE: Exact command/API call with quoted variables
- PREFLIGHT: Verified space, power state, network mapping, no active sessions
- ROLLBACK: Exact inverse (delete export, unregister VM, revert snapshot)
- VERIFICATION: Read-only confirmation (file size, checksum, VM registration, power state)
- APPROVAL REQUIRED: Explicit user confirmation text
```

## Tool-Calling Patterns for Backup/Restore Operations

### 1. Pre-Flight Discovery (Always First)

```bash
# Nemotron: structured, batched, version-aware
: "${ESXI_HOST:?}" "${ESXI_USER:=agent}" "${ESXI_SSH_KEY:?}"
ssh -i "${ESXI_SSH_KEY}" -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="${ESXI_KNOWN_HOSTS}" \
    "${ESXI_USER}@${ESXI_HOST}" \
    'vim-cmd vmsvc/getallvms &&
     esxcli storage filesystem list --formatter=csv &&
     esxcli storage filesystem list --formatter=csv | grep <DATASTORE>'
```

### 2. VM Export (OVF/OVA) - R1 or R2

```bash
# Get VMID first (never guess)
VMID=$(ssh -i "${ESXI_SSH_KEY}" -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="${ESXI_KNOWN_HOSTS}" \
    "${ESXI_USER}@${ESXI_HOST}" \
    'vim-cmd vmsvc/getallvms' | awk -v name="${VM_NAME}" '$2==name {print $1}')

# A required power-off is a separate R2 action. Run only after approval and
# retain the observed pre-change power state for restoration.
ssh -i "${ESXI_SSH_KEY}" -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="${ESXI_KNOWN_HOSTS}" \
    "${ESXI_USER}@${ESXI_HOST}" \
    "vim-cmd vmsvc/power.off ${VMID}"

# Run ovftool on the management workstation, not inside the ESXi shell.
# Trust the exact ESXi certificate and let ovftool prompt for the password.
: "${VM_INVENTORY_PATH:?}" "${OVFTOOL_OUTPUT_DIR:?}"
ovftool "vi://${ESXI_USER}@${ESXI_HOST}/${VM_INVENTORY_PATH}" \
  "${OVFTOOL_OUTPUT_DIR}/${VM_NAME}.ova"
```

Do not embed `ESXI_PASS` in a URI or command line and do not add a TLS-bypass
flag. STOP if certificate verification fails or the destination already exists
without explicit overwrite approval.

### 3. Datastore File Copy - R1

```bash
# Copy VMDK between datastores (VM must be powered off)
ssh -i "${ESXI_SSH_KEY}" -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="${ESXI_KNOWN_HOSTS}" \
    "${ESXI_USER}@${ESXI_HOST}" \
    "vmkfstools -i /vmfs/volumes/${SRC_DATASTORE}/${VM_NAME}/${VM_NAME}.vmdk \
     -d thin /vmfs/volumes/${DST_DATASTORE}/${VM_NAME}/${VM_NAME}.vmdk"
```

### 4. Snapshot Staging (Short-lived only) - R1

```bash
# Create snapshot before risky operation
ssh -i "${ESXI_SSH_KEY}" -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="${ESXI_KNOWN_HOSTS}" \
    "${ESXI_USER}@${ESXI_HOST}" \
    "vim-cmd vmsvc/snapshot.create ${VMID} 'pre-change-$(date +%s)' 'Staging snapshot' 0 0"

# List snapshots to verify
ssh -i "${ESXI_SSH_KEY}" -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="${ESXI_KNOWN_HOSTS}" \
    "${ESXI_USER}@${ESXI_HOST}" \
    "vim-cmd vmsvc/get.snapshot ${VMID}"

# Select the ID from the freshly observed tree and match its name/path to the
# approved rollback point. Never assume snapshot ID 0.
: "${SNAPSHOT_ID:?set from fresh get.snapshot output and exact approval}"

# Revert if needed (R2 - service disruptive)
ssh -i "${ESXI_SSH_KEY}" -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="${ESXI_KNOWN_HOSTS}" \
    "${ESXI_USER}@${ESXI_HOST}" \
    "vim-cmd vmsvc/snapshot.revert ${VMID} ${SNAPSHOT_ID} 0"
```

### 5. Structured Output Parsing

```bash
# GOOD: CSV with field-based extraction for datastore space
esxcli storage filesystem list --formatter=csv | awk -F, 'NR>1 && $1=="<DATASTORE>" {print $4,$5}'

# GOOD: JSON for VM list where available
vim-cmd vmsvc/getallvms  # Note: vim-cmd doesn't have --formatter, parse with awk

# Parse VM list reliably
vim-cmd vmsvc/getallvms | awk 'NR>1 && $2!="" {print $1,$2,$3,$4,$5}'
```

### 6. Batch Verification After Operation

```python
execute_code(code='''
from hermes_tools import terminal
# Batch: verify backup/restore result
cmds = [
  "ls -lh /vmfs/volumes/<DATASTORE>/exports/<VM_NAME>.ova",
  "sha256sum /vmfs/volumes/<DATASTORE>/exports/<VM_NAME>.ova",
  "vim-cmd vmsvc/getallvms | grep <VM_NAME>",
  "esxcli storage filesystem list --formatter=csv | grep <DATASTORE>"
]
results = {}
for c in cmds:
    results[c] = terminal(command=f"ssh -i \\\"$ESXI_SSH_KEY\\\" -o StrictHostKeyChecking=yes -o UserKnownHostsFile=\\\"$ESXI_KNOWN_HOSTS\\\" \\\"$ESXI_USER@$ESXI_HOST\\\" \\'{c}\\'")
''')
```

## Backup/Restore Method Selection

| Method | Use Case | Risk | Space Required |
|---|---|---|---|
| VM Export (OVF/OVA) | Full VM backup, migration | R1 if already off; R2 for power-off/import | Destination capacity plus working margin |
| Datastore File Copy | Clone VMDK, move between datastores | R1 (copy), R2 (overwrite) | 1x VM size on destination |
| Snapshot Staging | Pre-change rollback point | R1 (create), R2 (revert) | Grows with changes |
| Host Config Backup | ESXi host config only | R2 (restore) | ~10-50MB |

**Nemotron rule:** Snapshots are NOT backups. They grow unbounded and are for short-lived staging only. Always verify datastore free space before snapshot create.

## Risk Classification & Approval Framing

```text
RISK CLASS: R2 when export requires a service-disruptive VM power-off
TARGET: ESXi host ${ESXI_HOST}, VM "${VM_NAME}" (VMID=${VMID}), datastore ${DATASTORE}
CHANGE: Preserve power state → approved power-off → local ovftool export → restore power state
PREFLIGHT:
  - VM powered off confirmed
  - Management-workstation destination capacity is sufficient
  - No active snapshots on VM
  - ovftool available on management workstation
ROLLBACK: Remove the incomplete export only after exact-path verification; restore the observed power state
VERIFICATION: File exists, size > 0, sha256 matches source (if computed)
APPROVAL REQUIRED: Explicit "APPROVE R2: power off and export ${VM_NAME} to ${OVFTOOL_OUTPUT_DIR}"
```

```text
RISK CLASS: R3 (destructive: restore overwriting existing VM)
TARGET: ESXi host ${ESXI_HOST}, datastore ${DATASTORE}, VM "${VM_NAME}" (existing VMID=${OLD_VMID})
CHANGE: Unregister old VM → deploy OVF → register new VM → configure network
PREFLIGHT:
  - OVF/OVA file verified (size, checksum)
  - Datastore free space > VM provisioned size
  - Target port group exists and has capacity
  - No active sessions on old VM
  - Independent backup of old VM confirmed (separate from this restore)
ROLLBACK: Unregister new VM → re-register old VM from backup
VERIFICATION: New VM powered on, network reachable, services running
APPROVAL REQUIRED: Explicit "APPROVE R3: restore ${VM_NAME} from OVA, overwriting existing"
```

## Common Nemotron Failure Modes (Backup/Restore-Specific)

- ❌ Exporting VM while powered on (inconsistent state)
- ❌ Not verifying datastore free space before export/copy/snapshot
- ❌ Using snapshots as long-term backups (they grow, consume space, affect performance)
- ❌ Guessing VMID instead of confirming via `vim-cmd vmsvc/getallvms`
- ❌ Overwriting existing VM without R3 approval and independent backup
- ❌ Skipping checksum verification on exported/imported files
- ❌ Not recording original VM network mapping before restore
- ❌ Using `df -h` on SSH instead of `esxcli storage filesystem list`
- ❌ Forgetting to power on VM after export if it was originally running
- ❌ Not cleaning up staging snapshots after operation completes

## Profile Variable Substitution

Treat the local Markdown profile as data, never as shell. Copy only required,
freshly verified fields into the protected management-workstation environment.
Keep the password out of the URI and let `ovftool` prompt for it:

```bash
: "${ESXI_HOST:?}" "${ESXI_USER:?}" "${VM_ROUTER:?}" \
  "${OVFTOOL_OUTPUT_DIR:?}"
ovftool "vi://${ESXI_USER}@${ESXI_HOST}/${VM_ROUTER}" \
  "${OVFTOOL_OUTPUT_DIR}/${VM_ROUTER}.ova"
```

## Validation Gates (Before Reporting Complete)

- [ ] Required env vars checked (no secrets printed)
- [ ] Local profile loaded or absence noted
- [ ] Capability probe performed, transport documented
- [ ] Datastore free space verified before operation
- [ ] VM power state confirmed before export/restore
- [ ] Every state change approved at R1/R2/R3 level with explicit confirmation
- [ ] Rollback command documented and tested (where applicable)
- [ ] Post-change state verified: file size/checksum, VM registration, power state, network
- [ ] No credentials, tokens, private IPs, logs, keys, `.env` in repo
- [ ] Staging snapshots cleaned up (if created)
- [ ] Facts → Hypotheses → R0 check → Change gate → Verify documented

## Quick Reference Card

| Task | Nemotron Do | Nemotron Don't |
|---|---|---|
| Pre-flight | Batched `vim-cmd getallvms` + `esxcli storage filesystem` | Guess VMID; skip space check |
| Export VM | Power off → ovftool → verify checksum → power on | Export while running; skip verify |
| Copy VMDK | `vmkfstools -i` with thin provisioning | `cp` on SSH (wrong block handling) |
| Snapshot | Create with timestamped name → verify → clean up after | Keep indefinitely; skip space check |
| Restore | R3 approval → independent backup → deploy → verify | Overwrite without R3; skip network remap |
| Host config | `vim-cmd hostsvc/firmware/backup_config` → verify bundle | Restore without maintenance window |

---

**See also:**

- Parent: [`../../../SKILL.md`](../../../SKILL.md)
- Reference: [`../../../references/backup-restore.md`](../../../references/backup-restore.md)
- Host Config Backup: [`../../../references/host-configuration-backup.md`](../../../references/host-configuration-backup.md)
- Stable SSH Shell Nemotron variant: [`../stable-ssh-shell/SKILL.md`](../stable-ssh-shell/SKILL.md)
- ESXi Operations Nemotron variant: [`../esxi-operations/SKILL.md`](../esxi-operations/SKILL.md)

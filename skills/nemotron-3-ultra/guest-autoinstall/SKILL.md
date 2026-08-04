---
name: nemotron-3-ultra-guest-autoinstall
description: "Nemotron-optimized guest OS unattended installation on ESXi: structured ISO/media generation, answer-file validation, VM deployment, and post-install verification. Use when running on Nemotron 3 Ultra 550B A55B and performing guest OS auto-installs."
---

# Nemotron 3 Ultra — Guest OS Auto-Install

## Scope

Model-specific tuning for the **NVIDIA Nemotron 3 Ultra 550B A55B** running in Hermes. This sub-skill wraps the model-agnostic `esxi-server` skill with Nemotron-optimized patterns for guest OS unattended installation inside VMs on ESXi.

**Parent skill:** [`../../../SKILL.md`](../../../SKILL.md) — load it first. This variant only adds Nemotron-specific guidance; all core procedures, task router, and references remain in the parent.

**Reference:** [`../../../references/guest-os-autoinstall.md`](../../../references/guest-os-autoinstall.md) — load for method matrix, compatibility, and templates.

**Examples:** [`../../../examples/guest-autoinstall/`](../../../examples/guest-autoinstall/) — answer files, Packer templates, ISO generators.

## Nemotron Model Profile

Load [`../model-profile.md`](../model-profile.md). The active Hermes context
limit—not the published model ceiling—controls batching and disclosure.

## Guest Auto-Install Reasoning Protocol

Apply the **Multi-Step Reasoning Protocol** from the parent skill to every guest install task:

```text
FACTS:
- ESXi version/build, target VM (name, UUID, VMID if exists), firmware (BIOS/EFI)
- Guest OS: type, version, ISO path, answer-file variant
- Datastore: name, free space, ISO store location
- Network: port group for install, post-install network
- Capability probe: SSH PASS, REST PARTIAL/BLOCKED

HYPOTHESES (2-3 distinct, with evidence):
1. Answer-file variant matches guest OS version/firmware exactly
2. ISO/media generation will produce bootable media
3. VM hardware config matches guest OS requirements

NEXT R0 CHECK:
- Exactly ONE read-only command to verify preconditions

CHANGE GATE (before any R1-R3):
- RISK CLASS: R2 (VM creation, disk allocation) / R3 (disk overwrite, external network attach)
- TARGET: Exact object (VMID, datastore path, ISO, answer media)
- CHANGE: Exact commands/API calls with quoted variables
- PREFLIGHT: ISO verified, answer-file validated, datastore space, network isolated
- ROLLBACK: Delete VM, remove ISO/media, free datastore space
- VERIFICATION: VM powered on, install progressing, post-install checks pass
- APPROVAL REQUIRED: Explicit user confirmation text
```

## Tool-Calling Patterns for Guest Auto-Install

### 1. Pre-Flight Validation (Always First)

```bash
# Nemotron: structured validation pipeline
: "${ESXI_HOST:?}" "${ESXI_USER:=agent}" "${ESXI_SSH_KEY:?}"

# 1. Verify ISO exists on datastore
ssh -i "${ESXI_SSH_KEY}" -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="${ESXI_KNOWN_HOSTS}" \
    "${ESXI_USER}@${ESXI_HOST}" \
    "ls -la /vmfs/volumes/${ISO_DATASTORE}/isos/${GUEST_ISO}"

# 2. Verify answer-file template exists locally
ls -la examples/guest-autoinstall/${GUEST_OS}/${ANSWER_FILE_TEMPLATE}

# 3. Check datastore free space for VM + answer media
ssh -i "${ESXI_SSH_KEY}" -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="${ESXI_KNOWN_HOSTS}" \
    "${ESXI_USER}@${ESXI_HOST}" \
    "esxcli storage filesystem list --formatter=csv | grep ${VM_DATASTORE}"

# 4. Verify port group exists
ssh -i "${ESXI_SSH_KEY}" -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="${ESXI_KNOWN_HOSTS}" \
    "${ESXI_USER}@${ESXI_HOST}" \
    "esxcli network vswitch standard portgroup list | grep ${PORTGROUP}"
```

### 2. Answer-File Preparation (Local, No Secrets)

```bash
# Nemotron: always use local working directory, sanitize before use
mkdir -p /tmp/guest-autoinstall/${VM_NAME}
cd /tmp/guest-autoinstall/${VM_NAME}

# Copy EXACT variant (never modify committed templates)
cp /home/netbos/Documents/GitHub/esxi-server/examples/guest-autoinstall/${GUEST_OS}/${ANSWER_FILE_TEMPLATE} \
   ./Autounattend.xml  # or user-data, ks.cfg, preseed.cfg

# Validate XML well-formedness (Windows)
xmllint --noout ./Autounattend.xml

# Validate cloud-init schema (Ubuntu)
cloud-init schema --config-file ./user-data

# Verify no real secrets in answer file
grep -i "password\|key\|token" ./Autounattend.xml | grep -v "placeholder\|REPLACE" && echo "WARNING: Potential secrets found"
```

### 3. Answer Media Generation

```bash
# Windows: genisoimage for Autounattend.xml on virtual floppy/ISO
genisoimage -o /tmp/guest-autoinstall/${VM_NAME}/answer.iso \
    -V "ANSWER" -r -J /tmp/guest-autoinstall/${VM_NAME}/Autounattend.xml

# Ubuntu: cloud-localds for NoCloud seed ISO
cloud-localds /tmp/guest-autoinstall/${VM_NAME}/seed.iso \
    /tmp/guest-autoinstall/${VM_NAME}/user-data \
    /tmp/guest-autoinstall/${VM_NAME}/meta-data

# Transfer to ESXi datastore
scp -i "${ESXI_SSH_KEY}" -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="${ESXI_KNOWN_HOSTS}" \
    /tmp/guest-autoinstall/${VM_NAME}/answer.iso \
    "${ESXI_USER}@${ESXI_HOST}:/vmfs/volumes/${ISO_DATASTORE}/autoinstall/${VM_NAME}/"
```

### 4. VM Creation and Deployment

Do not execute placeholder commands, ellipses, guessed `vim-cmd` device
subcommands, or a partial VMX recipe. Select one proven path for the observed
environment:

- use the bundled Packer templates only with compatible vCenter/licensed
  vSphere API access and successful isolated `packer validate`;
- otherwise use the ESXi Host Client/manual fallback described in the parent
  reference, recording the exact firmware, guest type, disk, controllers,
  vNIC/port group, boot order, OS ISO, and answer-media attachment;
- use SSH/API automation only when every exact create/reconfigure/attach command
  is documented for the observed ESXi build and independently validated before
  approval.

VM creation, disk allocation, device attachment, and power-on are R2. A reused
disk, disk wipe, or external-network attachment is R3. After creation, obtain a
fresh VM UUID and VMID; never parse an assumed ID from an undocumented command
shape.

### 5. Install Monitoring and Verification

```bash
# Nemotron: poll for install progress, don't assume completion
# Check VM power state
ssh -i "${ESXI_SSH_KEY}" -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="${ESXI_KNOWN_HOSTS}" \
    "${ESXI_USER}@${ESXI_HOST}" \
    "vim-cmd vmsvc/power.getstate ${VMID}"

# Check console for install progress (via Host Client or SDK screenshot)
# For stuck installs: detect stall vs progress
# Use vim-cmd vmsvc/get.guest to check guest heartbeat (requires VMware Tools)
```

### 6. Batch Post-Install Verification

```python
execute_code(code='''
from hermes_tools import terminal
# Batch: verify post-install state
cmds = [
  "vim-cmd vmsvc/get.guest ${VMID} | grep -E 'ipAddress|hostName|guestFamily'",
  "vim-cmd vmsvc/power.getstate ${VMID}",
  "esxcli storage filesystem list --formatter=csv | grep ${VM_DATASTORE}",
  # From management workstation: SSH/ping to guest IP
]
results = {}
for c in cmds:
    results[c] = terminal(command=f"ssh -i \\\"$ESXI_SSH_KEY\\\" -o StrictHostKeyChecking=yes -o UserKnownHostsFile=\\\"$ESXI_KNOWN_HOSTS\\\" \\\"$ESXI_USER@$ESXI_HOST\\\" \\'{c}\\'")
''')
```

## Guest OS Variant Selection Matrix

| Guest OS | Firmware | Answer File | Delivery | Nemotron Notes |
|---|---|---|---|---|
| Windows 10 | BIOS/MBR | `autounattend-win10-bios-mbr.xml` | Secondary ISO | Legacy; prefer UEFI |
| Windows 10 | UEFI/GPT | `autounattend-win10-uefi-gpt.xml` | Secondary ISO | Standard |
| Windows 11 | UEFI/GPT | `autounattend-win11-uefi-gpt.xml` | Secondary ISO | TPM 2.0 required in VM |
| Windows Server 2022 | UEFI/GPT | `autounattend-server2022-uefi-gpt.xml` | Secondary ISO | Server defaults |
| Ubuntu Server | UEFI | `user-data` + `meta-data` | NoCloud seed ISO | cloud-init schema validate |
| RHEL/Rocky/Alma | UEFI | `ks.cfg` | HTTP/ISO/removable | `inst.ks=` kernel param |
| Debian | UEFI | `preseed.cfg` | HTTP/initrd/ISO | `preseed/url=` kernel param |
| Packer | UEFI | `*.pkr.hcl` | vSphere API | `vsphere-iso` builder |

**Nemotron rule:** Always use the EXACT committed variant filename. Copy to local `Autounattend.xml` / `user-data` / `ks.cfg` / `preseed.cfg` as the root filename the installer expects. Never rename committed template files.

## Windows OOBE Local Account (Nemotron-Specific)

For Windows 11 local account without Microsoft account:

```text
PREFERRED: Use answer-file variant with Microsoft-Windows-Shell-Setup → UserAccounts → LocalAccounts
FALLBACK: Shift+F10 at OOBE network prompt → manual commands (version-dependent, not guaranteed)
NEVER: Bypass activation/licensing
```

## Risk Classification & Approval Framing

```text
RISK CLASS: R2 (VM creation, disk allocation, ISO attach)
TARGET: ESXi host ${ESXI_HOST}, datastore ${VM_DATASTORE}, new VM "${VM_NAME}"
CHANGE: Create VM → configure hardware → attach OS ISO + answer ISO → power on
PREFLIGHT:
  - Guest OS ISO verified (checksum, version)
  - Answer file validated (schema, no secrets)
  - Datastore free space > VM provisioned + 20% overhead
  - Port group exists, isolated (no external access during install)
  - VM firmware matches answer file (BIOS vs UEFI)
ROLLBACK: power off and isolate the new VM; unregister or delete disks only under the separately approved R3 scope; remove answer media after exact-path verification
VERIFICATION: VM powered on, install screen visible, guest heartbeat (post-Tools)
APPROVAL REQUIRED: Explicit "APPROVE R2: create and install ${VM_NAME} (${GUEST_OS}) on ${VM_DATASTORE}"
```

```text
RISK CLASS: R3 (disk overwrite, external network attach)
TARGET: ESXi host ${ESXI_HOST}, existing VM "${VM_NAME}" (VMID=${VMID})
CHANGE: Reconfigure existing VM → attach new OS ISO → power on → connect to external network
PREFLIGHT:
  - Independent backup of existing VM confirmed
  - External network attachment approved separately
  - Post-install firewall/VPN rules verified
ROLLBACK: Restore from backup; detach external network
VERIFICATION: Services running, external reachability confirmed, no unexpected open ports
APPROVAL REQUIRED: Explicit "APPROVE R3: reinstall ${VM_NAME} and attach to external network ${PORTGROUP}"
```

## Common Nemotron Failure Modes (Guest Auto-Install-Specific)

- ❌ Using wrong answer-file variant for guest OS version/firmware (e.g., Win10 BIOS for Win11 UEFI)
- ❌ Not validating answer-file schema before media generation
- ❌ Embedding real passwords/keys in answer files (use placeholders only)
- ❌ Attaching answer media to wrong device (CDROM vs floppy)
- ❌ Not setting boot order to boot from OS ISO first
- ❌ Assuming install completes without monitoring (stuck at OOBE, license, partition)
- ❌ Not isolating install network (VM gets external access mid-install)
- ❌ Skipping VMware Tools / open-vm-tools installation post-install
- ❌ Using `df -h` instead of `esxcli storage filesystem list` for datastore space
- ❌ Not cleaning up answer ISOs after install completes
- ❌ Confusing ESXi host scripted install (`ks.cfg`) with guest OS answer files

## Profile Variable Substitution

Treat the local Markdown profile as data, never as shell. Copy only required,
freshly verified fields into the protected environment:

```bash
: "${ANSWER_VARIANT:?}" "${VM_NAME:?}"
cp "examples/guest-autoinstall/windows/${ANSWER_VARIANT}" \
  "/tmp/guest-autoinstall/${VM_NAME}/Autounattend.xml"
```

## Validation Gates (Before Reporting Complete)

- [ ] Required env vars checked (no secrets printed)
- [ ] Local profile loaded or absence noted
- [ ] Capability probe performed, transport documented
- [ ] Guest OS ISO verified (checksum, version match)
- [ ] Answer-file variant matches guest OS version/firmware exactly
- [ ] Answer-file validated (XML/cloud-init schema, no real secrets)
- [ ] Datastore free space verified for VM + media
- [ ] Port group exists and is isolated for install
- [ ] VM firmware matches answer file (BIOS/UEFI)
- [ ] Every state change approved at R2/R3 level with explicit confirmation
- [ ] Install monitored for progress (not assumed complete)
- [ ] Post-install: VMware Tools / open-vm-tools installed
- [ ] Answer media cleaned up from datastore
- [ ] No credentials, tokens, private IPs, logs, keys, `.env` in repo
- [ ] Facts → Hypotheses → R0 check → Change gate → Verify documented

## Quick Reference Card

| Task | Nemotron Do | Nemotron Don't |
|---|---|---|
| Select variant | Match exact guest OS version + firmware | Guess; use Windows 10 for Windows 11 |
| Validate answer file | `xmllint`, `cloud-init schema` | Skip validation; embed real secrets |
| Generate media | Local working dir → ISO → transfer | Generate on ESXi (no tools) |
| Create VM | Proven vCenter/Packer path or documented Host Client fallback | Invent `vim-cmd` device commands; execute ellipses |
| Monitor install | Poll power state, console, guest heartbeat | Assume 30 min = done |
| Post-install | Install VMware Tools, verify IP, clean media | Leave answer ISO attached |
| Network | Isolated port group during install | External network during install |

---

**See also:**

- Parent: [`../../../SKILL.md`](../../../SKILL.md)
- Reference: [`../../../references/guest-os-autoinstall.md`](../../../references/guest-os-autoinstall.md)
- Examples: [`../../../examples/guest-autoinstall/`](../../../examples/guest-autoinstall/)
- Windows OOBE notes: [`../../../examples/guest-autoinstall/windows/oobe-local-account-notes.md`](../../../examples/guest-autoinstall/windows/oobe-local-account-notes.md)
- Stable SSH Shell Nemotron variant: [`../stable-ssh-shell/SKILL.md`](../stable-ssh-shell/SKILL.md)
- ESXi Operations Nemotron variant: [`../esxi-operations/SKILL.md`](../esxi-operations/SKILL.md)

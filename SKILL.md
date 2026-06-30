---
name: esxi-server
description: How to communicate with and operate a remote VMware ESXi 7.0 dedicated server via SSH (esxcli/vim-cmd) and the vSphere REST API. Use when the user asks to inspect or manage VMs, datastores, snapshots, networking, file transfers, or resources on a standalone ESXi host. Prioritizes read-only discovery, environment-based secrets, and explicit confirmation for destructive operations.
---

# ESXi Server Skill

## Overview

Use this skill to safely inspect and operate a standalone **VMware ESXi 7.0 / 7.0 Update 1c** host through SSH, `esxcli`, `vim-cmd`, vSphere REST API calls, and datastore file-transfer endpoints.

This is an AI-assisted operational skill. Treat every command as environment-sensitive: start with read-only discovery, avoid hardcoded secrets, and require explicit user confirmation before destructive or disruptive actions.

## Environment

| Detail | Value |
|---|---|
| Host | Read from env var `ESXI_HOST` |
| Username | Read from env var `ESXI_USER` (typically `root`) |
| Password | Read from secret/env var `ESXI_PASS` |
| SSH key path | Read from env var `ESXI_SSH_KEY` when key-based auth is preferred |
| REST API base | `https://$ESXI_HOST/api` (port 443, commonly self-signed TLS) |
| REST API session header | `vmware-api-session-id` |

Before any ESXi access, verify required configuration is present without printing secrets:

```bash
: "${ESXI_HOST:?ESXI_HOST is required}"
: "${ESXI_USER:?ESXI_USER is required}"
# Require either ESXI_PASS for REST/password auth or ESXI_SSH_KEY for key-based SSH.
printf 'Using ESXi host %s as user %s\n' "$ESXI_HOST" "$ESXI_USER"
```

If required values are missing, ask the user to provide them through their shell, local environment, or secret manager. Never request that secrets be pasted into repository files.

When working from a local repo that stores ESXi details on disk, confirm the exact filename instead of assuming `secrets.md`; this workspace used `ESXi_INFO.txt` for host details and `secrest.md` for credentials.

## Known Infrastructure Conventions

These names are conventions used by the reference docs. Confirm live state before relying on them.

| Item | Detail |
|---|---|
| ESXi version | VMware ESXi 7.0 / 7.0 Update 1c |
| CPU | 4× Intel Xeon E31220 |
| RAM | 15.97 GB total; check current usage before VM changes |
| Datastores | `datastore1` for normal VM storage; `backup_nfs41` for backups, ISOs, OVFs, and transfer staging |
| Port groups | `VM Network`, `PG-UNRESTRICTED`, `PG-RESTRICTED` |
| Restricted network | Treat `PG-RESTRICTED` as isolated/restricted |
| Unrestricted network | Treat `PG-UNRESTRICTED` as externally reachable or less restricted |

## Standard Safety Workflow

1. **Discover first.** Run read-only checks for host version, VM inventory, datastore free space, network names, and VM power state before planning changes.
2. **Select the least-risk interface.** Use REST for normal VM lifecycle and snapshots, SSH/`esxcli` for host-level checks, and datastore browser endpoints for file transfers.
3. **Check resources.** Verify host memory before creating or powering on VMs. Verify datastore free space before uploads, cloning, creating VMDKs, restoring backups, or snapshot-heavy operations.
4. **Check VM state.** Inspect power state before modifying VM hardware, disks, NICs, snapshots, or datastore files.
5. **Confirm networking.** Confirm port group choice before attaching or moving a VM NIC. Prefer least-privilege networking; use `PG-RESTRICTED` unless external access is required.
6. **Show dangerous actions.** For destructive or disruptive operations, show the command/API request and wait for explicit confirmation.
7. **Verify after changes.** Re-read VM, datastore, network, or snapshot state after any write operation.

On standalone ESXi, a successful REST login does not guarantee every `vcenter/*` inventory endpoint is implemented. If inventory reads return `400`, empty, or inconsistent data, fall back to `/sdk` + pyVmomi or SSH inventory instead of assuming bad credentials.

## Destructive Operations Require Explicit Confirmation

Never perform these without explicit user approval in the current task:

- Delete VMs, disks, VMDKs, datastore files, or datastores.
- Delete, revert, or remove all snapshots.
- Power off, reset, suspend, or reboot production or unknown VMs.
- Change vSwitches, VMkernel adapters, physical NIC bindings, port groups, or management networking.
- Attach a VM to `PG-UNRESTRICTED` or another externally reachable network.
- Increase VM CPU/RAM or create new VMDKs without checking host and datastore capacity.

Snapshots are not free backups. They consume datastore space and can grow quickly; check free space before creating snapshots and before leaving snapshots in place for extended periods.

## Secrets and Logging Rules

- Never hardcode credentials, session IDs, hostnames, private IPs, API tokens, SSH keys, cookies, or `.env` contents in repository files.
- Never commit `.env`, private keys, logs containing credentials, or copied command output containing sensitive host inventory.
- Use environment variables or a secret manager for `ESXI_HOST`, `ESXI_USER`, `ESXI_PASS`, and `ESXI_SSH_KEY`.
- Avoid printing `$ESXI_PASS`, REST session tokens, guest passwords, or HTTP `Authorization` headers.

## When to Use SSH vs REST API

| Task | Preferred method |
|---|---|
| Query host-level hardware, memory, storage, or network info | SSH + `esxcli` |
| List standalone ESXi VMs when REST is unavailable | SSH + `vim-cmd vmsvc/getallvms` |
| List, inspect, start, gracefully stop, or create VMs | REST API (`/api/vcenter/vm`) |
| Hard power operations | REST API or `vim-cmd`, only after confirming impact |
| Snapshot listing/creation/removal/revert | REST API; confirm before removal/revert |
| Datastore free-space checks | REST API or SSH + `esxcli storage filesystem list` |
| Datastore browsing | HTTPS datastore browser API or SSH path checks |
| Low-level networking (`vSwitch`, `vmk`, port groups) | SSH + `esxcli`; confirm before changes |
| Upload/download ISO, OVF, OVA, VMDK files | HTTPS datastore browser API (`/folder/`), SCP, or `ovftool`; prefer `/folder/` when SSH auth or SFTP is flaky |
| Run commands inside a guest VM | REST Guest Processes API when VMware Tools is running |

REST API sessions expire. If a request returns `401`, re-authenticate rather than reusing stale session tokens.

## Reference Files

Load only the reference file needed for the task:

- [`references/ssh-esxcli.md`](references/ssh-esxcli.md) — SSH connection patterns, `esxcli`, `vim-cmd`, read-only host checks, networking, datastore, and VM shell tips.
- [`references/rest-api.md`](references/rest-api.md) — vSphere REST API authentication, VM lifecycle, snapshots, datastores, resource checks, and guest processes.
- [`references/file-transfers.md`](references/file-transfers.md) — datastore browsing, ISO/OVF/OVA/VMDK uploads/downloads, SCP, and transfer verification.

## Common Preflight Checks

Use read-only checks before planning changes:

```bash
# Host version and memory over SSH
ssh -i "$ESXI_SSH_KEY" -o StrictHostKeyChecking=no \
  "$ESXI_USER@$ESXI_HOST" 'esxcli system version get && esxcli hardware memory get'

# Datastore capacity over SSH
ssh -i "$ESXI_SSH_KEY" -o StrictHostKeyChecking=no \
  "$ESXI_USER@$ESXI_HOST" 'esxcli storage filesystem list'

# VM inventory and power state over SSH
ssh -i "$ESXI_SSH_KEY" -o StrictHostKeyChecking=no \
  "$ESXI_USER@$ESXI_HOST" 'vim-cmd vmsvc/getallvms'
```

For REST API preflight, authenticate first, then list VMs, datastores, and networks:

```bash
SESSION=$(curl -sk -X POST \
  "https://$ESXI_HOST/api/session" \
  -u "$ESXI_USER:$ESXI_PASS" \
  -H "Content-Type: application/json" | tr -d '"')

curl -sk "https://$ESXI_HOST/api/vcenter/vm" \
  -H "vmware-api-session-id: $SESSION"

curl -sk "https://$ESXI_HOST/api/vcenter/datastore" \
  -H "vmware-api-session-id: $SESSION"

curl -sk "https://$ESXI_HOST/api/vcenter/network" \
  -H "vmware-api-session-id: $SESSION"
```

## TLS Notes

Standalone ESXi commonly uses a self-signed TLS certificate. The reference commands use `-k`, `--insecure`, `--noSSLVerify`, or equivalent code settings for that reason. Document this clearly in any new automation; do not silently disable certificate verification in unrelated contexts.

## Completion Checklist

Before reporting an ESXi task complete:

- [ ] Required environment variables/secrets were checked without printing secret values.
- [ ] Relevant reference file was used instead of loading unrelated procedures.
- [ ] Read-only discovery was performed first.
- [ ] Destructive or disruptive actions received explicit confirmation.
- [ ] RAM, datastore free space, VM power state, and network/port group choice were checked when relevant.
- [ ] Post-change state was verified with a read-only command or API call.
- [ ] No credentials, tokens, private hostnames/IPs, logs, SSH keys, or `.env` files were written to the repository.

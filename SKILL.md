---
name: esxi-server
description: How to communicate with and operate a remote VMware ESXi 7.0 dedicated server via SSH (esxcli) and the vSphere REST API. Use when the user asks to manage VMs, datastores, snapshots, networking, or resources on their ESXi host. Triggers on phrases like "ESXi", "vSphere", "my server", "VM", "datastore", "snapshot", "port group", "vSwitch", or any request to start/stop/create/delete virtual machines on the dedicated server.
---

# ESXi Server Skill

## Environment

The host runs **VMware ESXi 7.0 Update 1c** on a dedicated bare-metal machine.

| Detail | Value |
|---|---|
| Host | Read from env var `ESXI_HOST` |
| Username | Read from env var `ESXI_USER` (typically `root`) |
| Password | Read from secret `ESXI_PASS` |
| SSH key path | Read from env var `ESXI_SSH_KEY` (if key-based auth is preferred) |
| REST API base | `https://$ESXI_HOST/api` (port 443, self-signed cert) |
| REST API session header | `vmware-api-session-id` |

**Before any ESXi work**, check env vars are present:

```javascript
const result = await viewEnvVars({ type: "all", keys: ["ESXI_HOST", "ESXI_USER", "ESXI_SSH_KEY"] });
// Also check secret: ESXI_PASS
```

If any are missing, use `requestEnvVar` to ask the user before proceeding. See the environment-secrets skill.

## Known Infrastructure

| Item | Detail |
|---|---|
| CPU | 4× Intel Xeon E31220 |
| RAM | 15.97 GB |
| Datastores | `datastore1` (VMFS6, 3.58 TB / ~3.37 TB free), `backup_nfs41` (NFS 4.1, 100 GB / 100 GB free) |
| Port groups | `VM Network`, `PG-UNRESTRICTED`, `PG-RESTRICTED` |
| Active VMs | ~7 VMs across port groups |
| DNS | 8.8.8.8 / 1.1.1.1 |
| IPv6 | Enabled (dual-stack) |

## When to Use SSH vs REST API

| Task | Preferred method |
|---|---|
| Query host-level hardware/network info | SSH + `esxcli` |
| List/start/stop/delete VMs | REST API (`/api/vcenter/vm`) |
| Create VMs | REST API |
| Snapshot management | REST API |
| Datastore browsing | REST API |
| Low-level networking (vSwitch, vmk) | SSH + `esxcli` or `vim-cmd` |
| Upload files (ISO, OVF, VMDK) | `curl` via HTTPS datastore browser API |
| Run commands inside a guest VM | SSH + `vim-cmd vmsvc/guestinfo` or VMware Tools |

## Reference Files

- [`references/ssh-esxcli.md`](references/ssh-esxcli.md) — SSH connection patterns, common `esxcli` and `vim-cmd` commands, networking queries, and shell tips
- [`references/rest-api.md`](references/rest-api.md) — vSphere REST API: authentication, VM lifecycle, snapshots, datastores, resource monitoring
- [`references/file-transfers.md`](references/file-transfers.md) — Uploading and downloading ISOs, OVFs, and VMDKs to/from datastores

Load the relevant reference file(s) based on the task at hand. You rarely need all three at once.

## General Rules

- **Never hardcode credentials.** Always pull from env vars / secrets.
- **ESXi uses a self-signed TLS cert.** Pass `-k` or `--insecure` in curl, and set `verify=False` in Python requests, or use `NODE_TLS_REJECT_UNAUTHORIZED=0` in Node. Document this clearly in any code you write — it is intentional for a private dedicated server, not a security oversight.
- **REST API sessions expire.** Always re-authenticate if a 401 is returned; do not assume a session token persists across agent runs.
- **RAM is limited (15.97 GB).** When creating new VMs, be conservative with memory allocation. Warn the user if a request would over-commit RAM.
- **`datastore1` is the primary working datastore; `backup_nfs41` is for backups and ISO/OVF transfers.** Default new VMs and disks to `datastore1` unless the user specifies otherwise.
- **Port group choice matters.** `PG-RESTRICTED` isolates VMs from external traffic; `PG-UNRESTRICTED` allows it. Ask the user which to use if they don't specify when creating VMs.
- When writing shell commands for SSH, prefer single-quoted strings to avoid local variable expansion.

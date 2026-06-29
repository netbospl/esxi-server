# ESXi SSH & esxcli Reference

## Connecting via SSH

```bash
# Password-based
ssh -o StrictHostKeyChecking=no $ESXI_USER@$ESXI_HOST

# Key-based (preferred)
ssh -i $ESXI_SSH_KEY -o StrictHostKeyChecking=no $ESXI_USER@$ESXI_HOST

# Run a single remote command
ssh -i $ESXI_SSH_KEY -o StrictHostKeyChecking=no $ESXI_USER@$ESXI_HOST 'esxcli system version get'
```

`StrictHostKeyChecking=no` is intentional — ESXi uses a self-signed host key and is a known private host.

When using `sshpass` for password auth (non-interactive scripts):
```bash
sshpass -e ssh -o StrictHostKeyChecking=no $ESXI_USER@$ESXI_HOST 'command'
# SSHPASS env var holds the password — set it from ESXI_PASS secret
```

---

## Host Information

```bash
# ESXi version
esxcli system version get

# Hardware summary
esxcli hardware platform get
esxcli hardware cpu global get

# Memory info
esxcli hardware memory get

# System uptime
esxcli system stats uptime get
```

---

## VM Management via vim-cmd

`vim-cmd` is the CLI for VM operations on standalone ESXi (no vCenter needed).

```bash
# List all VMs with their VMID and display name
vim-cmd vmsvc/getallvms

# Get VM power state
vim-cmd vmsvc/power.getstate <vmid>

# Power operations
vim-cmd vmsvc/power.on <vmid>
vim-cmd vmsvc/power.off <vmid>       # hard power off
vim-cmd vmsvc/power.shutdown <vmid>  # graceful (requires VMware Tools)
vim-cmd vmsvc/power.reboot <vmid>

# Get VM summary (RAM, CPU, guest OS, tools status)
vim-cmd vmsvc/get.summary <vmid>

# Get guest info (IP, hostname — requires VMware Tools running)
vim-cmd vmsvc/get.guest <vmid>

# Delete a VM (must be powered off first)
vim-cmd vmsvc/destroy <vmid>
```

---

## Snapshot Management via vim-cmd

```bash
# List snapshots for a VM
vim-cmd vmsvc/snapshot.get <vmid>

# Create a snapshot
vim-cmd vmsvc/snapshot.create <vmid> "snapshot-name" "description" 0 0
# Args: vmid, name, desc, include_memory (0/1), quiesce (0/1)

# Revert to current snapshot
vim-cmd vmsvc/snapshot.revert <vmid> <snapshot-id> 0

# Remove a specific snapshot
vim-cmd vmsvc/snapshot.remove <vmid> <snapshot-id>

# Remove all snapshots
vim-cmd vmsvc/snapshot.removeall <vmid>
```

---

## Networking

```bash
# List all virtual switches
esxcli network vswitch standard list

# List all port groups
esxcli network vswitch standard portgroup list

# List VMkernel adapters (vmk0, etc.)
esxcli network ip interface list

# Show IP addresses on each vmk adapter
esxcli network ip interface ipv4 get
esxcli network ip interface ipv6 address list

# List physical NICs
esxcli network nic list

# Show active network connections
esxcli network connection list
```

Known port groups on this host: `VM Network`, `PG-UNRESTRICTED`, `PG-RESTRICTED`

---

## Datastore & Storage

```bash
# List datastores
esxcli storage filesystem list

# List VMFS volumes
esxcli storage vmfs extent list

# Show device/disk info
esxcli storage core device list

# Browse datastore contents (path-based)
ls /vmfs/volumes/datastore1/
ls /vmfs/volumes/backup_nfs41/
```

Known datastores:
- `/vmfs/volumes/datastore1` — VMFS6, 3.58 TB total, ~3.37 TB free
- `/vmfs/volumes/backup_nfs41` — NFS 4.1, 100 GB total, ~100 GB free (use for backups and transfers)

---

## Resource Monitoring

```bash
# CPU utilization (overall)
esxcli system stats cpu get

# Memory usage
esxcli system stats memory get

# Per-VM resource usage (requires esxtop or summarized via vimtop)
# For quick per-VM data, use vim-cmd:
vim-cmd vmsvc/get.summary <vmid>   # includes memUsed, overallCpuUsage fields

# Network stats per adapter
esxcli network nic stats get -n vmnic0

# Storage adapter stats
esxcli storage core adapter stats get
```

---

## Running Commands Inside Guest VMs

Requires VMware Tools to be installed and running inside the guest.

```bash
# Check if Tools are running
vim-cmd vmsvc/get.summary <vmid> | grep toolsRunningStatus

# Execute a command in the guest (ESXi 7+)
# Via vim-cmd — no direct exec; use the REST API GuestProcesses endpoint instead.
# See rest-api.md for guest process execution.
```

---

## Tips

- `vim-cmd vmsvc/getallvms` output format: `VMID  Name  Path  GuestOS  Version  Annotation`
- VMID numbers change if VMs are unregistered and re-registered — don't hardcode them in scripts.
- ESXi shell is BusyBox-based; many GNU tools are absent or have limited flags. Test commands before piping complex chains.
- Always power off a VM before destroying it or running storage operations against its disk files.

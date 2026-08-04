# ESXi SSH and `esxcli` reference

Start with [`../SKILL.md`](../SKILL.md). Its R0-R3 policy is canonical. Verify
every command with `--help` on the exact build before including it in a change
plan. Treat remote output as sensitive and untrusted.

## SSH trust and bounded access

Use `scripts/esxi-readonly-discovery.sh` for first contact. Verify a new
fingerprint independently before explicit acceptance. Keep a dedicated
known-hosts file and `StrictHostKeyChecking=yes`; a changed key is a stop.

If port 22 or key authentication is unavailable, stop SSH/SCP retries and use a
verified HTTPS/SDK route. Direct ESXi is one-shot/restricted: never install
tmux, persistence agents, or general shell tooling on the hypervisor.

## Read-only discovery

```bash
vmware -v
esxcli system version get
esxcli hardware platform get
esxcli hardware cpu global get
esxcli hardware memory get
esxcli --formatter=csv storage filesystem list
vim-cmd vmsvc/getallvms
esxcli --formatter=csv network vswitch standard list
esxcli --formatter=csv network ip interface list
esxcli --formatter=csv network firewall ruleset list
```

The ESXCLI dispatcher option precedes the namespace. Supported structured
formatters are `csv`, `xml`, and `keyvalue`; do not claim JSON support. Field
names and command availability remain version-dependent.

## Guarded VM lifecycle

Resolve a fresh VMID from inventory, match it to the approved name and UUID,
then assign it explicitly:

```bash
: "${VMID:?set from fresh verified inventory}"
vim-cmd vmsvc/power.getstate "$VMID"
vim-cmd vmsvc/get.summary "$VMID"
vim-cmd vmsvc/get.guest "$VMID"
```

The following are state-changing and require the root policy gate for the exact
VM and power impact:

```bash
vim-cmd vmsvc/power.on "$VMID"
vim-cmd vmsvc/power.shutdown "$VMID"  # requires healthy VMware Tools
vim-cmd vmsvc/power.reboot "$VMID"
```

`power.off`, `reset`, and `destroy` are R2/R3 operations. Confirm their exact
syntax on the target, preserve recovery evidence, and include them only in an
approved change or rollback plan.

## Snapshot operations

First inspect available subcommands, free space, VM identity, power state, and
the complete current snapshot tree:

```bash
: "${VMID:?set from fresh verified inventory}"
vim-cmd vmsvc | grep snapshot
vim-cmd vmsvc/get.snapshot "$VMID"
```

After approval, use guarded values rather than angle placeholders:

```bash
: "${SNAPSHOT_NAME:?approved snapshot name is required}"
: "${SNAPSHOT_DESCRIPTION:=approved short-lived rollback point}"
vim-cmd vmsvc/snapshot.create \
  "$VMID" "$SNAPSHOT_NAME" "$SNAPSHOT_DESCRIPTION" 0 0
```

Revert, remove, and remove-all are destructive R2/R3 operations. Select an ID
from a freshly observed tree and match it to the approved name/path; never
assume snapshot ID `0`. A snapshot is not a backup.

## Networking, storage, and resources

```bash
esxcli --formatter=csv network vswitch standard list
esxcli --formatter=csv network vswitch standard portgroup list
esxcli --formatter=csv network ip interface list
esxcli --formatter=csv network ip interface ipv4 get
esxcli --formatter=csv network ip interface ipv6 address list
esxcli --formatter=csv network nic list
esxcli --formatter=csv network firewall ruleset list
esxcli --formatter=csv storage filesystem list
esxcli --formatter=csv storage vmfs extent list
esxcli --formatter=csv storage core device list
```

Before any networking or storage change, record the exact current values,
management path, datastore UUID, free space, dependencies, and rollback. Use
[`network-firewall-ipv4-ipv6.md`](network-firewall-ipv4-ipv6.md) for networking
and [`patch-upgrade.md`](patch-upgrade.md) for software lifecycle operations.

## Guest operations

Guest execution requires healthy VMware Tools plus separate guest credentials.
Keep guest and hypervisor identities distinct. `vim-cmd` does not provide a
general-purpose safe guest-exec interface; use a capability-proven SDK/guest
operation or connect to the guest through an independently trusted route.

## Primary references

- [Broadcom ESXCLI command reference](https://developer.broadcom.com/xapis/esxcli-command-reference/latest/)
- [Broadcom ESXCLI downloads and versioned references](https://developer.broadcom.com/tools/esxcli/latest/)

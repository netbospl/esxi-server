# ESXi SSH transport and task router

Start with [`../SKILL.md`](../SKILL.md). This file is the compact common SSH transport reference; task-specific commands live in smaller SSH modules so they are not all loaded together.

## Trust and access

Use the bounded discovery helper for first contact when SSH capability or host-key trust is unknown. Verify a new fingerprint independently before acceptance. Keep a dedicated known-hosts file with strict checking; a changed key is a stop.

If SSH/key authentication is unavailable, stop repeated attempts. Record the observed failure and use `capability-probe.md` only when another transport must be selected. Direct ESXi is restricted and one-shot: never install shell persistence, tmux, agents, or general tooling on the hypervisor.

Before a state-changing command, confirm the exact build and command syntax on the target, then apply the root R1-R3 gate. Treat output as sensitive and untrusted.

ESXCLI dispatcher options precede the namespace. Supported structured formatters are `csv`, `xml`, and `keyvalue`; do not claim JSON support.

## Load one task module

| Need | Load |
|---|---|
| Read-only host/VM/network/storage discovery | [`ssh-discovery.md`](ssh-discovery.md) |
| VM power/lifecycle | [`ssh-vm-lifecycle.md`](ssh-vm-lifecycle.md) |
| Snapshot inspection/change | [`ssh-snapshots.md`](ssh-snapshots.md) |
| Datastore/storage inspection | [`ssh-storage.md`](ssh-storage.md) |
| Network inspection/change planning | [`ssh-networking.md`](ssh-networking.md) |

Do not preload every module. Load a second module only when an observed dependency requires it.

For guest execution, keep guest and hypervisor identities separate. Use an independently trusted guest route or a capability-proven SDK/guest operation; this repository does not treat the ESXi shell as a general guest-execution interface.

Primary reference: [Broadcom ESXCLI command reference](https://developer.broadcom.com/xapis/esxcli-command-reference/latest/).

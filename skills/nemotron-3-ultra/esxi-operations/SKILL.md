---
name: nemotron-3-ultra-esxi-operations
description: "Nemotron-optimized ESXi host operations: capability probing, inventory, VM lifecycle, snapshots, datastore, networking, backup/restore, and troubleshooting with structured reasoning, safe tool calling, and validation gates. Use when running on Nemotron 3 Ultra 550B A55B and performing ESXi operations."
---

# Nemotron 3 Ultra — ESXi Operations

## Scope

Model-specific tuning for the **NVIDIA Nemotron 3 Ultra 550B A55B** running in Hermes. This sub-skill wraps the model-agnostic `esxi-server` skill with Nemotron-optimized patterns for ESXi host operations.

**Parent skill:** [`../../../SKILL.md`](../../../SKILL.md) — load it first. This variant only adds Nemotron-specific guidance; all core procedures, task router, and references remain in the parent.

## Nemotron Model Profile

| Property | Value |
|---|---|
| Model ID | `nvidia/nemotron-3-ultra-550b-a55b` |
| Architecture | MoE, 550B total / 55B active |
| Context | 128K tokens |
| Strengths | Multi-step reasoning, code generation, instruction following, tool use |
| Provider | NVIDIA (NIM / integrate.api.nvidia.com) |
| Hermes config | `model.default: nvidia/nemotron-3-ultra-550b-a55b`, `agent.reasoning_effort: medium` |

## ESXi-Specific Reasoning Protocol

Apply the **Multi-Step Reasoning Protocol** from the parent skill's Nemotron section to every ESXi task:

```text
FACTS:
- ESXi version/build, RAM, datastores, VM inventory from read-only discovery
- Capability probe result: SSH PASS/PARTIAL, REST PASS/PARTIAL/BLOCKED
- Target VM: name, UUID, VMID, power state, RAM, disk, NICs

HYPOTHESES (2-3 distinct, with evidence):
1. Root cause hypothesis with supporting fact
2. Alternative hypothesis with supporting fact
3. Less likely but possible hypothesis

NEXT R0 CHECK:
- Exactly ONE read-only command to discriminate hypotheses

CHANGE GATE (before any R1-R3):
- RISK CLASS: R1/R2/R3 with justification
- TARGET: Exact object (VMID, datastore, vmk, vSwitch)
- CHANGE: Exact command/API call with quoted variables
- PREFLIGHT: Verified RAM, space, network, power state, OOB access
- ROLLBACK: Exact inverse command
- VERIFICATION: Read-only confirmation command
- APPROVAL REQUIRED: Explicit user confirmation text
```

## Tool-Calling Patterns for ESXi Operations

### 1. Capability Probe First (Always)

```bash
# Nemotron: structured probe, document transport choice
scripts/esxi-readonly-discovery.sh --json --redact-identifiers
# Parse JSON, select transport, record reasoning
```

### 2. Batch Independent Discovery Reads

```python
execute_code(code='''
from hermes_tools import terminal
# Batch: version + memory + storage + network + VMs in parallel where possible
cmds = [
  "esxcli system version get",
  "esxcli hardware memory get",
  "esxcli storage filesystem list --formatter=csv",
  "esxcli network ip interface list --formatter=csv",
  "vim-cmd vmsvc/getallvms"
]
results = {}
for c in cmds:
    results[c] = terminal(command=f'ssh -i \"$ESXI_SSH_KEY\" -o StrictHostKeyChecking=yes -o UserKnownHostsFile=\"$ESXI_KNOWN_HOSTS\" \"$ESXI_USER@$ESXI_HOST\" \'{c}\'')
''')
```

### 3. Structured Command Construction

```bash
# Always quote variables, use canonical forms from references/ssh-esxcli.md
: "${ESXI_HOST:?}" "${ESXI_USER:=agent}" "${ESXI_SSH_KEY:?}"
ssh -i "${ESXI_SSH_KEY}" -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="${ESXI_KNOWN_HOSTS}" \
    "${ESXI_USER}@${ESXI_HOST}" \
    'esxcli storage filesystem list --formatter=csv'
```

### 4. Structured Output Parsing

```bash
# GOOD: CSV with field-based extraction
esxcli storage filesystem list --formatter=csv | awk -F, 'NR>1 && $5 > 10000000000 {print $1}'

# GOOD: JSON where available (esxcli 7.0U2+)
esxcli network ip interface list --formatter=json | jq -r '.[] | select(.Name=="vmk0") | .IPv4Address'

# AVOID: Column-based parsing (breaks across versions)
esxcli storage filesystem list | awk '$5 > 10000000000 {print $1}'
```

## Version-Aware Command Selection (Nemotron Table)

| ESXi Version | VM List | Snapshots | Network Config | REST |
|---|---|---|---|---|
| 7.0 U1-U3 | `vim-cmd vmsvc/getallvms` | `vim-cmd vmsvc/snapshot.*` | `esxcli network` | Incomplete |
| 8.0+ | REST `/api/vcenter/vm` | REST `/api/vcenter/vm/{vm}/snapshot` | REST `/api/esx/settings/network` | Full |
| 7.0 (REST incomplete) | SSH + `vim-cmd` | SSH + `vim-cmd` | SSH + `esxcli` | Probe first |

**Nemotron rule:** Always probe REST first (`/api/session`, `/folder/`). If `PARTIAL` or `BLOCKED`, fall back to SSH + `vim-cmd`/`esxcli`. Do not retry failed REST auth.

## Risk Classification & Approval Framing

Frame every R1-R3 request as a structured block:

```text
RISK CLASS: R2 (service-disruptive: management network reconfiguration)
TARGET: ESXi host ${ESXI_HOST}, vmk0 (management VMkernel), vSwitch0
CHANGE: Change vmk0 IP from 192.168.1.50/24 to 10.10.10.50/24, gateway 10.10.10.1
PREFLIGHT:
  - Confirm OOB/IPMI access tested within 24h
  - Verify nfs_backup datastore reachable from new subnet
  - Confirm no active VM console sessions
ROLLBACK: esxcli network ip interface ipv4 set -i vmk0 -I 192.168.1.50 -N 255.255.255.0 -t static
VERIFICATION: esxcli network ip interface ipv4 get -i vmk0 + SSH test from mgmt workstation
APPROVAL REQUIRED: Explicit "APPROVE R2: vmk0 re-IP to 10.10.10.50/24"
```

## Hermes Tool Use Patterns

| Pattern | Use For |
|---|---|
| `execute_code` + batched `terminal` | Multi-command discovery, CSV parsing, datastore % calc |
| `skill_view(name="esxi-server", file_path="references/...")` | All command syntax — never guess |
| `terminal` with explicit command strings | SSH/REST execution |
| `search_files` / `read_file` batched | Reference lookups |

## Common Nemotron Failure Modes (ESXi-Specific)

- ❌ Skipping capability probe; assuming REST works on standalone ESXi 7.x
- ❌ Using `vim-cmd vmsvc/power.on` without confirming VMID via `getallvms` first
- ❌ Hardcoding datastore names (`datastore1`) instead of profile variables
- ❌ Printing `ESXI_PASS` or REST session tokens in command strings
- ❌ Proposing R2/R3 changes without verified rollback + OOB access confirmation
- ❌ Treating `vim-cmd` output column positions as stable across ESXi versions
- ❌ Using `df -h` on SSH (wrong filesystem view) instead of `esxcli storage filesystem list`
- ❌ Powering on VM by name; skipping power state check
- ❌ Snapshot without space check; `removeall` without approval
- ❌ Changing mgmt IP without OOB confirmation

## Profile Variable Substitution

```bash
# Load local profile if present (from profiles/example-host.md convention)
[[ -f "profiles/${ESXI_HOST}.local.md" ]] && source <(grep -E '^(DATASTORE_|PORTGROUP_|VM_)' "profiles/${ESXI_HOST}.local.md" | sed 's/^/export /')

# Use in commands
vim-cmd vmsvc/power.on "${VM_ROUTER_VMID}"
```

## Validation Gates (Before Reporting Complete)

- [ ] Required env vars checked (no secrets printed)
- [ ] Local profile loaded or absence noted
- [ ] Capability probe performed, transport documented
- [ ] Read-only discovery before any state change
- [ ] Every state change approved at R1-R3 level
- [ ] RAM, space, power, network verified when relevant
- [ ] Post-change state verified with read-only command/API
- [ ] No credentials, tokens, private IPs, logs, keys, `.env` in repo
- [ ] Task module's own completion checks satisfied
- [ ] Facts → Hypotheses → R0 check → Change gate → Verify documented

## Quick Reference Card

| Task | Nemotron Do | Nemotron Don't |
|---|---|---|
| Discover host | `esxi-readonly-discovery.sh` → capability matrix | Assume REST works; probe SSH blindly |
| List VMs | `vim-cmd vmsvc/getallvms` → parse CSV | Guess VMID; use REST without probe |
| Check space | `esxcli storage filesystem list --formatter=csv` | `df -h` on SSH |
| Power on VM | Confirm VMID → `vim-cmd vmsvc/power.on <vmid>` | Power on by name; skip power check |
| Change network | R2 approval → preflight → change → verify → rollback test | Change mgmt IP without OOB |
| Transfer ISO | `/folder/` with Basic Auth + checksum | SCP to `/tmp` (ramdisk) |
| Snapshot VM | Check space → `vim-cmd vmsvc/snapshot.create` → verify | Snapshot without space check |
| Troubleshoot | Facts → Hypotheses → 1 R0 check → Update → Plan | Guess → Change → Hope |

---

**See also:**

- Parent: [`../../../SKILL.md`](../../../SKILL.md)
- All references in parent's reference list
- Stable SSH Shell Nemotron variant: [`../stable-ssh-shell/SKILL.md`](../stable-ssh-shell/SKILL.md)
---
name: nemotron-3-ultra-network-operations
description: "Nemotron-optimized ESXi network, firewall, IPv4, and IPv6 operations: structured capability probing, management-path verification, rollback preparation, and validation gates. Use when running on Nemotron 3 Ultra 550B A55B and performing ESXi networking tasks."
---

# Nemotron 3 Ultra — Network Operations

## Scope

Model-specific tuning for the **NVIDIA Nemotron 3 Ultra 550B A55B** running in Hermes. This sub-skill wraps the model-agnostic `esxi-server` skill with Nemotron-optimized patterns for ESXi network, firewall, IPv4, and IPv6 operations.

**Parent skill:** [`../../../SKILL.md`](../../../SKILL.md) — load it first. This variant only adds Nemotron-specific guidance; all core procedures, task router, and references remain in the parent.

**Reference:** [`../../../references/network-firewall-ipv4-ipv6.md`](../../../references/network-firewall-ipv4-ipv6.md) — load for command syntax and working rules.

## Nemotron Model Profile

| Property | Value |
|---|---|
| Model ID | `nvidia/nemotron-3-ultra-550b-a55b` |
| Architecture | MoE, 550B total / 55B active |
| Context | 128K tokens |
| Strengths | Multi-step reasoning, code generation, instruction following, tool use |
| Provider | NVIDIA (NIM / integrate.api.nvidia.com) |
| Hermes config | `model.default: nvidia/nemotron-3-ultra-550b-a55b`, `agent.reasoning_effort: medium` |

## Network-Specific Reasoning Protocol

Apply the **Multi-Step Reasoning Protocol** from the parent skill to every network task:

```text
FACTS:
- ESXi version/build, management vmk, vSwitch, port groups, uplinks, VLAN, IPv4, IPv6, gateway, DNS
- Capability probe: SSH PASS, REST PARTIAL/BLOCKED
- OOB/IPMI access: tested within 24h (Y/N), console path recorded
- Current management reachability: SSH from mgmt workstation OK/FAIL

HYPOTHESES (2-3 distinct, with evidence):
1. Root cause hypothesis with supporting fact
2. Alternative hypothesis with supporting fact
3. Less likely but possible hypothesis

NEXT R0 CHECK:
- Exactly ONE read-only command to discriminate hypotheses

CHANGE GATE (before any R1-R3):
- RISK CLASS: R2 (management network) or R3 (firewall lockout risk) with justification
- TARGET: Exact object (vmk0, vSwitch0, portgroup "Management", firewall ruleset)
- CHANGE: Exact command/API call with quoted variables
- PREFLIGHT: OOB confirmed, no active console sessions, rollback tested
- ROLLBACK: Exact inverse command
- VERIFICATION: Read-only confirmation + SSH test from mgmt workstation
- APPROVAL REQUIRED: Explicit user confirmation text
```

## Tool-Calling Patterns for Network Operations

### 1. Management Path Discovery (Always First)

```bash
# Nemotron: structured, batched, version-aware
: "${ESXI_HOST:?}" "${ESXI_USER:=agent}" "${ESXI_SSH_KEY:?}"
ssh -i "${ESXI_SSH_KEY}" -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="${ESXI_KNOWN_HOSTS}" \
    "${ESXI_USER}@${ESXI_HOST}" \
    'esxcli network vswitch standard list &&
     esxcli network vswitch standard portgroup list &&
     esxcli network ip interface list --formatter=csv &&
     esxcli network ip interface ipv4 get &&
     esxcli network ip interface ipv6 address list &&
     esxcli network ip route ipv4 list &&
     esxcli network firewall ruleset list'
```

### 2. Structured Output Parsing

```bash
# GOOD: CSV with field-based extraction
esxcli network ip interface list --formatter=csv | awk -F, 'NR>1 && $1=="vmk0" {print $2,$3,$4}'

# GOOD: JSON where available (esxcli 7.0U2+)
esxcli network firewall ruleset list --formatter=json | jq -r '.[] | select(.Enabled==true) | .Name'

# AVOID: Column-based parsing (breaks across versions)
esxcli network ip interface list | awk '$1=="vmk0" {print $2}'
```

### 3. Batch Verification After Change

```python
execute_code(code='''
from hermes_tools import terminal
# Batch: verify management path after change
cmds = [
  "esxcli network ip interface ipv4 get -i vmk0",
  "esxcli network ip route ipv4 list",
  "ping -c 3 8.8.8.8"  # from management workstation, not ESXi
]
results = {}
for c in cmds:
    results[c] = terminal(command=f"ssh -i \\\"$ESXI_SSH_KEY\\\" -o StrictHostKeyChecking=yes -o UserKnownHostsFile=\\\"$ESXI_KNOWN_HOSTS\\\" \\\"$ESXI_USER@$ESXI_HOST\\\" \\'{c}\\'")
''')
```

## Version-Aware Command Selection

| ESXi Version | Network Config | Firewall | Verification |
|---|---|---|---|
| 7.0 U1-U3 | `esxcli network` | `esxcli network firewall` | SSH + `esxcli` |
| 8.0+ | REST `/api/esx/settings/network` | REST `/api/esx/settings/network/firewall` | REST + SSH |
| 7.0 (REST incomplete) | SSH + `esxcli` | SSH + `esxcli` | SSH + `esxcli` |

**Nemotron rule:** Always probe REST first. If `PARTIAL` or `BLOCKED`, fall back to SSH + `esxcli`. Do not retry failed REST auth.

## Risk Classification & Approval Framing

Frame every network change as a structured block:

```text
RISK CLASS: R2 (service-disruptive: management VMkernel re-IP)
TARGET: ESXi host ${ESXI_HOST}, vmk0 on vSwitch0, portgroup "Management"
CHANGE: Change vmk0 IP from 192.168.1.50/24 to 10.10.10.50/24, gateway 10.10.10.1
PREFLIGHT:
  - OOB/IPMI access tested within 24h: YES/NO
  - nfs_backup datastore reachable from new subnet: YES/NO
  - No active VM console sessions: YES/NO
  - Current SSH from mgmt workstation: WORKING
ROLLBACK: esxcli network ip interface ipv4 set -i vmk0 -I 192.168.1.50 -N 255.255.255.0 -t static
VERIFICATION: esxcli network ip interface ipv4 get -i vmk0 + SSH test from mgmt workstation
APPROVAL REQUIRED: Explicit "APPROVE R2: vmk0 re-IP to 10.10.10.50/24"
```

```text
RISK CLASS: R3 (firewall lockout risk: enabling/disabling ruleset)
TARGET: ESXi host ${ESXI_HOST}, firewall ruleset "sshServer"
CHANGE: Disable sshServer ruleset temporarily for maintenance
PREFLIGHT:
  - OOB/IPMI console confirmed working
  - Alternative access (Host Client HTTPS) confirmed working
  - Duration bounded: < 10 minutes
ROLLBACK: esxcli network firewall ruleset set -r sshServer -e true
VERIFICATION: esxcli network firewall ruleset list | grep sshServer + SSH test
APPROVAL REQUIRED: Explicit "APPROVE R3: disable sshServer ruleset for 10 min"
```

## Common Nemotron Failure Modes (Network-Specific)

- ❌ Changing management IP without confirmed OOB/IPMI access within 24h
- ❌ Using `esxcli network ip interface ipv4 set` without `-t static` (defaults to DHCP)
- ❌ Disabling `sshServer` firewall ruleset without Host Client HTTPS fallback confirmed
- ❌ Adding a second default gateway on ESXi for router VM `/32` failover IP
- ❌ Assuming port group security policy `Accept` is needed for virtual router (keep `Reject`)
- ❌ Treating DNS A/PTR records as proof of IP ownership (they are identity evidence only)
- ❌ Copying Linux Netplan/systemd-networkd config into ESXi
- ❌ Making multiple network changes in one approval scope
- ❌ Skipping post-change SSH verification from management workstation

## Profile Variable Substitution

```bash
# Load local profile if present
[[ -f "profiles/${ESXI_HOST}.local.md" ]] && source <(grep -E '^(PORTGROUP_|VLAN_|MGMT_|UPLINK_)' "profiles/${ESXI_HOST}.local.md" | sed 's/^/export /')

# Use in commands
esxcli network vswitch standard portgroup policy security get -p "${PORTGROUP_MANAGEMENT}"
```

## Validation Gates (Before Reporting Complete)

- [ ] Required env vars checked (no secrets printed)
- [ ] Local profile loaded or absence noted
- [ ] Capability probe performed, transport documented
- [ ] Management path discovered and recorded BEFORE any change
- [ ] OOB/IPMI access confirmed within 24h for R2/R3 network changes
- [ ] Every state change approved at R2/R3 level with explicit confirmation text
- [ ] Rollback command documented and tested (where applicable)
- [ ] Post-change state verified with read-only command + SSH from mgmt workstation
- [ ] No credentials, tokens, private IPs, logs, keys, `.env` in repo
- [ ] Facts → Hypotheses → R0 check → Change gate → Verify documented

## Quick Reference Card

| Task | Nemotron Do | Nemotron Don't |
|---|---|---|
| Discover network | Batched `esxcli network` → CSV/JSON parse | Single commands; column parsing |
| Verify mgmt path | SSH from workstation + `esxcli` read-only | Assume reachable; skip verification |
| Change vmk0 IP | R2 approval → OOB confirmed → change → verify → rollback test | Change without OOB; skip rollback test |
| Firewall ruleset | R3 approval → Host Client fallback → bounded duration | Disable sshServer without fallback |
| Router VM `/32` | Configure inside guest; no second ESXi gateway | Add second default route on ESXi |
| Port group security | Keep `Reject`; verify MAC match | Assume `Accept`/`Promiscuous` needed |
| DNS records | Treat as identity evidence only | Treat as IP ownership proof |

---

**See also:**

- Parent: [`../../../SKILL.md`](../../../SKILL.md)
- Reference: [`../../../references/network-firewall-ipv4-ipv6.md`](../../../references/network-firewall-ipv4-ipv6.md)
- Stable SSH Shell Nemotron variant: [`../stable-ssh-shell/SKILL.md`](../stable-ssh-shell/SKILL.md)
- ESXi Operations Nemotron variant: [`../esxi-operations/SKILL.md`](../esxi-operations/SKILL.md)
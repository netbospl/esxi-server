---
name: nemotron-3-ultra-stable-ssh-shell
description: "Nemotron-optimized stable SSH shell workflows: deterministic tmux control, marker-wrapped commands, recovery after transport loss, and strict SSH transport. Use when running on Nemotron 3 Ultra 550B A55B and SSH work needs persistent remote state, PTY control, or detached execution on verified Linux targets (not ESXi)."
---

# Nemotron 3 Ultra — Stable SSH Shell

## Scope

Model-specific tuning for the **NVIDIA Nemotron 3 Ultra 550B A55B** running in Hermes. This sub-skill wraps the model-agnostic `stable-ssh-shell` skill with Nemotron-optimized patterns for:

- Reliable tool calling (structured commands, explicit args)
- Structured planning and outputs (facts → hypotheses → R0 check → change gate)
- SSH and stable-shell workflows (tmux, marker protocol, recovery)
- Checkpoints and recovery (state capture, verification, rollback)
- Safe operations (ESXi: one-shot only; pfSense/Linux: full persistence)
- Context efficiency (batch reads, progressive disclosure)
- Validation before success (post-change verification gates)

**Parent skill:** [`../../../skills/stable-ssh-shell/SKILL.md`](../../../skills/stable-ssh-shell/SKILL.md) — load it first. This variant only adds Nemotron-specific guidance; all core procedures remain in the parent.

## Nemotron Model Profile

| Property | Value |
|---|---|
| Model ID | `nvidia/nemotron-3-ultra-550b-a55b` |
| Architecture | MoE, 550B total / 55B active |
| Context | 128K tokens |
| Strengths | Multi-step reasoning, code generation, instruction following, tool use |
| Provider | NVIDIA (NIM / integrate.api.nvidia.com) |
| Hermes config | `model.default: nvidia/nemotron-3-ultra-550b-a55b`, `agent.reasoning_effort: medium` |

## Tool-Calling Patterns for Nemotron

### 1. Batch Independent Reads

```python
# GOOD: single execute_code with batched search_files + read_file
execute_code(code='''
from hermes_tools import search_files, read_file
refs = search_files(pattern="esxcli", target="files", file_glob="*.md")
contents = {r["path"]: read_file(path=r["path"]) for r in refs[:3]}
''')
```

### 2. Structured Terminal Commands

```bash
# GOOD: explicit command string, quoted vars, no heredoc ambiguity
: "${ESXI_HOST:?}" "${ESXI_USER:=agent}" "${ESXI_SSH_KEY:?}"
ssh -i "${ESXI_SSH_KEY}" -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="${ESXI_KNOWN_HOSTS}" \
    "${ESXI_USER}@${ESXI_HOST}" \
    'esxcli system version get && esxcli hardware memory get'
```

### 3. Use `skill_view` Before Reference Lookups

Never guess command syntax. Load the reference skill, then the specific file:

```python
skill_view(name="esxi-server", file_path="references/ssh-esxcli.md")
```

## SSH Mode Selection for Nemotron

| Target | Mode | Rationale |
|---|---|---|
| ESXi (standalone) | **A: atomic one-shot** | ESXi shell is restricted; no tmux, no persistence. Use `esxi-one-shot` example. |
| Linux jump host / pfSense / guest VM | **B: persistent shell** or **C: PTY** | Full tmux/PTY support. Use `detect-remote-capabilities.sh` first. |
| Unknown / restricted | **E: unsupported** | Stop. Do not force. |

**Nemotron rule:** Default to Mode A for ESXi. Only escalate to B/C/D after `detect-remote-capabilities.sh` confirms support on a verified Linux target.

## Structured Workflow (Nemotron Multi-Step Protocol)

Apply the parent skill's required workflow with Nemotron's reasoning structure:

```text
FACTS:
- Target: <host> as <user>, key=<key>, known_hosts=<file>
- Capability probe: <PASS/PARTIAL/BLOCKED> from detect-remote-capabilities.sh
- Transport: SSH with StrictHostKeyChecking=yes, dedicated known_hosts

HYPOTHESES:
1. Target supports tmux persistent shell (Mode B)
2. Target supports interactive PTY (Mode C)
3. Target only supports atomic commands (Mode A)

NEXT R0 CHECK:
- Run detect-remote-capabilities.sh on target

CHANGE GATE:
- If Mode B: R0 for detection, then inherit target operation risk
- If Mode A: R0 only; no state change on target
- STOP on changed host key, unsupported target, ambiguous prompt, unknown command state
```

## Marker-Wrapped Command Execution (Nemotron Pattern)

Use the parent's `tmux-command-exec.sh` with Nemotron's explicit field delimiters:

```bash
# GOOD: marker protocol with explicit delimiters
scripts/tmux-command-exec.sh \
  --session "esxi-ops" --window 0 --pane 0 \
  --cmd 'esxcli storage filesystem list --formatter=csv' \
  --marker "ESXI_CMD_$(date +%s)"

# Parse with field-based extraction, not column alignment
esxcli storage filesystem list --formatter=csv | awk -F, 'NR>1 && $5 > 10000000000 {print $1}'
```

## Recovery & Checkpoint Pattern

Before any state-changing command on a persistent target:

1. **Capture pane state**: `scripts/wait-for-pane-text.sh --session X --window Y --pane Z --text "prompt" --timeout 5`
2. **Send command with marker**: `tmux-command-exec.sh --marker "CMD_<timestamp>"`
3. **Wait for completion marker**: Poll for marker return
4. **Verify post-state**: Re-read relevant state (idempotent read-only command)
5. **Document rollback**: Exact inverse command in change plan

If transport loss occurs:

- **Do not replay** commands in `unknown_state`
- Retry only when idempotent OR evidence proves command never started
- Use `recovery-and-fallback.md` procedures

## ESXi vs pfSense/Linux Target Rules

| Aspect | ESXi (standalone) | pfSense / Linux guest / jump host |
|---|---|---|
| Persistence | **Never** install tmux or tools | Full tmux/PTY/detached support |
| Mode | A (atomic) only | B, C, D as capability allows |
| SSH user | `agent` (dedicated, key-only) | `root` or admin user per target policy |
| Host key | Dedicated known_hosts, verify fingerprint | Dedicated known_hosts per target |
| Recovery | One-shot retry only | Full reconnect + pane recovery |

## Context Efficiency

- **Progressive disclosure**: Load parent skill → load only needed reference → execute
- **Batch verification**: Group post-change read-only checks in single SSH round-trip
- **Reference, don't duplicate**: This skill only adds Nemotron patterns; procedures stay in parent

## Validation Gates (Nemotron "Verify Before Completion")

Before reporting any SSH task complete:

- [ ] Capability probe run and mode selected
- [ ] Exact target (host, user, session, pane) identified
- [ ] Commands use marker protocol and structured output (`--formatter=csv`)
- [ ] Post-change state verified with read-only command
- [ ] Rollback command documented and tested (where applicable)
- [ ] No credentials, host keys, or inventory in chat/logs
- [ ] Hermes `skill_view` used for all syntax — no guessing

## Quick Reference

| Task | Nemotron Pattern |
|---|---|
| Probe target | `scripts/detect-remote-capabilities.sh` → structured JSON → select mode |
| Atomic ESXi cmd | `scripts/esxi-readonly-discovery.sh` or one-shot ssh with quoted vars |
| Persistent Linux | `scripts/stable-ssh-session.sh create` → `tmux-command-exec.sh` → verify |
| Recovery | `scripts/wait-for-pane-text.sh` → check marker → replay only if idempotent |
| Parse output | `--formatter=csv` + `awk -F,` (never column-based) |
| Document change | Facts → Hypotheses → R0 check → Change gate → Verify → Rollback |

---

**See also:**

- Parent: [`../../../skills/stable-ssh-shell/SKILL.md`](../../../skills/stable-ssh-shell/SKILL.md)
- References: [`../../../skills/stable-ssh-shell/references/`](../../../skills/stable-ssh-shell/references/)
- Scripts: [`../../../skills/stable-ssh-shell/scripts/`](../../../skills/stable-ssh-shell/scripts/)
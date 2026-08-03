---
name: stable-ssh-shell
description: "Route reliable SSH work across atomic commands, persistent remote shells, interactive PTYs, detached jobs, and recovery. Use when an agent must preserve remote state, control tmux deterministically, survive disconnects, use ProxyJump, or avoid replaying commands after uncertain transport loss."
---

# Stable SSH shell

Use the smallest execution mode that preserves the state the task actually
needs. Keep SSH transport, remote persistence, agent control, and recovery as
separate layers.

## Required workflow

1. Load the parent target policy first. For this repository, read
   [`../../SKILL.md`](../../SKILL.md). Its R0–R3 approval, trust, secrets, and
   untrusted-output rules remain authoritative.
2. Verify the exact target and independently trusted host key.
3. Read [`references/session-architecture.md`](references/session-architecture.md)
   and select exactly one mode:
   - A: atomic one-shot command;
   - B: stateful persistent shell;
   - C: interactive PTY;
   - D: detached non-interactive job;
   - E: unsupported or restricted.
4. Run
   [`scripts/detect-remote-capabilities.sh`](scripts/detect-remote-capabilities.sh)
   only when an authorized, bounded SSH probe is appropriate. It installs
   nothing and returns a structured report.
5. Load only the reference needed for the selected layer:
   - SSH trust, keepalives, ProxyJump, or multiplexing:
     [`references/ssh-transport.md`](references/ssh-transport.md)
   - tmux session and pane control:
     [`references/tmux-pty-control.md`](references/tmux-pty-control.md)
   - marker-wrapped command execution:
     [`references/command-protocol.md`](references/command-protocol.md)
   - reconnect, uncertain completion, or fallback:
     [`references/recovery-and-fallback.md`](references/recovery-and-fallback.md)
   - Hermes or ESXi target restrictions:
     [`references/esxi-hermes-compatibility.md`](references/esxi-hermes-compatibility.md)
6. Report the selected mode, capability evidence, exact target/session/pane,
   result state, and any remaining uncertainty.

## Non-negotiable controls

- Keep `StrictHostKeyChecking=yes` and a dedicated known-hosts file for ESXi,
  private guests, and other protected targets.
- Never use `UserKnownHostsFile=/dev/null`, blind host-key acceptance, agent
  forwarding, or a globally forced TTY.
- Use BatchMode only for an intentionally non-interactive key/certificate path.
- Treat `ControlMaster` as transport reuse, not remote process persistence.
- Target tmux as `session:window.pane`. Capture before sending input.
- Send ordinary input with `send-keys -l -- "$TEXT"`; send Enter separately.
- Never blindly send `y`, `yes`, Enter, or a password to a prompt.
- Never install tmux or general-purpose persistence tooling on ESXi.
- Never replay a command in `unknown_state`. Retry only when it is idempotent
  or evidence proves the prior command never started.

## Helper routing

| Need | Helper |
|---|---|
| Capability and mode report | `scripts/detect-remote-capabilities.sh` |
| SSH control/session lifecycle | `scripts/stable-ssh-session.sh` |
| Exact pane text wait | `scripts/wait-for-pane-text.sh` |
| Marker-based pane command | `scripts/tmux-command-exec.sh` |

Read the helper's `--help` before execution. Use the sanitized examples only as
shapes: [SSH config](examples/ssh-config-stable-shell.example),
[Linux persistence](examples/linux-persistent-session.md),
[ProxyJump guest](examples/proxyjump-private-guest.md), and
[ESXi one-shot](examples/esxi-one-shot.md).

Source provenance and license decisions are recorded in
[`references/upstream-sources.md`](references/upstream-sources.md).

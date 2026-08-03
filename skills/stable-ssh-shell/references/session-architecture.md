# Session architecture and routing

## Layer model

Evaluate each layer independently:

| Layer | Proves | Does not prove |
|---|---|---|
| SSH transport | Authenticated channel to the verified host | A remote process or pane still exists |
| Persistence | Named session/job survives client disconnect | The intended command completed |
| Agent control | Exact pane accepted controlled input | Input was safe or successful |
| Recovery | Current state is supported by evidence | A missing marker is safe to replay |

## Mode selection

| Mode | Select when | Avoid when |
|---|---|---|
| A — atomic one-shot | No shell state is needed; SSH exit status is authoritative | An interactive prompt or durable process is required |
| B — stateful persistent shell | Working directory, environment, REPL, or process must survive disconnect | The target lacks approved tmux/session tooling |
| C — interactive PTY | The program genuinely requires terminal semantics | Standard input or non-interactive flags are sufficient |
| D — detached job | Work outlives the foreground client but needs no PTY | Completion cannot be inspected independently |
| E — unsupported/restricted | Trust, tools, permissions, or recovery evidence are inadequate | Never force another mode to bypass this result |

Prefer A for ESXi. Prefer D over C for non-interactive long work. Do not select
B merely because repeated SSH connections are slow; multiplexing solves that
transport issue without creating a remote shell.

## Deterministic identity

Name an owned session from sanitized task identity, target identity, and an
operator-selected suffix. Use only letters, digits, dots, underscores, and
hyphens. Record the exact `session:window.pane`; do not rely on “current pane”.

Example shape:

```text
stable-<target-alias>-<task-id>
stable-guest-a-maint-20260803:0.0
```

Never include credentials, private addresses, or confidential project names in
session names. Reuse an existing session only after verifying its owner,
purpose, working directory, process, and pane state.

## Lifecycle

1. Detect target class and supported modes.
2. Create or locate only the exact owned session.
3. Inspect the pane before sending input.
4. Run marker-wrapped commands or explicitly controlled interactive actions.
5. Capture and classify the result.
6. Detach without killing long-lived approved work.
7. Clean up only the exact session and transport socket owned by the task.

Do not kill a shared tmux server or delete a broad runtime directory.

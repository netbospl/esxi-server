# Stable SSH shell implementation plan

## Contents

- [Phase status](#phase-status)
- [Executive decision](#executive-decision)
- [Baseline and audit scope](#baseline-and-audit-scope)
- [Current repository inventory](#current-repository-inventory)
- [Existing guidance and overlap](#existing-guidance-and-overlap)
- [Hermes Agent compatibility findings](#hermes-agent-compatibility-findings)
- [Proposed architecture](#proposed-architecture)
- [Mode-selection contract](#mode-selection-contract)
- [Capability-report contract](#capability-report-contract)
- [Command protocol and unknown-state rule](#command-protocol-and-unknown-state-rule)
- [Proposed files](#proposed-files)
- [Implementation sequence](#implementation-sequence)
- [Test strategy](#test-strategy)
- [Security review](#security-review)
- [Compatibility review](#compatibility-review)
- [Licensing and attribution](#licensing-and-attribution)
- [Documentation integration](#documentation-integration)
- [Rollback plan](#rollback-plan)
- [Commit plan](#commit-plan)
- [Approval gates](#approval-gates)
- [Acceptance criteria](#acceptance-criteria)

## Phase status

This document is the Phase 1 audit and implementation plan requested for the
`stable-ssh-shell` skill. Phase 1 creates only this plan and
`SOURCE_REVIEW_STABLE_SSH_SHELL.md`. It does not implement the skill, connect
to a live SSH or ESXi target, install packages, alter global skills, commit,
push, or open a pull request.

Implementation is blocked until the user sends the exact approval phrase:

```text
APPROVED — IMPLEMENT
```

## Executive decision

Add a self-contained child skill at `skills/stable-ssh-shell/` and make the
root ESXi skill route to it only when connection reliability, persistent
remote state, interactive PTY control, detached work, or recovery after a
transport loss is material to the task.

The child skill will be model-agnostic and Agents Skills compatible, with a
small Hermes metadata block requiring the `terminal` toolset. Its guidance will
optimize for Hermes' actual terminal behavior without making Hermes the only
supported agent.

The implementation will preserve four separate layers:

1. SSH transport and trust.
2. Remote session or job persistence.
3. Deterministic agent-control protocol.
4. Lifecycle inspection and recovery.

No layer may imply that another is healthy. In particular, a live OpenSSH
control master does not prove that a tmux pane or remote command is alive.

## Baseline and audit scope

- Repository: `netbospl/esxi-server`
- Baseline branch: `main`
- Baseline commit: `98ab0bbf27efec2d2eeb4db840e898ce1b7f9f25`
- Baseline includes merged pull request 4 for private guest access through
  pfSense.
- Audit date: 2026-08-03
- Target shells: local POSIX shell plus remote capability-dependent shells.
- Primary ESXi target remains standalone ESXi 7.x, with conditional ESXi 8.x
  guidance and no unverified ESXi 9.x claim.
- No live infrastructure validation is part of the audit or default tests.

The repository currently has one root skill and flat `references/`, `scripts/`,
`examples/`, and `tests/` directories. It does not yet have a nested `skills/`
convention. The implementation must therefore introduce that convention
minimally and document it without moving unrelated existing content.

## Current repository inventory

| Area | Relevant current files | Audit result |
|---|---|---|
| Root policy/router | `SKILL.md`, `AGENTS.md` | Own R0–R3 policy, task routing, trust, secrets, and Hermes workflow. Keep as source of truth. |
| SSH/ESXi | `references/ssh-esxcli.md` | Own ESXi command compatibility and bounded SSH probing. Do not duplicate command catalog. |
| Capability selection | `references/capability-probe.md` | Own ESXi HTTPS/REST/SDK/SSH selection. Add a narrow route to stable-shell capability detection, not another ESXi probe matrix. |
| Validated paths | `references/validated-interaction-methods.md` | Own observed standalone ESXi access behavior. Keep reliability architecture separate. |
| Private guests | `references/private-guest-access-via-pfsense.md` | Own VPN/jump path, independent guest identity, and ProxyJump boundary. Stable shell may operate after this path is proven. |
| Existing helper | `scripts/esxi-readonly-discovery.sh` | Guarded ESXi discovery only. Do not turn it into a generic SSH session manager. |
| Test harness | `Makefile`, `tests/test-*.sh`, GitHub Actions | Shell-first, mock-only validation with optional local tools and mandatory CI tools. Extend this pattern. |
| Licensing | `LICENSE`, `NOTICE.md` | Repository is MIT and identifies AI-assisted status. Third-party notices must preserve compatible upstream notices when code is adapted. |

## Existing guidance and overlap

### Guidance to keep canonical

- Root `SKILL.md` remains canonical for R0–R3 approval, secret handling,
  untrusted-output treatment, first-contact host-key verification, transport
  selection, and completion reporting.
- `references/ssh-esxcli.md` remains canonical for BusyBox-like ESXi shell
  limitations and `esxcli`/`vim-cmd` commands.
- `references/private-guest-access-via-pfsense.md` remains canonical for VPN,
  dedicated jump host, independent two-hop trust, and prohibition on using
  pfSense as a general-purpose bastion.
- `references/capability-probe.md` remains canonical for choosing among ESXi
  REST, SDK, HTTPS, and SSH.

### Duplication to remove or avoid

The root skill, SSH reference, validated-methods reference, and pfSense guest
reference each repeat parts of strict host-key checking, bounded retries,
dedicated identities, and transport fallback. The new child skill must link to
the applicable parent policy and define only the additional reliability
contract. Existing text should be edited only where a concise router link can
replace or clarify duplicated reliability details.

The child skill must not repeat:

- the full R0–R3 table;
- ESXi command catalogs;
- pfSense VPN or firewall procedures;
- guest identity and access-approval rules;
- REST/SDK endpoint probing;
- unattended guest installation guidance.

### Conflicts to resolve during implementation

| Conflict | Planned resolution |
|---|---|
| Generic SSH convenience versus ESXi trust policy | ESXi and protected guest paths always retain dedicated `known_hosts` plus `StrictHostKeyChecking=yes`; convenience settings never override them. |
| Persistent remote shell versus ESXi restrictions | Never install or assume tmux, Bash, Python, systemd, or a package manager on ESXi. Use atomic one-shot commands or an approved management/jump host. |
| Hermes SSH backend versus restricted appliances | Mark Hermes' built-in SSH environment unsupported for direct ESXi use because it invokes remote Bash and syncs files. Use Hermes' local terminal to invoke guarded OpenSSH instead. |
| Hermes background process versus persistent remote state | Treat Hermes `background=true` as client-side process tracking; use tmux only when the remote process must survive client or SSH loss. |
| ControlMaster health versus command health | Inspect transport, session, pane, and command-marker state independently. |
| Retry convenience versus uncertain side effects | Never repeat a command in `unknown_state`; retry only when idempotent or when evidence proves it never started. |

## Hermes Agent compatibility findings

The reviewed Hermes Agent source is compatible with Agents Skills progressive
disclosure and supports `references/`, `scripts/`, and `examples/` alongside a
skill `SKILL.md`. The planned child skill should use:

```yaml
metadata:
  hermes:
    requires_toolsets:
      - terminal
```

The final frontmatter will keep the standard `name` and concise `description`
fields and avoid model-specific prompting. Every support file needed by the
skill will be linked directly from its `SKILL.md`, because Hermes URL/GitHub
skill installation copies referenced support files.

Hermes terminal behavior affects routing as follows:

| Hermes behavior | Design implication |
|---|---|
| SSH environment spawns a fresh remote `bash -c` command per call. | It is suitable only where remote Bash is verified. It is not the direct ESXi path. |
| It snapshots environment variables and working directory between calls. | Do not mislabel snapshot continuity as process or PTY persistence. |
| It can reuse an OpenSSH control master. | Detect or cooperate with multiplexing; never use it as proof of remote command completion. |
| It defaults to `StrictHostKeyChecking=accept-new`. | Protected ESXi/guest workflows must use the repository's stricter local OpenSSH path with preverified keys. |
| `pty=true` is available for local and SSH-backed calls. | Request PTY only for Mode C; do not set global `RequestTTY force`. |
| `background=true` returns a process session identifier. | Prefer this for supported detached client-side tracking when remote survival is unnecessary. |
| SSH setup syncs Hermes files to the remote home directory. | Reject that backend for restricted or immutable appliances unless compatibility and authorization are explicit. |

For direct ESXi work, the skill will tell Hermes to use its local terminal
backend to execute an explicit `ssh` command or repository helper. For a Linux
management VM or dedicated jump host, the skill may use the Hermes SSH backend
after capability detection confirms Bash, writable paths, and intended trust
semantics.

## Proposed architecture

The parent/router is `stable-ssh-shell`. The requested conceptual submodules
will map to a concise set of progressive-disclosure references:

| Conceptual submodule | Planned reference | Responsibility |
|---|---|---|
| `ssh-transport` | `references/ssh-transport.md` | Trust, authentication mode, keepalives, ProxyJump, multiplexing, stale control sockets, transport statuses. |
| `persistent-remote-shell` | `references/session-architecture.md` | Mode selection, deterministic session names, local/remote boundary, tmux/session lifecycle. |
| `interactive-pty-control` | `references/tmux-pty-control.md` | Explicit pane targeting, literal input, special keys, prompt inspection, polling. |
| `remote-command-protocol` | `references/command-protocol.md` | Command identifiers, start/done markers, exit status, output boundaries, structured result. |
| `session-lifecycle-recovery` | `references/recovery-and-fallback.md` | Reconnect, inspect, unknown-state handling, missing/dead panes, cleanup, fallback. |
| ESXi/Hermes constraints | `references/esxi-hermes-compatibility.md` | Restricted appliance rules and Hermes-specific routing without duplicating parent ESXi policy. |
| Provenance | `references/upstream-sources.md` | Pinned sources, licenses, adopted concepts, rejected assumptions, and notices. |

This uses seven focused references rather than many thin files. The child
`SKILL.md` will remain a short router and protocol summary. If implementation
shows that two references are each shorter than one screen and always loaded
together, they may be consolidated without changing the conceptual modules.

### Layer boundaries

| Layer | Positive evidence | Failure examples | Recovery owner |
|---|---|---|---|
| SSH transport | Verified host identity and successful SSH control operation | DNS/TCP failure, auth rejection, changed key, stale socket | `ssh-transport` |
| Persistence | Expected tmux session/job exists on a supported host | session missing, server unavailable, unsupported remote | `persistent-remote-shell` |
| Agent control | Exact pane targeted and deterministic marker observed | prompt detected, timeout, pane dead, malformed marker | command/PTY modules |
| Lifecycle | Current state classified without guessing | lost transport plus incomplete evidence | recovery module |

## Mode-selection contract

Capability detection and task semantics select exactly one mode:

| Mode | Selection rule | Typical implementation |
|---|---|---|
| A — atomic one-shot | Stateless or restricted target; command can be safely quoted and its SSH exit status is authoritative. | `ssh host -- '<command>'`; primary direct ESXi mode. |
| B — stateful persistent shell | State such as working directory, environment, REPL, or long process must survive client disconnect and tmux is verified. | Deterministically named detached tmux session and explicit pane. |
| C — interactive PTY | Program genuinely requires terminal semantics or a bounded prompt interaction. | Hermes/local PTY plus tmux control, prompt inspection, literal input. |
| D — detached non-interactive job | No PTY is needed, but work outlives a single foreground client call. | Hermes background tracking or approved remote job mechanism; record ownership and status source. |
| E — unsupported/restricted | Required shell/tool/trust/write capability is absent or disallowed. | Stop, report structured limitations, and use an approved fallback. |

Mode B or C must not be selected only because the task is long. Mode D is
preferred for non-interactive work. Mode A is preferred for ESXi.

## Capability-report contract

`scripts/detect-remote-capabilities.sh` will perform non-invasive, bounded
checks and produce machine-readable JSON by default, with an optional concise
human view. It will not install software or modify the remote host.

Planned fields:

```json
{
  "schema_version": "1",
  "target_class": "linux|esxi|restricted|unknown",
  "transport": {
    "reachable": true,
    "host_key_verified": true,
    "batch_auth": true,
    "multiplexing": "available|unavailable|unchecked"
  },
  "remote": {
    "shell": "bash|sh|busybox|unknown",
    "tmux": "available|missing|forbidden|unchecked",
    "writable_runtime_dir": true,
    "pty": "available|unavailable|unchecked"
  },
  "hermes": {
    "builtin_ssh_compatible": false,
    "recommended_backend": "local|ssh|none"
  },
  "supported_modes": ["A", "E"],
  "recommended_mode": "A",
  "limitations": ["remote_bash_unavailable"]
}
```

The final schema may add diagnostic status and exit code fields, but it will
not expose credentials, private key material, command output, or full host
inventory. Network or authentication failures will be classified distinctly
and will not trigger aggressive retries.

## Command protocol and unknown-state rule

Every protocol-wrapped command will receive an unpredictable or collision-safe
command identifier. The controlled pane output must include:

```text
__STABLE_SSH_START__:<id>
__STABLE_SSH_DONE__:<id>:<exit>
```

The controller must capture the pane before submission, submit literal text,
send Enter separately, and poll bounded captures for the matching completion
marker. It must never infer success from a prompt, a sleeping interval, an SSH
exit caused by transport loss, or output from a different pane.

Structured command states are:

- `completed`
- `failed`
- `timed_out`
- `transport_lost`
- `session_missing`
- `pane_dead`
- `prompt_detected`
- `unknown_state`

After transport loss, recovery order is:

1. Re-establish and reverify the intended host identity.
2. Check the transport control socket independently.
3. Locate the deterministic session and exact pane.
4. Inspect captured history for the matching start and done markers.
5. Return the proven state.
6. Retry only if the operation is declared idempotent or evidence proves the
   original command never started.

If neither completion nor non-start can be proved, return `unknown_state` and
do not repeat the command.

## Proposed files

### Files to create after approval

```text
skills/stable-ssh-shell/SKILL.md
skills/stable-ssh-shell/references/session-architecture.md
skills/stable-ssh-shell/references/ssh-transport.md
skills/stable-ssh-shell/references/tmux-pty-control.md
skills/stable-ssh-shell/references/command-protocol.md
skills/stable-ssh-shell/references/recovery-and-fallback.md
skills/stable-ssh-shell/references/esxi-hermes-compatibility.md
skills/stable-ssh-shell/references/upstream-sources.md
skills/stable-ssh-shell/scripts/detect-remote-capabilities.sh
skills/stable-ssh-shell/scripts/wait-for-pane-text.sh
skills/stable-ssh-shell/scripts/stable-ssh-session.sh
skills/stable-ssh-shell/scripts/tmux-command-exec.sh
skills/stable-ssh-shell/examples/ssh-config-stable-shell.example
skills/stable-ssh-shell/examples/linux-persistent-session.md
skills/stable-ssh-shell/examples/proxyjump-private-guest.md
skills/stable-ssh-shell/examples/esxi-one-shot.md
tests/test-stable-ssh-capabilities.sh
tests/test-stable-ssh-transport.sh
tests/test-stable-ssh-session.sh
tests/test-stable-ssh-command-protocol.sh
tests/test-stable-ssh-pty.sh
tests/test-stable-ssh-recovery.sh
tests/test-stable-ssh-restricted-fallback.sh
```

### Existing files to modify after approval

| File | Narrow change |
|---|---|
| `SKILL.md` | Add one task-router entry and one reference/link for persistent SSH or PTY work; retain policy ownership. |
| `AGENTS.md` | Add a routing bullet for the child skill and reinforce direct ESXi restriction. |
| `README.md` | Describe the new optional child skill and supported mode summary. |
| `docs/index.md` | Add documentation navigation. |
| `CHANGELOG.md` | Record the new child skill and local test coverage. |
| `NOTICE.md` | Add third-party attribution only if implementation adapts protected source code or wording. |
| `Makefile` | Usually no change: new `tests/test-*.sh` files are auto-discovered. Modify only if a targeted test entry becomes necessary. |

No installed skill under `~/.hermes/skills`, `.agents/skills`, or a global
Codex skill directory will be changed. No host profile or secret-bearing SSH
configuration will be committed.

## Implementation sequence

1. After `APPROVED — IMPLEMENT`, create branch `feat/stable-ssh-shell` from the
   audited main baseline, carrying these two plan documents onto the branch.
2. Add the child skill skeleton, concise frontmatter, Hermes terminal metadata,
   and progressive-disclosure router.
3. Write the architecture, routing, ESXi/Hermes compatibility, and provenance
   references before helper code.
4. Implement capability detection using portable local Bash and mockable SSH
   boundaries. Avoid invasive remote writes.
5. Implement the transport/session helper with explicit `check`, `start`,
   `status`, `stop`, and cleanup operations. Control sockets must be unique,
   user-private, inspected with `ssh -O check`, and closed with `ssh -O exit`.
6. Implement literal pane input and bounded polling helpers.
7. Implement marker-based command execution and state classification.
8. Add sanitized examples for Linux, ProxyJump, and ESXi Mode A.
9. Add mock binaries/fixtures inside test-created temporary directories. Do
   not invoke real infrastructure.
10. Add root documentation links with no duplicated policy.
11. Run repository validation available locally, document skipped tools, and
    inspect executable bits and the complete diff.
12. Stop and report implementation results. Do not push until exact
    `PUSH APPROVED` is received.
13. After `PUSH APPROVED`, push the feature branch and create a pull request
    targeting `main` with validation evidence, security notes, and source
    attribution summary.

## Test strategy

All tests will be local and mock-only by default. They must override `PATH` or
inject explicit binary paths to fake `ssh`, `tmux`, and remote responses. They
must not read real SSH configuration, contact port 22, or depend on a running
tmux server outside the temporary test directory.

| Test area | Required cases |
|---|---|
| Capability detection | Bash/tmux present; BusyBox/restricted; no tmux; no writable runtime; auth failure; transport failure; stable JSON and mode recommendation. |
| Host trust | Dedicated known-hosts path; strict checking; missing key is a STOP; changed key is a STOP; no `/dev/null`; no unsafe override. |
| Authentication | Batch mode only for non-interactive key/cert paths; auth rejection classified without retry loop; no secret output. |
| Multiplexing | `ControlMaster` optional; safe private path; `-O check`; stale socket detection; `-O exit`; no health conflation. |
| Session names | Deterministic, sanitized, collision-resistant across target/user/project; exact pane required. |
| tmux input | `send-keys -l -- "$TEXT"`; Enter sent separately; special keys only through explicit allowed operation. |
| Capture and polling | Capture-before-submit; bounded polling; exact marker; timeout; large/noisy output; wrong-pane and stale-marker rejection. |
| Command results | `completed`, nonzero `failed`, prompt, pane death, missing session, transport loss, and unknown state. |
| Recovery | Reconnect and inspect; completed-after-loss; running-after-loss; unknown state; retry allowed only with idempotency/non-start proof. |
| Mode fallback | ESXi selects A/E; Linux with tmux can select B/C; no PTY selects A/D/E; unsupported requirements stop safely. |
| ProxyJump | Separate final-host trust; no agent forwarding; sanitized config; pfSense not selected as bastion. |
| Hermes routing | Direct ESXi recommends local backend; verified Linux may allow built-in SSH; Hermes background is not called remote persistence. |
| Static policy | No dangerous SSH defaults, blind prompt responses, credentials, real targets, or package installation commands for ESXi. |

Additional quality gates:

- `bash -n` for every tracked shell script.
- ShellCheck when available, and mandatory ShellCheck in CI.
- Existing `make tests` plus the new mock-only tests.
- Markdown lint, link check, secrets scan, and action lint through existing CI.
- `git diff --check` and a manual review of file modes.
- No live integration test unless a future user separately authorizes and
  supplies a protected test environment.

## Security review

| Risk | Control | Test/evidence |
|---|---|---|
| Host impersonation | Dedicated known-hosts file, independent fingerprint verification, strict checking. | Static assertion and mocked changed-key failure. |
| Credential leakage | No passwords in argv/examples; no agent forwarding; redact diagnostics; do not print environment values. | Secret-pattern tests and diff scan. |
| Command injection | Separate local/remote arguments; literal tmux input; constrained session identifiers; avoid `eval`. | Metacharacter fixtures and ShellCheck. |
| Blind prompt acceptance | Detect and return `prompt_detected`; never auto-send `y`, `yes`, Enter, or passwords. | Prompt fixtures. |
| Duplicate side effects | Marker protocol and unconditional unknown-state stop. | Interrupted non-idempotent fixture. |
| Stale multiplex socket | Private runtime directory, `ssh -O check`, validated ownership/permissions where portable, explicit cleanup. | Mock stale/live socket tests. |
| Wrong pane/session | Exact deterministic identifiers and existence checks before input/capture. | Multiple-session and wrong-pane fixtures. |
| Unbounded waiting | Explicit deadlines and polling intervals; no fixed completion sleeps. | Timeout-duration test. |
| Overbroad private access | Inherit pfSense/jump policy; no pfSense bastion; no forwarding changes in this skill. | Documentation/static tests. |
| ESXi lockout or mutation | Direct ESXi defaults to one-shot, retains parent approval policy, and never installs persistence tooling. | Restricted-host mode tests and policy scan. |

The generic example SSH configuration will set safe host-scoped defaults. It
will not use `StrictHostKeyChecking=no`, `UserKnownHostsFile=/dev/null`, agent
forwarding, wildcard TTY forcing, embedded credentials, or real hostnames.

## Compatibility review

### Linux and POSIX-like management hosts

- Bash is required locally for bundled helpers.
- Remote tmux is optional and must be detected.
- Remote Bash is not assumed for one-shot POSIX mode; commands will either
  declare their shell requirement or use a verified shell.
- tmux behavior must be checked against live `tmux -V` and `tmux ... -h`/manual
  semantics where version differences matter.

### Windows and WSL

- Retain the repository's WSL guidance for Bash helpers and executable bits.
- SSH examples remain valid OpenSSH config shapes, but path syntax is left as
  a placeholder rather than hardcoded to POSIX paths.
- Do not add another POSIX compatibility layer.

### ProxyJump and private guests

- Stable shell begins only after the access path and exact guest are proven by
  the pfSense/private-guest module.
- Jump and final host keys remain independently verified.
- Control sockets and session names must distinguish final destinations.

### ESXi and restricted appliances

- Do not assume Bash, tmux, systemd, Python, GNU utilities, package managers,
  writable home directories, or durable local storage.
- Do not install tmux on ESXi.
- Prefer quoted one-shot SSH with authoritative SSH exit status for read-only
  operations and parent-approved state changes.
- Prefer ESXi-native task/status mechanisms for long-running platform work.
- Place persistent tooling on the local agent, dedicated jump host, or Linux
  management VM only when that host is approved and compatible.
- If reliable persistence cannot be established safely, select Mode E and stop.

### Alternative transports

Mosh, Eternal Terminal, zmx, and autossh may be documented as optional design
alternatives, never installed automatically and never selected without
capability, network, policy, and live-version checks. They are not required by
the initial implementation and are not ESXi dependencies.

## Licensing and attribution

The repository is MIT licensed. The implementation will prefer independently
written helpers based on documented interfaces and concepts. It will not copy
source whose license is unknown.

If protected upstream code or substantial wording is adapted:

- retain the applicable MIT copyright and permission notice;
- name the source file and pinned revision in
  `skills/stable-ssh-shell/references/upstream-sources.md`;
- add a concise entry to root `NOTICE.md` when redistribution obligations make
  that appropriate;
- identify material modifications;
- avoid importing upstream project-specific hostnames, paths, cluster policy,
  email contacts, or dependency assumptions.

`SOURCE_REVIEW_STABLE_SSH_SHELL.md` records the source-by-source license and
reuse decision.

## Documentation integration

The root task router will gain one row similar to:

| Category | Load | Preflight / transport | Typical risk and STOP condition |
|---|---|---|---|
| Persistent or interactive SSH session | `skills/stable-ssh-shell/SKILL.md`, then the target-specific reference | Verify host trust, target class, shell/tmux/PTY capability, and required persistence mode | R0 for detection; inherit target operation risk. STOP on changed key, unsupported target, prompt ambiguity, or unknown command state. |

The child skill will explicitly send ESXi-specific operations back to root
policy and `references/ssh-esxcli.md`. It will send private guest routing back
to `references/private-guest-access-via-pfsense.md`. This keeps policy and
topology ownership clear.

README and docs index changes will explain:

- what problem stable shell solves;
- the distinction between connection reuse and remote persistence;
- the five modes;
- the direct ESXi restriction;
- how Hermes should route local versus SSH terminal work;
- that tests are local mocks and not live validation.

## Rollback plan

Before push, rollback is a normal source edit on the feature branch: remove the
new `skills/stable-ssh-shell/` tree and its tests, then revert only the narrow
router/documentation edits. Do not use destructive worktree reset commands.

After merge, rollback should be a dedicated revert pull request for the stable
shell commits. Because the feature does not change live infrastructure,
installed global skills, credentials, or host profiles, source rollback is
sufficient. Any user-installed copy of the child skill remains operator-owned
and should be removed or updated through the installation method used.

Helper cleanup operations must be scoped to the exact deterministic tmux
session or OpenSSH control socket created by the helper. They must never kill
an entire shared tmux server, delete broad directories, or close unrelated SSH
connections.

## Commit plan

After implementation approval, use small reviewable commits:

1. `docs: add stable SSH shell design and source review`
2. `feat: add stable SSH shell skill and transport guidance`
3. `feat: add deterministic tmux command helpers`
4. `test: cover stable SSH shell recovery and fallbacks`
5. `docs: route ESXi and Hermes stable shell workflows`

The exact split may combine adjacent commits if the final diff is small, but
tests must land with the behavior they validate. No unrelated cleanup belongs
in these commits.

## Approval gates

| Gate | Exact phrase | Allowed next actions |
|---|---|---|
| Phase 1 complete | None | Review these two documents only. |
| Begin implementation | `APPROVED — IMPLEMENT` | Create feature branch, implement, and run local/mock validation. No push. |
| Publish branch | `PUSH APPROVED` | Push the reviewed feature branch and create a pull request to `main`. |
| Live infrastructure | Separate explicit authorization naming target and scope | Not part of this plan or default tests. |

The user's request to finish with a pull request is recorded, but the pull
request cannot be created until both earlier gates are satisfied.

## Acceptance criteria

Phase 2 will be considered ready for push only when:

- the child skill uses progressive disclosure and directly references every
  required support file;
- the root ESXi skill remains the safety-policy source of truth;
- Hermes direct ESXi routing avoids the Bash/sync assumptions of its built-in
  SSH environment;
- capability detection is bounded, non-invasive, structured, and mock-tested;
- Modes A–E have explicit selection and fallback rules;
- tmux input is literal, pane-specific, and never blindly confirms prompts;
- command completion uses matching markers and captured state;
- `unknown_state` can never cause automatic command replay;
- control masters are optional, safely scoped, independently checked, and
  explicitly cleanable;
- ESXi examples install nothing and default to atomic one-shot commands;
- tests contact no real host and cover interruption, prompt, timeout, stale
  socket, missing/dead pane, and restricted-host cases;
- scripts have executable modes and pass available repository checks;
- source provenance and required license notices are complete;
- no secret, private inventory, credential, generated session artifact, or
  unsafe SSH default is added;
- the final implementation report states result, changed files, validation,
  security decisions, compatibility limits, source reuse, and remaining risk;
- push and pull-request creation wait for exact `PUSH APPROVED`.

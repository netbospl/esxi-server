# Stable SSH shell source review

## Contents

- [Review status](#review-status)
- [Method](#method)
- [Summary matrix](#summary-matrix)
- [Yale staying-connected](#yale-staying-connected)
- [OpenClaw tmux skill](#openclaw-tmux-skill)
- [Superpowers Lab skill](#superpowers-lab-skill)
- [claude-code-tools tmux-cli](#claude-code-tools-tmux-cli)
- [claude-session](#claude-session)
- [Hermes Agent](#hermes-agent)
- [Canonical protocol and tool references](#canonical-protocol-and-tool-references)
- [Concepts accepted](#concepts-accepted)
- [Assumptions rejected](#assumptions-rejected)
- [License and attribution plan](#license-and-attribution-plan)
- [Provenance decision](#provenance-decision)

## Review status

- Review date: 2026-08-03
- Phase: 1, audit and plan only
- Code copied or adapted in this phase: none
- Packages installed: none
- Live SSH/ESXi activity: none
- Target repository baseline:
  `98ab0bbf27efec2d2eeb4db840e898ce1b7f9f25`

This review compares the requested upstream material with the current
`netbospl/esxi-server` policy, the current Hermes Agent implementation, and
canonical SSH/tmux documentation. Source revisions are pinned where a reviewed
Git commit was available. Website documentation is date-stamped because it can
change without a repository revision.

## Method

For each source, the review recorded:

1. The exact file or official page examined.
2. A commit or blob identifier when available.
3. The repository license visible at review time.
4. Reusable concepts relevant to stable SSH sessions.
5. Project-specific assumptions that must be removed.
6. Whether code reuse is allowed, unnecessary, or prohibited.

The design follows documented interfaces rather than copying helper code. If
Phase 2 changes that decision, the implementation must update the child skill's
`references/upstream-sources.md` and the root notice where required.

## Summary matrix

| Source | Reviewed revision/file | License found | Planned use |
|---|---|---|---|
| Yale `staying-connected` | Commit `0a8f62dafb0e9ededa9efc3e4a47edf086f2ad87`; skill blob `a7845d5d809d0ea78c71c3e82cac3625d41c6263` | Unlicense/public domain | Concepts and comparison language only. |
| OpenClaw tmux | Skill blob `6daf7358173026b1afcd4ebc8b818e360438d325`; wait helper blob `56354be835459c7614bfc96b5526e92dc1dbde5d` | MIT, OpenClaw Foundation, 2026 | tmux control concepts; independently implement. Preserve notice if code is adapted. |
| Superpowers Lab | Skill blob `b8805d846d01c9ed2bfa1d6985fbfadeb663f5fa` | MIT, Jesse Vincent, 2025 | PTY and detached-session concepts; independently implement. |
| `claude-code-tools` tmux-cli | Skill blob `8e9da3a8c3912c9270268eb5b8302f21d8ae4bbf` | MIT, Prasad Chalasani, 2025 | Structured result concepts; no dependency or code import. |
| `claude-session` | Commit `c8a0944ec7a0d7415126e5183a378dd1be0ac579`; skill blob `a70ec31252c213934aecc3ba218e7ff937de1955` | No repository license found during review | Concept-only; no code or wording reuse. |
| Hermes Agent | Commit `34d6095e41c1c595fe2f458923f3a85e9081a414`; skills docs and SSH environment source | Repository license governs upstream project; no code planned for reuse | Compatibility target and routing evidence only. |
| OpenBSD `ssh_config(5)` | Official manual, reviewed 2026-08-03 | Documentation terms of OpenBSD site | Canonical behavior reference. |
| OpenBSD `tmux(1)` | Official manual, reviewed 2026-08-03 | Documentation terms of OpenBSD site | Canonical tmux behavior reference. |
| Mosh, Eternal Terminal, zmx | Official sites, reviewed 2026-08-03 | Project-specific; no code reuse planned | Optional alternatives and boundary comparison only. |

For sources reviewed from a moving default branch, the content blob identifies
the exact reviewed file even when the branch later advances. Phase 2 should
also record the resolved commit in the child provenance reference when code is
actually adapted.

## Yale staying-connected

Reviewed source:

- Repository material titled `staying-connected`
- Commit: `0a8f62dafb0e9ededa9efc3e4a47edf086f2ad87`
- Skill blob: `a7845d5d809d0ea78c71c3e82cac3625d41c6263`
- License blob: `3aa5470f2bee2fa250e23cf993064da29cb0bf0b`
- License: Unlicense/public-domain dedication

Useful concepts:

- Clearly distinguish the local agent machine from the remote machine.
- Use tmux or another server-side session mechanism when work must survive an
  SSH client disconnect.
- Use SSH keepalives and optional control multiplexing for transport behavior,
  while keeping them separate from process persistence.
- Reattach to named sessions after reconnecting.
- Compare alternatives such as autossh, Mosh, Eternal Terminal, and zmx by the
  failure mode they solve rather than treating them as equivalent.

Assumptions to remove:

- Yale-specific hostnames, cluster names, email addresses, home-directory
  layouts, institutional policy, HPC modules, schedulers, and support contacts.
- Any implication that a remote Linux cluster environment resembles ESXi.
- Any instruction to install a persistence package without target approval and
  compatibility checks.
- Any transport recommendation that weakens the current repository's explicit
  host-key trust requirements.

Reuse decision:

Use the public-domain concepts as design input. Write all repository text and
helpers independently so the skill remains concise and tailored to ESXi,
private guests, and Hermes.

## OpenClaw tmux skill

Reviewed source:

- Skill blob: `6daf7358173026b1afcd4ebc8b818e360438d325`
- Wait-for-text helper blob: `56354be835459c7614bfc96b5526e92dc1dbde5d`
- License blob: `ebaebf7c416761a32f932ad70ebe5d1d2e214f68`
- License: MIT, Copyright 2026 OpenClaw Foundation

Useful concepts:

- Always identify a specific tmux pane.
- Capture pane contents as observable state.
- Send ordinary input literally, then send Enter separately.
- Inspect prompts before responding.
- Poll for text with a deadline rather than assuming a fixed sleep proves
  readiness.

Canonical confirmation:

The official tmux manual states that `send-keys -l` disables key-name lookup
and processes literal UTF-8 text, `capture-pane -p` writes captured pane
contents to standard output, and `has-session` returns zero only when the
specified session exists.

Assumptions to remove:

- OpenClaw-specific directory layouts, agent names, tool wrappers, and session
  naming.
- Any helper behavior that searches insufficiently scoped pane output or treats
  arbitrary matching text as command completion.
- Any blind response to prompts.

Reuse decision:

Independently implement a smaller polling helper with exact target and marker
matching. If Phase 2 copies or closely adapts protected code, preserve the MIT
notice in the child provenance reference and root `NOTICE.md`, name the source,
and describe modifications.

## Superpowers Lab skill

Reviewed source:

- Skill blob: `b8805d846d01c9ed2bfa1d6985fbfadeb663f5fa`
- License blob: `abf0390320aa14406af7a520b9b0739fdda9bf08`
- License: MIT, Copyright 2025 Jesse Vincent

Useful concepts:

- Some programs require a real PTY and should not be driven as ordinary
  non-interactive commands.
- Detached tmux sessions allow later inspection and reattachment.
- Special keys should be explicit operations, separate from ordinary literal
  text.
- Working directory, lifecycle cleanup, and ownership must be deliberate.
- One-shot, interactive, and detached work are distinct modes.

Assumptions to remove:

- Author-specific absolute paths such as `/home/jesse/...`.
- Fixed sleep intervals as proof that an interactive program is ready.
- Development-tool examples that do not define a completion protocol.
- Any global cleanup that kills unrelated sessions.

Reuse decision:

Use concepts only and independently implement the ESXi repository behavior.
If protected code is later adapted, retain the MIT notice and identify the
modified source.

## claude-code-tools tmux-cli

Reviewed source:

- Skill blob: `8e9da3a8c3912c9270268eb5b8302f21d8ae4bbf`
- License blob: `21d071708bee563a21a7fea0763f781b9c40449b`
- License: MIT, Copyright 2025 Prasad Chalasani

Useful concepts:

- Return structured output that distinguishes transport, command, and timeout
  outcomes.
- Preserve remote exit status when it is known.
- Distinguish an explicit indefinite timeout setting from an accidental missing
  deadline.
- Distinguish shell command execution from interactive agent-chat control.

Assumptions to remove:

- Dependency on a separately installed `tmux-cli` package.
- CLI-specific JSON shape that does not express session missing, pane death,
  prompt detection, transport loss, or unknown state.
- Any blanket infinite-wait default.

Reuse decision:

Do not add the dependency and do not copy code. Implement a repository-local,
mockable result schema in Bash using the requested status vocabulary.

## claude-session

Reviewed source:

- Commit: `c8a0944ec7a0d7415126e5183a378dd1be0ac579`
- Skill blob: `a70ec31252c213934aecc3ba218e7ff937de1955`
- README at the same reviewed revision
- License: no repository license was found during the review; the attempted
  license fetch returned not found.

Useful concepts:

- Derive stable session identity from a project or task boundary.
- Bound restart attempts and increase delay between recovery attempts.
- Treat a user-level service manager as one optional lifecycle owner on
  compatible Linux systems.
- Make diagnostics and restart history observable.

Assumptions to remove:

- Claude-specific process/session naming.
- systemd user-manager availability.
- Any automatic restart of a command whose completion state or side effects are
  unknown.
- Any implication that ESXi supports a durable service manager for this use.

Reuse decision:

Concept-only. Because no license was found, copy no code, wording, templates,
or configuration. The proposed skill's recovery logic will be independently
specified and will stop on unknown state.

## Hermes Agent

Reviewed source:

- Repository: `NousResearch/hermes-agent`
- Commit: `34d6095e41c1c595fe2f458923f3a85e9081a414`
- Skills documentation, terminal/tool documentation, SSH environment source,
  terminal environment selection, and base environment snapshot behavior

### Skill compatibility

Hermes supports Agents Skills-style discovery and progressive disclosure:

- the skill catalog exposes names and descriptions;
- `skill_view(name)` loads a skill body;
- `skill_view(name, path)` loads a referenced support file;
- skill layouts may contain `references/`, `scripts/`, and `examples/`;
- Hermes metadata can declare `requires_toolsets: [terminal]`;
- external skill directories can be configured;
- URL/GitHub installation copies support files referenced by the skill.

Design consequences:

- Keep `skills/stable-ssh-shell/SKILL.md` short and directly link every required
  support file.
- Use a concise trigger description and Hermes terminal-toolset metadata.
- Do not modify `~/.hermes/skills/` during repository implementation.
- Keep the content model-agnostic; Hermes is a supported runtime, not the
  skill's identity.

### SSH environment behavior

The reviewed Hermes SSH environment:

- builds OpenSSH commands with `BatchMode=yes` and a connect timeout;
- defaults to `StrictHostKeyChecking=accept-new`;
- can use `ControlMaster=auto` and `ControlPersist=300` with a temporary control
  socket;
- executes a fresh remote `bash -c` command for each call;
- snapshots environment variables and working directory between calls;
- can sync Hermes files into the remote home directory;
- closes its control master with an SSH control operation;
- supports terminal PTY and background process tracking through the terminal
  tool surface.

Compatibility decision:

| Target | Hermes route |
|---|---|
| Direct ESXi or Bash-less restricted appliance | Use Hermes local terminal to invoke guarded repository/OpenSSH commands. Do not use built-in SSH environment. |
| Verified Linux management/jump host | Built-in SSH may be used if Bash, remote writes, and `accept-new` trust semantics are appropriate or the key is already safely established. |
| Interactive PTY on compatible host | Use `pty=true` only for Mode C; pair with explicit tmux pane control when remote survival is needed. |
| Detached client-tracked process | Use `background=true` for Mode D when loss of the client process does not violate persistence requirements. |

The built-in environment's snapshot continuity is not a persistent shell
process. The child skill must say this explicitly. It must also retain the ESXi
repository's stronger first-contact trust model instead of silently accepting a
new ESXi key.

No Hermes code will be copied into the target repository.

## Canonical protocol and tool references

### OpenSSH client configuration

Official reference:
[OpenBSD `ssh_config(5)`](https://man.openbsd.org/ssh_config), reviewed
2026-08-03.

Relevant documented behavior:

- `BatchMode=yes` disables password and host-key confirmation interaction, so
  it belongs only in intentionally non-interactive flows.
- `ConnectTimeout` bounds connection establishment and handshake.
- `ControlMaster` and `ControlPersist` share an SSH transport; they do not
  persist a remote process by themselves.
- a safe `ControlPath` should include destination identity such as `%h`, `%p`,
  and `%r` or `%C` and live in a directory not writable by other users.
- an indefinite control master can be closed with `ssh -O exit`.
- agent forwarding exposes signing capability to the remote environment and is
  not a safe default.

Planned use:

- Keep multiplexing optional and host-scoped.
- Use `ssh -O check` and `ssh -O exit` for explicit control lifecycle.
- Never equate a reusable transport with a running or completed remote command.
- Retain dedicated known-hosts files and strict checking for ESXi/private guest
  examples.

### tmux

Official reference:
[OpenBSD `tmux(1)`](https://man.openbsd.org/tmux.1), reviewed 2026-08-03.

Relevant documented behavior:

- `send-keys -l` sends literal text instead of interpreting key names.
- `capture-pane -p` emits observable pane content.
- `has-session` provides an existence status for a specific session.
- pane/session targets must be explicit to avoid controlling the wrong object.

Planned use:

- Send command text with `send-keys -l -- "$TEXT"` and Enter in a separate
  invocation.
- Capture before submission and poll exact markers afterward.
- Inspect pane-dead and session-existence state independently.
- Never kill the entire tmux server during routine cleanup.

### Mosh

Official reference: [mosh.org](https://mosh.org/), reviewed 2026-08-03.

Mosh is designed for roaming, intermittent connectivity, and responsive
interactive terminal state. It is an optional alternative for compatible
hosts and networks, not a command-completion protocol, not an OpenSSH control
master, and not an ESXi dependency. It uses a distinct UDP-based design, so its
network and security requirements must be reviewed before use.

### Eternal Terminal

Official reference:
[eternalterminal.dev](https://eternalterminal.dev/), reviewed 2026-08-03.

Eternal Terminal is an optional reconnecting terminal transport. The initial
skill will mention it only as an alternative. It will not install, configure,
or assume the service, and it will not use it for direct ESXi work.

### zmx

Official reference: [zmx.sh](https://zmx.sh/), reviewed 2026-08-03.

The site documents named persistent sessions, SSH PTY requirements, and
optional OpenSSH multiplexing. zmx is an alternative session layer rather than
a required dependency. Its live CLI help and installed version must be checked
before generating commands because its interface can change.

## Concepts accepted

The combined source review supports these design choices:

- separate local agent, SSH transport, remote session, exact pane, and command
  state;
- prefer atomic one-shot execution when state is unnecessary;
- use a named remote session only when process/PTY survival is required;
- use a PTY only for genuinely interactive programs;
- send literal text and special keys through separate operations;
- capture observable state before and after submission;
- require exact start and done markers with a command identifier;
- classify prompt, timeout, transport loss, missing session, pane death, and
  unknown state separately;
- make transport reconnection bounded and observable;
- never replay an unknown-state command automatically;
- treat alternative transports as optional capability-dependent choices;
- keep restricted appliances on minimal, non-invasive fallback paths.

## Assumptions rejected

The implementation must reject these cross-source assumptions:

- every remote target is a general-purpose Linux system;
- Bash, tmux, Python, systemd, GNU tools, or package installation are present;
- an SSH control master is a persistent remote shell;
- a Hermes environment/CWD snapshot keeps a process alive;
- a prompt proves that the intended command completed;
- sleeping for a fixed duration establishes readiness;
- an SSH reconnect makes command replay safe;
- it is acceptable to send `y`, `yes`, Enter, or a password without first
  identifying the exact prompt and approved action;
- first-contact `accept-new` trust is sufficient for protected ESXi access;
- pfSense is a suitable general-purpose SSH bastion;
- agent forwarding is an acceptable default;
- missing license information permits code reuse;
- example hostnames, paths, credentials, or cluster procedures belong in a
  generic skill.

## License and attribution plan

The target repository is MIT licensed. Phase 2 should independently implement
the small Bash helpers from official interface behavior and the design concepts
above. This minimizes provenance complexity and keeps behavior auditable.

| Upstream | If concepts only | If code/substantial wording is adapted |
|---|---|---|
| Yale Unlicense source | Cite in provenance reference. | Record pinned source and modification; attribution is still useful even if not required. |
| OpenClaw MIT | Cite concepts and canonical tmux manual. | Retain copyright and MIT permission notice; add root notice if redistributed. |
| Superpowers MIT | Cite concepts. | Retain copyright and MIT permission notice; identify modifications. |
| claude-code-tools MIT | Cite concepts. | Retain copyright and MIT permission notice; identify modifications. |
| claude-session, no license found | Cite high-level concept if useful. | Do not copy or adapt code/wording without a confirmed license or permission. |
| Hermes Agent | Cite compatibility revision. | No code reuse is planned; if that changes, review the repository license and file provenance again. |

The final child provenance reference should include full commit identifiers,
direct source links, review date, license, what was reused, what was rejected,
and whether any implementation code was independently written.

## Provenance decision

Proceed in Phase 2 with an independent implementation based on official
OpenSSH/tmux behavior and the accepted architectural concepts. Do not vendor an
upstream CLI, install a new dependency, or copy unlicensed source.

The implementation should attribute conceptual influence in
`skills/stable-ssh-shell/references/upstream-sources.md`. Root `NOTICE.md`
should change only if protected source code or substantial protected wording is
actually redistributed. Any change from this decision must be documented in
the implementation report before push approval is requested.

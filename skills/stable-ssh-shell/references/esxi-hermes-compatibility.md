# ESXi and Hermes compatibility

## Hermes routing

Hermes can expose local, SSH, PTY, and background terminal execution. Treat
these as execution surfaces, not proof of persistent remote state.

- Hermes' SSH environment may execute fresh remote Bash commands and preserve
  environment/CWD snapshots. A snapshot is not a surviving shell process.
- Use `pty=true` only for Mode C.
- Use `background=true` for Mode D when Hermes process tracking meets the
  durability requirement.
- Use remote tmux only when the process must survive loss of the Hermes client
  or SSH transport.
- Keep the skill model-agnostic. Hermes is one compatible agent runtime.

For a repository checkout, expose its `skills/` directory through Hermes'
supported external-skill-directory configuration, or install the child skill
through Hermes' supported GitHub skill flow. Verify that every referenced
script, reference, and example is present before relying on the skill.

## Direct ESXi boundary

Do not use a generic remote environment that requires Bash, remote file sync,
or a writable home directory against ESXi. In Hermes, invoke guarded local
OpenSSH or the parent repository helper from the local terminal backend.

ESXi is BusyBox-like and may lack Bash, tmux, Python, systemd, GNU tools,
package managers, and durable writable paths. Therefore:

- never install tmux or persistence tooling on ESXi;
- prefer Mode A with carefully quoted one-shot `esxcli` or `vim-cmd` commands;
- retain dedicated known-hosts and strict host-key verification;
- use ESXi-native task/status surfaces for long-running platform operations;
- place optional persistence on an approved Linux management VM, dedicated
  jump host, or the local agent;
- return Mode E when the required behavior cannot be verified safely.

Load [`../../../references/ssh-esxcli.md`](../../../references/ssh-esxcli.md)
for ESXi commands and [`../../../SKILL.md`](../../../SKILL.md) for approvals.
The stable-shell skill does not authorize an ESXi, pfSense, or guest change.

## Private guests

First establish the approved VPN or dedicated-jump path described in
[`../../../references/private-guest-access-via-pfsense.md`](../../../references/private-guest-access-via-pfsense.md).
Then authenticate independently to the exact guest. A pfSense approval does
not authorize guest commands, and pfSense must not be used as the persistent
shell host.

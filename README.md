# ESXi Server Skill

This repository contains an **experimental ESXi Server Skill** for agentic workflows. It documents how a human or AI operations agent should safely interact with a standalone VMware ESXi host using SSH, `esxcli`, `vim-cmd`, the vSphere REST API, and datastore file-transfer endpoints.

The repository is documentation-only. It does not contain implementation code, dependencies, CI configuration, credentials, hostnames, private IP addresses, passwords, tokens, or SSH keys.

## AI-Assisted / Vibe-Coded Notice

This repository is AI-assisted / vibe-coded. The skill is experimental and may contain incomplete assumptions, environment-specific details, or rough edges.

Commands and guidance must be reviewed by a human before use on real ESXi hosts. Do not run destructive actions without explicit confirmation, and do not treat this repository as a substitute for ESXi administration knowledge, backups, or local change-control procedures.

No warranty is provided. Operators remain responsible for validating commands, assessing risk, and adapting procedures to their own environment. See [`NOTICE.md`](NOTICE.md) for the standalone notice.

## What this skill helps with

Use this skill when managing or inspecting a VMware ESXi 7.0 host, including:

- ESXi SSH access
- Host-level `esxcli` checks
- `vim-cmd` VM operations on standalone ESXi
- vSphere REST API authentication and VM lifecycle operations
- VM power state checks, starts, stops, shutdowns, and reboots
- Snapshot listing, creation, revert, and removal workflows
- Datastore browsing and free-space checks
- ISO, OVF, OVA, and VMDK transfers
- Resource checks for CPU, RAM, storage, and VM sizing
- Networking checks for vSwitches, VMkernel adapters, physical NICs, and port groups

## Supported environment

The current references are written for:

- VMware ESXi 7.0 / 7.0 Update 1c
- A standalone ESXi host without vCenter assumptions
- ESXi HTTPS endpoints using a self-signed TLS certificate
- SSH access for host-level commands
- REST API access at `https://$ESXI_HOST/api`

Self-signed TLS is expected for this environment. Commands intentionally use `-k`, `--insecure`, or equivalent TLS verification overrides where appropriate. Do not remove those flags unless the host has a trusted certificate chain.

## Required environment variables and secrets

Set these values in your local shell, secret manager, or agent runtime. Do **not** commit real values to Git.

| Variable | Purpose |
|---|---|
| `ESXI_HOST` | ESXi hostname or address |
| `ESXI_USER` | ESXi username, commonly `root` |
| `ESXI_PASS` | ESXi password or secret-manager-provided password |
| `ESXI_SSH_KEY` | Path to a private SSH key for key-based access |

Example placeholder file: [`.env.example`](.env.example).

> **Warning:** never commit `.env`, SSH private keys, API tokens, session IDs, private hostnames, private IP addresses, passwords, or screenshots/logs containing sensitive ESXi inventory details.

## Repository structure

```text
.
├── SKILL.md
├── references/
│   ├── ssh-esxcli.md
│   ├── rest-api.md
│   └── file-transfers.md
├── docs/
│   └── index.md
├── AGENTS.md
├── NOTICE.md
├── SECURITY.md
├── CONTRIBUTING.md
├── CHANGELOG.md
├── LICENSE
├── .env.example
├── .editorconfig
└── .gitignore
```

## Quick start

1. Read [`SKILL.md`](SKILL.md) first to understand the expected agent behavior, safety workflow, and host conventions.
2. Export local environment variables or configure them in your agent secret store:

   ```bash
   export ESXI_HOST="your-esxi-host.example.com"
   export ESXI_USER="root"
   export ESXI_PASS="use-a-secret-manager-or-local-env-only"
   export ESXI_SSH_KEY="/path/to/private/key"
   ```

3. Load the reference file that matches the task:
   - SSH, `esxcli`, `vim-cmd`: [`references/ssh-esxcli.md`](references/ssh-esxcli.md)
   - vSphere REST API: [`references/rest-api.md`](references/rest-api.md)
   - ISO/OVF/VMDK transfers: [`references/file-transfers.md`](references/file-transfers.md)
4. Start with read-only checks before making changes.
5. Ask for explicit confirmation before destructive operations.

## Safe example commands

These examples are intentionally read-only.

Check that required variables are present without printing secrets:

```bash
: "${ESXI_HOST:?ESXI_HOST is required}"
: "${ESXI_USER:?ESXI_USER is required}"
printf 'ESXi environment variables are set for host %s and user %s\n' "$ESXI_HOST" "$ESXI_USER"
```

Check ESXi version over SSH:

```bash
ssh -i "$ESXI_SSH_KEY" -o StrictHostKeyChecking=no \
  "$ESXI_USER@$ESXI_HOST" 'esxcli system version get'
```

Create a REST API session:

```bash
SESSION=$(curl -sk -X POST \
  "https://$ESXI_HOST/api/session" \
  -u "$ESXI_USER:$ESXI_PASS" \
  -H "Content-Type: application/json" | tr -d '"')
```

List VMs through the REST API:

```bash
curl -sk "https://$ESXI_HOST/api/vcenter/vm" \
  -H "vmware-api-session-id: $SESSION"
```

List datastores over SSH:

```bash
ssh -i "$ESXI_SSH_KEY" -o StrictHostKeyChecking=no \
  "$ESXI_USER@$ESXI_HOST" 'esxcli storage filesystem list'
```

## Choosing SSH vs REST API

Use the smallest, safest interface for the task.

| Task | Prefer |
|---|---|
| Host hardware, memory, NIC, vSwitch, VMkernel, or filesystem checks | SSH with `esxcli` |
| Standalone ESXi VM inspection when REST is insufficient | SSH with `vim-cmd` |
| VM listing, power state, lifecycle operations, and snapshots | vSphere REST API |
| Datastore browsing through HTTPS | REST/datastore browser endpoints |
| ISO, OVF, OVA, and VMDK upload/download | HTTPS datastore browser API, SCP, or `ovftool` where appropriate |
| Low-level network changes | SSH with `esxcli`, only after confirmation |

If a REST session returns `401`, re-authenticate rather than reusing stale session IDs.

## Safety notes

- Prefer read-only discovery commands before write operations.
- Avoid destructive operations without explicit user confirmation.
- Show the exact command or API action before running dangerous operations.
- Check available RAM before VM creation, VM power-on, or memory increases.
- Check VM power state before hardware changes.
- Check datastore free space before ISO, OVF, OVA, VMDK, cloning, restore, or snapshot-heavy operations.
- Ask before deleting VMs, disks, snapshots, datastore contents, datastores, or networking objects.
- Ask before powering off, rebooting, suspending, or resetting production or unknown VMs.
- Use `datastore1` for normal VM storage unless instructed otherwise.
- Use `backup_nfs41` for backups, ISOs, OVFs, and transfer staging unless instructed otherwise.
- Use `PG-RESTRICTED` for isolated or least-privilege VMs.
- Use `PG-UNRESTRICTED` only when external access is required and understood.
- Do not hardcode credentials, session tokens, host details, private IPs, or private inventory names in examples or scripts.

## Reference files

- [`SKILL.md`](SKILL.md) — top-level skill instructions, safety workflow, and host conventions
- [`references/ssh-esxcli.md`](references/ssh-esxcli.md) — SSH, `esxcli`, `vim-cmd`, networking, datastore, and resource checks
- [`references/rest-api.md`](references/rest-api.md) — vSphere REST API sessions, VM lifecycle, snapshots, datastores, networking, and resource checks
- [`references/file-transfers.md`](references/file-transfers.md) — datastore upload/download, OVF/OVA transfer patterns, and SCP notes
- [`AGENTS.md`](AGENTS.md) — concise operating rules for AI agents using this repository
- [`SECURITY.md`](SECURITY.md) — security expectations and private reporting guidance
- [`NOTICE.md`](NOTICE.md) — AI-assisted / vibe-coded experimental-use notice

## License

This repository is licensed under the [MIT License](LICENSE). MIT is permissive and includes an “AS IS” no-warranty disclaimer appropriate for a small experimental documentation/skill repository.

## Maintenance notes

- Keep examples practical and safe by default.
- Keep ESXi 7.0 compatibility in mind.
- Use placeholders for sensitive values.
- Update this README and `docs/index.md` when adding or renaming reference files.
- Do not add package managers, frameworks, CI systems, or dependencies unless the repository grows beyond documentation.
- Validate new commands against a non-production ESXi host where possible.

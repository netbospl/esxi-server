# ESXi Server Skill

This repository contains an experimental ESXi Server Skill for agentic workflows. It documents how a human or AI operations agent should safely interact with a standalone VMware ESXi host using SSH, `esxcli`, `vim-cmd`, the vSphere REST API, datastore file transfers, and related read-only discovery paths.

The repository contains safety documentation plus small local Bash helpers,
mocked tests, ISO-media generators, a Makefile, and a GitHub Actions quality
workflow. It contains no real credentials, hostnames, private IPs, passwords,
tokens, or SSH keys.

## Safety-first operating model

1. Start with read-only discovery.
2. Probe capabilities before choosing REST, SSH, or SDK access.
3. Write a plan that names the target, risk, and rollback idea.
4. Wait for explicit human approval before state changes.
5. Verify after the change and summarize honestly.

Read [`SKILL.md`](SKILL.md) first for the exact workflow, approval rules, host-key guidance, and local-profile conventions.

## Why this repo exists

- It packages a reusable ESXi safety workflow for humans and agents.
- It keeps generic skill logic separate from host-specific data.
- It provides a sanitized example profile plus templates for change plans, approvals, rollback notes, and post-change summaries.
- It includes a small read-only discovery helper script and optional quality checks.

## Repository layout

```text
.
├── SKILL.md
├── profiles/
│   ├── README.md
│   └── example-host.md
├── references/
│   ├── agent-communication-contract.md
│   ├── backup-restore.md
│   ├── capability-probe.md
│   ├── certificates-letsencrypt.md
│   ├── dedicated-agent-user.md
│   ├── file-transfers.md
│   ├── guest-os-autoinstall.md
│   ├── host-configuration-backup.md
│   ├── network-firewall-ipv4-ipv6.md
│   ├── rest-api.md
│   ├── ssh-esxcli.md
│   ├── troubleshooting.md
│   └── vm-import-export.md
├── examples/
│   └── guest-autoinstall/
│       ├── scripts/ (ISO generators and validate-inputs.sh)
│       ├── windows/ (four explicit Windows answer-file variants)
│       └── packer/ (vCenter vSphere-ISO templates)
├── scripts/
│   └── esxi-readonly-discovery.sh
├── tests/
│   ├── test-esxi-readonly-discovery.sh
│   ├── test-discovery-rest-state.sh
│   └── test-media-generators.sh
├── .github/workflows/quality.yml
├── lychee.toml
├── templates/
│   ├── approval-request.md
│   ├── change-plan.md
│   ├── discovery-report.md
│   ├── post-change-summary.md
│   └── rollback-notes.md
├── docs/
│   └── index.md
├── AGENTS.md
├── NOTICE.md
├── SECURITY.md
├── CONTRIBUTING.md
├── CHANGELOG.md
├── LICENSE
├── Makefile
├── .env.example
├── .editorconfig
└── .gitignore
```

## Guest OS unattended install examples

See [`references/guest-os-autoinstall.md`](references/guest-os-autoinstall.md) for the safety notes, compatibility checklist, and the guest/host install distinction.

A working template pack lives under [`examples/guest-autoinstall/`](examples/guest-autoinstall/README.md). It includes Windows answer-file templates, Windows 11 local-account notes, Ubuntu autoinstall seed files, Kickstart and preseed examples, Packer skeletons, and local helper scripts for creating seed media or serving HTTP content.

The active Windows answer files are Windows 10 BIOS/MBR, Windows 10 UEFI/GPT,
Windows 11 UEFI/GPT, and Windows Server 2022 UEFI/GPT. See the example README
for destructive-disk and firmware notes.

## Environment and local files

Use local environment variables or a secret manager. Do **not** commit real values to Git.

| Variable | Purpose |
|---|---|
| `ESXI_HOST` | ESXi hostname or address |
| `ESXI_USER` | Preferred ESXi user, ideally `agent` |
| `ESXI_PASS` | ESXi password when password auth is required |
| `ESXI_SSH_KEY` | Dedicated private SSH key path |
| `ESXI_KNOWN_HOSTS` | Dedicated SSH known-hosts file path |

Example placeholders live in [`profiles/example-host.md`](profiles/example-host.md) and [`.env.example`](.env.example). Local host profiles such as `profiles/*.local.md` and `HOST_PROFILE.local.md` are ignored by Git and may be loaded locally, but they must never be committed.

> **Warning:** never commit `.env`, private keys, API tokens, session IDs, private hostnames, private IP addresses, passwords, or screenshots/logs containing sensitive ESXi inventory details.

## Safe example commands

These examples are intentionally read-only.

Check that required variables are present without printing secrets:

```bash
: "${ESXI_HOST:?ESXI_HOST is required}"
: "${ESXI_USER:=agent}"
printf 'ESXi environment variables are set for host %s and user %s\n' "$ESXI_HOST" "$ESXI_USER"
```

Safe SSH pattern: use the guarded local helper. It prints an untrusted scanned
fingerprint and stops; verify it out of band before explicitly accepting it.

```bash
ESXI_HOST_FINGERPRINT=SHA256:verified-out-of-band \
scripts/esxi-readonly-discovery.sh --accept-new-host-key
```

The helper validates TLS by default, uses bounded requests and one REST session
for its probe series, distinguishes transport/TLS/authentication/authorization/
unsupported-endpoint outcomes, and never prints tokens. Use a verified
`ESXI_CA_BUNDLE` when required; `ESXI_INSECURE_TLS=1` is a temporary explicit
exception, never a default.

## Choosing SSH vs REST API

Use the smallest, safest interface for the task.

| Task | Prefer |
|---|---|
| Host hardware, memory, NIC, vSwitch, VMkernel, or filesystem checks | SSH with `esxcli` |
| Standalone ESXi VM inspection when REST is insufficient | SSH with `vim-cmd` |
| VM listing, power state, lifecycle operations, and snapshots | REST API when available and reliable |
| Datastore browsing through HTTPS | REST/datastore browser endpoints |
| ISO, OVF, OVA, and VMDK upload/download | HTTPS datastore browser API, SCP, or `ovftool` where appropriate |
| Low-level network changes | SSH with `esxcli`, only after confirmation |

If a REST session returns `401`, re-authenticate rather than reusing stale session IDs. If capability detection fails, stop and report the failure instead of guessing.

## Dedicated agent user guidance

Prefer a dedicated local ESXi user named `agent` for automation. Use a dedicated SSH key stored outside the repository, and treat key creation, user creation, and permission changes as human-approved actions only. See [`references/dedicated-agent-user.md`](references/dedicated-agent-user.md).

## Additional checks and tooling

- [`Makefile`](Makefile) provides local and CI checks for syntax, mocked tests,
  XML, Packer, linting, links, and secret scanning; the
  [`quality` workflow](.github/workflows/quality.yml) installs mandatory CI tools.
- [`tests/`](tests/) contains mock-only tests; no test connects to a real ESXi host.
- [`lychee.toml`](lychee.toml) keeps the documented link-checker exception precise.
- [`scripts/esxi-readonly-discovery.sh`](scripts/esxi-readonly-discovery.sh) performs bounded, read-only discovery only.
- [`templates/`](templates/) contains structured prompts for plans, approvals, rollback notes, and summaries.

## Safety notes

- Prefer read-only discovery commands before write operations.
- Avoid destructive operations without explicit user confirmation.
- Show the exact command or API action before running dangerous operations.
- Check available RAM before VM creation, VM power-on, or memory increases.
- Check VM power state before hardware changes.
- Check datastore free space before ISO, OVF, OVA, VMDK, cloning, restore, or snapshot-heavy operations.
- Ask before deleting VMs, disks, snapshots, datastore contents, datastores, or networking objects.
- Ask before powering off, rebooting, suspending, or resetting production or unknown VMs.
- Use host-specific datastore and network names from a local profile, not from this generic skill.
- Do not hardcode credentials, session tokens, host details, private IPs, or private inventory names in examples or scripts.

## Reference files

- [`SKILL.md`](SKILL.md) — top-level skill instructions, safety workflow, local profiles, and host conventions
- [`references/agent-communication-contract.md`](references/agent-communication-contract.md) — how an AI agent should behave when operating ESXi
- [`references/capability-probe.md`](references/capability-probe.md) — probe order for REST, SSH, VM inventory, datastore, network, and guest tools
- [`references/validated-interaction-methods.md`](references/validated-interaction-methods.md) — tested standalone ESXi interaction paths and fallback decisions
- [`references/dedicated-agent-user.md`](references/dedicated-agent-user.md) — least-privilege `agent` user guidance
- [`references/ssh-esxcli.md`](references/ssh-esxcli.md) — SSH, `esxcli`, `vim-cmd`, networking, datastore, and resource checks
- [`references/rest-api.md`](references/rest-api.md) — vSphere REST API sessions, VM lifecycle, snapshots, datastores, networking, and resource checks
- [`references/file-transfers.md`](references/file-transfers.md) — datastore upload/download, OVF/OVA transfer patterns, and SCP notes
- [`references/backup-restore.md`](references/backup-restore.md) — backup and restore workflow guidance
- [`references/host-configuration-backup.md`](references/host-configuration-backup.md) — host configuration bundle backup/restore boundary and R3 runbook
- [`references/network-firewall-ipv4-ipv6.md`](references/network-firewall-ipv4-ipv6.md) — network, firewall, and IP-stack checks
- [`references/certificates-letsencrypt.md`](references/certificates-letsencrypt.md) — certificate handling and trust guidance
- [`references/vm-import-export.md`](references/vm-import-export.md) — import/export workflow notes
- [`references/guest-os-autoinstall.md`](references/guest-os-autoinstall.md) — guest OS unattended install templates, safety notes, and compatibility reminders
- [`examples/guest-autoinstall/README.md`](examples/guest-autoinstall/README.md) — template pack for Windows, Ubuntu, RHEL/Rocky/Alma, Debian, and Packer examples
- [`references/troubleshooting.md`](references/troubleshooting.md) — read-only troubleshooting and recovery guidance
- [`AGENTS.md`](AGENTS.md) — concise operating rules for AI agents using this repository
- [`SECURITY.md`](SECURITY.md) — secret handling and private reporting guidance
- [`NOTICE.md`](NOTICE.md) — AI-assisted / vibe-coded experimental-use notice

## Maintenance notes

- Keep examples practical and safe by default.
- Keep ESXi 7.x compatibility in mind.
- Use placeholders for sensitive values.
- Keep host-specific facts in local profiles or local notes, not in the generic skill.
- Update this README and `docs/index.md` when adding or renaming reference files.
- Keep helpers small, mock-tested, and dependency-light; do not add broad automation frameworks.
- Validate new commands against a non-production ESXi host where possible.

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
- It gives Hermes an ESXi-focused foundation for layered networking, storage,
  security, virtualization, and troubleshooting reasoning without loading a
  complete certification knowledge base into every task.
- It keeps generic skill logic separate from host-specific data.
- It provides sanitized general and dual-public-router profiles plus templates
  for change plans, approvals, rollback notes, and post-change summaries.
- It includes a small read-only discovery helper script and optional quality checks.

## Repository layout

```text
.
├── SKILL.md
├── profiles/
│   ├── README.md
│   ├── example-host.md
│   └── example-dual-public-router.md
├── references/
│   ├── agent-communication-contract.md
│   ├── backup-restore.md
│   ├── capability-probe.md
│   ├── certificates-letsencrypt.md
│   ├── dedicated-agent-user.md
│   ├── file-transfers.md
│   ├── guest-os-autoinstall.md
│   ├── host-configuration-backup.md
│   ├── it-foundations-for-esxi.md
│   ├── network-firewall-ipv4-ipv6.md
│   ├── dedibox-dual-public-router-vm.md
│   ├── single-public-ip-router-migration.md
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
│   ├── test-discovery-capability-matrix.sh
│   ├── test-discovery-privacy-and-status.sh
│   ├── test-dual-public-policy.sh
│   ├── test-it-foundations-routing.sh
│   └── test-media-generators.sh
├── .github/workflows/quality.yml
├── lychee.toml
├── templates/
│   ├── approval-request.md
│   ├── change-plan.md
│   ├── dual-public-router-plan.md
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

For a host that retains public ESXi management while a separate provider
failover `/32` belongs to a router VM, start from
[`profiles/example-dual-public-router.md`](profiles/example-dual-public-router.md)
and load
[`references/dedibox-dual-public-router-vm.md`](references/dedibox-dual-public-router-vm.md).
This is intentionally separate from moving a sole public address away from
ESXi.

> **Warning:** never commit `.env`, private keys, API tokens, session IDs, private hostnames, private IP addresses, passwords, or screenshots/logs containing sensitive ESXi inventory details.

## Windows and WSL tooling

On Windows, keep Hermes and native ESXi clients such as `curl`, OpenSSH,
pyVmomi, and optionally VMware `ovftool` on the Windows side. Load this skill
in Hermes with `/skill esxi-server`; after a local skill refresh, run
`/reload-skills` and start a new session before relying on the revised guidance.

When a task crosses multiple IT layers, the task router loads
[`references/it-foundations-for-esxi.md`](references/it-foundations-for-esxi.md)
before the single relevant ESXi reference. The foundation is curated from the
A+, Network+, Security+, CCNA, and AZ-900 data in the companion
`it-certification-knowledge-base` project. It provides diagnostic models, not
exam guidance or permission to change a host.

Use WSL2 Ubuntu for the repository's Bash helpers, mocked tests, Linux
validators, and ISO generators. Keep a separate validation clone in the WSL
filesystem (for example `~/src/esxi-server`) rather than `/mnt/c`. This avoids
Git-Bash/native-Python temporary-path mismatches and Windows CRLF conversions
that can break shell here-documents.

Install the WSL prerequisites in that environment:

```bash
sudo apt update
sudo apt install -y make shellcheck libxml2-utils cloud-init cloud-image-utils xorriso
```

The command supplies `make`, `cloud-init`, `cloud-localds`, `xorriso`, and
`genisoimage`. Run local checks from the WSL clone with `make check`; optional
quality tools not installed there are reported as `NOT RUN`. The repository's
`.gitattributes` forces LF for shell files on Windows checkouts. Never pass an
`ESXI_PASS` value through a `wsl.exe` command line; configure secrets only in
the execution environment and retain local host profiles as uncommitted files.

WSL commonly appends the Windows `PATH`. To prevent a Windows npm/Node command
from being paired with the WSL Node runtime during validation, run checks with
a Linux-only `PATH`:

```bash
env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make check
```

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

The helper validates TLS by default, probes `/folder/` independently with Basic
Auth before REST, uses one modern session attempt plus a single legacy fallback
only when appropriate, and never prints credentials or tokens. It suppresses
full inventory unless `--include-inventory` is explicitly supplied and reports
`PASS`, `PARTIAL`, `BLOCKED`, `AUTH_FAILED`, or `AUTHZ_FAILED`. Use a verified
`ESXI_CA_BUNDLE` when required; `ESXI_INSECURE_TLS=1` is a temporary explicit
exception, never a default.

Use `--strict` in automation when any result other than `PASS` must return a
nonzero exit code.

## Choosing SSH vs REST API

Use the smallest, safest interface for the task.

| Task | Prefer |
|---|---|
| Host hardware, memory, NIC, vSwitch, VMkernel, or filesystem checks | SSH with `esxcli` |
| Standalone ESXi VM inspection when REST is insufficient | SSH with `vim-cmd` |
| VM listing, power state, lifecycle operations, and snapshots | REST API when available and reliable |
| Datastore browsing through HTTPS | `/folder/` with Basic Auth, independently of REST sessions |
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
- [`references/it-foundations-for-esxi.md`](references/it-foundations-for-esxi.md) — layered IT reasoning for Hermes across hardware, networking, security, virtualization, and troubleshooting
- [`references/network-firewall-ipv4-ipv6.md`](references/network-firewall-ipv4-ipv6.md) — network, firewall, and IP-stack checks
- [`references/dedibox-dual-public-router-vm.md`](references/dedibox-dual-public-router-vm.md) — retained ESXi management plus provider failover `/32`, virtual MAC, isolated LAN, and router-VM gates
- [`references/single-public-ip-router-migration.md`](references/single-public-ip-router-migration.md) — R3 staged runbook for moving a sole public IPv4 from ESXi management to a router VM
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
- Keep dual-public and sole-public-IP router variants separate; never infer an
  allocation-specific gateway or MAC from a generic example.
- Use placeholders for sensitive values.
- Keep host-specific facts in local profiles or local notes, not in the generic skill.
- Update this README and `docs/index.md` when adding or renaming reference files.
- Keep helpers small, mock-tested, and dependency-light; do not add broad automation frameworks.
- Validate new commands against a non-production ESXi host where possible.

# Documentation index

This documentation set describes safe, experimental ESXi operations for humans and AI agents.

## Start here

- [`../SKILL.md`](../SKILL.md) — top-level skill behavior, local-profile conventions, and operational rules
- [`../AGENTS.md`](../AGENTS.md) — concise instructions for AI agents using this repository
- [`../README.md`](../README.md) — repository overview, quick start, safety notes, and maintenance guidance
- [`../NOTICE.md`](../NOTICE.md) — AI-assisted / vibe-coded experimental-use notice
- [`safety-workflow.md`](safety-workflow.md) — concise summary of discovery, planning, confirmation, rollback, and prompt-injection resistance

## Profiles, templates, scripts

- [`../profiles/README.md`](../profiles/README.md) — local-only profile naming and usage notes
- [`../profiles/example-host.md`](../profiles/example-host.md) — sanitized example host profile
- [`../scripts/esxi-readonly-discovery.sh`](../scripts/esxi-readonly-discovery.sh) — read-only discovery helper script
- [`../templates/change-plan.md`](../templates/change-plan.md) — structured change-plan template
- [`../templates/approval-request.md`](../templates/approval-request.md) — explicit approval prompt template
- [`../templates/discovery-report.md`](../templates/discovery-report.md) — structured discovery report template
- [`../templates/post-change-summary.md`](../templates/post-change-summary.md) — post-change summary template
- [`../templates/rollback-notes.md`](../templates/rollback-notes.md) — rollback notes template

## References

- [`../references/agent-communication-contract.md`](../references/agent-communication-contract.md) — communication contract for AI agents
- [`../references/backup-restore.md`](../references/backup-restore.md) — backup and restore workflow guidance
- [`../references/capability-probe.md`](../references/capability-probe.md) — probe order for REST, SSH, VM inventory, datastore, network, and guest tools
- [`../references/validated-interaction-methods.md`](../references/validated-interaction-methods.md) — tested standalone ESXi interaction paths and fallback decisions
- [`../references/certificates-letsencrypt.md`](../references/certificates-letsencrypt.md) — certificate handling and trust guidance
- [`../references/dedicated-agent-user.md`](../references/dedicated-agent-user.md) — least-privilege `agent` user guidance
- [`../references/file-transfers.md`](../references/file-transfers.md) — datastore upload/download, OVF/OVA transfer patterns, and SCP notes
- [`../references/network-firewall-ipv4-ipv6.md`](../references/network-firewall-ipv4-ipv6.md) — network, firewall, and IP-stack checks
- [`../references/rest-api.md`](../references/rest-api.md) — vSphere REST API sessions, VM lifecycle, snapshots, datastores, networking, and resource checks
- [`../references/ssh-esxcli.md`](../references/ssh-esxcli.md) — SSH, `esxcli`, `vim-cmd`, networking, datastore, and resource checks
- [`../references/troubleshooting.md`](../references/troubleshooting.md) — read-only troubleshooting and recovery guidance
- [`../references/vm-import-export.md`](../references/vm-import-export.md) — import/export workflow notes

## Security, license, and contribution guidance

- [`../SECURITY.md`](../SECURITY.md) — secret handling, destructive-operation confirmation, TLS notes, and private reporting guidance
- [`../CONTRIBUTING.md`](../CONTRIBUTING.md) — documentation style and contribution expectations
- [`../CHANGELOG.md`](../CHANGELOG.md) — unreleased changes
- [`../LICENSE`](../LICENSE) — MIT License

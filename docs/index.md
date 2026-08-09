# Documentation index

This repository documents safe standalone ESXi operations with progressive
disclosure: start at `SKILL.md`, load one primary task reference, and load
fallback material only when evidence requires it.

## Start here

- [`../SKILL.md`](../SKILL.md) — canonical R0-R3 policy, context budget, and task router
- [`../AGENTS.md`](../AGENTS.md) — compact agent entry instructions
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — authority layers and progressive-disclosure runtime
- [`inventory.txt`](inventory.txt) — machine-checked repository contract inventory
- [`safety-workflow.md`](safety-workflow.md) — discovery, planning, approval, rollback, and verification
- [`../README.md`](../README.md) — repository overview

## Maintainer assurance

- [`../references/source-verification-policy.md`](../references/source-verification-policy.md) — source hierarchy and uncertainty policy
- [`../evals/README.md`](../evals/README.md) — behavioural evaluation workflow
- [`../evals/evals.json`](../evals/evals.json) — safety-critical behavioural prompts/assertions
- [`../scripts/validate-behavioural-evals.sh`](../scripts/validate-behavioural-evals.sh) — evaluation contract validation
- [`../scripts/validate-documentation-inventory.sh`](../scripts/validate-documentation-inventory.sh) — inventory validation
- [`../scripts/validate-model-overlays.sh`](../scripts/validate-model-overlays.sh) — thin-overlay validation and 250-word hard cap
- [`../scripts/validate-operational-docs.sh`](../scripts/validate-operational-docs.sh) — operational example safety checks
- [`../scripts/validate-packer-contract.sh`](../scripts/validate-packer-contract.sh) — Packer skeleton validation
- [`../tests/test-token-budget.sh`](../tests/test-token-budget.sh) — runtime context-budget regression guard

## Canonical child skills and model overlays

- [`../skills/incident-triage/SKILL.md`](../skills/incident-triage/SKILL.md) — evidence-first incident workflow
- [`../skills/stable-ssh-shell/SKILL.md`](../skills/stable-ssh-shell/SKILL.md) — persistent/PTY/detached shell routing for compatible non-ESXi hosts
- [`../skills/private-guest-shell/SKILL.md`](../skills/private-guest-shell/SKILL.md) — VPN/jump/recovery routing to private guests
- [`../skills/model-overlays/CONTRACT.md`](../skills/model-overlays/CONTRACT.md) — authoring/validation contract; not normal runtime context
- [`../skills/model-overlays/harnesses/hermes.md`](../skills/model-overlays/harnesses/hermes.md) — Hermes tool-semantics adapter
- [`../skills/nemotron-3-ultra/model-profile.md`](../skills/nemotron-3-ultra/model-profile.md) — compact Nemotron runtime context policy

## References

### Transport and task-specific SSH

- [`../references/ssh-esxcli.md`](../references/ssh-esxcli.md) — compact SSH trust/transport router
- [`../references/ssh-discovery.md`](../references/ssh-discovery.md) — bounded R0 host/VM/network/storage discovery
- [`../references/ssh-vm-lifecycle.md`](../references/ssh-vm-lifecycle.md) — VM lifecycle checks/actions
- [`../references/ssh-snapshots.md`](../references/ssh-snapshots.md) — snapshot inspection and guarded change planning
- [`../references/ssh-storage.md`](../references/ssh-storage.md) — datastore/storage inspection
- [`../references/ssh-networking.md`](../references/ssh-networking.md) — network inspection and change planning
- [`../references/rest-api.md`](../references/rest-api.md) — standalone HTTPS/session boundaries and SDK fallback
- [`../references/capability-probe.md`](../references/capability-probe.md) — first-contact or unknown/failed transport probing
- [`../references/validated-interaction-methods.md`](../references/validated-interaction-methods.md) — tested interaction paths/fallback decisions

### Operations and safety

- [`../references/agent-communication-contract.md`](../references/agent-communication-contract.md) — AI communication contract
- [`../references/backup-restore.md`](../references/backup-restore.md) — VM backup/restore semantics
- [`../references/host-configuration-backup.md`](../references/host-configuration-backup.md) — host configuration backup/restore
- [`../references/certificates-letsencrypt.md`](../references/certificates-letsencrypt.md) — certificate handling/trust
- [`../references/dedicated-agent-user.md`](../references/dedicated-agent-user.md) — least-privilege agent account
- [`../references/file-transfers.md`](../references/file-transfers.md) — datastore/ISO/OVF/VMDK transfer patterns
- [`../references/guest-os-autoinstall.md`](../references/guest-os-autoinstall.md) — unattended guest installation
- [`../references/it-foundations-for-esxi.md`](../references/it-foundations-for-esxi.md) — cross-layer diagnostic foundations
- [`../references/network-firewall-ipv4-ipv6.md`](../references/network-firewall-ipv4-ipv6.md) — network/firewall/IP policy
- [`../references/patch-upgrade.md`](../references/patch-upgrade.md) — host patch/upgrade gates
- [`../references/pfsense-documentation-sources.md`](../references/pfsense-documentation-sources.md) — version-aware Netgate source routing
- [`../references/dedibox-dual-public-router-vm.md`](../references/dedibox-dual-public-router-vm.md) — retained-management dual-public router VM
- [`../references/private-guest-access-via-pfsense.md`](../references/private-guest-access-via-pfsense.md) — private guest access behind pfSense
- [`../references/single-public-ip-router-migration.md`](../references/single-public-ip-router-migration.md) — sole-public-IP R3 migration
- [`../references/troubleshooting.md`](../references/troubleshooting.md) — read-only troubleshooting/recovery guidance
- [`../references/vm-import-export.md`](../references/vm-import-export.md) — VM import/export
- [`../references/source-verification-policy.md`](../references/source-verification-policy.md) — maintainer evidence hierarchy

## Profiles, examples, and templates

- [`../profiles/README.md`](../profiles/README.md) — local-profile conventions
- [`../profiles/example-host.md`](../profiles/example-host.md) — sanitized host profile
- [`../profiles/example-dual-public-router.md`](../profiles/example-dual-public-router.md) — sanitized router profile
- [`../examples/guest-autoinstall/README.md`](../examples/guest-autoinstall/README.md) — unattended-install examples
- [`../templates/change-plan.md`](../templates/change-plan.md) — change plan
- [`../templates/approval-request.md`](../templates/approval-request.md) — approval request
- [`../templates/rollback-notes.md`](../templates/rollback-notes.md) — rollback notes
- [`../templates/post-change-summary.md`](../templates/post-change-summary.md) — post-change summary

## Project guidance

- [`../SECURITY.md`](../SECURITY.md)
- [`../CONTRIBUTING.md`](../CONTRIBUTING.md)
- [`../CHANGELOG.md`](../CHANGELOG.md)
- [`../LICENSE`](../LICENSE)

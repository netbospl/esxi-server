# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project does not currently use versioned releases.

## [Unreleased]

### Added
- Initial repository documentation.
- MIT License.
- AI-assisted / vibe-coded notice.
- Agent instructions and documentation index.
- Validated standalone ESXi interaction-method notes covering Host Client, `/folder`, REST fallback, and SSH-unavailable handling.
- Guest OS unattended install reference docs, example templates, and helper scripts for Windows, Ubuntu, RHEL/Rocky/Alma, Debian, and Packer.
- Windows 11 OOBE/local-account notes for ESXi guest installs.
- Windows 11 local-account answer-file snippet and manual fallback documentation.
- Canonical R0–R3 risk model, task router, host-configuration backup runbook, local placeholder validation, mocked script tests, and GitHub Actions quality workflow.
- Single-public-IP router migration runbook.
- Dedibox dual-public IPv4 router-VM runbook, sanitized local-profile template,
  topology-specific change-plan template, and policy regression test.
- Curated ESXi-focused IT foundations from the companion certification
  knowledge base, with a compact Hermes diagnostic loop and routing test.
- `stable-ssh-shell` child skill with atomic, persistent, PTY, detached, and
  restricted modes; strict SSH transport guidance; deterministic tmux command
  markers; recovery rules; sanitized examples; and mock-only tests.

### Changed
- Reviewed and clarified ESXi skill safety guidance.
- Clarified that Windows 11 OOBE bypass commands are version-dependent manual fallbacks, not licensing bypasses.
- Hardened SSH host-key acceptance, REST/TLS session handling, ISO generators, Windows answer templates, guest examples, and Packer defaults.
- Made datastore-browser discovery independent of REST sessions with Basic Auth.
- Added one bounded legacy REST-session fallback after an unsupported modern endpoint.
- Suppressed sensitive inventory by default and added explicit result states and strict mode.
- Aligned TLS verification, version support boundaries, and R0–R3 approval policy across the skill.
- Expanded mocked regression coverage and hardened CI dependency pinning.
- Split sole-public-IP migration from retained-management dual-public topology;
  added allocation-source authority, `/32` non-local gateway, virtual-MAC,
  strict port-group, isolated-LAN, constrained-host, and autostart safeguards.
- Added forward/reverse DNS identity checks, Cloudflare DNS-only guidance, and
  a guard against applying provider Linux IPv6 examples to ESXi or pfSense.
- Clarified that a Dedibox failover `/32` gateway must come from protected
  provider evidence rather than an adjacent-address assumption, and documented
  trusted pfSense installation, `config.xml` restore, and recovery-image
  boundaries without publishing real infrastructure addresses.
- Routed Hermes direct ESXi work through guarded local OpenSSH while reserving
  Bash-dependent SSH environments and remote persistence for verified
  compatible Linux management, jump, or guest hosts.

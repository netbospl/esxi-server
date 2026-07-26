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

### Changed
- Reviewed and clarified ESXi skill safety guidance.
- Clarified that Windows 11 OOBE bypass commands are version-dependent manual fallbacks, not licensing bypasses.
- Hardened SSH host-key acceptance, REST/TLS session handling, ISO generators, Windows answer templates, guest examples, and Packer defaults.
- Made datastore-browser discovery independent of REST sessions with Basic Auth.
- Added one bounded legacy REST-session fallback after an unsupported modern endpoint.
- Suppressed sensitive inventory by default and added explicit result states and strict mode.
- Aligned TLS verification, version support boundaries, and R0–R3 approval policy across the skill.
- Expanded mocked regression coverage and hardened CI dependency pinning.

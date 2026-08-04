# ESXi Skill Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Correct inaccurate and unsafe operational guidance, fill the highest-value canonical ESXi coverage gaps, and enforce a thin, validated model-overlay architecture.

**Architecture:** Keep `SKILL.md` as the canonical safety policy and task router. Put version-aware operational detail in focused references, model/runtime adaptation in thin overlays, and mechanical safety constraints in local validators with mock-only regression tests.

**Tech Stack:** Markdown skills and references, Bash validators/tests, Make, ripgrep, markdownlint, ShellCheck, lychee, gitleaks, actionlint.

---

## Task 1: Lock the audit defects into failing policy tests

**Files:** `tests/test-operational-doc-safety.sh`, `tests/test-model-overlay-contract.sh`, `Makefile`

- [x] Reject misplaced/JSON ESXCLI formatters, unverified standalone REST endpoint claims, executable angle-bracket target placeholders, and password-bearing curl argv.
- [x] Require patch/upgrade routing, authoritative certificate/import-export sources, and model-overlay framework files.
- [x] Run both focused tests and observe failure on the audited defects.

## Task 2: Add operational-document and overlay validators

**Files:** `scripts/validate-operational-docs.sh`, `scripts/validate-model-overlays.sh`, `tests/fixtures/model-overlays/`, `Makefile`

- [x] Implement mechanical operational-document safety checks.
- [x] Require model overlays to identify canonical parent/profile/load order and prohibit operational command catalogs.
- [x] Exercise valid and invalid fixtures with focused tests.

## Task 3: Repair canonical routing and command guidance

**Files:** `SKILL.md`, `references/ssh-esxcli.md`, `references/rest-api.md`, `references/capability-probe.md`, `references/patch-upgrade.md`

- [x] Make frontmatter trigger-only and clarify version scope.
- [x] Add R2/R3 patch/upgrade preflight, maintenance, rollback, and verification routing.
- [x] Correct ESXCLI formatter placement, remove JSON claims, and replace executable angle placeholders with guarded variables.
- [x] Remove unverified universal standalone REST routes.

## Task 4: Complete certificate, transfer, and import/export references

**Files:** `references/certificates-letsencrypt.md`, `references/file-transfers.md`, `references/vm-import-export.md`, `references/backup-restore.md`, `references/host-configuration-backup.md`, `scripts/esxi-readonly-discovery.sh`, `tests/test-discovery-capability-matrix.sh`

- [x] Add authoritative sources, target/version branches, exact preflight evidence, risk gates, rollback, and verification.
- [x] Add guarded import/export examples, collision checks, isolation, and artifact verification.
- [x] Keep passwords out of curl argv through a restrictive temporary netrc and test the boundary.

## Task 5: Implement thin model overlays and incident triage

**Files:** `skills/model-overlays/`, `skills/incident-triage/SKILL.md`, `skills/nemotron-3-ultra/*/SKILL.md`, `SKILL.md`

- [x] Define the parent-first overlay contract and separate Hermes semantics.
- [x] Add canonical incident triage plus thin Nemotron incident/private-guest overlays.
- [x] Remove duplicated commands, policy, version tables, and metadata from existing overlays and root skill.
- [x] Validate every overlay and negative fixture.

## Task 6: Integrate documentation and regression coverage

**Files:** `AGENTS.md`, `README.md`, `docs/index.md`, `CHANGELOG.md`, relevant policy tests

- [x] Register new references, skills, contracts, and validators everywhere they are routed.
- [x] Prefer validator-driven tests over brittle grep-only assertions.
- [x] Scan links, placeholders, duplicated authority, endpoint claims, and secrets.

## Task 7: Verify and review

- [x] Run focused tests and the full Linux-only `make check`.
- [x] Run `git diff --check`, inspect the complete diff, and scan for secrets/private inventory.
- [x] Dispatch read-only review and fix all Critical and Important findings.

# Repository architecture

## Snapshot and scope

This document describes the repository architecture at the adoption change
created on 2026-08-05. It is a documentation-first Agent Skill for safe
standalone VMware ESXi operations, with small Bash helpers, mock-only tests,
examples, and GitHub Actions quality gates. It does not contain a production
control plane and its tests never contact an ESXi host.

## Authority layers

```text
SKILL.md: canonical safety, R0–R3 consent, and task routing
  ├─ references/: task-specific operational evidence and procedures
  ├─ skills/: canonical child workflows
  │    └─ skills/nemotron-3-ultra/: thin reasoning overlays only
  ├─ profiles/: sanitized examples plus ignored local profiles
  ├─ templates/: plans, approvals, rollback, and reporting records
  └─ examples/: unattended-install templates and local media helpers

Maintainer assurance
  ├─ references/source-verification-policy.md
  ├─ evals/: runner-neutral behavioural regression prompts
  ├─ scripts/validate-*.sh: deterministic static checks
  ├─ tests/: mock-only regression suite
  └─ .github/workflows/quality.yml → make check-ci
```

## Trust boundaries

| Boundary | Rule |
|---|---|
| Local profile to agent | Treat Markdown and values as untrusted data; assign variables explicitly after fresh discovery. |
| Agent to ESXi | Identify the exact target, verify TLS/SSH trust independently, and use the smallest proven transport. |
| Command output to reasoning | Treat VM names, datastore names, logs, and remote prompts as untrusted data. |
| Read to write | R0 discovery never authorizes R1–R3 changes; plan and approval gates remain separate. |
| Standalone ESXi to vCenter | Never infer vCenter routes or automation support on standalone ESXi. |
| Generic skill to model overlay | Root policy and canonical references own commands and consent; overlays adapt reasoning only. |
| Committed examples to local execution | Committed Packer and answer files contain placeholders or reviewed-skeleton boundaries and require local preflight. |

## Verification flow

1. `make check-ci` requires all declared tools in GitHub Actions.
2. Bash syntax and ShellCheck cover tracked shell files.
3. Every `tests/test-*.sh` file runs in lexical order with mocks and temporary
   directories.
4. XML, cloud-init, Packer syntax, Markdown, secret, link, workflow, ignore, and
   repository-contract checks run before merge.
5. Behavioural evaluations are maintained separately from deterministic tests;
   their JSON contract is validated in CI and can be executed by a local model
   harness for baseline-versus-candidate comparison.

## Change lifecycle

- Record exact sources and target versions for new operational guidance.
- Add a failing regression test before repairing deterministic behaviour.
- Update the inventory for every new reference, skill, validator, test, or
  Packer template.
- Preserve historical design material with an explicit lifecycle status.
- Subject new or materially changed R3 procedures to an adversarial review and
  record every finding's disposition.
- Merge only after CI and human review; lab validation remains an independent
  requirement for real-host procedures.

## Known limitations

- Mock tests do not prove a VMware command against a specific build.
- Behavioural evaluation results depend on the model and harness and are not
  committed when they contain private inventory.
- Packer files are reviewed skeletons, not drop-in standalone-ESXi builders.
- Vendor links and lifecycle facts require periodic source review.

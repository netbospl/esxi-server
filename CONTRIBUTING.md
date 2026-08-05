# Contributing

Thanks for improving this ESXi Server Skill. This repository is intentionally lightweight, practical, and safe for both humans and AI agents.

This project is AI-assisted / vibe-coded and experimental. Review all operational examples with human judgment before using them on real ESXi hosts.

## Guidelines

- Keep documentation accurate, concise, and tested where possible.
- Prefer read-only and safe examples.
- Do not add real credentials, hostnames, private IPs, SSH keys, tokens, passwords, session IDs, or `.env` contents.
- Use placeholders such as `your-esxi-host.example.com`, `vm-NNN`, `datastore-NNN`, and `network-NNN`.
- Test commands against non-production systems when possible.
- Keep VMware ESXi 7.x compatibility in mind while treating ESXi 8.x as the primary documented target; always record the exact build.
- Avoid adding frameworks, package managers, generated files, or CI systems unless the repository gains code that requires them.
- Update `docs/index.md` and `docs/inventory.txt` when adding, renaming, or removing references, canonical child skills, model overlays, validators, tests, or Packer templates.
- Keep `SKILL.md` focused on top-level behavior; put detailed task-specific procedures in `references/`.
- Follow [`references/source-verification-policy.md`](references/source-verification-policy.md) for every new or materially changed product-specific claim.
- Add a failing regression test before fixing deterministic behavior whenever the failure can be represented locally.
- Preserve completed plans and reviews with an explicit lifecycle status; do not leave obsolete approval gates looking active.
- For new or materially changed R3 guidance, include exact-version sources, regression coverage, and a documented adversarial review with every finding dispositioned.
- Update `evals/evals.json` when a skill change should alter model behavior or protect an existing safety decision.

## Documentation style

- Start with read-only discovery steps before write operations.
- Clearly label destructive commands.
- Mention confirmation requirements for risky operations.
- Prefer environment variables over inline values.
- Explain when SSH, `vim-cmd`, `esxcli`, REST API, datastore browser endpoints, or `ovftool` are appropriate.
- Keep standalone ESXi and vCenter boundaries explicit.
- Keep examples free of secrets and private inventory.
- Mark anything unverified rather than presenting confidence as evidence.

## Before submitting changes

Run:

```bash
git status --short
find . -maxdepth 3 -type f | sort
git diff --check
make check
git diff
```

`make check` validates behavioural-evaluation structure, repository inventory,
Packer reviewed-skeleton boundaries, mock-only regression tests, and the
existing syntax, lint, secret, link, and workflow checks available locally.
GitHub Actions runs the mandatory CI toolset.

Do not commit or publish sensitive data. If a secret is accidentally committed, rotate it immediately and remove it from history before sharing the repository.

# Contributing

Thanks for improving this ESXi Server Skill. This repository is intentionally lightweight, practical, and safe for both humans and AI agents.

This project is AI-assisted / vibe-coded and experimental. Review all operational examples with human judgment before using them on real ESXi hosts.

## Guidelines

- Keep documentation accurate, concise, and tested where possible.
- Prefer read-only and safe examples.
- Do not add real credentials, hostnames, private IPs, SSH keys, tokens, passwords, session IDs, or `.env` contents.
- Use placeholders such as `your-esxi-host.example.com`, `vm-NNN`, `datastore-NNN`, and `network-NNN`.
- Test commands against non-production systems when possible.
- Keep VMware ESXi 7.0 / 7.0 Update 1c compatibility in mind.
- Avoid adding frameworks, package managers, generated files, or CI systems unless the repository gains code that requires them.
- Update `README.md` and `docs/index.md` when adding, renaming, or removing reference files.
- Keep `SKILL.md` focused on top-level behavior; put detailed task-specific procedures in `references/`.

## Documentation style

- Start with read-only discovery steps before write operations.
- Clearly label destructive commands.
- Mention confirmation requirements for risky operations.
- Prefer environment variables over inline values.
- Explain when SSH, `vim-cmd`, `esxcli`, REST API, datastore browser endpoints, or `ovftool` are appropriate.
- Keep examples free of secrets and private inventory.

## Before submitting changes

Run:

```bash
git status --short
find . -maxdepth 3 -type f | sort
git diff --check
git diff
```

Do not commit or publish sensitive data. If a secret is accidentally committed, rotate it immediately and remove it from history before sharing the repository.

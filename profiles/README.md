# Local ESXi profiles

Use this directory for host-specific data that must not be committed.

## Naming

- `profiles/example-host.md` is the committed sanitized example.
- `profiles/<host>.local.md` is the preferred local-only file name for a real host profile.
- `HOST_PROFILE.local.md` is also allowed for workflows that prefer a single root-level profile file.

## Rules

- Keep real hostnames, datastores, port groups, inventory names, and credentials out of the generic skill files.
- Do not commit local profiles.
- Store secrets in a secret manager or local environment variables, not in profile markdown.
- If a local profile exists, the agent may load it for context before choosing commands.

## Suggested contents

A local profile can define sanitized or real values such as:

- ESXi version and support notes
- Preferred user (`agent`)
- SSH key path and known-hosts file path
- Primary VM datastore
- Transfer datastore
- Management, restricted, and unrestricted port groups
- Any host-specific rollback or maintenance notes

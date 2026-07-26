# Local ESXi profiles

Use this directory for host-specific data that must not be committed.

## Naming

- `profiles/example-host.md` is the committed sanitized example.
- `profiles/example-dual-public-router.md` is the committed sanitized template
  for a retained public management IP plus a provider failover IP on a router
  VM.
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
- Current owner of any public IP, default gateway, and provider MAC constraints
- Evidence source and timestamp for a failover IP, allocation-specific gateway,
  and virtual MAC; STOP on source conflicts
- Public WAN and isolated LAN topology, including effective vSwitch security
  policy and explicit no-uplink state
- Router VM UUID/current VMID, disk identity, vNIC mapping, egress-IP proof,
  guest-tools state, and autostart evidence
- Independent console path for management-network recovery
- Any host-specific rollback or maintenance notes

# Example ESXi host profile (sanitized)

This file is an example only. Replace the values below in a local-only profile such as `profiles/my-host.local.md`.

## Environment

```bash
ESXI_HOST=esxi.example.test
ESXI_USER=agent
ESXI_SSH_KEY=$HOME/.ssh/esxi-agent-example
ESXI_KNOWN_HOSTS=$PWD/.ssh-known-hosts/esxi_known_hosts
ESXI_PASS=use-secret-manager-or-local-env-only
```

## Example host facts

- ESXi version: VMware ESXi 7.x
- Primary VM datastore: `primary-datastore`
- Transfer datastore: `transfer-datastore`
- Management port group: `VM Network`
- Restricted port group: `PG-RESTRICTED`
- Unrestricted port group: `PG-UNRESTRICTED`
- Preferred automation user: `agent`

## Notes

- This profile is deliberately fake and safe to commit.
- Keep any real host-specific data in a local-only `*.local.md` file.
- Never put passwords, private keys, tokens, or session IDs in a profile file.

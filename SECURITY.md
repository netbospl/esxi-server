# Security Policy

This repository documents operational access patterns for a VMware ESXi host. Treat all host details, credentials, inventory names, and logs as sensitive unless they have been explicitly sanitized.

## Secrets and sensitive data

Never commit:

- ESXi passwords
- SSH private keys
- API tokens
- vSphere REST API session IDs
- Private hostnames
- Private IP addresses
- Sensitive VM names or inventory details
- Datastore paths that reveal private project or customer data
- Debug logs or screenshots containing any of the above

Use environment variables, local `.env` files, operating-system credential stores, or a secret manager. This repository includes `.env.example` only for placeholder names.

## TLS and certificates

Standalone ESXi commonly uses a self-signed TLS certificate. The references may use `-k`, `--insecure`, `--noSSLVerify`, or equivalent TLS verification overrides. That is expected for this environment, but any production usage should clearly document why certificate verification is disabled and which host is being contacted.

## Destructive operations require confirmation

Confirm intent before performing operations that can disrupt workloads or destroy data, including:

- Deleting VMs
- Deleting snapshots
- Removing datastore files or datastores
- Changing networking, vSwitches, VMkernel adapters, or port groups
- Powering off, resetting, or suspending production or unknown VMs
- Reverting snapshots
- Reconfiguring VM disks, NICs, CPU, or memory

For dangerous operations, show the exact command or API request first and wait for explicit approval.

## Sanitizing bug reports

Before sharing bug reports, examples, screenshots, or logs, remove:

- Hostnames
- IP addresses
- Passwords
- SSH keys
- API tokens
- Session tokens
- Sensitive VM names
- Sensitive datastore paths
- Organization, customer, or project names if private

Use placeholders such as `your-esxi-host.example.com`, `vm-NNN`, `datastore1`, and `network-NNN` where possible.

## Reporting security issues

Report security issues privately to the repository maintainer or owner through the private communication channel used for this project. Do not open a public issue containing secrets, exploitable host details, private inventory, or sensitive logs.

If no private channel is documented, contact the maintainer first with a minimal, sanitized description and ask where to send details securely.

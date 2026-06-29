# Agent Instructions

This repository is an experimental, AI-assisted ESXi Server Skill for coding and operations agents. Use it as documentation and procedure guidance, not as executable source code or a substitute for operator judgment.

## Operating rules

1. Read `SKILL.md` first.
2. Inspect only the reference file relevant to the task:
   - `references/ssh-esxcli.md` for SSH, `esxcli`, `vim-cmd`, networking, datastores, and host resource checks.
   - `references/rest-api.md` for REST authentication, VM lifecycle operations, snapshots, datastores, and networks.
   - `references/file-transfers.md` for ISO, OVF, OVA, VMDK, SCP, and datastore browser transfers.
3. Never hardcode credentials, hostnames, private IPs, passwords, API tokens, session IDs, SSH keys, or `.env` contents.
4. Do not commit secrets, logs containing secrets, copied private inventory, or generated local artifacts.
5. Check required environment variables before attempting ESXi access: `ESXI_HOST`, `ESXI_USER`, `ESXI_PASS`, and/or `ESXI_SSH_KEY`.
6. Prefer read-only discovery before write operations.
7. Require explicit confirmation before destructive or disruptive ESXi actions.
8. Clearly show dangerous commands or API requests before running them.
9. Validate RAM, datastore free space, networking, and VM power state before making changes.
10. Keep documentation edits concise, practical, and consistent with ESXi 7.0 standalone host behavior.

## Host conventions

- Use `datastore1` for normal VM storage unless instructed otherwise.
- Use `backup_nfs41` for backups, ISOs, OVFs, and transfer staging.
- Treat `PG-RESTRICTED` as isolated/restricted and prefer it for least-privilege VM networking.
- Treat `PG-UNRESTRICTED` as externally reachable or less restricted; use it only when external access is required and confirmed.

## Confirmation required

Ask before:

- Deleting VMs, disks, snapshots, datastore files, or datastores.
- Reverting snapshots or removing all snapshots.
- Changing networking, vSwitches, VMkernel adapters, or port groups.
- Powering off, resetting, rebooting, or suspending production or unknown VMs.
- Reconfiguring VM CPU, RAM, disks, or NICs.
- Connecting a VM to `PG-UNRESTRICTED`.

When in doubt, stop after read-only discovery and ask the user how to proceed.

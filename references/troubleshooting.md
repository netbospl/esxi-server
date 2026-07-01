# Troubleshooting

Use read-only discovery first, then isolate the failure before making changes.

## First checks

- Confirm `ESXI_HOST`, `ESXI_USER`, and the local profile.
- Run the capability probe.
- Verify the target ESXi version.
- Re-check host key verification if SSH fails unexpectedly.

## Common read-only checks

```bash
vmware -v
esxcli system version get
esxcli hardware memory get
esxcli storage filesystem list
vim-cmd vmsvc/getallvms
```

## What to do when things look stuck

- If the console is sticky, use a direct screenshot path or another observation channel before repeating input.
- If REST inventory looks incomplete on standalone ESXi, fall back to SSH or `/sdk`.
- If snapshot syntax is uncertain, verify the available `vim-cmd` subcommands first.
- If a command fails, do not hide it. Report the failure and the next safe diagnostic step.

## Stop conditions

Stop and ask for human verification if:

- the SSH host key changes unexpectedly
- the management network might be affected
- the capability probe cannot identify a safe path
- the target version differs from the documentation in a material way
- a destructive step has not been approved

## Useful follow-up data

A useful troubleshooting report should include:

- target host and version
- local profile used or missing
- capability probe result
- transport chosen
- command output summary
- the exact step that failed

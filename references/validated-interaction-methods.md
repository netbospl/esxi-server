# Validated standalone ESXi interaction methods

Start from [`../SKILL.md`](../SKILL.md) for safety policy, local-profile conventions, and approval rules.

This reference records field-tested access patterns for standalone ESXi 7.x hosts. Keep host-specific addresses, credentials, VM names, datastore contents, and screenshots in local profiles or private task notes, not in this generic skill repository.

## Validation discipline

1. Load host-specific facts from the current workspace or a local-only profile.
2. Use the dedicated `agent` account unless the user explicitly approves another account for the current task.
3. Run one harmless reachability or discovery probe per transport.
4. Record success or failure as a capability result.
5. Do not repeat failing login or SSH probes aggressively.

## Tested read-only probes

These checks were validated against a standalone ESXi 7.x host using local credentials without committing secrets or host inventory:

| Method | Probe | Validated behavior | Use it for |
|---|---|---|---|
| HTTPS Host Client | `GET https://$ESXI_HOST/ui/` | `200 OK` confirms the web UI is reachable. | Interactive work, console access, datastore browser workflow. |
| HTTPS datastore browser | `GET /folder?dcPath=ha-datacenter&dsName=<datastore>` with Basic auth | `200 OK` with an HTML listing confirms credentials and datastore-browser access. | Browsing, downloads, and upload planning when REST is incomplete. |
| vSphere REST session | `POST /api/session` and `POST /rest/com/vmware/cis/session` | Can return `400` on standalone ESXi 7.x even when Host Client and `/folder` work. | Treat as a capability probe; do not retry blindly. |
| SSH | Single connection probe to port 22, then read-only `esxcli`/`vim-cmd` if reachable | If port 22 is unreachable, stop SSH/SCP/SFTP attempts for the session. | Host-level inventory only when SSH is actually available. |

## Recommended transport choice

- Prefer the HTTPS Host Client for interactive VM-console work and when the current task needs human-visible verification.
- Prefer the HTTPS `/folder/` datastore browser for datastore listing, downloads, and upload workflows when it authenticates successfully.
- Use REST only after the session endpoint succeeds on that host; standalone ESXi may not expose the vCenter-style REST surface agents expect.
- Use SSH/`esxcli`/`vim-cmd` only after a single harmless connectivity/auth probe succeeds. If SSH is unavailable, avoid SCP/SFTP and use HTTPS paths instead.
- For sticky guest-console checks, use the Host Client console or direct `/screen?id=<vmid>` screenshot path when the VM ID is known from a verified inventory source.

## Safe probe snippets

Do not paste real passwords into chat, logs, or committed files. These examples assume environment variables are already populated from a local secret source.

```bash
: "${ESXI_HOST:?ESXI_HOST is required}"
: "${ESXI_USER:=agent}"
: "${ESXI_PASS:?ESXI_PASS is required for HTTPS auth}"

curl -sk --fail --show-error "https://$ESXI_HOST/ui/" >/dev/null

curl -sk --fail --show-error \
  -u "$ESXI_USER:$ESXI_PASS" \
  "https://$ESXI_HOST/folder?dcPath=ha-datacenter&dsName=<datastore>" \
  >/tmp/esxi-folder-listing.html
```

For SSH, probe once before any `esxcli`, `vim-cmd`, SCP, or SFTP workflow:

```bash
nc -z -w 5 "$ESXI_HOST" 22
```

If this fails, record SSH as unavailable and use HTTPS workflows instead of retrying credentials.

## Reporting results

A useful agent summary should state:

- which local source provided host facts and credentials, without printing secret values;
- which transport probes succeeded or failed;
- which transport was chosen for the next action;
- whether the next action is read-only, state-changing, or destructive;
- what confirmation is required before proceeding.

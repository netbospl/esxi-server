# ESXi vSphere REST API reference

Start from [`../SKILL.md`](../SKILL.md) for policy, capability probing, and approval rules.

Use REST when it is available and reliable for the exact task. On standalone ESXi, do not assume every vCenter-style endpoint exists.

## Authentication

```bash
SESSION=$(curl -sk -X POST \
  "https://$ESXI_HOST/api/session" \
  -u "$ESXI_USER:$ESXI_PASS" \
  -H "Content-Type: application/json" | tr -d '"')
```

Do not echo the session token. Keep it in memory only. Avoid putting passwords in shell history, logs, or markdown reports.

## Read-only discovery

```bash
curl -sk "https://$ESXI_HOST/api/vcenter/vm" \
  -H "vmware-api-session-id: $SESSION"

curl -sk "https://$ESXI_HOST/api/vcenter/datastore" \
  -H "vmware-api-session-id: $SESSION"

curl -sk "https://$ESXI_HOST/api/vcenter/network" \
  -H "vmware-api-session-id: $SESSION"
```

If a read-only endpoint returns `400`, `404`, or inconsistent data, treat that as a capability signal and fall back to SSH or `/sdk` + pyVmomi instead of assuming bad credentials.

## VM lifecycle

```bash
curl -sk "https://$ESXI_HOST/api/vcenter/vm/$VM_ID" \
  -H "vmware-api-session-id: $SESSION"

curl -sk -X POST "https://$ESXI_HOST/api/vcenter/vm/$VM_ID/power?action=start" \
  -H "vmware-api-session-id: $SESSION"
```

Power off, reboot, suspend, shutdown, and delete are state-changing. Ask for explicit approval before using them.

## Snapshots

```bash
curl -sk "https://$ESXI_HOST/api/vcenter/vm/$VM_ID/snapshots" \
  -H "vmware-api-session-id: $SESSION"

curl -sk -X POST "https://$ESXI_HOST/api/vcenter/vm/$VM_ID/snapshots" \
  -H "vmware-api-session-id: $SESSION" \
  -H "Content-Type: application/json" \
  -d '{"spec":{"name":"pre-change","description":"Before change","memory":false,"quiesce":false}}'
```

Snapshot revert and delete require explicit approval and a rollback plan. Check datastore free space before creating or keeping snapshots.

## Datastores and network

Use IDs from the listing endpoints or from a local profile. Do not hardcode host-specific datastore or portgroup names into generic skill logic.

## Guest processes

Guest execution requires VMware Tools and guest credentials.

Prefer the guest process API over shelling into the host. Keep guest credentials separate from ESXi credentials.

## Secret handling notes

- Use `-u "$ESXI_USER:$ESXI_PASS"` only in simple examples or controlled scripts.
- Prefer environment variables, protected config files, or prompt-based authentication for real workflows.
- Never write passwords, tokens, or session IDs into markdown reports.
- If a command needs to be copied into a chat or issue, redact credentials first.

## Error handling

- `401` usually means the session expired; re-authenticate.
- `400` or missing data may mean the endpoint is not implemented on standalone ESXi.
- `403` may mean a privilege mismatch.
- `404` may mean the endpoint or object does not exist on that target version.

When in doubt, record the capability probe result and fall back to SSH or `/sdk`.

# Capability probe

Start with the canonical policy and task router in [`../SKILL.md`](../SKILL.md).
This is an R0, bounded, sanitised discovery procedure; it does not authorize
any state change.

- **Supported scope:** standalone ESXi 7.x/8.x; vCenter is a distinct target.
- **Last validated:** static documentation review, 2026-07-22.
- **Lab status:** not tested on a live ESXi host by this repository revision.

## Classify every result

Record the exact distinction below. Do not turn an endpoint capability miss into
repeated credential attempts.

| Result | Meaning | Safe next action |
|---|---|---|
| Reachability failure | DNS/TCP/connect-timeout route problem | Stop retries; verify target/path out of band. |
| TLS failure | Certificate chain/name/CA trust failure | Keep TLS validation; add a verified CA bundle or explicitly document a temporary exception. |
| Authentication failure | Credentials rejected (`401`) | Stop; do not retry aggressively. |
| Authorization failure | Valid session lacks privilege (`403`) | Stop and request least-privilege correction. |
| Endpoint unsupported | `400`/`404` or documented missing surface | Record it and select another verified transport. |
| Transport unavailable | SSH/HTTPS/SDK path unavailable | Record it; do not infer host state. |

## Ordered probe matrix

1. Identify target, version and build. Determine standalone ESXi versus vCenter
   before selecting a vCenter-oriented endpoint.
2. Verify HTTPS reachability to Host Client `/ui/` with TLS validation.
3. Probe datastore browser `/folder/` only with an authorized, read-only request.
4. If credentials are intentionally supplied, try modern REST
   `POST /api/session` once; then the older
   `POST /rest/com/vmware/cis/session` only when the first is unsupported and
   the target/version makes it appropriate. Inspect HTTP status and token shape.
5. Probe only needed REST inventory endpoints with one valid session.
6. Record SOAP SDK `/sdk` reachability as a separate capability; it is a
   fallback, not evidence that REST is complete.
7. If SSH is authorized, verify the host key first, then run one read-only
   `esxcli system version get` and one `vim-cmd vmsvc/getallvms` probe.
8. Record required privileges, licence/API limitations, and per-VM VMware Tools
   availability before proposing guest operations.

`scripts/esxi-readonly-discovery.sh` implements a bounded local helper with
text and optional sanitised JSON report output. It intentionally never prints
passwords, session IDs, or Authorization headers. Local report paths are Git
ignored. A `400` from standalone ESXi session endpoints can be a normal
capability result even where Host Client and `/folder/` work.

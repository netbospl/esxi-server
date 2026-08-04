# ESXi HTTPS, REST, and SDK capability reference

Start with [`../SKILL.md`](../SKILL.md) and
[`capability-probe.md`](capability-probe.md). This reference controls endpoint
selection; it is not a promise that standalone ESXi implements the vCenter
Automation API.

- **Validated repository evidence:** standalone ESXi 7.x can expose Host Client,
  `/folder/`, and `/sdk` while rejecting both REST session endpoints.
- **ESXi 8.x:** conditional; prove each endpoint on the exact standalone build.
- **ESX 9.x:** out of scope and unvalidated in this revision.
- **vCenter:** separate target. `/api/vcenter/*` documentation describes vCenter
  inventory and must not be used as standalone proof.

## Capability classes

| Surface | What success proves | What it does not prove |
|---|---|---|
| `GET /ui/` | Host Client HTTPS reachability | Authentication or API support |
| `GET /folder/` with Basic Auth | Datastore-browser authentication/listing | REST session or VM lifecycle support |
| `POST /api/session` | Modern session creation on this target | Availability of any unprobed operation |
| Legacy session endpoint | Legacy session creation on this target | Modern API parity |
| `/sdk` | SOAP endpoint reachability, including method-limited `405` | A usable SDK operation, REST support, or authorization |
| SSH | Guarded shell transport | REST/SDK support |

## TLS and bounded requests

TLS verification is the default. Prefer a verified CA bundle. A temporary
insecure exception requires explicit acknowledgement, a time limit, and a
recorded reason; it never weakens SSH host-key validation. Bound connect and
total time. Do not retry rejected authentication.

Use a protected credential mechanism that keeps passwords and tokens out of
process arguments. `scripts/esxi-readonly-discovery.sh` creates mode-0600
temporary netrc and session-header files, removes them on exit, and suppresses
credentials and headers from reports.

## Session handling

A valid session requires successful transport, expected HTTP `200`/`201`, a
nonempty conservatively shaped token, and memory-only storage. Classify:

- `401`: authentication/session expiry; stop automatic retries;
- `403`: authorization; request least-privilege correction;
- `400`/`404`/`405`/`501`: potentially unsupported endpoint;
- TLS/DNS/TCP/timeout: transport failure, not endpoint evidence.

Probe `/folder/` independently before REST. Try the legacy session endpoint
once only when the modern endpoint is unsupported, never after `401` or `403`.
Delete a valid session best-effort on cleanup without logging the token.

## Operation selection gate

Before any lifecycle, hardware, network, datastore, snapshot, or guest request:

1. Link the exact vendor operation page for the observed product/version.
2. Prove the endpoint and method on the exact target with an R0 request where
   one exists; otherwise stop and use a canonical SSH/SDK route.
3. Record required privileges, request/response schema, idempotency, task/poll
   behavior, timeout, success response, error mapping, and rollback.
4. Freshly resolve object IDs and match name plus UUID. Never translate a
   `vim-cmd` VMID into a REST identifier by assumption.
5. Apply the root R1-R3 gate before sending a state-changing request.

This repository intentionally provides no universal standalone REST lifecycle
or snapshot endpoint. If a target proves a route, record it in a protected
host profile/task plan and propose a mock-tested, version-scoped reference
update rather than generalizing it immediately.

## SDK fallback

When `/sdk` is reachable and REST is incomplete, use a pinned pyVmomi/SDK
version compatible with the observed host. Verify TLS, required privileges,
managed-object identity, task completion, and faults. A reachable SDK endpoint
is a capability result, not authorization to mutate the host.

Guest operations additionally require healthy VMware Tools and separately
protected guest credentials.

## Primary references

- [Broadcom vSphere Automation API](https://developer.broadcom.com/xapis/vsphere-automation-api/latest/)
- [Broadcom vCenter VM API](https://developer.broadcom.com/xapis/vsphere-automation-api/latest/api/vcenter/vm/get/)
- [Broadcom vSphere Web Services API](https://developer.broadcom.com/xapis/vsphere-web-services-api/latest/)

# ESXi vSphere REST API reference

Start with [`../SKILL.md`](../SKILL.md): its risk model and task router are
canonical. This reference is for capability-aware REST operations, not a
promise that standalone ESXi implements the vCenter REST surface.

- **Supported scope:** standalone ESXi 7.x/8.x where endpoints exist; vCenter
  has a broader API surface.
- **Last validated:** static review, 2026-07-22; no live host test was run.

## TLS and bounded requests

TLS verification is the default. Use a verified CA bundle with `--cacert` when
needed. `ESXI_INSECURE_TLS=1` is a documented, temporary, explicit exception;
it does not relax SSH host-key verification. Use bounded `--connect-timeout`
and `--max-time`. Do not aggressively retry authentication.

`scripts/esxi-readonly-discovery.sh` handles these controls and keeps one
session for its probe series. It never prints credentials, session IDs, or
Authorization headers.

## Session handling

A valid REST session requires all of:

1. successful `curl` exit status;
2. expected HTTP `200`/`201`;
3. a nonempty token of expected conservative shape;
4. in-memory-only storage; never logs/reports.

Classify `401` as authentication/session expiry, `403` as authorization,
`400`/`404` as potentially unsupported endpoint, and transport/TLS failures
separately. On `401` during a series, end the stale session and perform at most
one deliberate re-authentication after checking the task context. On cleanup,
attempt `DELETE /api/session` best-effort without exposing the result/token.

Standalone ESXi 7.x can return `400` from `POST /api/session` and
`POST /rest/com/vmware/cis/session` while Host Client and `/folder/` work. That
is a capability result, not evidence that credentials should be retried.

## Operation controls

Before any VM lifecycle or snapshot request, fresh discovery must confirm VM
name, UUID, VMID, current power state, RAM, datastore free space, and intended
network. Use IDs returned by the target; never assume a VMID is stable. Keep
operations idempotent where possible. No automatic delete, overwrite, or
power-off is permitted without explicit approval for the exact target.

Guest operations require VMware Tools and guest credentials; keep them separate
from ESXi/vCenter credentials. See the task router for reference selection and
risk class.

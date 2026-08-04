# SSH transport

## Trust and authentication

- Verify the host fingerprint through an independent channel before first use.
- Use a dedicated `UserKnownHostsFile` and `StrictHostKeyChecking=yes` for
  protected targets.
- Treat a changed host key as a STOP condition.
- Use a dedicated identity and `IdentitiesOnly=yes` where practical.
- Use `BatchMode=yes` only when prompts are intentionally forbidden.
- Keep `ForwardAgent=no`; ProxyJump does not require agent forwarding.
- Distinguish reachability, trust, authentication, authorization, and remote
  command failures. Do not retry rejected credentials aggressively.

## Keepalives

Host-scoped `ServerAliveInterval` and `ServerAliveCountMax` can detect a dead
transport. They do not keep a remote process alive after SSH exits and do not
prove command completion.

## Multiplexing

`ControlMaster` and `ControlPersist` can reuse one authenticated transport.
Use a `ControlPath` containing `%C` or destination user/host/port tokens inside
a directory accessible only to the local user.

Lifecycle:

```bash
: "${CONTROL_PATH:?}" "${HOST_ALIAS:?}"
ssh -S "$CONTROL_PATH" -O check "$HOST_ALIAS"
ssh -S "$CONTROL_PATH" -O exit "$HOST_ALIAS"
```

Check a socket before reuse. Treat a failed check as stale/unavailable; do not
infer remote session state. Close only the exact socket owned by the task.

## ProxyJump

Verify jump and final host keys independently. Keep the final target as the
authorization boundary and ensure session/control identifiers distinguish the
final destination. Do not store unrelated credentials or enable agent
forwarding on a jump host.

For private ESXi guests, first load
[`../../../references/private-guest-access-via-pfsense.md`](../../../references/private-guest-access-via-pfsense.md).
Do not use pfSense itself as a general-purpose bastion.

## Safe defaults

Never disable strict host-key checking, direct the known-hosts database to a
null device, enable agent forwarding by default, or force TTY allocation for
every connection.

Inspect live `ssh -G "$HOST_ALIAS"` output before relying on merged configuration,
without printing protected identity paths into public reports.

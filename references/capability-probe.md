# Capability probe

Probe capabilities before choosing a communication path. Do not assume that standalone ESXi exposes the full vCenter-style REST surface.

## Preferred checks

| Capability | Preferred check |
|---|---|
| REST session creation | `POST /api/session` |
| REST VM listing | `GET /api/vcenter/vm` |
| REST datastore listing | `GET /api/vcenter/datastore` |
| REST network / portgroup visibility | available vSphere API network endpoints |
| SSH basic command execution | `esxcli system version get` |
| SSH VM listing | `vim-cmd vmsvc/getallvms` |
| SSH datastore listing | `esxcli storage filesystem list` |
| SSH network listing | `esxcli network vswitch standard portgroup list` |
| Guest tools availability | per-VM VMware Tools state, for example `vim-cmd vmsvc/get.summary <vmid>` |

## Suggested probe order

1. Confirm `ESXI_HOST` and the preferred local profile.
2. Try REST session creation if `ESXI_PASS` is available.
3. Probe `GET /api/vcenter/vm`, `GET /api/vcenter/datastore`, and the network endpoint(s) the target version supports.
4. If REST is incomplete or inconsistent, fall back to SSH read-only discovery.
5. Record which transport worked and why it was chosen.

For standalone ESXi 7.x, a `400` from `POST /api/session` or `POST /rest/com/vmware/cis/session` can be a normal capability miss even when credentials are valid for the HTTPS Host Client and `/folder/` datastore browser. Do not loop on REST authentication in that case; record the result and switch to a verified alternative.

## Decision rules

- Prefer REST when it is available and reliable for the exact task.
- Prefer SSH/`esxcli`/`vim-cmd` for standalone ESXi inventory and host checks when REST is incomplete.
- Do not continue if the capability probe itself fails in a way that blocks safe identification of the target.
- Never guess at API support from a single successful endpoint.
- Treat a 400/404 on one endpoint as a capability signal, not as proof that the host is down.
- Treat a closed or unreachable SSH port as a transport capability result. Do not repeat aggressive SSH retries; use HTTPS Host Client, `/folder/`, or another verified path until SSH availability is restored.

## Example probe notes

A discovery report should capture:

- which capabilities were tested
- which succeeded
- which failed
- the chosen transport
- the reason the other transport was not selected

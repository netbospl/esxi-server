# Private guest access through pfSense

Use this module when an automation agent outside the ESXi host must administer
VMs attached to the internal LAN behind a pfSense router VM. Load
[`dedibox-dual-public-router-vm.md`](dedibox-dual-public-router-vm.md) first for
the retained-management plus secondary-public-IP topology. Load
[`pfsense-documentation-sources.md`](pfsense-documentation-sources.md) before
selecting a pfSense CE VPN, firewall, NAT, routing, or package procedure.
When the requested outcome is an SSH or persistent guest shell, load
[`../skills/private-guest-shell/SKILL.md`](../skills/private-guest-shell/SKILL.md)
for outer-path selection and stable-shell handoff.

The secondary public address is only an outer endpoint on pfSense. It does not
make private guest addresses Internet-routable, identify a guest, or grant
guest credentials. Model the connection as two independent layers:

1. Establish an approved path through pfSense to the private LAN.
2. Authenticate independently to the exact guest service.

## Access-path selection

Use the first viable method:

| Order | Method | Use | Boundary |
|---|---|---|---|
| 1 | WireGuard or OpenVPN on pfSense | Preferred for remote agent access | Expose only the VPN listener on the secondary WAN address; allow only required tunnel sources, guest targets, and ports. |
| 2 | Site-to-site VPN | Stable agent network or automation runner subnet | Route only the approved remote and guest prefixes; do not create a new default route. |
| 3 | Dedicated jump VM | VPN client cannot run in the agent environment | Harden and patch a minimal jump guest; restrict the WAN rule or port forward to known agent source addresses. |
| 4 | Direct guest port forward | Time-limited recovery only | One source, one public port, one guest, one service, explicit expiry, and immediate removal after verification. |

Do not use the pfSense shell as a general-purpose SSH bastion. Its SSH service
is an administrative interface for the firewall, not an automation runtime for
private guests. Keep pfSense WebGUI and SSH closed on WAN during normal
operation.

## Risk and approval boundaries

- Reading existing interface, route, VPN, NAT, firewall, DHCP, and guest
  identity state is R0.
- Creating a VPN peer, firewall rule, alias, route, port forward, jump-host
  account, or guest credential is at least R1 and normally R2 because it changes
  the reachable attack surface.
- Broad WAN exposure, default-route changes, or changes that can remove the
  only management path are R3.
- A pfSense change approval does not authorize an ESXi or guest change. A guest
  approval must name the exact VM identity and permitted operation.
- Guest commands inherit the canonical R0-R3 model from
  [`../SKILL.md`](../SKILL.md). Read-only guest access is not permission to
  install software, restart services, alter the firewall, or reboot the VM.

STOP when the agent source is unknown, guest identity is ambiguous, return
routing is unproven, a rule is broader than the approved target/service, or
independent console recovery is unavailable for a network change.

## Local-only profile contract

Record sanitized field names in the committed example profile, but keep real
values and credentials in a protected local profile or secret manager:

- access mode and exact public endpoint;
- VPN tunnel prefix and the agent peer address or jump-host identity;
- exact guest UUID, current VMID, vNIC MAC, private address, and guest hostname;
- allowed source, destination, protocol, port, and rule expiry;
- guest user, key or certificate reference, and verified host-key fingerprint;
- independent console path, pfSense backup reference, and revocation steps.

Suggested local environment names:

```bash
GUEST_ACCESS_MODE=vpn
PFSENSE_VPN_PROFILE=<PROTECTED_CLIENT_PROFILE_PATH>
GUEST_HOST=<PRIVATE_GUEST_ADDRESS_OR_NAME>
GUEST_USER=<DEDICATED_GUEST_USER>
GUEST_SSH_KEY=<PROTECTED_GUEST_KEY_PATH>
GUEST_KNOWN_HOSTS=<DEDICATED_GUEST_KNOWN_HOSTS_PATH>
```

Do not commit a populated VPN profile, WireGuard private key, OpenVPN client
bundle, guest key, SSH config, firewall export, or `config.xml`.

## Read-only preflight

Before proposing a path, collect protected evidence for all of the following:

1. The secondary public IPv4 has one owner: the pfSense WAN interface.
2. The pfSense WAN and LAN routes, outbound NAT, and default inbound block are
   healthy; ESXi management remains reachable independently.
3. The intended VPN listener or jump-host public mapping is absent or exactly
   matches the approved current state.
4. The guest is identified by VM UUID plus current VMID, vNIC MAC, port group,
   and a current DHCP lease, static assignment, or internal DNS record.
5. The guest service listens only where intended and its local firewall permits
   the proposed source.
6. The agent has a protected credential and an independently verified host-key
   or certificate fingerprint for the guest.
7. The return path from the guest to the VPN client or jump host is known. Do
   not add NAT merely to hide a routing mistake.
8. Revocation and rollback can disable the peer, rule, mapping, account, and
   credential without changing the ESXi management path.

Do not infer a guest address from VM order or reuse an old VMID. If DHCP is in
use, prefer a static mapping tied to the verified guest vNIC MAC or protected
internal DNS identity.

## VPN-first implementation gate

Use the current Netgate remote-access documentation for the selected VPN. Keep
the committed skill provider-neutral and store product-specific values only in
the approved plan.

The plan must include:

1. A unique peer identity and protected client key or certificate.
2. A non-overlapping tunnel prefix.
3. One WAN rule for the selected VPN listener on the secondary public address.
4. Tunnel-interface rules restricted to the agent peer or agent subnet, exact
   guest aliases, and required management ports.
5. No tunnel default route unless full-tunnel operation is explicitly required
   and approved.
6. No WAN rule for pfSense WebGUI, pfSense SSH, or guest management services.
7. A peer-disable and firewall-rule rollback sequence.

After approval, apply one component at a time. Verify the VPN handshake before
testing a guest port. Then verify routing, the scoped firewall match, and the
guest identity before attempting authentication. Avoid repeated login attempts
after `AUTH_FAILED` or `AUTHZ_FAILED`.

## Dedicated jump-host fallback

Use a separate minimal VM, not pfSense, when a VPN client cannot run where the
agent runs. Require:

- a dedicated non-root account and key for the agent;
- strict host-key checking for both jump host and final guest;
- source-address restriction on the WAN rule or port forward;
- no agent forwarding unless a specific workflow requires and approves it;
- no stored ESXi, pfSense, or unrelated guest credentials on the jump host;
- logging, patching, rate limiting, expiry, and a tested disable path;
- an internal firewall rule from the jump host to only the approved guests and
  services.

Keep the local SSH configuration outside the repository. A sanitized shape is:

```sshconfig
Host private-guest
    HostName <PRIVATE_GUEST_ADDRESS>
    User <GUEST_USER>
    IdentityFile <GUEST_KEY_PATH>
    UserKnownHostsFile <GUEST_KNOWN_HOSTS_PATH>
    StrictHostKeyChecking yes
    ProxyJump dedicated-jump

Host dedicated-jump
    HostName <JUMP_PUBLIC_ENDPOINT>
    User <JUMP_USER>
    IdentityFile <JUMP_KEY_PATH>
    UserKnownHostsFile <JUMP_KNOWN_HOSTS_PATH>
    StrictHostKeyChecking yes
```

Verify both fingerprints independently. A changed key at either hop is a STOP
condition; do not delete known-hosts entries and continue.

## Agent connection gate

Before running a guest command, report:

- outer path: VPN or dedicated jump host;
- final protocol: SSH, WinRM, RDP, HTTPS, or another approved service;
- exact guest UUID/current VMID and protected address/identity evidence;
- guest credential reference and trust verification state;
- risk class, approved command scope, and expiry;
- rollback or revocation owner.

For SSH after the VPN is established, use a dedicated known-hosts file and
identity without printing secrets:

```bash
: "${GUEST_HOST:?GUEST_HOST is required}"
: "${GUEST_USER:?GUEST_USER is required}"
: "${GUEST_SSH_KEY:?GUEST_SSH_KEY is required}"
: "${GUEST_KNOWN_HOSTS:?GUEST_KNOWN_HOSTS is required}"

ssh -o BatchMode=yes \
  -o StrictHostKeyChecking=yes \
  -o "UserKnownHostsFile=$GUEST_KNOWN_HOSTS" \
  -i "$GUEST_SSH_KEY" \
  "$GUEST_USER@$GUEST_HOST" -- '<APPROVED_READ_ONLY_COMMAND>'
```

Do not accept a host key from the same untrusted network path being validated.
Verify it through the VM console, a previously trusted record, or another
independent channel before the first connection.

## Verification and rollback

Verify success with protected evidence:

1. The VPN handshake or jump-host session belongs to the intended agent.
2. The observed guest host key or certificate matches the approved record.
3. The agent can reach only the approved guest services, not the whole LAN.
4. A non-approved peer/source cannot reach the VPN listener or guest service as
   defined by the plan.
5. pfSense WebGUI and SSH remain unreachable from WAN.
6. ESXi management, router egress, guest egress, DNS, DHCP, and NAT still work.
7. Disabling the peer, mapping, or temporary rule removes the access path.

Rollback in reverse order: stop guest work, revoke the guest credential if
needed, disable the jump mapping or VPN peer, remove the scoped firewall rule,
and re-read the final pfSense and guest state. Do not alter the retained ESXi
management address or default route as compensation.

## Primary documentation

- [Complete pfSense documentation source map](pfsense-documentation-sources.md)
- [Netgate: complete pfSense documentation index](https://docs.netgate.com/pfsense/en/latest/index.html)
- [Bogdan Caraman: pfSense CE practical guide (secondary installation guidance)](https://blog.bogdancaraman.com/getting-started-with-pfsense-ce-a-practical-guide/)
- [Netgate: WireGuard remote access](https://docs.netgate.com/pfsense/en/latest/recipes/wireguard-ra.html)
- [Netgate: OpenVPN remote access](https://docs.netgate.com/pfsense/en/latest/recipes/openvpn-ra.html)
- [Netgate: VPN firewall rules](https://docs.netgate.com/pfsense/en/latest/vpn/firewall-rules.html)
- [Netgate: remote firewall administration](https://docs.netgate.com/pfsense/en/latest/recipes/remote-firewall-administration.html)
- [Netgate: SSH access](https://docs.netgate.com/pfsense/en/latest/recipes/ssh-access.html)

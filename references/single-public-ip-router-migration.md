# Single-public-IP router migration

Use this runbook when one public IPv4 currently belongs to the ESXi management
VMkernel and the intended design moves that address to a router VM such as
pfSense while guest VMs use a private LAN with DHCP, DNS, NAT, and firewalling.

Treat the migration as R3. A mistake can remove the only remote management path.
Do not begin without independent console access, a maintenance window, exact
target approval, a verified host-configuration backup, and a tested rollback.

## Required target state

Record a host-specific design in a protected local profile:

| Component | Required fact |
|---|---|
| Current public-IP owner | VMkernel interface, vSwitch, port group, uplink, VLAN, prefix, gateway |
| Router WAN | Intended vNIC, port group, uplink/VLAN, public IP, prefix, gateway |
| Router LAN | Internal-only vSwitch/port group, private subnet, router address |
| ESXi management after migration | Explicitly chosen reachable address and management path |
| Guest VMs | Intended LAN port group, DHCP/static policy, DNS and isolation |
| Recovery | OOB console path and exact commands/UI actions to restore the original VMkernel state |

Never leave the post-migration ESXi management path implicit. Moving the only
public IP to a router VM does not by itself make the ESXi host reachable behind
that router.

## Hard gates

Stop unless all gates pass:

1. Verify hands-on or provider console access independently of the current
   management network.
2. Export and checksum the ESXi host configuration bundle outside the host.
3. Record current VMkernel, route, DNS, vSwitch, port-group, VLAN, uplink, and
   physical-NIC state.
4. Confirm provider requirements for prefix, gateway, allowed MAC address,
   virtual MAC registration, and anti-spoofing.
5. Confirm that the router VM can autostart and that recovery does not depend on
   services reachable only through that VM.
6. Define success, abort, and rollback tests before changing any interface.
7. Obtain exact approval for the public-IP move and expected outage.
8. Obtain the second R3 acknowledgement of management-lockout risk.

## Staged procedure

Keep discovery and planning read-only until both approvals exist.

1. Build the internal LAN without touching the working management VMkernel.
2. Attach only isolated test guests to the LAN and verify DHCP/DNS/firewall
   policy locally.
3. Prepare the router WAN configuration without assigning the live public IP.
4. Verify vNIC-to-port-group mapping from both the ESXi and router sides.
5. Re-read the provider MAC and gateway requirements immediately before the
   maintenance window.
6. Capture final pre-change evidence and verify that no target identifier has
   drifted.
7. From the independent console, apply only the approved public-IP ownership
   change.
8. Verify WAN link, gateway reachability, NAT, DNS, and an external egress test.
9. Verify the new ESXi management path from a separate client.
10. Move guest vNICs one at a time, verifying isolation and Internet access
    after each approved move.
11. Leave the old management configuration recoverable until all success
    criteria pass and the user approves cleanup.

Do not combine the IP move with unrelated certificate, firewall, storage, VM
hardware, or upgrade work.

## Immediate abort conditions

Rollback from the independent console if:

- the router WAN cannot reach the documented gateway;
- the provider rejects the router vNIC MAC;
- the new ESXi management path is unavailable;
- the router VM fails to boot or loses its expected port-group mapping;
- an unexpected default route appears;
- the observed state differs from the approved plan;
- rollback evidence or console access becomes uncertain.

Do not improvise compensating network changes while remote access is degraded.

## Verification and evidence

Record without publishing sensitive values:

- current public-IP owner and MAC;
- router WAN/LAN link and route status;
- ESXi management reachability through the intended path;
- DHCP lease, DNS resolution, NAT egress, and blocked inbound tests;
- router and required-guest autostart behavior;
- exit codes, deviations, residual risks, and whether rollback remains ready.

Complete cleanup only after a separate approval confirms that the new design is
stable and the old configuration is no longer required.

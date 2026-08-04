# Network, firewall, IPv4, and IPv6

Use read-only checks first. The canonical R0–R3 policy is in
[`../SKILL.md`](../SKILL.md). Management networking is R2 or R3: exact-target
approval, a maintenance window, written rollback, and out-of-band console are
required whenever lockout is plausible.

## Read-only discovery

```bash
esxcli network vswitch standard list
esxcli network vswitch standard portgroup list
esxcli network ip interface list
esxcli network ip interface ipv4 get
esxcli network ip interface ipv6 address list
esxcli network ip route ipv4 list
esxcli network firewall ruleset list
```

For a known standard port group, inspect its effective security overrides:

```bash
: "${PORTGROUP:?set the observed standard port-group name}"
esxcli network vswitch standard portgroup policy security get -p "$PORTGROUP"
```

## Working rules

- Confirm the management network before making any network change.
- Record the management VMkernel, uplinks, vSwitch, port groups, VLAN, IPv4,
  IPv6, default route, and current working management path before planning.
- Confirm the target port group before attaching or moving a VM NIC.
- Record public-IP ownership. A provider failover IP assigned to a VM must not
  also exist on a VMkernel adapter or another powered-on guest.
- Keep the existing ESXi default gateway unless the approved task explicitly
  changes management routing. A router VM's non-local `/32` gateway belongs
  inside the guest, not as a second ESXi default route.
- Treat forward A and reverse PTR records as identity evidence only. DNS does
  not assign an IP, register a provider virtual MAC, or install a route.
- Treat provider Netplan, `dhclient`, systemd, and
  `/etc/network/interfaces` examples as Linux-only instructions. Do not copy
  them into ESXi, and verify the pfSense-specific persistence method
  separately.
- Treat any management-network or firewall change as a lockout risk.
- Stop and ask for human approval if a proposed change could cut off SSH or Host Client access.
- Do not continue after detecting a likely network lockout.
- Change one component at a time; immediately verify Host Client and the
  selected automation client after each approved change.
- Do not assume a virtual firewall requires promiscuous mode, MAC address
  changes, or forged transmits. Keep the effective policy at `Reject` when its
  vNIC is configured with the one MAC it actually uses.
- A router VM cannot protect a public management VMkernel that shares the
  upstream network but does not route through that VM.
- Restore temporary firewall exceptions after verification. STOP immediately if
  the management path changes unexpectedly; use the pre-recorded console path
  and rollback rather than making compensating guesses.

## IPv4 / IPv6 guidance

- Check both IPv4 and IPv6 state before making network assumptions.
- Verify that the management interface still has a reachable address after any change.
- If a host uses IPv6 for management, treat firewall and portgroup changes with the same caution as IPv4.

## Verification after change

After any approved network change, re-run the read-only checks above and confirm that the management path is still reachable.

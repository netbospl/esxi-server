# Network, firewall, IPv4, and IPv6

Use read-only checks first. Treat any networking change as potentially disruptive.

## Read-only discovery

```bash
esxcli network vswitch standard list
esxcli network vswitch standard portgroup list
esxcli network ip interface list
esxcli network ip interface ipv4 get
esxcli network ip interface ipv6 address list
esxcli network firewall ruleset list
```

## Working rules

- Confirm the management network before making any network change.
- Confirm the target port group before attaching or moving a VM NIC.
- Treat any management-network or firewall change as a lockout risk.
- Stop and ask for human approval if a proposed change could cut off SSH or Host Client access.
- Do not continue after detecting a likely network lockout.

## IPv4 / IPv6 guidance

- Check both IPv4 and IPv6 state before making network assumptions.
- Verify that the management interface still has a reachable address after any change.
- If a host uses IPv6 for management, treat firewall and portgroup changes with the same caution as IPv4.

## Verification after change

After any approved network change, re-run the read-only checks above and confirm that the management path is still reachable.

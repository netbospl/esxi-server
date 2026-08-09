# SSH network inspection and change planning

Start with [`../SKILL.md`](../SKILL.md). Use this module for ESXi networking over an already trusted SSH path.

Read only the subset needed:

```bash
esxcli --formatter=csv network vswitch standard list
esxcli --formatter=csv network vswitch standard portgroup list
esxcli --formatter=csv network ip interface list
esxcli --formatter=csv network ip interface ipv4 get
esxcli --formatter=csv network ip interface ipv6 address list
esxcli --formatter=csv network nic list
esxcli --formatter=csv network firewall ruleset list
```

For topology, provider addressing, firewall, IPv4/IPv6, VLAN, routing, or ownership reasoning, load `network-firewall-ipv4-ipv6.md` only when that deeper policy is needed.

Any management-network change is R2/R3. Before proposing one, establish the exact management VMkernel/uplink/port group/VLAN/routes, return path, provider constraints, dependent VMs, and an independent out-of-band recovery path. Never infer gateway, VLAN, virtual MAC, or public-address ownership from adjacency or naming.

Do not provide speculative write commands. Build the exact approved plan from fresh state and verify command syntax on the observed build immediately before execution.

After an approved change, verify management reachability and the intended network state from an independent path before continuing.

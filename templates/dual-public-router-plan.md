# Dual-public router VM change plan

Copy this template to a protected local record. Do not commit populated IP
addresses, MAC addresses, VM inventory, datastore paths, or approval records.

## Identity and scope

- Plan ID / timestamp:
- Exact ESXi target and version/build:
- Local profile and evidence timestamp:
- Router VM UUID and fresh VMID:
- Approved maintenance window:
- Independent console test:
- Out-of-scope freeze: certificates / DNS record changes / IPv6 / ESXi
  upgrade / host reboot

## Risk and approval split

| Action | Exact target | R class | Downtime/access impact | Approval reference |
|---|---|---|---|---|
| Port-group or vNIC change |  | R2/R3 |  |  |
| External WAN attachment |  | R2/R3 |  |  |
| Router virtual-disk install |  | R3 if destructive/uncertain |  |  |
| Autostart configuration |  | R1/R2 |  |  |

Second R3 acknowledgement, when required:

## Provider facts

- Primary management IPv4 owner:
- Failover IPv4/prefix:
- Provider gateway:
- Provider virtual MAC:
- Exact allocation/server reference:
- Provider evidence source and timestamp:
- Conflicting source present: yes / no
- Conflict resolution evidence:
- Canonical router FQDN:
- Cloudflare A record and proxy state:
- Provider-managed PTR:
- Resolver 1 / resolver 2:
- Forward/reverse normalization and agreement evidence:

STOP if any provider source disagrees or is stale.

## Pre-change ESXi evidence

- Management VMkernel, gateway, and working client:
- Public vSwitch, physical uplink, WAN port group, and VLAN:
- WAN port-group effective security policy:
- Internal vSwitch and proof of no physical uplink:
- Physical NIC inventory/link/speed; unused-NIC decision:
- Proof failover IPv4 is absent from VMkernel and other VMs:
- Host CPU/RAM/free-memory evidence:
- Datastore free-space evidence:
- Host configuration backup reference/checksum:

## Router VM and disk gate

- Powered-off proof:
- Guest/hardware compatibility:
- WAN vNIC / port group / configured MAC:
- LAN vNIC / internal port group:
- ISO source and checksum:
- Exact writable virtual disk capacity and backing path:
- Proof no other writable disk is attached:

## Approved actions

List exact UI actions, commands, or API calls in execution order:

1.

Do not add compensating network, certificate, DNS, IPv6, or physical-uplink
changes during execution.

## Success tests

- Interface-specific route to the provider gateway:
- Resolver 1 and resolver 2 return the failover IPv4 for the router FQDN:
- Resolver 1 and resolver 2 return the normalized router FQDN for PTR:
- Cloudflare record remains DNS only:
- HTTPS egress endpoint 1 reports the failover IPv4:
- HTTPS egress endpoint 2 reports the failover IPv4:
- Actual Netgate installer/package metadata source succeeds:
- LAN DHCP/DNS/NAT and inbound-block tests:
- pfSense WebGUI and SSH remain unreachable through WAN:
- ESXi management remains unchanged from a separate client:
- Failover IPv4 remains absent from all VMkernel adapters:
- Open-VM-Tools and clean guest shutdown:
- Controlled router reboot restores required services:
- Autostart order/configuration:

## Abort conditions

- Provider MAC, gateway, or ownership mismatch
- Forward A, reverse PTR, or Cloudflare proxy-state mismatch
- Egress source differs from the failover IPv4
- ESXi management path, route, DNS, certificate, or IPv6 drift
- Unexpected uplink, VLAN, port-group security, or disk state
- Missing rollback evidence or independent console

## Rollback

- Router power-off and WAN-detach action:
- Exact port-group/vNIC pre-change values:
- pfSense protected `config.xml` reference:
- Verification after rollback:
- Residual risk and unproven items:

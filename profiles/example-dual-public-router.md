# Example dual-public ESXi router profile (sanitized)

Copy this example to `profiles/<host>.local.md` and replace every placeholder.
The populated file must remain ignored and uncommitted. Store credentials in a
secret manager, never in this profile.

Use one of these evidence states for every material fact:

- `observed`: read from the host or guest;
- `provider-confirmed`: tied to the exact server/allocation;
- `planned`: intended but not yet applied;
- `proven`: verified by the stated success test.

## Contents

- [Change boundary](#change-boundary)
- [Public address ownership](#public-address-ownership)
- [Router DNS identity](#router-dns-identity)
- [ESXi network topology](#esxi-network-topology)
- [Router VM](#router-vm)
- [Network and recovery tests](#network-and-recovery-tests)
- [Private guest access](#private-guest-access)
- [Rollback](#rollback)

## Change boundary

| Field | Value | State / evidence |
|---|---|---|
| Exact ESXi version/build | `<ESXI_VERSION_BUILD>` | `observed / <TIMESTAMP>` |
| Host resources | `<CPU_CORES> cores, <RAM_GIB> GiB` | `observed / <TIMESTAMP>` |
| Independent console | `<OOB_CONSOLE_REFERENCE>` | `proven / login test <TIMESTAMP>` |
| Host config backup | `<BACKUP_REFERENCE_AND_SHA256>` | `proven / <TIMESTAMP>` |
| Maintenance window | `<WINDOW>` | `planned / approval <REFERENCE>` |
| Certificate changes | `frozen` | `planned / outside scope` |
| DNS changes | `frozen` | `planned / outside scope` |
| IPv6 changes | `frozen` | `planned / outside scope` |
| Host reboot | `not approved` | `planned / separate approval required` |
| SSH lifecycle | `<DISABLED_OR_APPROVED_WINDOW>` | `observed / <TIMESTAMP>` |

## Public address ownership

| Role | Address/prefix | Owner | Gateway | State / evidence |
|---|---|---|---|---|
| ESXi management | `<ESXI_MANAGEMENT_IPV4>/<MANAGEMENT_PREFIX>` | `<MANAGEMENT_VMK>` | `<ESXI_GATEWAY>` | `observed / host inventory` |
| Router WAN | `<FAILOVER_IPV4>/32` | `<ROUTER_WAN_INTERFACE>` | `<PROVIDER_GATEWAY>` | `provider-confirmed / <SOURCE_AND_TIMESTAMP>` |

- Provider product: `<PROVIDER_PRODUCT>`
- Exact server/allocation reference: `<PROVIDER_ALLOCATION_REFERENCE>`
- Provider virtual MAC: `<PROVIDER_VMAC>`
- Virtual-MAC assignment state: `provider-confirmed / <TIMESTAMP>`
- Generic documentation value checked: `<YES_NO_AND_DATE>`
- Source conflict present: `<YES_OR_NO>`; STOP when `YES`
- Proof that failover IPv4 is absent from all VMkernel adapters:
  `<COMMAND_OR_UI_EVIDENCE_REFERENCE>`
- Proof that each public IPv4 has one owner:
  `<OWNERSHIP_EVIDENCE_REFERENCE>`

## Router DNS identity

| Field | Value | State / evidence |
|---|---|---|
| Canonical router FQDN | `<ROUTER_FQDN>` | `provider-confirmed / <TIMESTAMP>` |
| Forward A record | `<ROUTER_FQDN>` → `<FAILOVER_IPV4>` | `observed / <DNS_CONTROL_PLANE_AND_TIMESTAMP>` |
| Reverse PTR record | `<FAILOVER_IPV4>` → `<ROUTER_FQDN>.` | `provider-confirmed / <TIMESTAMP>` |
| Cloudflare proxy state | `DNS only` | `observed / <TIMESTAMP>` |
| Resolver 1 | `<DNS_RESOLVER_1>` | `<STATE_AND_EVIDENCE>` |
| Resolver 2 | `<DNS_RESOLVER_2>` | `<STATE_AND_EVIDENCE>` |
| Forward-confirmed reverse DNS | `<ALIGNED_OR_STOP>` | `<STATE_AND_EVIDENCE>` |

- Normalize the PTR by lowercasing it and removing one trailing dot before
  comparison.
- DNS record changes remain frozen; read-only verification is allowed.
- The FQDN does not authorize pfSense WebGUI or SSH exposure on WAN.

## ESXi network topology

| Object | Intended role | Uplink/VLAN | State / evidence |
|---|---|---|---|
| `<PUBLIC_VSWITCH>` | Management plus router WAN L2 | `<PUBLIC_UPLINK>` / `<WAN_VLAN>` | `observed` |
| `<WAN_PORTGROUP>` | Router WAN only | inherited public uplink / `<WAN_VLAN>` | `observed` |
| `<LAN_VSWITCH>` | Private router LAN | **no physical uplink** | `observed` |
| `<LAN_PORTGROUP>` | Private guests | internal only | `observed` |
| `<UNUSED_PHYSICAL_NIC>` | Unassigned | do not repurpose without proof | `observed` |

WAN port-group effective security:

- Promiscuous Mode: `Reject`
- MAC Address Changes: `Reject`
- Forged Transmits: `Reject`
- Exception required for a proven feature: `<NO_OR_SEPARATE_PLAN_REFERENCE>`

## Router VM

| Field | Value | State / evidence |
|---|---|---|
| VM UUID / current VMID | `<ROUTER_VM_UUID>` / `<CURRENT_VMID>` | `observed / <TIMESTAMP>` |
| Power state | `powered off before topology edits` | `observed` |
| Guest / virtual hardware | `<PFSENSE_VERSION>` / `<VM_HW_VERSION>` | `planned` |
| CPU | `1 vCPU, 1 socket` | `planned / measure before expansion` |
| Memory | `2048 MiB` | `planned / measure before expansion` |
| Disk | `20 GiB thin, <DISK_BACKING_PATH>` | `observed / blank-target proof` |
| WAN vNIC | `VMXNET3, <WAN_PORTGROUP>, <PROVIDER_VMAC>` | `planned` |
| LAN vNIC | `VMXNET3, <LAN_PORTGROUP>, <ESXI_GENERATED_MAC>` | `planned` |
| Installer ISO | `<TRUSTED_ISO_PATH_AND_SHA256>` | `proven` |
| Autostart | `disabled until all gates pass` | `observed` |

## Network and recovery tests

| Test | Expected | State / evidence |
|---|---|---|
| Non-local gateway route | `<PROVIDER_GATEWAY>` reachable through WAN | `<STATE_AND_EVIDENCE>` |
| Egress check 1 | `<EGRESS_IP_CHECK_1>` reports `<FAILOVER_IPV4>` | `<STATE_AND_EVIDENCE>` |
| Egress check 2 | `<EGRESS_IP_CHECK_2>` reports `<FAILOVER_IPV4>` | `<STATE_AND_EVIDENCE>` |
| Forward DNS | Both resolvers return `<FAILOVER_IPV4>` for `<ROUTER_FQDN>` | `<STATE_AND_EVIDENCE>` |
| Reverse DNS | Both resolvers return `<ROUTER_FQDN>.` for `<FAILOVER_IPV4>` | `<STATE_AND_EVIDENCE>` |
| Netgate metadata | Installer/package version list loads | `<STATE_AND_EVIDENCE>` |
| LAN | DHCP, DNS, NAT, default inbound block | `<STATE_AND_EVIDENCE>` |
| WAN management | WebGUI and SSH unreachable from WAN | `<STATE_AND_EVIDENCE>` |
| ESXi management | Unchanged from a separate client | `<STATE_AND_EVIDENCE>` |
| Open-VM-Tools | `vmtoolsd` and ESXi Tools status healthy | `<STATE_AND_EVIDENCE>` |
| Clean shutdown | ESXi guest shutdown completes cleanly | `<STATE_AND_EVIDENCE>` |
| Router reboot | WAN/LAN/DHCP/DNS/NAT/VPN recover | `<STATE_AND_EVIDENCE>` |
| Host-boot autostart | Router precedes dependent guests | `unproven until approved host reboot` |

## Private guest access

Keep tunnel keys, SSH keys, passwords, certificates, and populated SSH config
outside this profile and repository.

| Field | Value | State / evidence |
|---|---|---|
| Access mode | `<VPN_OR_DEDICATED_JUMP>` | `<PLANNED_OR_PROVEN>` |
| Public endpoint | `<ROUTER_FQDN>:<VPN_PORT>` | `<STATE_AND_EVIDENCE>` |
| VPN client prefix | `<VPN_CLIENT_PREFIX>` | `<STATE_AND_EVIDENCE>` |
| Allowed guest targets | `<GUEST_ALIASES_OR_PREFIXES>` | `<SCOPED_RULE_EVIDENCE>` |
| Allowed services | `<SSH_WINRM_RDP_OR_OTHER>` | `<SCOPED_RULE_EVIDENCE>` |
| Guest identity source | `<VM_UUID_MAC_DHCP_OR_DNS_EVIDENCE>` | `<STATE_AND_EVIDENCE>` |
| Guest host-key trust | `<OUT_OF_BAND_FINGERPRINT_REFERENCE>` | `<STATE_AND_EVIDENCE>` |
| Revocation test | `<PEER_OR_KEY_DISABLE_TEST>` | `<STATE_AND_EVIDENCE>` |
| WAN guest-management exposure | `none` | `<EXTERNAL_PROBE_EVIDENCE>` |

## Rollback

- Router isolation action: `<POWER_OFF_AND_WAN_DETACH_STEPS>`
- Port-group rollback: `<EXACT_PRECHANGE_VALUES_AND_STEPS>`
- ESXi management rollback: `not changed by this plan`
- pfSense configuration backup: `<PROTECTED_CONFIG_XML_REFERENCE>`
- Abort owner and decision channel: `<OPERATOR_AND_CHANNEL>`

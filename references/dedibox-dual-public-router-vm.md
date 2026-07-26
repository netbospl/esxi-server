# Dedibox dual-public IPv4 router VM

Use this runbook only when the ESXi management VMkernel keeps its working
public IPv4 address and a separate provider failover IPv4 address is assigned
exclusively to a router VM such as pfSense. The failover address is routed by
the provider to a registered virtual MAC address and may use a `/32` prefix
with a gateway outside that prefix.

- **Target:** standalone ESXi 7.x with a Dedibox failover IPv4 and router VM.
- **Last documentation review:** 2026-07-26.
- **Validation status:** static documentation and mock-policy validation only;
  no ESXi host, provider account, or router VM was contacted.

If the router must take the only public IPv4 away from ESXi, use
[`single-public-ip-router-migration.md`](single-public-ip-router-migration.md)
instead.

## Contents

- [Risk split and required topology](#risk-split-and-required-topology)
- [Source authority and profile contract](#source-authority-and-profile-contract)
- [Router DNS identity](#router-dns-identity)
- [Safety invariants](#safety-invariants)
- [Constrained-host sizing](#constrained-host-sizing)
- [Read-only preflight](#read-only-preflight)
- [Staged implementation gates](#staged-implementation-gates)
- [Autostart and shutdown](#autostart-and-shutdown)
- [Abort and rollback](#abort-and-rollback)
- [Residual risk and deferred hardening](#residual-risk-and-deferred-hardening)
- [Primary documentation](#primary-documentation)

## Risk split and required topology

Read-only discovery is R0. Creating or changing a vSwitch, port group, VM NIC,
route, firewall rule, or externally reachable attachment is R2 unless the
canonical policy in [`../SKILL.md`](../SKILL.md) raises it to R3. Installing to
a virtual disk is R3 when disk identity is uncertain or existing data may be
destroyed. Any change to the working ESXi management path is a separate R3
operation and is outside this runbook.

The required ownership model is:

| Component | Required state |
|---|---|
| Primary public IPv4 | Owned only by the existing management VMkernel |
| Failover public IPv4 | Owned only by the router WAN interface |
| ESXi default route | Unchanged; no second default route is added |
| Router WAN vNIC | Provider-facing port group; manual provider virtual MAC |
| Router LAN vNIC | Internal port group on a vSwitch with no physical uplink |
| Private guests | Attached only to the router LAN or explicitly designed internal segments |
| Unused physical NIC | Left unassigned unless upstream wiring and provider behavior are independently proven |

The provider-facing router port group may share the management vSwitch and its
single working uplink. A generic two-physical-NIC firewall recipe must not
override the observed host topology. The isolated LAN requires no physical
uplink.

## Source authority and profile contract

Copy [`../profiles/example-dual-public-router.md`](../profiles/example-dual-public-router.md)
to an ignored `profiles/<host>.local.md` file. Record every value as
`observed`, `provider-confirmed`, `planned`, or `proven`; do not present a plan
as current state.

Use this authority order for the failover prefix, gateway, server assignment,
and virtual MAC:

1. Current provider console data tied to the exact server and failover IP.
2. A current provider support response tied to that exact allocation.
3. A timestamped local profile copied from either source.
4. Generic provider documentation as a reference candidate only.

The provider currently documents a shared "unique gateway" for Dedibox virtual
machines, but it must not silently replace an allocation-specific value. STOP
if the console, support response, local profile, or historical test evidence
disagree. Resolve the conflict with the provider and repeat a non-destructive
network test before installation.

The local profile must contain:

- `<ESXI_MANAGEMENT_IPV4>`, `<MANAGEMENT_VMK>`, current prefix and gateway;
- `<FAILOVER_IPV4>/32`, `<PROVIDER_GATEWAY>`, and `<PROVIDER_VMAC>`;
- `<ROUTER_FQDN>`, its forward A record, provider-managed PTR record, and
  Cloudflare proxy state;
- evidence source, timestamp, and server-assignment status for provider values;
- public vSwitch, uplink, WAN port group, VLAN, and effective security policy;
- internal vSwitch and LAN port group, explicitly recording no uplink;
- router VM UUID/current VMID, power state, vNIC mapping, and writable disk;
- out-of-band console proof, current host backup evidence, and change freezes;
- two independent egress-IP check endpoints and package-metadata success test.

Do not commit the populated profile, provider screenshots, VM inventory, IP
addresses, MAC addresses, datastore paths, or support-ticket content.

## Router DNS identity

Treat DNS identity and IP routing as separate control planes. An A record or PTR
record does not assign an address, register a virtual MAC, create the `/32`
route, or open a service. Record the existing DNS state during R0 discovery;
changing it remains outside this network runbook.

For a router identity such as `<ROUTER_FQDN>`, require all of the following:

1. The Cloudflare A record for `<ROUTER_FQDN>` returns exactly
   `<FAILOVER_IPV4>` with no conflicting A or CNAME record.
2. The provider-managed PTR for `<FAILOVER_IPV4>` returns
   `<ROUTER_FQDN>.`.
3. Compare names after lowercasing and removing one trailing dot. Store the
   canonical profile value without the trailing dot.
4. Keep the Cloudflare record at **DNS only** when the name identifies a
   router, VPN, or other non-HTTP service. A separately designed supported web
   service may use the Cloudflare HTTP proxy, but never infer that the proxy
   can front arbitrary pfSense, VPN, or ESXi protocols.
5. Verify forward and reverse DNS through two independent recursive resolvers
   before relying on the name for a certificate or production service.

Example read-only checks:

```bash
dig @<DNS_RESOLVER_1> +short <ROUTER_FQDN> A
dig @<DNS_RESOLVER_2> +short <ROUTER_FQDN> A
dig @<DNS_RESOLVER_1> +short -x <FAILOVER_IPV4>
dig @<DNS_RESOLVER_2> +short -x <FAILOVER_IPV4>
```

The two A results must equal `<FAILOVER_IPV4>`. The normalized PTR result must
equal `<ROUTER_FQDN>`. STOP if the provider panel, Cloudflare dashboard,
authoritative DNS, or recursive-resolver results disagree. Preserve the
screenshots or command output only in protected local evidence.

The FQDN is an identity, not permission to expose administration. Keep pfSense
WebGUI and SSH closed on WAN even when forward and reverse DNS agree.

## Safety invariants

These are STOP conditions, not preferences:

- Never assign `<FAILOVER_IPV4>` to a VMkernel adapter.
- Never remove or renumber the working management VMkernel in this runbook.
- Never add a second ESXi default route for the router WAN gateway.
- Ensure each public IPv4 has exactly one live owner.
- Configure the WAN vNIC with `<PROVIDER_VMAC>` in the ESXi VM settings while
  the router VM is powered off; verify the same MAC inside the guest.
- Keep the WAN port group untagged unless the provider record explicitly
  requires a VLAN.
- Keep Promiscuous Mode, MAC Address Changes, and Forged Transmits at `Reject`
  when the guest uses the exact MAC configured on its vNIC and does not bridge,
  run CARP, or emit additional source MAC addresses.
- Do not enable promiscuous mode or forged transmits merely because the guest is
  a firewall. Re-evaluate the policy only for a separately approved feature
  that demonstrably requires multiple MAC addresses.
- Keep the LAN vSwitch free of physical uplinks.
- Identify WAN and LAN by their recorded ESXi vNIC MAC and port-group mapping;
  do not rely only on guest adapter order such as `vmx0`/`vmx1`.
- Keep pfSense WebGUI and SSH closed on WAN. Bootstrap from the VM console or
  isolated LAN and add remote administration only through a separately tested
  VPN design.
- Do not repurpose an apparently available physical NIC based only on link
  state; prove cabling, speed, upstream switch behavior, and provider support.
- Do not combine this work with certificate, DNS-record, IPv6, ESXi upgrade, or
  public management retirement changes. Existing DNS may be observed and
  validated read-only.
- Treat provider Netplan, `/etc/network/interfaces`, `dhclient`, or systemd
  examples as Linux guest guidance only. Never apply them directly to ESXi or
  assume they describe pfSense persistence.
- Verify independent out-of-band console access before any R2/R3 network step.

The router VM protects guests behind it. It does not filter the retained public
ESXi management interface.

## Constrained-host sizing

For a small legacy host, start with one virtual CPU in one socket, 2 GiB RAM,
a 20 GiB thin disk, and two VMXNET3 adapters. Netgate documents that a basic
firewall can run with 1 GiB RAM and at least 16 GB disk, but extra headroom
reduces avoidable pressure during installation and package operations.

Before power-on, record host free memory, datastore free space, existing VM
commitment, and CPU contention. Keep packages minimal. Do not add IDS/IPS,
proxying, or other resource-heavy services until measured CPU, RAM, storage,
and throughput data justify them. Do not add CPU or memory reservations
blindly; treat a reservation as a separate resource-allocation decision.

## Read-only preflight

Load [`ssh-esxcli.md`](ssh-esxcli.md) and
[`network-firewall-ipv4-ipv6.md`](network-firewall-ipv4-ipv6.md). Use the
guarded discovery helper or an already trusted Host Client path. SSH may be
enabled only for an approved window and must be stopped afterward when that is
the host policy.

Record without publishing output:

1. Exact ESXi version/build, CPU, RAM, datastore free space, and physical NIC
   link/speed.
2. Management VMkernel, public vSwitch/uplink, port groups, VLANs, IPv4/IPv6,
   route table, DNS, and effective port-group security settings.
3. Current Cloudflare A/proxy state and provider PTR for `<ROUTER_FQDN>`, plus
   forward and reverse DNS results from two independent resolvers.
4. Proof that `<FAILOVER_IPV4>` is absent from every VMkernel adapter and other
   VM.
5. Router VM UUID and fresh VMID, powered-off state, virtual hardware version,
   both vNIC mappings, configured MACs, ISO attachment, and disk backing.
6. Proof that the only installer target is the intended blank virtual disk,
   including its capacity and datastore path.
7. Current external ESXi management reachability from a separate client.
8. Independent console access and a checksummed host configuration bundle
   stored outside the host.

STOP on stale VMID, uncertain disk identity, changed uplink, virtual-MAC
mismatch, provider-assignment ambiguity, or missing recovery evidence.

## Staged implementation gates

Use [`../templates/dual-public-router-plan.md`](../templates/dual-public-router-plan.md)
for the exact targets, actions, approvals, and rollback.

### Gate 1: isolated topology

With the router powered off:

1. Verify the WAN vNIC maps to the provider-facing port group and its ESXi
   configured MAC equals `<PROVIDER_VMAC>`.
2. Verify the LAN vNIC maps to the internal-only port group.
3. Verify the internal vSwitch has no uplink.
4. Verify the WAN port group effective VLAN and all three security settings.
5. Reconfirm that management networking is unchanged.

### Gate 2: network proof before disk write

Boot only the trusted installer/rescue environment. Configure the WAN as
`<FAILOVER_IPV4>/32` with `<PROVIDER_GATEWAY>`. If the installer cannot express
an off-prefix gateway, use its supported rescue shell to create a temporary
interface-specific gateway route for this proof; record the exact commands and
do not mistake them for persistent pfSense configuration.

Before allowing an installer to write:

1. Verify the interface-specific route to `<PROVIDER_GATEWAY>` and the default
   route through it.
2. Verify upstream reachability. Do not treat a failed gateway ping alone as
   failure when the provider does not answer ICMP; use route, neighbor, DNS,
   and HTTPS evidence together.
3. Verify `<ROUTER_FQDN>` forward and reverse DNS through two recorded
   resolvers and confirm the Cloudflare record remains DNS only.
4. Complete HTTPS requests to two independent egress-IP endpoints and prove
   both report exactly `<FAILOVER_IPV4>`.
5. Reach the actual Netgate installer metadata/version source used by this
   installation, not merely an unrelated website.
6. Reconfirm the primary ESXi management path from a separate client.

STOP if the observed source address is the management IPv4, the two egress
checks disagree, the package/installer source is unreachable, or management
reachability changes.

### Gate 3: disk install

Immediately before accepting the installer write:

1. Re-read the VM UUID/current VMID and virtual disk inventory.
2. Match disk capacity and backing path to the approved blank target.
3. Ensure no other writable disk is attached.
4. Obtain the R3 acknowledgement naming that exact virtual disk.

Install only to that disk. Do not alter ESXi boot media or another VM disk.

### Gate 4: service verification

After installation:

1. Configure the pfSense WAN gateway with **Use non-local gateway through
   interface-specific route** because the provider requires a gateway outside
   the WAN prefix. Verify the WAN address, route, gateway/monitor state, DNS,
   HTTPS, and both external source-IP results.
2. Verify LAN addressing, DHCP, DNS forwarding, outbound NAT, and default
   inbound blocking with an isolated test guest. Confirm WebGUI and SSH are not
   reachable through WAN.
3. Re-run the two-resolver A/PTR checks for `<ROUTER_FQDN>` without opening
   WebGUI or SSH on WAN.
4. Verify the primary ESXi management path and confirm its route did not
   change.
5. Confirm `<FAILOVER_IPV4>` remains absent from all VMkernel adapters.
6. Save an encrypted/protected pfSense `config.xml` backup outside the VM and
   repository.

## Autostart and shutdown

Do not enable autostart merely because routing works.

1. Load the official package list through **System > Packages** and install only
   the Netgate Open-VM-Tools package after repository metadata succeeds.
2. Verify `vmtoolsd` inside pfSense and a current Tools status in ESXi.
3. Prove that an ESXi guest shutdown request performs a clean pfSense shutdown.
4. Perform a controlled router-VM reboot and re-run WAN, LAN, DHCP, DNS, NAT,
   VPN, source-IP, and management-path tests.
5. Put the router before dependent private guests in the standalone-host
   autostart order. Base startup delay on measured service readiness.
6. Re-read and record the final autostart configuration.

A host reboot is a separate disruptive operation. Do not reboot the host only
to prove autostart without its own approved maintenance window. Until that test
occurs, report configuration as present but host-boot recovery as unproven.

## Abort and rollback

Power off the router VM and detach its WAN vNIC from the provider-facing port
group if any of these occur:

- the guest MAC differs from the provider virtual MAC;
- the failover IP appears on more than one owner;
- the non-local gateway route is missing or unstable;
- egress source IP differs from `<FAILOVER_IPV4>`;
- ESXi management, DNS, certificate behavior, or IPv6 changes unexpectedly;
- an unapproved physical uplink, VLAN, route, or security-policy change appears;
- disk identity or rollback evidence becomes uncertain.

Because ESXi management retains its primary IPv4, rollback for this variant
must not move addresses or change the host default route. Restore only the
approved router VM/port-group state, preserve evidence, and use the independent
console if management degrades.

## Residual risk and deferred hardening

- Public ESXi management remains directly exposed. Restricting ESXi firewall
  allowed IPs or moving management behind a private VPN is a separate R3 plan
  with out-of-band recovery; pfSense cannot protect the current public path.
- An old ESXi build needs a separate compatibility and security review. Do not
  combine upgrade experiments with router deployment.
- The router VM is a single point of failure for private guests. Keep a current
  protected `config.xml`, installer media, and a documented manual start path.
- Add only exact VPN-subnet return routes to ESXi when private management is
  later introduced. Do not replace its working default route.
- Observe VPN NAT/SNAT and return routing in tests; do not assume product
  defaults.

## Primary documentation

- [Scaleway: configure a VM network on a Dedibox host](https://www.scaleway.com/en/docs/dedibox-ip-failover/how-to/configure-network-virtual-machine/)
- [Scaleway: create a virtual MAC for a failover IP](https://www.scaleway.com/en/docs/dedibox-ip-failover/how-to/create-virtual-mac/)
- [Cloudflare: DNS proxy status](https://developers.cloudflare.com/dns/proxy-status/)
- [Netgate: gateway settings](https://docs.netgate.com/pfsense/en/latest/routing/gateway-configure.html)
- [Netgate: virtualize pfSense on ESXi](https://docs.netgate.com/pfsense/en/latest/recipes/virtualize-esxi.html)
- [Netgate: Open-VM-Tools package](https://docs.netgate.com/pfsense/en/latest/packages/open-vm-tools.html)
- [Netgate: outbound NAT](https://docs.netgate.com/pfsense/en/latest/nat/outbound.html)
- [Broadcom: VMkernel static routes and default gateway](https://knowledge.broadcom.com/external/article/308786/configuring-static-routes-for-vmkernel-p.html)
- [Broadcom: port-group MAC security](https://knowledge.broadcom.com/external/article/427110/forged-transmits-and-mac-address-changes.html)

# pfSense documentation sources and retrieval policy

Use this source map for every pfSense-specific task. The deployed router is
pfSense Community Edition (CE), but the exact running release and installed
packages remain observed facts: verify them read-only before selecting a
procedure. Load only the category and exact child page needed for the task.

## Source authority

Use sources in this order:

1. Observed pfSense CE edition, release, interface state, package versions, and
   capabilities from the protected local environment.
2. The current task-specific page under the
   [Netgate pfSense documentation index](https://docs.netgate.com/pfsense/en/latest/index.html),
   cross-checked for CE, Plus-only, package, and release qualifications.
3. The official Netgate PDF snapshot described below when live documentation
   is unavailable or a stable point-in-time comparison is required.
4. The Bogdan Caraman pfSense CE practical guide described below for
   installation orientation and screenshots only.

STOP when sources disagree about the installed CE release, an option is marked
Plus-only, a package is unavailable, or the live page no longer supports the
planned procedure. Do not convert documentation into a command by guessing.
Documentation can establish syntax and vendor guidance; it does not establish
the current router state or grant R1-R3 approval.

## Retrieval workflow

1. Record the observed pfSense edition, release, architecture, and relevant
   installed package version without exposing private configuration.
2. Select the narrowest category below, then open the exact child page for the
   operation. Use the documentation search for a specific feature or error.
3. Record the page title, canonical URL, retrieval date, and any CE/Plus or
   version qualifier in the change plan.
4. Compare the page prerequisites with observed WAN/LAN ownership, routes,
   firewall state, recovery access, and the canonical R0-R3 policy.
5. Treat examples as placeholders. Never copy example addresses, interface
   names, credentials, gateways, certificates, or tunnel prefixes into a plan.
6. If only the PDF or practical guide is available, mark the evidence as
   snapshot or secondary and revalidate against live Netgate documentation
   before a state change.

## Complete Netgate documentation map

The complete index is the coverage source of truth. These category links route
an agent across the full official documentation set without copying it into
the skill.

| Area | Official entry point |
|---|---|
| Preface | https://docs.netgate.com/pfsense/en/latest/preface/index.html |
| Introduction and CE/Plus differences | https://docs.netgate.com/pfsense/en/latest/general/index.html |
| Releases | https://docs.netgate.com/pfsense/en/latest/releases/index.html |
| Product manuals | https://docs.netgate.com/pfsense/en/latest/product-manuals.html |
| Networking concepts | https://docs.netgate.com/pfsense/en/latest/network/index.html |
| IPv6 | https://docs.netgate.com/pfsense/en/latest/network/ipv6/index.html |
| Hardware | https://docs.netgate.com/pfsense/en/latest/hardware/index.html |
| Installation and upgrades | https://docs.netgate.com/pfsense/en/latest/install/index.html |
| Configuration | https://docs.netgate.com/pfsense/en/latest/config/index.html |
| Netgate Nexus | https://docs.netgate.com/pfsense/en/latest/nexus/index.html |
| Backup and recovery | https://docs.netgate.com/pfsense/en/latest/backup/index.html |
| Interfaces | https://docs.netgate.com/pfsense/en/latest/interfaces/index.html |
| Users and authentication | https://docs.netgate.com/pfsense/en/latest/usermanager/index.html |
| Certificates | https://docs.netgate.com/pfsense/en/latest/certificates/index.html |
| Firewall | https://docs.netgate.com/pfsense/en/latest/firewall/index.html |
| NAT | https://docs.netgate.com/pfsense/en/latest/nat/index.html |
| Routing | https://docs.netgate.com/pfsense/en/latest/routing/index.html |
| Bridging | https://docs.netgate.com/pfsense/en/latest/bridges/index.html |
| VLANs | https://docs.netgate.com/pfsense/en/latest/vlan/index.html |
| Multi-WAN | https://docs.netgate.com/pfsense/en/latest/multiwan/index.html |
| VPN overview | https://docs.netgate.com/pfsense/en/latest/vpn/index.html |
| IPsec | https://docs.netgate.com/pfsense/en/latest/vpn/ipsec/index.html |
| L2TP | https://docs.netgate.com/pfsense/en/latest/vpn/l2tp/index.html |
| OpenVPN | https://docs.netgate.com/pfsense/en/latest/vpn/openvpn/index.html |
| WireGuard | https://docs.netgate.com/pfsense/en/latest/vpn/wireguard/index.html |
| Services | https://docs.netgate.com/pfsense/en/latest/services/index.html |
| DHCP | https://docs.netgate.com/pfsense/en/latest/services/dhcp/index.html |
| DNS | https://docs.netgate.com/pfsense/en/latest/services/dns/index.html |
| Dynamic DNS | https://docs.netgate.com/pfsense/en/latest/services/dyndns/index.html |
| NTP | https://docs.netgate.com/pfsense/en/latest/services/ntpd/index.html |
| Traffic shaping | https://docs.netgate.com/pfsense/en/latest/trafficshaper/index.html |
| Captive portal | https://docs.netgate.com/pfsense/en/latest/captiveportal/index.html |
| High availability | https://docs.netgate.com/pfsense/en/latest/highavailability/index.html |
| Monitoring | https://docs.netgate.com/pfsense/en/latest/monitoring/index.html |
| Monitoring graphs | https://docs.netgate.com/pfsense/en/latest/monitoring/graphs/index.html |
| System logs | https://docs.netgate.com/pfsense/en/latest/monitoring/logs/index.html |
| Diagnostics | https://docs.netgate.com/pfsense/en/latest/diagnostics/index.html |
| Packages | https://docs.netgate.com/pfsense/en/latest/packages/index.html |
| Virtualization | https://docs.netgate.com/pfsense/en/latest/virtualization/index.html |
| Wireless | https://docs.netgate.com/pfsense/en/latest/wireless/index.html |
| Cellular | https://docs.netgate.com/pfsense/en/latest/cellular/index.html |
| Troubleshooting | https://docs.netgate.com/pfsense/en/latest/troubleshooting/index.html |
| Configuration recipes | https://docs.netgate.com/pfsense/en/latest/recipes/index.html |
| Menu guide | https://docs.netgate.com/pfsense/en/latest/menuguide/index.html |
| Glossary | https://docs.netgate.com/pfsense/en/latest/glossary.html |
| Development | https://docs.netgate.com/pfsense/en/latest/development/index.html |
| Documentation references | https://docs.netgate.com/pfsense/en/latest/references/index.html |
| Licensing | https://docs.netgate.com/pfsense/en/latest/licensing/index.html |

## Netgate PDF snapshot

The user-provided `the-pfsense-documentation.pdf` was inspected as a reference
artifact with this metadata:

- title: **The pfSense Documentation**;
- author: Netgate;
- generated: 2026-07-16;
- length: 2,502 pages;
- scope: the complete documentation hierarchy, including CE/Plus differences,
  installation, firewall, NAT, routing, VPNs, services, packages,
  virtualization, diagnostics, recipes, menu guide, development, and licensing.

Use the
[official hosted PDF](https://docs.netgate.com/manuals/pfsense/en/latest/the-pfsense-documentation.pdf)
as the reproducible source. Do not commit or redistribute the attached binary.
The PDF is a point-in-time snapshot, so prefer the live page when it differs.

## pfSense CE practical guide

[Getting Started with pfSense CE: A Practical Guide](https://blog.bogdancaraman.com/getting-started-with-pfsense-ce-a-practical-guide/)
by Bogdan Caraman was last updated 2026-07-27. It provides a useful visual
walkthrough for acquiring the Netgate installer, selecting CE, planning a
small virtual machine, assigning interfaces, confirming destructive disk
selection, completing installation, and entering the initial setup wizard.

Treat this article as secondary practitioner guidance:

- verify every installer step and requirement against current Netgate pages;
- use it only when the observed installer screen and CE release match;
- never copy its VMware Workstation `VMnet` topology, DHCP WAN assumption,
  example LAN addressing, interface names, DNS choices, or sizing claims into
  the Dedibox ESXi plan;
- never replace the provider-confirmed failover `/32`, virtual MAC, non-local
  gateway, isolated LAN, or retained ESXi management design with the article's
  generic lab topology;
- never expose WebGUI or SSH on WAN or retain default credentials because an
  introductory walkthrough shows first-login behavior;
- treat disk selection and installation as R3 under the parent skill.

The article does not cover the provider-specific secondary-IP topology or
authorize pfSense to act as a general SSH bastion. For private guest access,
load [`private-guest-access-via-pfsense.md`](private-guest-access-via-pfsense.md)
and the current Netgate VPN, firewall, NAT, routing, and multi-WAN pages.

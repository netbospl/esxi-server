#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
reference="$repo_root/references/dedibox-dual-public-router-vm.md"
profile="$repo_root/profiles/example-dual-public-router.md"
template="$repo_root/templates/dual-public-router-plan.md"
guest_access="$repo_root/references/private-guest-access-via-pfsense.md"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

for file in "$reference" "$profile" "$template"; do
  [[ -f $file ]] || fail "missing dual-public artifact: $file"
done

[[ -f $guest_access ]] || fail "missing private guest access reference"

for token in \
  '<ESXI_MANAGEMENT_IPV4>' \
  '<FAILOVER_IPV4>' \
  '<PROVIDER_GATEWAY>' \
  '<PROVIDER_VMAC>' \
  '<ROUTER_FQDN>'; do
  grep -Fq "$token" "$reference" || fail "reference missing placeholder: $token"
  grep -Fq "$token" "$profile" || fail "profile missing placeholder: $token"
done

grep -Fq 'Use non-local gateway' "$reference" ||
  fail 'non-local pfSense gateway gate is missing'
grep -Fq 'Never calculate' "$reference" ||
  fail 'failover gateway derivation guard is missing'
grep -Fq 'official installer ISO' "$reference" ||
  fail 'trusted pfSense installation path is missing'
grep -Fq 'Configuration Restore' "$reference" ||
  fail 'supported config.xml restore path is missing'
grep -Fq 'third-party preconfigured pfSense image' "$reference" ||
  fail 'untrusted preconfigured image guard is missing'
grep -Fq 'never be powered on alongside the original VM' "$reference" ||
  fail 'duplicate recovery-VM ownership guard is missing'
grep -Fq 'Never assign' "$reference" ||
  fail 'VMkernel ownership invariant is missing'
grep -Fq 'to a VMkernel adapter' "$reference" ||
  fail 'VMkernel ownership invariant is missing'
grep -Fq 'Promiscuous Mode, MAC Address Changes, and Forged Transmits' "$reference" ||
  fail 'strict WAN port-group policy is missing'
grep -Fq 'LAN vSwitch free of physical uplinks' "$reference" ||
  fail 'isolated LAN invariant is missing'
grep -Fq 'does not filter the retained public' "$reference" ||
  fail 'public ESXi residual-risk warning is missing'
grep -Fiq 'generic provider documentation as a reference candidate only' "$reference" ||
  fail 'provider source-authority guard is missing'
grep -Fq 'forward and reverse DNS' "$reference" ||
  fail 'forward/reverse DNS identity gate is missing'
grep -Fq 'DNS only' "$reference" ||
  fail 'Cloudflare DNS-only gate is missing'
grep -Fq 'does not assign an address' "$reference" ||
  fail 'DNS-versus-routing boundary is missing'
grep -Fq 'Linux guest guidance only' "$reference" ||
  fail 'provider Linux IPv6 guidance boundary is missing'
grep -Fq 'WebGUI and SSH closed on WAN' "$reference" ||
  fail 'WAN management exposure guard is missing'
grep -Fq 'Do not use the pfSense shell as a general-purpose SSH bastion' "$guest_access" ||
  fail 'pfSense bastion boundary is missing'
grep -Fq 'WireGuard or OpenVPN on pfSense' "$guest_access" ||
  fail 'VPN-first private guest path is missing'
grep -Fq 'A pfSense change approval does not authorize an ESXi or guest change' "$guest_access" ||
  fail 'cross-target approval boundary is missing'
grep -Fq 'StrictHostKeyChecking yes' "$guest_access" ||
  fail 'nested SSH host-key policy is missing'
grep -Fq 'GUEST_KNOWN_HOSTS' "$guest_access" ||
  fail 'dedicated guest known-hosts contract is missing'

for file in "$reference" "$profile" "$template" "$guest_access"; do
  if grep -Eq '(^|[^0-9])([0-9]{1,3}\.){3}[0-9]{1,3}([^0-9]|$)' "$file"; then
    fail "concrete IPv4 address found in sanitized artifact: $file"
  fi
  if grep -Eiq '(^|[^[:xdigit:]])([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}([^[:xdigit:]]|$)' "$file"; then
    fail "concrete MAC address found in sanitized artifact: $file"
  fi
done

grep -Fq 'dedibox-dual-public-router-vm.md' "$repo_root/SKILL.md" ||
  fail 'task router does not link the dual-public reference'
grep -Fq 'single-public-ip-router-migration.md' "$reference" ||
  fail 'variant-selection guard is missing'

if git -C "$repo_root" ls-files 'profiles/*.local.md' | grep -q .; then
  fail 'a populated local profile is tracked'
fi

printf 'PASS: dual-public ownership, source authority, isolation, and sanitization policy\n'

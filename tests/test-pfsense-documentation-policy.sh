#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source_map="$repo_root/references/pfsense-documentation-sources.md"
guest_access="$repo_root/references/private-guest-access-via-pfsense.md"
router_runbook="$repo_root/references/dedibox-dual-public-router-vm.md"
example_profile="$repo_root/profiles/example-dual-public-router.md"
router_plan="$repo_root/templates/dual-public-router-plan.md"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -f $source_map ]] || fail 'missing pfSense documentation source map'

for token in \
  'Netgate pfSense documentation index' \
  'the-pfsense-documentation.pdf' \
  'generated: 2026-07-16' \
  'Getting Started with pfSense CE: A Practical Guide' \
  'last updated 2026-07-27' \
  'Documentation can establish syntax and vendor guidance' \
  'current router state or grant R1-R3 approval' \
  'never copy its VMware Workstation' \
  'provider-confirmed failover `/32`' \
  'Do not commit or redistribute the attached binary'; do
  grep -Fq "$token" "$source_map" ||
    fail "source policy missing required boundary: $token"
done

for path in \
  '/general/index.html' \
  '/install/index.html' \
  '/backup/index.html' \
  '/interfaces/index.html' \
  '/firewall/index.html' \
  '/nat/index.html' \
  '/routing/index.html' \
  '/multiwan/index.html' \
  '/vpn/index.html' \
  '/vpn/openvpn/index.html' \
  '/vpn/wireguard/index.html' \
  '/services/dhcp/index.html' \
  '/services/dns/index.html' \
  '/certificates/index.html' \
  '/packages/index.html' \
  '/virtualization/index.html' \
  '/diagnostics/index.html' \
  '/troubleshooting/index.html' \
  '/recipes/index.html' \
  '/menuguide/index.html' \
  '/references/index.html' \
  '/licensing/index.html'; do
  grep -Fq "$path" "$source_map" ||
    fail "complete Netgate map missing category: $path"
done

grep -Fq 'pfsense-documentation-sources.md' "$repo_root/SKILL.md" ||
  fail 'task router does not load the pfSense documentation source map'
grep -Fq 'pfsense-documentation-sources.md' "$repo_root/AGENTS.md" ||
  fail 'agent instructions do not load the pfSense documentation source map'
grep -Fq 'pfsense-documentation-sources.md' "$guest_access" ||
  fail 'private guest access does not load the source map'
grep -Fq 'pfsense-documentation-sources.md' "$router_runbook" ||
  fail 'dual-public runbook does not load the source map'
grep -Fq 'Do not use the pfSense shell as a general-purpose SSH bastion' "$guest_access" ||
  fail 'pfSense bastion boundary regressed'
grep -Fq '| Router edition | `pfSense CE` |' "$example_profile" ||
  fail 'sanitized profile does not record the pfSense CE edition'
grep -Fq '<PFSENSE_CE_RELEASE>' "$example_profile" ||
  fail 'sanitized profile does not record the observed pfSense CE release'
grep -Fq 'Relevant installed package versions and timestamp' "$router_plan" ||
  fail 'router plan does not gate documentation against package versions'

if git -C "$repo_root" ls-files '*.pdf' | grep -q .; then
  fail 'vendored PDF found; keep external documentation as a referenced source'
fi

printf 'PASS: complete pfSense source routing and CE guidance boundaries\n'

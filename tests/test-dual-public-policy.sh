#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
reference="$repo_root/references/dedibox-dual-public-router-vm.md"
profile="$repo_root/profiles/example-dual-public-router.md"
template="$repo_root/templates/dual-public-router-plan.md"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

for file in "$reference" "$profile" "$template"; do
  [[ -f $file ]] || fail "missing dual-public artifact: $file"
done

for token in \
  '<ESXI_MANAGEMENT_IPV4>' \
  '<FAILOVER_IPV4>' \
  '<PROVIDER_GATEWAY>' \
  '<PROVIDER_VMAC>'; do
  grep -Fq "$token" "$reference" || fail "reference missing placeholder: $token"
  grep -Fq "$token" "$profile" || fail "profile missing placeholder: $token"
done

grep -Fq 'Use non-local gateway' "$reference" ||
  fail 'non-local pfSense gateway gate is missing'
grep -Fq 'Never assign `<FAILOVER_IPV4>` to a VMkernel adapter' "$reference" ||
  fail 'VMkernel ownership invariant is missing'
grep -Fq 'Promiscuous Mode, MAC Address Changes, and Forged Transmits' "$reference" ||
  fail 'strict WAN port-group policy is missing'
grep -Fq 'LAN vSwitch free of physical uplinks' "$reference" ||
  fail 'isolated LAN invariant is missing'
grep -Fq 'does not filter the retained public' "$reference" ||
  fail 'public ESXi residual-risk warning is missing'
grep -Fiq 'generic provider documentation as a reference candidate only' "$reference" ||
  fail 'provider source-authority guard is missing'

for file in "$reference" "$profile" "$template"; do
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

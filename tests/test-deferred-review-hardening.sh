#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
model_profile="$repo_root/skills/nemotron-3-ultra/model-profile.md"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -f $model_profile ]] || fail 'missing shared Nemotron model profile'
grep -Fq 'active Hermes/provider context limit as authoritative' "$model_profile" ||
  fail 'runtime profile does not defer to the active context limit'
grep -Fq 'progressive disclosure' "$model_profile" ||
  fail 'runtime profile does not enforce progressive disclosure'

if rg -n '128K tokens|64K tokens|Up to 1M tokens|source <\(grep|--noSSLVerify|ESXI_PASS.*ovftool|snapshot\.revert .* 0$|vmsvc/device\.(config|connect)|createdummyvm' \
  "$repo_root/SKILL.md" "$repo_root/skills/nemotron-3-ultra"; then
  fail 'stale context sizing or deferred unsafe/inaccurate pattern remains'
fi

for skill in "$repo_root"/skills/nemotron-3-ultra/*/SKILL.md; do
  grep -Fq '../model-profile.md' "$skill" ||
    fail "Nemotron child does not load shared model profile: $skill"
done

"$repo_root/scripts/validate-model-overlays.sh" --repo "$repo_root"
"$repo_root/scripts/validate-operational-docs.sh" "$repo_root"

printf 'PASS: token-aware Nemotron consistency and deferred safety hardening\n'

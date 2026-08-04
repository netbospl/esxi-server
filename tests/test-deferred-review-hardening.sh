#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
backup_skill="$repo_root/skills/nemotron-3-ultra/backup-restore/SKILL.md"
guest_skill="$repo_root/skills/nemotron-3-ultra/guest-autoinstall/SKILL.md"
model_profile="$repo_root/skills/nemotron-3-ultra/model-profile.md"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -f $model_profile ]] || fail 'missing shared Nemotron model profile'
grep -Fq 'Up to 1M tokens' "$model_profile" ||
  fail 'official Nemotron model ceiling is not recorded'
grep -Fq '64K tokens' "$model_profile" ||
  fail 'Hermes deployment context is not distinguished from model ceiling'

if rg -n '128K tokens|source <\(grep|--noSSLVerify|ESXI_PASS.*ovftool|snapshot\.revert .* 0$|vmsvc/device\.(config|connect)|createdummyvm' \
  "$repo_root/SKILL.md" "$repo_root/skills/nemotron-3-ultra"; then
  fail 'deferred unsafe or inaccurate pattern remains'
fi

for skill in "$repo_root"/skills/nemotron-3-ultra/*/SKILL.md; do
  grep -Fq '../model-profile.md' "$skill" ||
    fail "Nemotron child does not load shared model profile: $skill"
done

grep -Fq 'prompt for the password' "$backup_skill" ||
  fail 'OVF export no longer requires interactive/protected credential input'
grep -Fq 'SNAPSHOT_ID' "$backup_skill" ||
  fail 'snapshot revert does not require an observed snapshot ID'
grep -Fq 'Do not execute placeholder commands' "$guest_skill" ||
  fail 'guest deployment does not reject placeholder commands'

printf 'PASS: deferred review safety and Nemotron consistency hardening\n'

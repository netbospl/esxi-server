#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
validator="$repo_root/scripts/validate-operational-docs.sh"
fixtures="$repo_root/tests/fixtures/operational-docs"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -x $validator ]] || fail 'operational documentation validator is missing or not executable'
"$validator" "$repo_root"
"$validator" --file "$fixtures/valid.md"
for invalid in password-argv.sh session-argv.sh vcenter-probe.sh misplaced-formatter.md raw-netrc.sh; do
  if "$validator" --file "$fixtures/$invalid" >/dev/null 2>&1; then
    fail "unsafe operational fixture was accepted: $invalid"
  fi
done

[[ -f $repo_root/references/patch-upgrade.md ]] || fail 'patch/upgrade reference is missing'
grep -Fq '| Host patch/upgrade |' "$repo_root/SKILL.md" || fail 'task router omits host patch/upgrade'
grep -Fq 'knowledge.broadcom.com/external/article/341649' \
  "$repo_root/references/certificates-letsencrypt.md" || fail 'certificate reference lacks the authoritative standalone source'
grep -Fq 'developer.broadcom.com/tools/open-virtualization-format-ovf-tool' \
  "$repo_root/references/vm-import-export.md" || fail 'VM import/export lacks the authoritative OVF Tool source'

printf 'PASS: operational documentation safety policy\n'

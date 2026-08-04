#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
validator="$repo_root/scripts/validate-model-overlays.sh"
fixtures="$repo_root/tests/fixtures/model-overlays"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -x $validator ]] || fail 'model overlay validator is missing or not executable'
[[ -f $repo_root/skills/model-overlays/CONTRACT.md ]] || fail 'overlay contract is missing'
[[ -f $repo_root/skills/model-overlays/harnesses/hermes.md ]] || fail 'Hermes adapter is missing'
[[ -f $repo_root/skills/incident-triage/SKILL.md ]] || fail 'canonical incident-triage skill is missing'

"$validator" --repo "$repo_root"
"$validator" --overlay "$fixtures/valid/SKILL.md"

if "$validator" --overlay "$fixtures/missing-parent/SKILL.md" >/dev/null 2>&1; then
  fail 'missing-parent fixture was accepted'
fi
if "$validator" --overlay "$fixtures/duplicated-command/SKILL.md" >/dev/null 2>&1; then
  fail 'duplicated-command fixture was accepted'
fi
if "$validator" --overlay "$fixtures/reversed-order/SKILL.md" >/dev/null 2>&1; then
  fail 'reversed-load-order fixture was accepted'
fi

printf 'PASS: model overlay contract and fixtures\n'

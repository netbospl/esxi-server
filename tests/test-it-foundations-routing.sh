#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
reference="$repo_root/references/it-foundations-for-esxi.md"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -f $reference ]] || fail "missing IT foundations reference"

for token in \
  'Hermes context discipline' \
  'FACTS:' \
  'HYPOTHESES:' \
  'NEXT R0 CHECK:' \
  'CHANGE GATE:' \
  'Layer map' \
  'Networking foundations' \
  'Compute, storage, and virtualization foundations' \
  'Security foundations' \
  'Troubleshooting method' \
  'does not establish ESXi command compatibility' \
  'does not authorize a state change'; do
  grep -Fq "$token" "$reference" ||
    fail "IT foundations reference missing guard or section: $token"
done

for file in SKILL.md README.md docs/index.md references/troubleshooting.md; do
  grep -Fq 'it-foundations-for-esxi.md' "$repo_root/$file" ||
    fail "$file does not route to the IT foundations reference"
done

grep -Fq 'Cross-layer diagnosis' "$repo_root/SKILL.md" ||
  fail 'SKILL task router is missing the cross-layer route'
grep -Fq 'then one task module only if needed' "$repo_root/SKILL.md" ||
  fail 'SKILL task router does not preserve progressive disclosure'

if grep -Eiq '(passing score|exam price|retirement date).*[0-9]' "$reference"; then
  fail 'volatile certification metadata leaked into operational guidance'
fi

printf 'PASS: IT foundations are routed with progressive disclosure and ESXi safety boundaries\n'

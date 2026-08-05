#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
validator="$repo_root/scripts/validate-documentation-inventory.sh"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

bash "$validator" >"$work_dir/valid.out" || fail 'committed inventory did not validate'
grep -Fq 'PASS:' "$work_dir/valid.out" || fail 'valid inventory run did not report PASS'

grep -v '^references/source-verification-policy.md$' "$repo_root/docs/inventory.txt" >"$work_dir/missing.txt"
set +e
bash "$validator" "$work_dir/missing.txt" >"$work_dir/missing.out" 2>&1
status=$?
set -e
[[ $status -ne 0 ]] || fail 'validator accepted a missing tracked reference'
grep -Fq 'does not match tracked repository surfaces' "$work_dir/missing.out" || fail 'missing inventory rejection was not specific'

cp "$repo_root/docs/inventory.txt" "$work_dir/extra.txt"
printf '%s\n' 'references/does-not-exist.md' >>"$work_dir/extra.txt"
set +e
bash "$validator" "$work_dir/extra.txt" >"$work_dir/extra.out" 2>&1
status=$?
set -e
[[ $status -ne 0 ]] || fail 'validator accepted an untracked inventory entry'
grep -Fq 'does not match tracked repository surfaces' "$work_dir/extra.out" || fail 'extra inventory rejection was not specific'

printf 'PASS: documentation inventory regression tests\n'

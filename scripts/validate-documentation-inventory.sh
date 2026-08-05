#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
inventory=${1:-"$repo_root/docs/inventory.txt"}
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -f $inventory ]] || fail "inventory file not found: $inventory"

git -C "$repo_root" ls-files | awk '
  /^evals\/evals\.json$/ ||
  /^examples\/guest-autoinstall\/packer\/(ubuntu|windows)-vsphere-iso\.pkr\.hcl$/ ||
  /^references\/[^/]+\.md$/ ||
  /^scripts\/[^/]+\.sh$/ ||
  /^skills\/(incident-triage|private-guest-shell|stable-ssh-shell)\/SKILL\.md$/ ||
  /^skills\/nemotron-3-ultra\/[^/]+\/SKILL\.md$/ ||
  /^tests\/test-[^/]+\.sh$/ { print }
' | LC_ALL=C sort -u >"$work_dir/expected"

awk 'NF && $1 !~ /^#/ { print $0 }' "$inventory" | LC_ALL=C sort -u >"$work_dir/actual"

if ! diff -u "$work_dir/expected" "$work_dir/actual" >"$work_dir/diff"; then
  cat "$work_dir/diff" >&2
  fail 'docs/inventory.txt does not match tracked repository surfaces'
fi

while IFS= read -r path; do
  [[ -e "$repo_root/$path" ]] || fail "inventory path does not exist: $path"
done <"$work_dir/actual"

while IFS= read -r reference; do
  grep -Fq "../$reference" "$repo_root/docs/index.md" || fail "docs/index.md does not link reference: $reference"
done < <(git -C "$repo_root" ls-files 'references/*.md' | LC_ALL=C sort)

for path in \
  'skills/incident-triage/SKILL.md' \
  'skills/private-guest-shell/SKILL.md' \
  'skills/stable-ssh-shell/SKILL.md'; do
  grep -Fq "../$path" "$repo_root/docs/index.md" || fail "docs/index.md does not link canonical child skill: $path"
done

grep -Fq 'inventory.txt' "$repo_root/docs/index.md" || fail 'docs/index.md does not link docs/inventory.txt'
grep -Fq 'status: implemented' "$repo_root/PLAN_STABLE_SSH_SHELL.md" || fail 'stable-shell plan is not marked implemented'
grep -Fq 'status: completed' "$repo_root/SOURCE_REVIEW_STABLE_SSH_SHELL.md" || fail 'stable-shell source review is not marked completed'

printf 'PASS: documentation inventory and historical status\n'

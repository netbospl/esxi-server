#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_words_at_most() {
  local path=$1 limit=$2 words
  words=$(wc -w <"$repo_root/$path")
  (( words <= limit )) || fail "$path exceeds ${limit}-word runtime budget ($words)"
}

assert_words_at_most SKILL.md 900
assert_words_at_most AGENTS.md 250
assert_words_at_most skills/nemotron-3-ultra/model-profile.md 150
assert_words_at_most references/ssh-esxcli.md 500

grep -Fq 'Do not preload fallback transports' "$repo_root/SKILL.md" ||
  fail 'root skill must forbid fallback preloading'
grep -Fq 'should not be loaded during normal task execution' "$repo_root/SKILL.md" ||
  fail 'root skill must keep overlay contract out of runtime context'

for module in ssh-discovery ssh-vm-lifecycle ssh-snapshots ssh-storage ssh-networking; do
  grep -Fq "references/${module}.md" "$repo_root/SKILL.md" ||
    fail "root task router does not reference ${module}.md"
done

printf 'PASS: runtime context budgets and progressive-disclosure routing\n'

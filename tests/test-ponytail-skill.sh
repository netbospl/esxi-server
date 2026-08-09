#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
skill="$repo_root/skills/ponytail/SKILL.md"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -f $skill ]] || fail 'Ponytail skill is missing'
grep -Fqx 'name: ponytail' "$skill" || fail 'Ponytail skill name is missing'
grep -Fq 'description: Use when implementing, reviewing, or scoping code changes' "$skill" || fail 'Ponytail skill trigger is missing'
grep -Fq 'Does this need to exist at all?' "$skill" || fail 'YAGNI rung is missing'
grep -Fq 'Already in this codebase?' "$skill" || fail 'reuse rung is missing'
grep -Fq 'Bug fix = root cause, not symptom.' "$skill" || fail 'root-cause rule is missing'
grep -Fq '# ponytail:' "$skill" || fail 'simplification marker is missing'
grep -Fq 'Code first. Then at most three short lines.' "$skill" || fail 'output constraint is missing'
grep -Fq 'Review, summarize, commit, and push skill self-improvements.' "$skill" || fail 'skill improvement delivery rule is missing'

printf 'PASS: Ponytail skill contract\n'

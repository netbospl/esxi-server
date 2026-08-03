#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
skill_dir="$repo_root/skills/stable-ssh-shell"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

grep -Fq 'never install tmux or persistence tooling on ESXi' \
  "$skill_dir/references/esxi-hermes-compatibility.md" || fail 'ESXi install prohibition missing'
grep -Fq 'prefer Mode A' "$skill_dir/references/esxi-hermes-compatibility.md" || fail 'ESXi one-shot fallback missing'
grep -Fq 'backend=local' \
  "$skill_dir/scripts/detect-remote-capabilities.sh" || fail 'Hermes local backend fallback missing'
grep -Fq 'StrictHostKeyChecking=yes' "$skill_dir/examples/esxi-one-shot.md" || fail 'strict ESXi trust missing'
grep -Fq 'ForwardAgent=no' "$skill_dir/examples/esxi-one-shot.md" || fail 'ESXi agent forwarding guard missing'

if rg -n 'apt(-get)? .*install.*tmux|yum .*install.*tmux|dnf .*install.*tmux|apk .*add.*tmux' \
  "$skill_dir"; then
  fail 'tmux installation command found in restricted-target skill'
fi

printf 'PASS: restricted ESXi fallback and no-install policy\n'

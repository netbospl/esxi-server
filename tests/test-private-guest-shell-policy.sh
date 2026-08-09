#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
guest_skill="$repo_root/skills/private-guest-shell/SKILL.md"
parent_skill="$repo_root/SKILL.md"
nemotron_shell="$repo_root/skills/nemotron-3-ultra/stable-ssh-shell/SKILL.md"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

[[ -f $guest_skill ]] || fail 'missing private-guest-shell skill'

for token in \
  'vpn-direct' \
  'dedicated-jump' \
  'direct-recovery' \
  'ExitOnForwardFailure=yes' \
  'ForwardAgent=no' \
  'StrictHostKeyChecking=yes' \
  'stable-ssh-shell/SKILL.md' \
  'Do not use the pfSense shell' \
  'current handshake' \
  'exact route' \
  'independently trusted' \
  'removes access'; do
  grep -Fq "$token" "$guest_skill" ||
    fail "private guest shell missing boundary: $token"
done

grep -Fq 'skills/private-guest-shell/SKILL.md' "$parent_skill" ||
  fail 'root task router does not load private-guest-shell'

if grep -Fq 'Linux jump host / pfSense / guest VM' "$nemotron_shell"; then
  fail 'Nemotron routing still treats pfSense as a persistent-shell target'
fi

printf 'PASS: private guest shell path, trust, and pfSense boundaries\n'

#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$repo_root/skills/stable-ssh-shell/scripts/stable-ssh-session.sh"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/bin" "$work_dir/runtime"
touch "$work_dir/known_hosts" "$work_dir/key"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

cat >"$work_dir/bin/ssh" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${MOCK_LOG:?}"
[[ ${MOCK_FAIL:-0} == 0 ]] || exit 255
exit 0
MOCK
chmod +x "$work_dir/bin/ssh"

common=(--host mock-host --known-hosts "$work_dir/known_hosts" --identity "$work_dir/key")
for action in transport-start transport-check transport-stop; do
  env PATH="$work_dir/bin:$PATH" XDG_RUNTIME_DIR="$work_dir/runtime" MOCK_LOG="$work_dir/log" \
    "$script" "${common[@]}" "$action" >"$work_dir/$action.out"
  grep -Fq 'status=completed' "$work_dir/$action.out" || fail "$action did not complete"
done
grep -Fq 'StrictHostKeyChecking=yes' "$work_dir/log" || fail 'strict host checking missing'
grep -Fq "UserKnownHostsFile=$work_dir/known_hosts" "$work_dir/log" || fail 'dedicated known-hosts missing'
grep -Fq 'ForwardAgent=no' "$work_dir/log" || fail 'agent forwarding was not disabled'
grep -Fq 'ControlMaster=yes' "$work_dir/log" || fail 'multiplex start missing'
grep -Fq -- '-O check' "$work_dir/log" || fail 'control check missing'
grep -Fq -- '-O exit' "$work_dir/log" || fail 'control exit missing'
grep -Fq -- '-T' "$work_dir/log" || fail 'non-PTY transport flag missing'

set +e
env PATH="$work_dir/bin:$PATH" XDG_RUNTIME_DIR="$work_dir/runtime" MOCK_LOG="$work_dir/log" MOCK_FAIL=1 \
  "$script" "${common[@]}" transport-check >"$work_dir/fail.out"
rc=$?
set -e
[[ $rc -eq 20 ]] || fail 'failed control check not classified'
grep -Fq 'status=transport_lost' "$work_dir/fail.out" || fail 'transport failure status missing'

if rg -n 'StrictHostKeyChecking[ =]+no|UserKnownHostsFile[ =]+/dev/null|ForwardAgent[ =]+yes|RequestTTY[ =]+force' \
  "$repo_root/skills/stable-ssh-shell" --glob '!upstream-sources.md' | rg -v 'Never add|Never use|these to generic'; then
  fail 'unsafe SSH default found'
fi

printf 'PASS: stable SSH strict transport and control lifecycle\n'

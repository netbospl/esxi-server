#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$repo_root/skills/stable-ssh-shell/scripts/stable-ssh-session.sh"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/bin" "$work_dir/runtime"
touch "$work_dir/known_hosts"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

cat >"$work_dir/bin/ssh" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${MOCK_LOG:?}"
command_line=${*: -1}
if [[ $command_line == *'bash -s --'* ]]; then
  cat >/dev/null
  printf '{"schema_version":"1","state":"completed","command_id":"mock","exit_code":0}\n'
  exit 0
fi
if [[ ${MOCK_MISSING:-0} == 1 && $command_line == *has-session* ]]; then exit 1; fi
if [[ $command_line == *display-message* ]]; then printf '0\n'; fi
if [[ $command_line == *capture-pane* ]]; then printf 'mock pane output\n'; fi
exit 0
MOCK
chmod +x "$work_dir/bin/ssh"

common=(--host mock-host --known-hosts "$work_dir/known_hosts" --session stable-mock-task)
for action in session-start session-status session-capture session-stop; do
  env PATH="$work_dir/bin:$PATH" XDG_RUNTIME_DIR="$work_dir/runtime" MOCK_LOG="$work_dir/log" \
    "$script" "${common[@]}" "$action" >"$work_dir/$action.out"
done
env PATH="$work_dir/bin:$PATH" XDG_RUNTIME_DIR="$work_dir/runtime" MOCK_LOG="$work_dir/log" \
  "$script" "${common[@]}" --command 'printf test' session-exec >"$work_dir/session-exec.out"
grep -Fq '"state":"completed"' "$work_dir/session-exec.out" || fail 'session-exec result missing'
grep -Fq 'new-session -d -s' "$work_dir/log" || fail 'detached session creation missing'
grep -Fq 'stable-mock-task:0.0' "$work_dir/log" || fail 'exact default pane missing'
grep -Fq 'capture-pane -p -J' "$work_dir/log" || fail 'pane capture missing'
grep -Fq 'bash -s -- --target' "$work_dir/log" || fail 'remote marker helper was not streamed'
grep -Fq 'kill-session -t' "$work_dir/log" || fail 'exact session cleanup missing'
if grep -Fq 'kill-server' "$work_dir/log"; then fail 'shared tmux server cleanup is forbidden'; fi

set +e
env PATH="$work_dir/bin:$PATH" XDG_RUNTIME_DIR="$work_dir/runtime" MOCK_LOG="$work_dir/log" MOCK_MISSING=1 \
  "$script" "${common[@]}" session-status >"$work_dir/missing.out"
rc=$?
set -e
[[ $rc -eq 21 ]] || fail 'missing session exit mismatch'
grep -Fq 'status=session_missing' "$work_dir/missing.out" || fail 'missing session status absent'

printf 'PASS: deterministic stable SSH session lifecycle\n'

#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
exec_script="$repo_root/skills/stable-ssh-shell/scripts/tmux-command-exec.sh"
wait_script="$repo_root/skills/stable-ssh-shell/scripts/wait-for-pane-text.sh"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/bin"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

cat >"$work_dir/bin/tmux" <<'MOCK'
#!/usr/bin/env bash
case ${MOCK_MODE:-timeout}:$1 in
  missing:has-session) exit 1 ;;
  *:has-session) exit 0 ;;
  dead:display-message) printf '1\n' ;;
  *:display-message) printf '0\n' ;;
  unknown:capture-pane) exit 1 ;;
  *:capture-pane) printf 'no matching marker\n' ;;
  *:send-keys) exit 0 ;;
esac
MOCK
chmod +x "$work_dir/bin/tmux"

set +e
env PATH="$work_dir/bin:$PATH" MOCK_MODE=timeout STABLE_SSH_COMMAND_ID=timeout-1 \
  "$exec_script" --target stable-task:0.0 --command true --timeout 0 >"$work_dir/timeout.out"
rc=$?
set -e
[[ $rc -eq 124 ]] || fail 'timeout exit mismatch'
grep -Fq '"state":"timed_out"' "$work_dir/timeout.out" || fail 'timeout status missing'

set +e
env PATH="$work_dir/bin:$PATH" MOCK_MODE=missing STABLE_SSH_COMMAND_ID=missing-1 \
  "$exec_script" --target stable-task:0.0 --command true >"$work_dir/missing.out"
rc=$?
set -e
[[ $rc -eq 11 ]] || fail 'session missing exit mismatch'

set +e
env PATH="$work_dir/bin:$PATH" MOCK_MODE=dead STABLE_SSH_COMMAND_ID=dead-1 \
  "$exec_script" --target stable-task:0.0 --command true >"$work_dir/dead.out"
rc=$?
set -e
[[ $rc -eq 12 ]] || fail 'pane dead exit mismatch'

set +e
env PATH="$work_dir/bin:$PATH" MOCK_MODE=unknown STABLE_SSH_COMMAND_ID=unknown-1 \
  "$exec_script" --target stable-task:0.0 --command true >"$work_dir/unknown.out"
rc=$?
set -e
[[ $rc -eq 14 ]] || fail 'unknown-state exit mismatch'
grep -Fq '"state":"unknown_state"' "$work_dir/unknown.out" || fail 'unknown-state status missing'

set +e
env PATH="$work_dir/bin:$PATH" MOCK_MODE=missing \
  "$wait_script" --target stable-task:0.0 --text never >"$work_dir/wait-missing.out"
rc=$?
set -e
[[ $rc -eq 4 ]] || fail 'wait helper missing-session exit mismatch'

grep -Fq 'Never replay a command in `unknown_state`' \
  "$repo_root/skills/stable-ssh-shell/SKILL.md" || fail 'unknown-state replay guard missing'

printf 'PASS: timeout, missing session, pane death, and replay guard\n'

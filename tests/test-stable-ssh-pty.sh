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
case $1 in
  has-session) exit 0 ;;
  display-message) printf '0\n' ;;
  capture-pane)
    if [[ ${MOCK_VIEW:-prompt} == ready ]]; then
      printf 'service READY\n'
    elif [[ -e ${MOCK_STATE:?} ]]; then
      printf '__STABLE_SSH_START__:%s\nConfirm destructive action? [yes/no]\n' "${STABLE_SSH_COMMAND_ID:?}"
    else
      printf 'shell ready\n'
    fi
    ;;
  send-keys)
    if [[ ${*: -1} == Enter ]]; then : >"${MOCK_STATE:?}"; fi
    exit 0
    ;;
esac
MOCK
chmod +x "$work_dir/bin/tmux"

env PATH="$work_dir/bin:$PATH" MOCK_STATE="$work_dir/state" MOCK_VIEW=ready \
  "$wait_script" --target stable-task:0.0 --text READY --timeout 1 --interval 0.1

set +e
output=$(env PATH="$work_dir/bin:$PATH" MOCK_STATE="$work_dir/state" MOCK_VIEW=prompt \
  STABLE_SSH_COMMAND_ID=prompt-1 "$exec_script" --target stable-task:0.0 \
  --command 'dangerous-operation' --prompt-pattern 'Confirm destructive action?')
rc=$?
set -e
[[ $rc -eq 13 ]] || fail 'prompt detection exit mismatch'
grep -Fq '"state":"prompt_detected"' <<<"$output" || fail 'prompt status missing'

printf 'PASS: bounded PTY polling and prompt stop\n'

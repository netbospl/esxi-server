#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$repo_root/skills/stable-ssh-shell/scripts/tmux-command-exec.sh"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/bin"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

cat >"$work_dir/bin/tmux" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${MOCK_LOG:?}"
case $1 in
  has-session) exit 0 ;;
  display-message) printf '0\n' ;;
  send-keys)
    if [[ ${*: -1} == Enter ]]; then : >"${MOCK_STATE:?}"; fi
    exit 0
    ;;
  capture-pane)
    if [[ -e ${MOCK_STATE:?} ]]; then
      printf '__STABLE_SSH_START__:%s\nmock output\n__STABLE_SSH_DONE__:%s:%s\n' \
        "${STABLE_SSH_COMMAND_ID:?}" "$STABLE_SSH_COMMAND_ID" "${MOCK_REMOTE_EXIT:-0}"
    else
      printf 'ready\n'
    fi
    ;;
esac
MOCK
chmod +x "$work_dir/bin/tmux"

run_case() {
  local remote_exit=$1 expected_state=$2 expected_rc=$3
  rm -f "$work_dir/state" "$work_dir/log"
  set +e
  output=$(env PATH="$work_dir/bin:$PATH" MOCK_LOG="$work_dir/log" MOCK_STATE="$work_dir/state" \
    MOCK_REMOTE_EXIT="$remote_exit" STABLE_SSH_COMMAND_ID=cmd-123 \
    "$script" --target stable-task:0.0 --command 'printf test' --include-output)
  rc=$?
  set -e
  [[ $rc -eq $expected_rc ]] || fail "$expected_state exit mismatch"
  grep -Fq "\"state\":\"$expected_state\"" <<<"$output" || fail "$expected_state JSON missing"
  grep -Fq '"command_id":"cmd-123"' <<<"$output" || fail 'command identifier missing'
  grep -Fq 'send-keys -t stable-task:0.0 -l --' "$work_dir/log" || fail 'literal send missing'
  [[ $(grep -Fc 'send-keys' "$work_dir/log") -eq 2 ]] || fail 'text and Enter were not separate'
}

run_case 0 completed 0
run_case 7 failed 10

printf 'PASS: marker-based tmux command and exit protocol\n'

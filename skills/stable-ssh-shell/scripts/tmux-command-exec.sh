#!/usr/bin/env bash
set -euo pipefail

target=''
command_text=''
timeout=30
interval=1
lines=2000
prompt_pattern=''
include_output=0
tmux_bin=${STABLE_SSH_TMUX:-tmux}

usage() {
  cat <<'EOF'
Usage: tmux-command-exec.sh --target SESSION:WINDOW.PANE --command COMMAND [OPTIONS]

Send one marker-wrapped shell line to an exact tmux pane and return JSON.

Options:
  --target TARGET          Exact pane target (required).
  --command COMMAND        One complete shell line (required; no CR/LF).
  --timeout SECONDS        Integer deadline, default 30.
  --interval SECONDS       Poll interval, default 1.
  --lines COUNT            Captured history lines, default 2000.
  --prompt-pattern TEXT    Fixed text that yields prompt_detected.
  --include-output         Include bounded marker-delimited output in JSON.
  -h, --help               Show help.

Exit codes: 0 completed, 10 failed, 11 session missing, 12 pane dead,
13 prompt detected, 14 unknown state, 124 timed out.
EOF
}

while (($#)); do
  case $1 in
    --target) target=${2:?--target requires a value}; shift ;;
    --command) command_text=${2:?--command requires a value}; shift ;;
    --timeout) timeout=${2:?--timeout requires a value}; shift ;;
    --interval) interval=${2:?--interval requires a value}; shift ;;
    --lines) lines=${2:?--lines requires a value}; shift ;;
    --prompt-pattern) prompt_pattern=${2:?--prompt-pattern requires a value}; shift ;;
    --include-output) include_output=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'error: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

[[ -n $target && $target == *:*.* ]] || { printf 'error: exact --target is required\n' >&2; exit 2; }
[[ -n $command_text ]] || { printf 'error: non-empty --command is required\n' >&2; exit 2; }
[[ $command_text != *$'\n'* && $command_text != *$'\r'* ]] || { printf 'error: command must be one complete line\n' >&2; exit 2; }
[[ $timeout =~ ^[0-9]+$ ]] || { printf 'error: timeout must be a non-negative integer\n' >&2; exit 2; }
[[ $interval =~ ^([0-9]+)(\.[0-9]+)?$ ]] || { printf 'error: interval must be numeric\n' >&2; exit 2; }
[[ $lines =~ ^[1-9][0-9]*$ ]] || { printf 'error: lines must be a positive integer\n' >&2; exit 2; }
command -v "$tmux_bin" >/dev/null 2>&1 || { printf 'error: tmux is unavailable\n' >&2; exit 2; }

json_escape() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  printf '%s' "$value"
}

emit() {
  local state=$1 command_id=$2 exit_value=${3:-null} output=${4:-}
  printf '{"schema_version":"1","state":"%s","command_id":"%s","exit_code":%s' \
    "$state" "$(json_escape "$command_id")" "$exit_value"
  if (( include_output )); then
    printf ',"output":"%s"' "$(json_escape "$output")"
  fi
  printf '}\n'
}

shell_quote() {
  local value=$1
  printf "'%s'" "${value//\'/\'\\\'\'}"
}

session=${target%%:*}
command_id=${STABLE_SSH_COMMAND_ID:-}
if [[ -z $command_id ]]; then
  if [[ -r /dev/urandom ]] && command -v od >/dev/null 2>&1; then
    command_id=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')
  else
    command_id="$(date +%s)-$$-${RANDOM:-0}"
  fi
fi
[[ $command_id =~ ^[A-Za-z0-9._-]+$ ]] || { printf 'error: invalid command identifier\n' >&2; exit 2; }
start_marker="__STABLE_SSH_START__:$command_id"
done_prefix="__STABLE_SSH_DONE__:$command_id:"

if ! "$tmux_bin" has-session -t "$session" 2>/dev/null; then
  emit session_missing "$command_id"
  exit 11
fi
pane_dead=$($tmux_bin display-message -p -t "$target" '#{pane_dead}' 2>/dev/null) || {
  emit pane_dead "$command_id"
  exit 12
}
if [[ $pane_dead != 0 ]]; then
  emit pane_dead "$command_id"
  exit 12
fi

# Capture before submission so a controller has observed the exact pane first.
"$tmux_bin" capture-pane -p -J -t "$target" -S "-$lines" >/dev/null 2>&1 || {
  emit unknown_state "$command_id"
  exit 14
}

quoted_command=$(shell_quote "$command_text")
payload="printf '%s%s\\n' '__STABLE_SSH_' 'START__:$command_id'; eval $quoted_command; __stable_ssh_rc=\$?; printf '%s%s%s\\n' '__STABLE_SSH_' 'DONE__:$command_id:' \"\$__stable_ssh_rc\""
"$tmux_bin" send-keys -t "$target" -l -- "$payload" || {
  emit unknown_state "$command_id"
  exit 14
}
"$tmux_bin" send-keys -t "$target" Enter || {
  emit unknown_state "$command_id"
  exit 14
}

start=$SECONDS
while true; do
  if ! "$tmux_bin" has-session -t "$session" 2>/dev/null; then
    emit session_missing "$command_id"
    exit 11
  fi
  pane_dead=$($tmux_bin display-message -p -t "$target" '#{pane_dead}' 2>/dev/null) || {
    emit pane_dead "$command_id"
    exit 12
  }
  if [[ $pane_dead != 0 ]]; then
    emit pane_dead "$command_id"
    exit 12
  fi
  pane_text=$($tmux_bin capture-pane -p -J -t "$target" -S "-$lines" 2>/dev/null) || {
    emit unknown_state "$command_id"
    exit 14
  }
  done_line=$(grep -F -- "$done_prefix" <<<"$pane_text" | tail -n 1 || true)
  if [[ -n $done_line ]]; then
    remote_exit=${done_line##*"$done_prefix"}
    remote_exit=${remote_exit%%[^0-9]*}
    if [[ $remote_exit =~ ^[0-9]+$ ]]; then
      bounded_output=$(awk -v start="$start_marker" -v done="$done_prefix" '
        index($0, start) { seen=1; next }
        seen && index($0, done) { exit }
        seen { print }
      ' <<<"$pane_text")
      if (( remote_exit == 0 )); then
        emit completed "$command_id" "$remote_exit" "$bounded_output"
        exit 0
      fi
      emit failed "$command_id" "$remote_exit" "$bounded_output"
      exit 10
    fi
    emit unknown_state "$command_id"
    exit 14
  fi
  post_start=$(awk -v start="$start_marker" '
    index($0, start) { seen=1; next }
    seen { print }
  ' <<<"$pane_text")
  if [[ -n $prompt_pattern ]] && grep -Fq -- "$prompt_pattern" <<<"$post_start"; then
    emit prompt_detected "$command_id"
    exit 13
  fi
  if (( SECONDS - start >= timeout )); then
    emit timed_out "$command_id"
    exit 124
  fi
  sleep "$interval"
done

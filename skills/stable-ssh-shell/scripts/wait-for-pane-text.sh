#!/usr/bin/env bash
set -euo pipefail

target=''
text=''
timeout=15
interval=1
lines=1000
tmux_bin=${STABLE_SSH_TMUX:-tmux}

usage() {
  cat <<'EOF'
Usage: wait-for-pane-text.sh --target SESSION:WINDOW.PANE --text TEXT [OPTIONS]

Poll one exact tmux pane for a fixed string.

Options:
  --target TARGET    Exact tmux pane target (required).
  --text TEXT        Fixed string to find (required).
  --timeout SECONDS  Integer deadline, default 15.
  --interval SECONDS Poll interval, default 1.
  --lines COUNT      Captured history lines, default 1000.
  -h, --help         Show help.

Exit codes: 0 found, 4 session missing, 5 pane missing/dead, 124 timeout.
EOF
}

while (($#)); do
  case $1 in
    --target) target=${2:?--target requires a value}; shift ;;
    --text) text=${2:?--text requires a value}; shift ;;
    --timeout) timeout=${2:?--timeout requires a value}; shift ;;
    --interval) interval=${2:?--interval requires a value}; shift ;;
    --lines) lines=${2:?--lines requires a value}; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'error: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

[[ -n $target && $target == *:*.* ]] || { printf 'error: exact --target is required\n' >&2; exit 2; }
[[ -n $text ]] || { printf 'error: non-empty --text is required\n' >&2; exit 2; }
[[ $timeout =~ ^[0-9]+$ ]] || { printf 'error: timeout must be a non-negative integer\n' >&2; exit 2; }
[[ $interval =~ ^([0-9]+)(\.[0-9]+)?$ ]] || { printf 'error: interval must be numeric\n' >&2; exit 2; }
[[ $lines =~ ^[1-9][0-9]*$ ]] || { printf 'error: lines must be a positive integer\n' >&2; exit 2; }
command -v "$tmux_bin" >/dev/null 2>&1 || { printf 'error: tmux is unavailable\n' >&2; exit 2; }

session=${target%%:*}
start=$SECONDS
while true; do
  "$tmux_bin" has-session -t "$session" 2>/dev/null || exit 4
  pane_dead=$($tmux_bin display-message -p -t "$target" '#{pane_dead}' 2>/dev/null) || exit 5
  [[ $pane_dead == 0 ]] || exit 5
  pane_text=$($tmux_bin capture-pane -p -J -t "$target" -S "-$lines" 2>/dev/null) || exit 5
  grep -Fq -- "$text" <<<"$pane_text" && exit 0
  (( SECONDS - start < timeout )) || exit 124
  sleep "$interval"
done

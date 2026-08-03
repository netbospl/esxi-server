#!/usr/bin/env bash
set -euo pipefail
umask 077

host=''
known_hosts=''
identity=''
session=''
control_path=''
persist=300
connect_timeout=10
cwd=''
remote_shell='sh'
lines=1000
command_text=''
exec_timeout=30
interval=1
prompt_pattern=''
include_output=0

usage() {
  cat <<'EOF'
Usage: stable-ssh-session.sh --host ALIAS --known-hosts FILE [OPTIONS] ACTION

Actions:
  transport-check   Check only the configured OpenSSH control socket.
  transport-start   Start a task-owned multiplexed transport.
  transport-stop    Close only that transport.
  session-status    Inspect the exact tmux session and default pane.
  session-start     Create the exact detached session if absent.
  session-capture   Capture the exact default pane.
  session-exec      Run one marker-wrapped command in the exact default pane.
  session-stop      Kill only the exact session.

Options:
  --host ALIAS          SSH host/alias (required).
  --known-hosts FILE    Existing dedicated known-hosts file (required).
  --identity FILE       Optional dedicated identity file.
  --session NAME        Required for session actions.
  --control-path PATH   Default: private runtime directory/cm-%C.
  --persist SECONDS     ControlPersist duration, default 300.
  --connect-timeout N   Default 10.
  --cwd PATH            Initial remote session directory.
  --remote-shell PATH   Session shell, default sh.
  --lines COUNT         Capture history lines, default 1000.
  --command COMMAND     Required for session-exec; one complete line.
  --timeout SECONDS     session-exec deadline, default 30.
  --interval SECONDS    session-exec polling interval, default 1.
  --prompt-pattern TEXT Fixed prompt text that stops session-exec.
  --include-output      Include marker-delimited output in session-exec JSON.
  -h, --help            Show help.

This helper is intentionally non-interactive and never allocates a TTY.
EOF
}

action=''
while (($#)); do
  case $1 in
    --host) host=${2:?--host requires a value}; shift ;;
    --known-hosts) known_hosts=${2:?--known-hosts requires a value}; shift ;;
    --identity) identity=${2:?--identity requires a value}; shift ;;
    --session) session=${2:?--session requires a value}; shift ;;
    --control-path) control_path=${2:?--control-path requires a value}; shift ;;
    --persist) persist=${2:?--persist requires a value}; shift ;;
    --connect-timeout) connect_timeout=${2:?--connect-timeout requires a value}; shift ;;
    --cwd) cwd=${2:?--cwd requires a value}; shift ;;
    --remote-shell) remote_shell=${2:?--remote-shell requires a value}; shift ;;
    --lines) lines=${2:?--lines requires a value}; shift ;;
    --command) command_text=${2:?--command requires a value}; shift ;;
    --timeout) exec_timeout=${2:?--timeout requires a value}; shift ;;
    --interval) interval=${2:?--interval requires a value}; shift ;;
    --prompt-pattern) prompt_pattern=${2:?--prompt-pattern requires a value}; shift ;;
    --include-output) include_output=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    *) [[ -z $action ]] || { printf 'error: only one action is allowed\n' >&2; exit 2; }; action=$1 ;;
  esac
  shift
done

[[ -n $host && $host =~ ^[A-Za-z0-9][A-Za-z0-9._@:-]*$ ]] || { printf 'error: valid --host is required\n' >&2; exit 2; }
[[ -n $known_hosts && -f $known_hosts && ! -L $known_hosts ]] || { printf 'error: existing non-symlink --known-hosts file is required\n' >&2; exit 2; }
[[ -z $identity || ( -f $identity && ! -L $identity ) ]] || { printf 'error: identity must be a regular non-symlink file\n' >&2; exit 2; }
[[ $persist =~ ^[0-9]+$ && $connect_timeout =~ ^[1-9][0-9]*$ && $lines =~ ^[1-9][0-9]*$ && $exec_timeout =~ ^[0-9]+$ ]] || { printf 'error: invalid numeric option\n' >&2; exit 2; }
[[ $interval =~ ^([0-9]+)(\.[0-9]+)?$ ]] || { printf 'error: interval must be numeric\n' >&2; exit 2; }
[[ -n $action ]] || { printf 'error: action is required\n' >&2; usage >&2; exit 2; }
if [[ $action == session-* ]]; then
  [[ $session =~ ^[A-Za-z0-9._-]+$ ]] || { printf 'error: safe --session is required\n' >&2; exit 2; }
fi
[[ $remote_shell =~ ^[A-Za-z0-9_./-]+$ ]] || { printf 'error: invalid remote shell path\n' >&2; exit 2; }
[[ $cwd != *$'\n'* && $cwd != *$'\r'* ]] || { printf 'error: cwd cannot contain newlines\n' >&2; exit 2; }
if [[ $action == session-exec ]]; then
  [[ -n $command_text && $command_text != *$'\n'* && $command_text != *$'\r'* ]] || { printf 'error: session-exec requires one complete command line\n' >&2; exit 2; }
fi

runtime_dir=${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}
owned_dir="$runtime_dir/stable-ssh-shell-${UID:-$(id -u)}"
if [[ -e $owned_dir ]]; then
  [[ -d $owned_dir && ! -L $owned_dir ]] || { printf 'error: unsafe runtime path: %s\n' "$owned_dir" >&2; exit 2; }
else
  mkdir -m 700 "$owned_dir"
fi
chmod 700 "$owned_dir"
control_path=${control_path:-$owned_dir/cm-%C}
[[ $control_path == "$owned_dir"/* ]] || { printf 'error: control path must be inside %s\n' "$owned_dir" >&2; exit 2; }

ssh_opts=(
  -T
  -S "$control_path"
  -o "UserKnownHostsFile=$known_hosts"
  -o StrictHostKeyChecking=yes
  -o ForwardAgent=no
  -o BatchMode=yes
  -o "ConnectTimeout=$connect_timeout"
  -o ConnectionAttempts=1
  -o ServerAliveInterval=30
  -o ServerAliveCountMax=3
)
[[ -z $identity ]] || ssh_opts+=(-i "$identity" -o IdentitiesOnly=yes)
session_ssh_opts=("${ssh_opts[@]}" -o ControlMaster=auto -o "ControlPersist=$persist")

shell_quote() {
  local value=$1
  printf "'%s'" "${value//\'/\'\\\'\'}"
}

emit() {
  printf 'status=%s\n' "$1"
  printf 'layer=%s\n' "$2"
  [[ -z ${3:-} ]] || printf 'detail=%s\n' "$3"
}

run_remote() {
  local remote_command=$1 rc
  set +e
  ssh "${session_ssh_opts[@]}" "$host" -- "$remote_command"
  rc=$?
  set -e
  if (( rc == 255 )); then
    emit transport_lost transport 'SSH transport failed'
    return 255
  fi
  return "$rc"
}

case $action in
  transport-check)
    if ssh "${ssh_opts[@]}" -O check "$host" >/dev/null 2>&1; then
      emit completed transport 'control socket is live'
    else
      emit transport_lost transport 'control socket is missing or stale'
      exit 20
    fi
    ;;
  transport-start)
    if ssh "${ssh_opts[@]}" -MNf -o ControlMaster=yes -o "ControlPersist=$persist" "$host" \
      && ssh "${ssh_opts[@]}" -O check "$host" >/dev/null 2>&1; then
      emit completed transport 'control socket started'
    else
      emit transport_lost transport 'control socket could not be started'
      exit 20
    fi
    ;;
  transport-stop)
    if ssh "${ssh_opts[@]}" -O exit "$host" >/dev/null 2>&1; then
      emit completed transport 'control socket closed'
    else
      emit transport_lost transport 'control socket was not live'
      exit 20
    fi
    ;;
  session-status)
    quoted_session=$(shell_quote "$session")
    remote_command="tmux has-session -t $quoted_session 2>/dev/null && tmux display-message -p -t $quoted_session:0.0 '#{pane_dead}'"
    set +e
    pane_state=$(ssh "${session_ssh_opts[@]}" "$host" -- "$remote_command" 2>/dev/null)
    rc=$?
    set -e
    if (( rc == 255 )); then
      emit transport_lost transport 'SSH transport failed'
      exit 20
    elif (( rc != 0 )); then
      emit session_missing session 'exact session does not exist'
      exit 21
    elif [[ $pane_state == 1 ]]; then
      emit pane_dead session 'exact session pane is dead'
      exit 23
    elif [[ $pane_state == 0 ]]; then
      emit completed session 'exact session and pane are live'
    else
      emit unknown_state session 'unexpected pane state'
      exit 24
    fi
    ;;
  session-start)
    quoted_session=$(shell_quote "$session")
    quoted_shell=$(shell_quote "$remote_shell")
    if [[ -n $cwd ]]; then
      quoted_cwd=$(shell_quote "$cwd")
      create="tmux new-session -d -s $quoted_session -c $quoted_cwd $quoted_shell"
    else
      create="tmux new-session -d -s $quoted_session $quoted_shell"
    fi
    remote_command="command -v tmux >/dev/null 2>&1 && { tmux has-session -t $quoted_session 2>/dev/null || $create; }"
    if run_remote "$remote_command"; then
      emit completed session 'exact session is available'
    else
      rc=$?
      (( rc == 255 )) && exit 20
      emit unsupported session 'tmux unavailable or session creation failed'
      exit 22
    fi
    ;;
  session-capture)
    quoted_target=$(shell_quote "$session:0.0")
    if run_remote "tmux capture-pane -p -J -S -$lines -t $quoted_target"; then
      :
    else
      rc=$?
      (( rc == 255 )) && exit 20
      emit pane_dead session 'exact pane unavailable'
      exit 23
    fi
    ;;
  session-exec)
    helper_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    exec_helper="$helper_dir/tmux-command-exec.sh"
    [[ -r $exec_helper ]] || { printf 'error: tmux command helper is missing\n' >&2; exit 2; }
    quoted_target=$(shell_quote "$session:0.0")
    quoted_command=$(shell_quote "$command_text")
    remote_command="bash -s -- --target $quoted_target --command $quoted_command --timeout $exec_timeout --interval $interval --lines $lines"
    if [[ -n $prompt_pattern ]]; then
      remote_command+=" --prompt-pattern $(shell_quote "$prompt_pattern")"
    fi
    (( include_output )) && remote_command+=' --include-output'
    set +e
    ssh "${session_ssh_opts[@]}" "$host" -- "$remote_command" <"$exec_helper"
    rc=$?
    set -e
    if (( rc == 255 )); then
      emit transport_lost transport 'SSH transport failed during session-exec'
      exit 20
    fi
    exit "$rc"
    ;;
  session-stop)
    quoted_session=$(shell_quote "$session")
    if run_remote "tmux has-session -t $quoted_session 2>/dev/null && tmux kill-session -t $quoted_session"; then
      emit completed session 'exact session stopped'
    else
      rc=$?
      (( rc == 255 )) && exit 20
      emit session_missing session 'exact session was absent'
      exit 21
    fi
    ;;
  *) printf 'error: unknown action: %s\n' "$action" >&2; usage >&2; exit 2 ;;
esac

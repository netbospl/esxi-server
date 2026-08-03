#!/usr/bin/env bash
set -euo pipefail
umask 077

host=''
known_hosts=''
identity=''
connect_timeout=10

usage() {
  cat <<'EOF'
Usage: detect-remote-capabilities.sh --host ALIAS --known-hosts FILE [OPTIONS]

Run one bounded, non-invasive SSH probe and return a JSON mode report.

Options:
  --host ALIAS          SSH host or configured alias (required).
  --known-hosts FILE    Existing dedicated known-hosts file (required).
  --identity FILE       Optional dedicated identity file.
  --connect-timeout N   Positive integer, default 10.
  -h, --help            Show help.

The helper never accepts a host key, installs software, allocates a PTY, or
prints remote inventory. Exit 20 indicates transport/authentication failure.
EOF
}

while (($#)); do
  case $1 in
    --host) host=${2:?--host requires a value}; shift ;;
    --known-hosts) known_hosts=${2:?--known-hosts requires a value}; shift ;;
    --identity) identity=${2:?--identity requires a value}; shift ;;
    --connect-timeout) connect_timeout=${2:?--connect-timeout requires a value}; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'error: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

[[ -n $host && $host =~ ^[A-Za-z0-9][A-Za-z0-9._@:-]*$ ]] || { printf 'error: valid --host is required\n' >&2; exit 2; }
[[ -n $known_hosts && -f $known_hosts && ! -L $known_hosts ]] || { printf 'error: existing non-symlink --known-hosts file is required\n' >&2; exit 2; }
[[ -z $identity || ( -f $identity && ! -L $identity ) ]] || { printf 'error: identity must be a regular non-symlink file\n' >&2; exit 2; }
[[ $connect_timeout =~ ^[1-9][0-9]*$ ]] || { printf 'error: connect timeout must be positive\n' >&2; exit 2; }

ssh_opts=(
  -T
  -o RequestTTY=no
  -o "UserKnownHostsFile=$known_hosts"
  -o StrictHostKeyChecking=yes
  -o ForwardAgent=no
  -o BatchMode=yes
  -o "ConnectTimeout=$connect_timeout"
  -o ConnectionAttempts=1
)
[[ -z $identity ]] || ssh_opts+=(-i "$identity" -o IdentitiesOnly=yes)

probe='target=unknown
if command -v vmware >/dev/null 2>&1 || test -f /etc/vmware-release; then target=esxi
elif test -f /etc/os-release; then target=linux
elif command -v busybox >/dev/null 2>&1; then target=restricted
fi
shell=unknown
if command -v bash >/dev/null 2>&1; then shell=bash
elif command -v sh >/dev/null 2>&1; then shell=sh
elif command -v busybox >/dev/null 2>&1; then shell=busybox
fi
tmux=no; command -v tmux >/dev/null 2>&1 && tmux=yes
nohup=no; command -v nohup >/dev/null 2>&1 && nohup=yes
runtime=no; test -w "${TMPDIR:-/tmp}" && runtime=yes
pty=no; test -e /dev/ptmx && pty=yes
printf "target=%s\nshell=%s\ntmux=%s\nnohup=%s\nruntime=%s\npty=%s\n" "$target" "$shell" "$tmux" "$nohup" "$runtime" "$pty"'

set +e
probe_output=$(ssh "${ssh_opts[@]}" "$host" -- "$probe" 2>/dev/null)
rc=$?
set -e
if (( rc != 0 )); then
  printf '%s\n' '{"schema_version":"1","target_class":"unknown","transport":{"reachable":false,"host_key_verified":false,"batch_auth":false,"multiplexing":"unchecked"},"remote":{"shell":"unknown","tmux":"unchecked","writable_runtime_dir":false,"pty":"unchecked"},"hermes":{"builtin_ssh_compatible":false,"recommended_backend":"none"},"supported_modes":["E"],"recommended_mode":"E","limitations":["transport_or_authentication_failed"]}'
  exit 20
fi

value_for() {
  local key=$1
  awk -F= -v wanted="$key" '$1 == wanted { print substr($0, index($0, "=") + 1); exit }' <<<"$probe_output"
}

target=$(value_for target)
shell=$(value_for shell)
tmux=$(value_for tmux)
nohup=$(value_for nohup)
runtime=$(value_for runtime)
pty=$(value_for pty)
[[ $target =~ ^(linux|esxi|restricted|unknown)$ ]] || target=unknown
[[ $shell =~ ^(bash|sh|busybox|unknown)$ ]] || shell=unknown
[[ $tmux =~ ^(yes|no)$ ]] || tmux=no
[[ $nohup =~ ^(yes|no)$ ]] || nohup=no
[[ $runtime =~ ^(yes|no)$ ]] || runtime=no
[[ $pty =~ ^(yes|no)$ ]] || pty=no

tmux_status=missing
[[ $tmux == yes ]] && tmux_status=available
pty_status=unavailable
[[ $pty == yes ]] && pty_status=available
writable=false
[[ $runtime == yes ]] && writable=true
hermes_compatible=false
backend=local
modes='"A","E"'
recommended=A
limitations=()

if [[ $target == esxi || $target == restricted ]]; then
  limitations+=("restricted_remote")
elif [[ $shell == bash && $runtime == yes ]]; then
  hermes_compatible=true
  backend=ssh
fi
if [[ $target != esxi && $target != restricted && $tmux == yes && $runtime == yes ]]; then
  modes='"A","B"'
  [[ $pty == yes ]] && modes+=',"C"'
  [[ $nohup == yes ]] && modes+=',"D"'
  modes+=',"E"'
elif [[ $target != esxi && $target != restricted && $nohup == yes ]]; then
  modes='"A","D","E"'
fi
[[ $tmux == yes ]] || limitations+=("tmux_unavailable")
[[ $pty == yes ]] || limitations+=("pty_unavailable")
[[ $runtime == yes ]] || limitations+=("writable_runtime_unavailable")
[[ $shell == bash ]] || limitations+=("remote_bash_unavailable")

limitations_json=''
for item in "${limitations[@]}"; do
  [[ -z $limitations_json ]] || limitations_json+=','
  limitations_json+="\"$item\""
done

printf '{"schema_version":"1","target_class":"%s","transport":{"reachable":true,"host_key_verified":true,"batch_auth":true,"multiplexing":"unchecked"},' "$target"
printf '"remote":{"shell":"%s","tmux":"%s","writable_runtime_dir":%s,"pty":"%s"},' "$shell" "$tmux_status" "$writable" "$pty_status"
printf '"hermes":{"builtin_ssh_compatible":%s,"recommended_backend":"%s"},' "$hermes_compatible" "$backend"
printf '"supported_modes":[%s],"recommended_mode":"%s","limitations":[%s]}\n' "$modes" "$recommended" "$limitations_json"

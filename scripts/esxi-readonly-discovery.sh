#!/usr/bin/env bash
# Local Bash helper. It performs read-only probes only; never run it against a
# target unless the target identity and host-key fingerprint have been checked.
set -euo pipefail
umask 077

CONNECT_TIMEOUT=${ESXI_CONNECT_TIMEOUT:-10}
MAX_TIME=${ESXI_MAX_TIME:-30}
RETRIES=${ESXI_READONLY_RETRIES:-1}
REPORT_FILE=${ESXI_DISCOVERY_REPORT:-}
REPORT_JSON=${ESXI_DISCOVERY_REPORT_JSON:-}
ACCEPT_NEW_HOST_KEY=0
REST_SESSION=''

usage() {
  cat <<'EOF'
Usage: esxi-readonly-discovery.sh [--accept-new-host-key] [--report FILE] [--report-json FILE]

Read-only capability discovery for an ESXi target supplied through ESXI_HOST.
For an unknown SSH host key, inspect the printed SHA256 fingerprint out of
band, then rerun with --accept-new-host-key. ESXI_HOST_FINGERPRINT, when set,
must exactly match the discovered SHA256 fingerprint.
EOF
}

while (($#)); do
  case $1 in
    --accept-new-host-key) ACCEPT_NEW_HOST_KEY=1 ;;
    --report) REPORT_FILE=${2:?--report requires a path}; shift ;;
    --report-json) REPORT_JSON=${2:?--report-json requires a path}; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'error: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

section() { printf '\n=== %s ===\n' "$1"; }
report() {
  printf '%s\n' "$1"
  if [[ -n $REPORT_FILE ]]; then
    printf '%s\n' "$1" >>"$REPORT_FILE"
  fi
}
stop() { report "STOP: $1"; exit 1; }

require_safe_output_path() {
  local path=$1
  [[ -z $path ]] && return 0
  mkdir -p "$(dirname "$path")"
  [[ ! -e $path ]] || stop "refusing to overwrite report: $path"
  : >"$path"
}

tls_args=()
if [[ ${ESXI_INSECURE_TLS:-0} == 1 ]]; then
  tls_args+=(--insecure)
else
  [[ -n ${ESXI_CA_BUNDLE:-} ]] && tls_args+=(--cacert "$ESXI_CA_BUNDLE")
fi
curl_base=(curl --silent --show-error --connect-timeout "$CONNECT_TIMEOUT" --max-time "$MAX_TIME" --retry "$RETRIES" --retry-delay 1 --retry-connrefused)

curl_request() {
  # Prints a body followed by an HTTP status line. Authentication requests are
  # intentionally never retried beyond the one bounded request.
  local method=$1 url=$2 auth=${3:-} session=${4:-}
  local -a args=("${curl_base[@]}" "${tls_args[@]}" -X "$method" -w $'\n%{http_code}')
  [[ -n $auth ]] && args+=(-u "$auth")
  [[ -n $session ]] && args+=(-H "vmware-api-session-id: $session")
  "${args[@]}" "$url"
}

cleanup() {
  local ignored
  [[ -z $REST_SESSION ]] && return 0
  # Cleanup is best effort. Never print a token, authorization header, or body.
  ignored=$(curl_request DELETE "https://$ESXI_HOST/api/session" '' "$REST_SESSION" 2>/dev/null || true)
  REST_SESSION=''
}
trap cleanup EXIT

fingerprint_for_file() {
  ssh-keygen -lf "$1" 2>/dev/null | awk '{print $2}' | head -n1
}

known_fingerprints() {
  ssh-keygen -F "$ESXI_HOST" -f "$ESXI_KNOWN_HOSTS" 2>/dev/null | ssh-keygen -lf - 2>/dev/null | awk '{print $2}'
}

verify_ssh_host_key() {
  local candidate candidate_fp known
  [[ -z ${ESXI_SSH_KEY:-} ]] && return 0
  mkdir -p "$(dirname "$ESXI_KNOWN_HOSTS")"
  touch "$ESXI_KNOWN_HOSTS"
  candidate=$(mktemp "${TMPDIR:-/tmp}/esxi-host-key.XXXXXX")
  if ! ssh-keyscan -T "$CONNECT_TIMEOUT" -H "$ESXI_HOST" >"$candidate" 2>/dev/null || [[ ! -s $candidate ]]; then
    rm -f "$candidate"
    stop 'could not retrieve SSH host key; do not bypass host-key verification'
  fi
  candidate_fp=$(fingerprint_for_file "$candidate")
  [[ -n $candidate_fp ]] || { rm -f "$candidate"; stop 'could not derive SSH host-key SHA256 fingerprint'; }
  section 'SSH host-key fingerprint'
  report "Discovered SSH host-key fingerprint: $candidate_fp"
  if [[ -n ${ESXI_HOST_FINGERPRINT:-} && $candidate_fp != "$ESXI_HOST_FINGERPRINT" ]]; then
    rm -f "$candidate"
    stop 'discovered SSH host-key fingerprint does not match ESXI_HOST_FINGERPRINT'
  fi
  known=$(known_fingerprints || true)
  if [[ -n $known ]]; then
    if ! grep -Fxq "$candidate_fp" <<<"$known"; then
      rm -f "$candidate"
      stop 'SSH host key changed or known-hosts does not contain the scanned key; verify out of band'
    fi
    rm -f "$candidate"
    report 'SSH host key matches the dedicated known-hosts file.'
    return 0
  fi
  if (( ! ACCEPT_NEW_HOST_KEY )); then
    rm -f "$candidate"
    stop 'SSH host key is not trusted. Verify the fingerprint out of band, then explicitly rerun with --accept-new-host-key.'
  fi
  cat "$candidate" >>"$ESXI_KNOWN_HOSTS"
  rm -f "$candidate"
  report 'SSH host key accepted after explicit operator opt-in.'
}

run_ssh() {
  local label=$1 remote_cmd=$2 output status
  [[ -n ${ESXI_SSH_KEY:-} ]] || { section "$label"; report 'SKIPPED: ESXI_SSH_KEY is not set'; return 0; }
  section "$label"
  if output=$(ssh -i "$ESXI_SSH_KEY" -o UserKnownHostsFile="$ESXI_KNOWN_HOSTS" -o StrictHostKeyChecking=yes -o BatchMode=yes -o ConnectTimeout="$CONNECT_TIMEOUT" "$ESXI_USER@$ESXI_HOST" "$remote_cmd" 2>&1); then
    report "$output"
  else
    status=$?
    report "FAILED [ssh transport/auth/authorization] ($status): $output"
  fi
}

create_rest_session() {
  local response body status token
  [[ -n ${ESXI_PASS:-} ]] || return 1
  response=$(curl --silent --show-error --connect-timeout "$CONNECT_TIMEOUT" --max-time "$MAX_TIME" "${tls_args[@]}" -X POST -u "$ESXI_USER:$ESXI_PASS" -H 'Content-Type: application/json' -w $'\n%{http_code}' "https://$ESXI_HOST/api/session" 2>&1) || {
    report 'REST: transport/TLS failure while creating session.'; return 1;
  }
  status=${response##*$'\n'}
  body=${response%$'\n'*}
  token=$(printf '%s' "$body" | tr -d '"[:space:]')
  case $status in
    200|201) ;;
    401) report 'REST: authentication rejected (401).'; return 1 ;;
    403) report 'REST: authorization denied (403).'; return 1 ;;
    400|404) report "REST: endpoint unsupported or incomplete on this target ($status)."; return 1 ;;
    *) report "REST: session creation failed with HTTP $status."; return 1 ;;
  esac
  [[ $token =~ ^[A-Za-z0-9._:-]{16,}$ ]] || { report 'REST: session response did not contain an expected token format.'; return 1; }
  REST_SESSION=$token
  return 0
}

run_rest() {
  local label=$1 endpoint=$2 response body status
  section "$label"
  [[ -n ${ESXI_PASS:-} ]] || { report 'SKIPPED: ESXI_PASS is not set'; return 0; }
  if [[ -z $REST_SESSION ]] && ! create_rest_session; then
    report 'SKIPPED: REST probes unavailable; see the classified result above.'
    return 0
  fi
  response=$(curl_request GET "https://$ESXI_HOST$endpoint" '' "$REST_SESSION" 2>&1) || { report 'FAILED: REST transport or TLS error.'; return 0; }
  status=${response##*$'\n'}
  body=${response%$'\n'*}
  case $status in
    200) report "$body" ;;
    401) report 'FAILED: REST session expired (401); no repeated login attempts were made.'; REST_SESSION='' ;;
    403) report 'FAILED: REST authorization denied (403).' ;;
    400|404) report "FAILED: REST endpoint unsupported or unavailable (HTTP $status)." ;;
    *) report "FAILED: REST request returned HTTP $status." ;;
  esac
}

[[ -n ${ESXI_HOST:-} ]] || { printf 'ESXI_HOST is required\n' >&2; exit 2; }
ESXI_USER=${ESXI_USER:-agent}
ESXI_KNOWN_HOSTS=${ESXI_KNOWN_HOSTS:-$PWD/.ssh-known-hosts/esxi_known_hosts}
require_safe_output_path "$REPORT_FILE"
require_safe_output_path "$REPORT_JSON"

section 'Environment'
report "ESXI_HOST=$ESXI_HOST"
report "ESXI_USER=$ESXI_USER"
report "ESXI_KNOWN_HOSTS=$ESXI_KNOWN_HOSTS"
report "TLS validation=$([[ ${ESXI_INSECURE_TLS:-0} == 1 ]] && printf 'DISABLED BY EXPLICIT OPT-IN' || printf 'enabled')"
report "ESXI_SSH_KEY=$([[ -n ${ESXI_SSH_KEY:-} ]] && printf 'set' || printf 'not set')"
report "ESXI_PASS=$([[ -n ${ESXI_PASS:-} ]] && printf 'set' || printf 'not set')"

verify_ssh_host_key
run_ssh 'Host version' 'vmware -v'
run_ssh 'ESXi version' 'esxcli system version get'
run_ssh 'Hardware memory' 'esxcli hardware memory get'
run_ssh 'Storage filesystems' 'esxcli storage filesystem list'
run_ssh 'VM inventory' 'vim-cmd vmsvc/getallvms'
run_ssh 'Virtual switches' 'esxcli network vswitch standard list'
run_ssh 'Port groups' 'esxcli network vswitch standard portgroup list'
run_ssh 'IP interfaces' 'esxcli network ip interface list'
run_ssh 'Firewall rulesets' 'esxcli network firewall ruleset list'
run_rest 'REST VM listing' '/api/vcenter/vm'
run_rest 'REST datastore listing' '/api/vcenter/datastore'
run_rest 'REST network listing' '/api/vcenter/network'

if [[ -n $REPORT_JSON ]]; then
  printf '{"host":"%s","user":"%s","note":"Sanitized local capability report; secrets omitted."}\n' "$ESXI_HOST" "$ESXI_USER" >"$REPORT_JSON"
fi
section 'Done'
report 'Read-only discovery complete. Review failed sections before any state-changing action.'
#!/usr/bin/env bash
# Read-only local capability discovery. Never changes an ESXi host.
set -euo pipefail
umask 077

CONNECT_TIMEOUT=${ESXI_CONNECT_TIMEOUT:-10}
MAX_TIME=${ESXI_MAX_TIME:-30}
RETRIES=${ESXI_READONLY_RETRIES:-1}
REPORT_FILE=${ESXI_DISCOVERY_REPORT:-}
REPORT_JSON=${ESXI_DISCOVERY_REPORT_JSON:-}
ACCEPT_NEW_HOST_KEY=0
NO_SSH=0
NO_REST=0
REDACT_IDENTIFIERS=0
INCLUDE_INVENTORY=0
STRICT=0
REST_SESSION=''
REST_SESSION_ATTEMPTED=0
REST_DISABLED=0
REST_SESSION_ENDPOINT=''
SSH_DISABLED=0
SAFE_PATHS=0
ISSUES=0
AUTH_FAILURES=0
AUTHZ_FAILURES=0
DISCOVERY_RESULT=BLOCKED
JSON_RECORDS=$(mktemp "${TMPDIR:-/tmp}/esxi-discovery-records.XXXXXX")
trap 'rm -f "$JSON_RECORDS"' EXIT

usage() {
  cat <<'EOF'
Usage: esxi-readonly-discovery.sh [OPTIONS]

Read-only capability discovery for ESXI_HOST. No guest, host, datastore, or
network state is changed.

Options:
  --accept-new-host-key  Trust a verified unknown SSH key for this known-hosts file.
  --no-ssh               Skip all SSH host-key and SSH probes.
  --no-rest              Skip all HTTPS/REST probes.
  --redact-identifiers   Replace host and user in reports with REDACTED.
  --include-inventory    Print sensitive command output; suppressed by default.
  --strict               Return exit code 3 unless the final result is PASS.
  --report FILE          Write a human-readable report without overwriting FILE.
  --report-json FILE     Write structured JSON without overwriting FILE.
EOF
}

while (($#)); do
  case $1 in
    --accept-new-host-key) ACCEPT_NEW_HOST_KEY=1 ;;
    --no-ssh) NO_SSH=1 ;;
    --no-rest) NO_REST=1 ;;
    --redact-identifiers) REDACT_IDENTIFIERS=1 ;;
    --include-inventory) INCLUDE_INVENTORY=1 ;;
    --strict) STRICT=1 ;;
    --report) REPORT_FILE=${2:?--report requires a path}; shift ;;
    --report-json) REPORT_JSON=${2:?--report-json requires a path}; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'error: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

is_nonnegative_int() { [[ $1 =~ ^[0-9]+$ ]]; }
is_positive_int() { [[ $1 =~ ^[1-9][0-9]*$ ]]; }
for value in "$CONNECT_TIMEOUT" "$MAX_TIME"; do
  is_positive_int "$value" || { printf 'error: timeout values must be positive integers\n' >&2; exit 2; }
done
is_nonnegative_int "$RETRIES" || { printf 'error: ESXI_READONLY_RETRIES must be a non-negative integer\n' >&2; exit 2; }
[[ ${ESXI_INSECURE_TLS:-0} =~ ^[01]$ ]] || { printf 'error: ESXI_INSECURE_TLS must be 0 or 1\n' >&2; exit 2; }

[[ -n ${ESXI_HOST:-} ]] || { printf 'ESXI_HOST is required\n' >&2; exit 2; }
ESXI_USER=${ESXI_USER:-agent}
ESXI_KNOWN_HOSTS=${ESXI_KNOWN_HOSTS:-$PWD/.ssh-known-hosts/esxi_known_hosts}
REPORT_HOST=$ESXI_HOST
REPORT_USER=$ESXI_USER
if (( REDACT_IDENTIFIERS )); then
  REPORT_HOST=REDACTED
  REPORT_USER=REDACTED
fi

report() {
  printf '%s\n' "$1"
  if [[ -n $REPORT_FILE ]]; then
    printf '%s\n' "$1" >>"$REPORT_FILE"
  fi
}
section() { report ""; report "=== $1 ==="; }
stop() { report "STOP: $1"; exit 1; }
record() { printf '%s\x1f%s\x1f%s\x1f%s\n' "$1" "$2" "$3" "$4" >>"$JSON_RECORDS"; }
mark_safe_path() { SAFE_PATHS=$((SAFE_PATHS + 1)); }
mark_issue() { ISSUES=$((ISSUES + 1)); }
mark_auth_failure() { AUTH_FAILURES=$((AUTH_FAILURES + 1)); mark_issue; }
mark_authz_failure() { AUTHZ_FAILURES=$((AUTHZ_FAILURES + 1)); mark_issue; }

prepare_report_path() {
  local path=$1
  [[ -z $path ]] && return 0
  [[ ! -L $path ]] || stop "refusing symlink report path: $path"
  mkdir -p "$(dirname "$path")"
  [[ ! -e $path ]] || stop "refusing to overwrite report: $path"
  : >"$path"
}
prepare_report_path "$REPORT_FILE"
prepare_report_path "$REPORT_JSON"

_tls_args=()
if [[ ${ESXI_INSECURE_TLS:-0} == 1 ]]; then
  _tls_args+=(--insecure)
elif [[ -n ${ESXI_CA_BUNDLE:-} ]]; then
  _tls_args+=(--cacert "$ESXI_CA_BUNDLE")
fi
curl_base=(curl --silent --show-error --connect-timeout "$CONNECT_TIMEOUT" --max-time "$MAX_TIME" --retry "$RETRIES" --retry-delay 1 --retry-connrefused)

# Sets RESPONSE_BODY and RESPONSE_STATUS. Curl failures are transport/TLS failures.
http_request() {
  local method=$1 url=$2 auth=${3:-} session=${4:-} response
  local -a args=("${curl_base[@]}" "${_tls_args[@]}" -X "$method" -w $'\n%{http_code}')
  [[ -n $auth ]] && args+=(-u "$auth")
  [[ -n $session ]] && args+=(-H "vmware-api-session-id: $session")
  response=$("${args[@]}" "$url" 2>&1) || return 1
  RESPONSE_STATUS=${response##*$'\n'}
  RESPONSE_BODY=${response%$'\n'*}
  [[ $RESPONSE_STATUS =~ ^[0-9]{3}$ ]] || return 1
}

classify_http() {
  case $1 in
    200|201|204) printf 'reachable' ;;
    401) printf 'authentication' ;;
    403) printf 'authorization' ;;
    400|404|405|501) printf 'unsupported endpoint' ;;
    *) printf 'HTTP %s' "$1" ;;
  esac
}

fingerprints_for_file() { ssh-keygen -lf "$1" 2>/dev/null | awk '{print $2}' | sort -u; }
known_fingerprints() { ssh-keygen -F "$ESXI_HOST" -f "$ESXI_KNOWN_HOSTS" 2>/dev/null | ssh-keygen -lf - 2>/dev/null | awk '{print $2}' | sort -u; }

verify_ssh_host_key() {
  local candidate candidate_fps known candidate_fp
  (( NO_SSH )) && { SSH_DISABLED=1; section 'SSH'; report 'SKIPPED: SSH disabled by --no-ssh.'; record ssh host-key skipped 'disabled by option'; return 0; }
  [[ -n ${ESXI_SSH_KEY:-} ]] || { SSH_DISABLED=1; mark_issue; section 'SSH'; report 'SSH unavailable: ESXI_SSH_KEY is not set.'; record ssh host-key unavailable 'key not configured'; return 0; }
  mkdir -p "$(dirname "$ESXI_KNOWN_HOSTS")"; touch "$ESXI_KNOWN_HOSTS"
  candidate=$(mktemp "${TMPDIR:-/tmp}/esxi-host-key.XXXXXX")
  if ! ssh-keyscan -T "$CONNECT_TIMEOUT" -H "$ESXI_HOST" >"$candidate" 2>/dev/null || [[ ! -s $candidate ]]; then
    rm -f "$candidate"; SSH_DISABLED=1; mark_issue
    section 'SSH'; report 'SSH unavailable: unable to retrieve a host key (port 22 may be closed). HTTPS probes may continue.'
    record ssh host-key unavailable 'host key retrieval failed'
    return 0
  fi
  candidate_fps=$(fingerprints_for_file "$candidate")
  [[ -n $candidate_fps ]] || { rm -f "$candidate"; stop 'could not derive SSH host-key SHA256 fingerprint'; }
  section 'SSH host-key fingerprints'
  while IFS= read -r candidate_fp; do report "Discovered SSH host-key fingerprint: $candidate_fp"; done <<<"$candidate_fps"
  if [[ -n ${ESXI_HOST_FINGERPRINT:-} ]] && ! grep -Fxq "$ESXI_HOST_FINGERPRINT" <<<"$candidate_fps"; then
    rm -f "$candidate"
    stop 'discovered SSH host-key fingerprints do not include ESXI_HOST_FINGERPRINT'
  fi
  known=$(known_fingerprints || true)
  if [[ -n $known ]]; then
    if ! grep -Fxf <(printf '%s\n' "$known") <(printf '%s\n' "$candidate_fps") >/dev/null; then
      rm -f "$candidate"
      stop 'SSH host key changed or known-hosts does not contain a scanned key; verify out of band'
    fi
    rm -f "$candidate"; report 'SSH host key matches the dedicated known-hosts file.'; record ssh host-key reachable trusted; return 0
  fi
  if (( ! ACCEPT_NEW_HOST_KEY )); then rm -f "$candidate"; stop 'SSH host key is not trusted. Verify the fingerprint out of band, then explicitly rerun with --accept-new-host-key.'; fi
  cat "$candidate" >>"$ESXI_KNOWN_HOSTS"; rm -f "$candidate"; report 'SSH host key accepted after explicit operator opt-in.'; record ssh host-key reachable accepted
}

run_ssh() {
  local label=$1 remote_cmd=$2 output status
  (( SSH_DISABLED )) && { section "$label"; report 'SKIPPED: SSH unavailable or disabled.'; record ssh "$label" skipped unavailable; return 0; }
  section "$label"
  if output=$(ssh -i "$ESXI_SSH_KEY" -o UserKnownHostsFile="$ESXI_KNOWN_HOSTS" -o StrictHostKeyChecking=yes -o BatchMode=yes -o ConnectTimeout="$CONNECT_TIMEOUT" "$ESXI_USER@$ESXI_HOST" "$remote_cmd" 2>&1); then
    mark_safe_path
    if (( INCLUDE_INVENTORY )); then
      report "$output"
    else
      report 'RESULT: reachable (command output suppressed; use --include-inventory only for a protected local session).'
    fi
    record ssh "$label" reachable success
  else
    status=$?
    mark_issue
    report "FAILED: SSH unavailable/auth/authorization ($status)."
    record ssh "$label" unavailable "exit $status"
  fi
}

extract_session_token() {
  python3 -c '
import json, sys
raw=sys.stdin.read().strip()
try:
    value=json.loads(raw)
except json.JSONDecodeError:
    value=raw.strip("\"")
if isinstance(value, dict):
    value=value.get("value", "")
print(value if isinstance(value, str) else "")
'
}

accept_session_response() {
  local endpoint=$1 token
  case $RESPONSE_STATUS in
    200|201) ;;
    *) return 1 ;;
  esac
  token=$(printf '%s' "$RESPONSE_BODY" | extract_session_token)
  REST_SESSION=$token
  [[ $REST_SESSION =~ ^[A-Za-z0-9._:-]{16,}$ ]] || { REST_DISABLED=1; REST_SESSION=''; report 'REST: invalid session-token response.'; record rest session invalid-token rejected; return 1; }
  REST_SESSION_ENDPOINT=$endpoint
  record rest session reachable created
  return 0
}

create_rest_session() {
  (( REST_SESSION_ATTEMPTED )) && return 1
  REST_SESSION_ATTEMPTED=1
  if [[ -z ${ESXI_PASS:-} ]]; then
    REST_DISABLED=1; mark_issue
    report 'REST disabled: ESXI_PASS is not set.'
    record rest session disabled 'password not configured'
    return 1
  fi
  if ! http_request POST "https://$ESXI_HOST/api/session" "$ESXI_USER:$ESXI_PASS"; then
    REST_DISABLED=1; mark_issue
    report 'REST: transport/TLS unavailable while creating session.'
    record rest session unavailable 'transport or TLS'
    return 1
  fi
  case $RESPONSE_STATUS in
    200|201)
      accept_session_response '/api/session'
      return
      ;;
    401)
      REST_DISABLED=1; mark_auth_failure
      report 'REST: authentication rejected (401); no legacy or repeated login will be attempted.'
      record rest session authentication 401
      return 1
      ;;
    403)
      REST_DISABLED=1; mark_authz_failure
      report 'REST: authorization denied (403).'
      record rest session authorization 403
      return 1
      ;;
    400|404|405|501)
      report "REST: modern session endpoint unsupported ($RESPONSE_STATUS); trying the legacy endpoint once."
      record rest session-modern unsupported "$RESPONSE_STATUS"
      ;;
    *)
      REST_DISABLED=1; mark_issue
      report "REST: modern session creation failed (HTTP $RESPONSE_STATUS)."
      record rest session "HTTP $RESPONSE_STATUS" failed
      return 1
      ;;
  esac
  if ! http_request POST "https://$ESXI_HOST/rest/com/vmware/cis/session" "$ESXI_USER:$ESXI_PASS"; then
    REST_DISABLED=1; mark_issue
    report 'REST: transport/TLS unavailable on the legacy session endpoint.'
    record rest session unavailable 'legacy transport or TLS'
    return 1
  fi
  case $RESPONSE_STATUS in
    200|201)
      accept_session_response '/rest/com/vmware/cis/session'
      return
      ;;
    401)
      REST_DISABLED=1; mark_auth_failure
      report 'REST: authentication rejected by the legacy endpoint (401); no retry will be attempted.'
      record rest session authentication 401
      ;;
    403)
      REST_DISABLED=1; mark_authz_failure
      report 'REST: authorization denied by the legacy endpoint (403).'
      record rest session authorization 403
      ;;
    400|404|405|501)
      REST_DISABLED=1; mark_issue
      report "REST: both session endpoints are unsupported (legacy HTTP $RESPONSE_STATUS)."
      record rest session unsupported "$RESPONSE_STATUS"
      ;;
    *)
      REST_DISABLED=1; mark_issue
      report "REST: legacy session creation failed (HTTP $RESPONSE_STATUS)."
      record rest session "HTTP $RESPONSE_STATUS" failed
      ;;
  esac
  return 1
}

run_https_probe() {
  local label=$1 endpoint=$2 auth_mode=${3:-none} kind=https classification
  section "$label"
  case $auth_mode in
    none)
      if ! http_request GET "https://$ESXI_HOST$endpoint"; then
        mark_issue; report 'FAILED: reachability/TLS transport unavailable.'; record https "$label" unavailable 'transport or TLS'; return 0
      fi
      ;;
    basic)
      kind=https-basic
      if [[ -z ${ESXI_PASS:-} ]]; then
        mark_issue; report 'SKIPPED: ESXI_PASS is required for the Basic Auth probe.'; record "$kind" "$label" skipped 'password not configured'; return 0
      fi
      if ! http_request GET "https://$ESXI_HOST$endpoint" "$ESXI_USER:$ESXI_PASS"; then
        mark_issue; report 'FAILED: Basic Auth transport/TLS unavailable.'; record "$kind" "$label" unavailable 'transport or TLS'; return 0
      fi
      ;;
    rest)
      kind=rest
      (( REST_DISABLED )) && { report 'SKIPPED: REST disabled after the session result.'; record rest "$label" skipped disabled; return 0; }
      [[ -n $REST_SESSION ]] || create_rest_session || { report 'SKIPPED: authenticated REST probe unavailable.'; record rest "$label" skipped unavailable; return 0; }
      if ! http_request GET "https://$ESXI_HOST$endpoint" '' "$REST_SESSION"; then
        mark_issue; report 'FAILED: REST transport/TLS unavailable.'; record rest "$label" unavailable 'transport or TLS'; return 0
      fi
      ;;
    *) stop "internal error: unknown HTTPS auth mode: $auth_mode" ;;
  esac
  classification=$(classify_http "$RESPONSE_STATUS")
  report "RESULT: $classification (HTTP $RESPONSE_STATUS)."
  record "$kind" "$label" "$classification" "$RESPONSE_STATUS"
  case $RESPONSE_STATUS in
    200|201|204) mark_safe_path ;;
    401)
      mark_auth_failure
      if [[ $auth_mode == rest ]]; then REST_DISABLED=1; REST_SESSION=''; report 'REST disabled after 401; no additional session attempt will be made.'; fi
      ;;
    403) mark_authz_failure ;;
    *) mark_issue ;;
  esac
}

urlencode() {
  python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

cleanup() {
  [[ -z $REST_SESSION || -z $REST_SESSION_ENDPOINT ]] && return 0
  http_request DELETE "https://$ESXI_HOST$REST_SESSION_ENDPOINT" '' "$REST_SESSION" >/dev/null 2>&1 || true
  REST_SESSION=''
}
trap 'cleanup; rm -f "$JSON_RECORDS"' EXIT

write_json() {
  [[ -z $REPORT_JSON ]] && return 0
  python3 - "$JSON_RECORDS" "$REPORT_JSON" "$REPORT_HOST" "$REPORT_USER" "$DISCOVERY_RESULT" <<'PY'
import json, sys
records=[]
for line in open(sys.argv[1], encoding='utf-8'):
    kind, label, status, detail = line.rstrip('\n').split('\x1f', 3)
    records.append({'kind': kind, 'label': label, 'status': status, 'detail': detail})
with open(sys.argv[2], 'w', encoding='utf-8') as output:
    json.dump({'host': sys.argv[3], 'user': sys.argv[4], 'result': sys.argv[5], 'probes': records}, output, ensure_ascii=False, indent=2)
    output.write('\n')
PY
}

determine_result() {
  if (( SAFE_PATHS > 0 && ISSUES == 0 )); then
    DISCOVERY_RESULT=PASS
  elif (( SAFE_PATHS > 0 )); then
    DISCOVERY_RESULT=PARTIAL
  elif (( AUTH_FAILURES > 0 )); then
    DISCOVERY_RESULT=AUTH_FAILED
  elif (( AUTHZ_FAILURES > 0 )); then
    DISCOVERY_RESULT=AUTHZ_FAILED
  else
    DISCOVERY_RESULT=BLOCKED
  fi
}

section 'Environment'
report "ESXI_HOST=$REPORT_HOST"; report "ESXI_USER=$REPORT_USER"
report "TLS validation=$([[ ${ESXI_INSECURE_TLS:-0} == 1 ]] && printf 'DISABLED BY EXPLICIT OPT-IN' || printf enabled)"
report "SSH=$([[ $NO_SSH == 1 ]] && printf disabled || printf enabled), REST=$([[ $NO_REST == 1 ]] && printf disabled || printf enabled)"
if [[ ${ESXI_INSECURE_TLS:-0} == 1 ]]; then report 'WARNING: TLS certificate verification is disabled for this explicitly approved run.'; fi
if (( INCLUDE_INVENTORY )); then report 'WARNING: full inventory output is enabled and may contain sensitive identifiers.'; fi
verify_ssh_host_key
run_ssh 'Host version' 'vmware -v'
run_ssh 'ESXi version' 'esxcli system version get'
run_ssh 'Hardware memory' 'esxcli hardware memory get'
run_ssh 'Storage filesystems' 'esxcli storage filesystem list'
run_ssh 'VM inventory' 'vim-cmd vmsvc/getallvms'
run_ssh 'Virtual switches' 'esxcli network vswitch standard list'
run_ssh 'Port groups' 'esxcli network vswitch standard portgroup list'
(( NO_REST )) || {
  run_https_probe 'HTTPS UI' '/ui/' none
  folder_endpoint='/folder?dcPath=ha-datacenter'
  if [[ -n ${ESXI_DATASTORE:-} ]]; then folder_endpoint+="&dsName=$(urlencode "$ESXI_DATASTORE")"; fi
  run_https_probe 'Datastore browser' "$folder_endpoint" basic
  run_https_probe 'HTTPS SDK' '/sdk' none
  run_https_probe 'REST VM listing' '/api/vcenter/vm' rest
  if [[ ${RESPONSE_STATUS:-} == 404 && $REST_DISABLED == 0 ]]; then
    run_https_probe 'Legacy REST VM listing' '/rest/vcenter/vm' rest
  fi
  if [[ $REST_SESSION_ENDPOINT == /rest/* ]]; then
    run_https_probe 'Legacy REST datastore listing' '/rest/vcenter/datastore' rest
    run_https_probe 'Legacy REST network listing' '/rest/vcenter/network' rest
  else
    run_https_probe 'REST datastore listing' '/api/vcenter/datastore' rest
    run_https_probe 'REST network listing' '/api/vcenter/network' rest
  fi
}
(( NO_REST )) && { section 'HTTPS/REST'; report 'SKIPPED: REST disabled by --no-rest.'; record rest all skipped 'disabled by option'; }
determine_result
section 'Summary'
report "RESULT: $DISCOVERY_RESULT"
report "Safe paths: $SAFE_PATHS; issues: $ISSUES; authentication failures: $AUTH_FAILURES; authorization failures: $AUTHZ_FAILURES."
case $DISCOVERY_RESULT in
  PASS) report 'Read-only discovery passed. Continue to task-specific planning; this does not authorize a state change.' ;;
  PARTIAL) report 'At least one safe path exists, but capability gaps require review before planning a state change.' ;;
  *) report 'No safe operational path was confirmed. STOP before any state-changing action.' ;;
esac
write_json
if (( STRICT )) && [[ $DISCOVERY_RESULT != PASS ]]; then exit 3; fi

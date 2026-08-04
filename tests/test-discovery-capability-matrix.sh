#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$repo_root/scripts/esxi-readonly-discovery.sh"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mock_bin="$work_dir/mock-bin"
mkdir -p "$mock_bin"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cat >"$mock_bin/curl" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${CURL_LOG:?}"
args=("$@")
for ((index=0; index < ${#args[@]}; index++)); do
  if [[ ${args[index]} == --netrc-file ]]; then
    netrc=${args[index + 1]}
    [[ -f $netrc && $(stat -c '%a' "$netrc") == 600 ]] || exit 90
    grep -Fq 'login "secret-user"' "$netrc" || exit 91
    grep -Fq 'password "secret pass\"word\\value"' "$netrc" || exit 92
    printf '%s\n' "$netrc" >"${NETRC_PATH_LOG:?}"
  fi
  if [[ ${args[index]} == -H && ${args[index + 1]:-} == @* ]]; then
    header_file=${args[index + 1]#@}
    [[ -f $header_file && $(stat -c '%a' "$header_file") == 600 ]] || exit 93
    grep -Fq 'vmware-api-session-id: legacy-session-token-1234567890' \
      "$header_file" || exit 94
    printf '%s\n' "$header_file" >"${HEADER_PATH_LOG:?}"
  fi
done
if [[ " $* " == *' -X POST '* && $* == *'/rest/com/vmware/cis/session'* ]]; then
  printf '{"value":"legacy-session-token-1234567890"}\n200\n'
elif [[ " $* " == *' -X POST '* && $* == *'/api/session'* ]]; then
  printf 'unsupported\n400\n'
elif [[ $* == *'/sdk'* ]]; then
  printf 'method not allowed\n405\n'
else
  printf 'ok\n200\n'
fi
MOCK
chmod +x "$mock_bin/curl"

env \
  PATH="$mock_bin:$PATH" \
  ESXI_HOST=mock.example.test \
  ESXI_USER=secret-user \
  ESXI_PASS='secret pass"word\value' \
  ESXI_DATASTORE='datastore with spaces' \
  CURL_LOG="$work_dir/curl.log" \
  NETRC_PATH_LOG="$work_dir/netrc-path.log" \
  HEADER_PATH_LOG="$work_dir/header-path.log" \
  "$script" --no-ssh --redact-identifiers --report-json "$work_dir/report.json" \
  >"$work_dir/report.txt" 2>&1

[[ $(grep -c -- ' -X POST ' "$work_dir/curl.log") == 2 ]] ||
  fail 'modern unsupported session did not produce exactly one legacy fallback'
grep -Fq '/folder?dcPath=ha-datacenter&dsName=datastore%20with%20spaces' "$work_dir/curl.log" ||
  fail 'datastore browser path was not safely encoded'
folder_line=$(grep -n -m1 '/folder?' "$work_dir/curl.log" | cut -d: -f1)
session_line=$(grep -n -m1 ' -X POST ' "$work_dir/curl.log" | cut -d: -f1)
[[ $folder_line -lt $session_line ]] || fail 'datastore browser did not run before REST session creation'
folder_args=$(grep -m1 '/folder?' "$work_dir/curl.log")
grep -Fq -- '--netrc-file ' <<<"$folder_args" ||
  fail 'datastore browser did not use the protected netrc credential file'
! grep -Fq 'secret pass"word\value' "$work_dir/curl.log" ||
  fail 'password leaked into curl process arguments'
[[ -s $work_dir/netrc-path.log ]] || fail 'mock curl did not inspect the credential file'
netrc_path=$(<"$work_dir/netrc-path.log")
[[ ! -e $netrc_path ]] || fail 'temporary credential file remained after discovery cleanup'
! grep -Fq 'legacy-session-token-1234567890' "$work_dir/curl.log" ||
  fail 'REST session token leaked into curl process arguments'
! grep -E ' -X (POST|DELETE) .*--retry' "$work_dir/curl.log" ||
  fail 'non-idempotent REST session request inherited automatic retries'
[[ -s $work_dir/header-path.log ]] || fail 'mock curl did not inspect the session-header file'
header_path=$(<"$work_dir/header-path.log")
[[ ! -e $header_path ]] || fail 'temporary session-header file remained after cleanup'
! grep -Fq 'vmware-api-session-id:' <<<"$folder_args" ||
  fail 'datastore browser incorrectly depended on a REST session'
! grep -Fq 'secret-pass' "$work_dir/report.txt" ||
  fail 'password leaked into the human-readable report'

python3 - "$work_dir/report.json" <<'PY'
import json, sys
report=json.load(open(sys.argv[1]))
assert report['result'] == 'PASS'
assert report['host'] == report['user'] == 'REDACTED'
assert any(
    item['label'] == 'Datastore browser'
    and item['kind'] == 'https-basic'
    and item['status'] == 'reachable'
    for item in report['probes']
)
assert any(
    item['label'] == 'session-modern'
    and item['status'] == 'unsupported'
    for item in report['probes']
)
assert any(
    item['label'] == 'session'
    and item['status'] == 'reachable'
    for item in report['probes']
)
assert any(
    item['label'] == 'HTTPS SDK'
    and item['kind'] == 'sdk'
    and item['status'] == 'reachable'
    and item['detail'] == 'method not allowed'
    for item in report['probes']
)
PY

printf 'PASS: datastore Basic Auth, REST legacy fallback, encoding, and secret-safe reporting\n'

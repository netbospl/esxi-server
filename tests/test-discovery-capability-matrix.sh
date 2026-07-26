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
if [[ " $* " == *' -X POST '* && $* == *'/rest/com/vmware/cis/session'* ]]; then
  printf '{"value":"legacy-session-token-1234567890"}\n200\n'
elif [[ " $* " == *' -X POST '* && $* == *'/api/session'* ]]; then
  printf 'unsupported\n400\n'
else
  printf 'ok\n200\n'
fi
MOCK
chmod +x "$mock_bin/curl"

env \
  PATH="$mock_bin:$PATH" \
  ESXI_HOST=mock.example.test \
  ESXI_USER=secret-user \
  ESXI_PASS=secret-pass \
  ESXI_DATASTORE='datastore with spaces' \
  CURL_LOG="$work_dir/curl.log" \
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
grep -Fq -- '-u secret-user:secret-pass' <<<"$folder_args" ||
  fail 'datastore browser did not use Basic Auth'
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
PY

printf 'PASS: datastore Basic Auth, REST legacy fallback, encoding, and secret-safe reporting\n'

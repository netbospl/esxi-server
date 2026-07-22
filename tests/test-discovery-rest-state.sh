#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$repo/scripts/esxi-readonly-discovery.sh"
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
mkdir "$work/bin"
cat >"$work/bin/ssh-keyscan" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
cat >"$work/bin/curl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${CURL_LOG:?}"
if [[ " $* " == *' -X POST '* ]]; then printf 'rejected\n401\n'; else printf 'ok\n200\n'; fi
EOF
chmod +x "$work/bin"/*
set +e
env PATH="$work/bin:$PATH" ESXI_HOST=mock.example.test ESXI_USER=secret-user ESXI_PASS=secret-pass ESXI_SSH_KEY=/dev/null ESXI_KNOWN_HOSTS="$work/known" CURL_LOG="$work/curl.log" "$script" --redact-identifiers --report-json "$work/report.json" >"$work/report.txt" 2>&1
status=$?
set -e
[[ $status == 0 ]] || { cat "$work/report.txt" >&2; exit "$status"; }
[[ $(grep -c -- ' -X POST ' "$work/curl.log") == 1 ]] || { echo 'FAIL: REST session attempted more than once' >&2; exit 1; }
grep -Fq 'SSH unavailable' "$work/report.txt" || { echo 'FAIL: SSH fallback missing' >&2; exit 1; }
python3 - "$work/report.json" <<'PY'
import json, sys
report=json.load(open(sys.argv[1]))
assert report['host'] == report['user'] == 'REDACTED'
assert any(item['label'] == 'session' and item['status'] == 'authentication' for item in report['probes'])
PY
printf 'PASS: mocked REST single-attempt, SSH fallback, and JSON report\n'

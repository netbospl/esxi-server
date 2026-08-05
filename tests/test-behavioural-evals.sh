#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
validator="$repo_root/scripts/validate-behavioural-evals.sh"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

bash "$validator" >"$work_dir/valid.out" || fail 'committed behavioural evaluations did not validate'
grep -Fq 'PASS:' "$work_dir/valid.out" || fail 'valid evaluation run did not report PASS'

python3 - "$repo_root/evals/evals.json" "$work_dir/duplicate.json" <<'PY'
import json
import sys
payload = json.load(open(sys.argv[1], encoding="utf-8"))
payload["evals"][1]["id"] = payload["evals"][0]["id"]
json.dump(payload, open(sys.argv[2], "w", encoding="utf-8"), indent=2)
PY

set +e
bash "$validator" "$work_dir/duplicate.json" >"$work_dir/duplicate.out" 2>&1
status=$?
set -e
[[ $status -ne 0 ]] || fail 'validator accepted a duplicate evaluation id'
grep -Fq 'duplicate evaluation id' "$work_dir/duplicate.out" || fail 'duplicate rejection was not specific'

python3 - "$repo_root/evals/evals.json" "$work_dir/missing.json" <<'PY'
import json
import sys
payload = json.load(open(sys.argv[1], encoding="utf-8"))
payload["evals"] = [item for item in payload["evals"] if item["id"] != "sole-public-ip-pfsense-r3"]
json.dump(payload, open(sys.argv[2], "w", encoding="utf-8"), indent=2)
PY

set +e
bash "$validator" "$work_dir/missing.json" >"$work_dir/missing.out" 2>&1
status=$?
set -e
[[ $status -ne 0 ]] || fail 'validator accepted removal of a required safety evaluation'
grep -Fq 'required safety evaluations missing' "$work_dir/missing.out" || fail 'missing-evaluation rejection was not specific'

printf 'PASS: behavioural evaluation contract\n'

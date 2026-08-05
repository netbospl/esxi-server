#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
evals_file=${1:-"$repo_root/evals/evals.json"}

command -v python3 >/dev/null 2>&1 || {
  printf 'FAIL: required tool missing: python3\n' >&2
  exit 127
}

python3 - "$evals_file" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    payload = json.loads(path.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as exc:
    raise SystemExit(f"FAIL: cannot read valid evaluation JSON: {exc}")

if payload.get("schema_version") != "1.0":
    raise SystemExit("FAIL: schema_version must be 1.0")
if payload.get("skill_name") != "esxi-server":
    raise SystemExit("FAIL: skill_name must be esxi-server")

evals = payload.get("evals")
if not isinstance(evals, list) or len(evals) < 8:
    raise SystemExit("FAIL: at least eight behavioural evaluations are required")

seen = set()
required_fragments = {
    "standalone-vcenter-boundary": "/api/vcenter/vm",
    "sole-public-ip-pfsense-r3": "R3",
    "unknown-ssh-command-state": "replay",
    "packer-placeholder-block": "REPLACE_WITH",
    "overlay-ownership": "root policy",
    "historical-plan-status": "historical",
}

for item in evals:
    if not isinstance(item, dict):
        raise SystemExit("FAIL: each evaluation must be an object")
    eval_id = item.get("id")
    if not isinstance(eval_id, str) or not eval_id:
        raise SystemExit("FAIL: every evaluation needs a non-empty id")
    if eval_id in seen:
        raise SystemExit(f"FAIL: duplicate evaluation id: {eval_id}")
    seen.add(eval_id)
    for field in ("prompt", "expected_output"):
        value = item.get(field)
        if not isinstance(value, str) or len(value.strip()) < 20:
            raise SystemExit(f"FAIL: {eval_id} has an incomplete {field}")
    assertions = item.get("assertions")
    if not isinstance(assertions, list) or len(assertions) < 3:
        raise SystemExit(f"FAIL: {eval_id} needs at least three assertions")
    if any(not isinstance(assertion, str) or len(assertion.strip()) < 12 for assertion in assertions):
        raise SystemExit(f"FAIL: {eval_id} contains an incomplete assertion")

missing = sorted(set(required_fragments) - seen)
if missing:
    raise SystemExit(f"FAIL: required safety evaluations missing: {', '.join(missing)}")

by_id = {item["id"]: item for item in evals}
for eval_id, fragment in required_fragments.items():
    text = json.dumps(by_id[eval_id], ensure_ascii=False)
    if fragment.lower() not in text.lower():
        raise SystemExit(f"FAIL: {eval_id} no longer covers required fragment: {fragment}")

print(f"PASS: {len(evals)} behavioural evaluations validated")
PY

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

cat >"$mock_bin/ssh-keygen" <<'MOCK'
#!/usr/bin/env bash
if [[ $1 == -F ]]; then exit 1; fi
if [[ $1 == -lf && ${2:-} != - ]]; then
  printf '256 SHA256:first-fingerprint mock (ED25519)\n'
  printf '3072 SHA256:second-fingerprint mock (RSA)\n'
  exit 0
fi
exit 1
MOCK
cat >"$mock_bin/ssh-keyscan" <<'MOCK'
#!/usr/bin/env bash
printf 'mock.example.test ssh-ed25519 AAAAC3NzaMockFirst\n'
printf 'mock.example.test ssh-rsa AAAAB3NzaMockSecond\n'
MOCK
cat >"$mock_bin/ssh" <<'MOCK'
#!/usr/bin/env bash
printf 'SENSITIVE_VM_NAME datastore-private PG-CUSTOMER\n'
MOCK
chmod +x "$mock_bin"/*

base_env=(
  PATH="$mock_bin:$PATH"
  ESXI_HOST=mock.example.test
  ESXI_USER=agent
  ESXI_SSH_KEY=/dev/null
  ESXI_HOST_FINGERPRINT=SHA256:second-fingerprint
)

env "${base_env[@]}" ESXI_KNOWN_HOSTS="$work_dir/known-default" \
  "$script" --accept-new-host-key --no-rest >"$work_dir/default.out" 2>&1
! grep -Fq 'SENSITIVE_VM_NAME' "$work_dir/default.out" ||
  fail 'inventory output was printed without --include-inventory'
grep -Fq 'output suppressed' "$work_dir/default.out" ||
  fail 'suppressed-output status was not reported'
grep -Fq 'RESULT: PASS' "$work_dir/default.out" ||
  fail 'successful SSH-only discovery did not return PASS'

env "${base_env[@]}" ESXI_KNOWN_HOSTS="$work_dir/known-full" \
  "$script" --accept-new-host-key --no-rest --include-inventory \
  >"$work_dir/full.out" 2>&1
grep -Fq 'SENSITIVE_VM_NAME' "$work_dir/full.out" ||
  fail '--include-inventory did not print command output'
grep -Fq 'full inventory output is enabled' "$work_dir/full.out" ||
  fail 'sensitive inventory warning was not shown'

set +e
ESXI_HOST=mock.example.test "$script" --no-ssh --no-rest --strict \
  >"$work_dir/strict.out" 2>&1
status=$?
set -e
[[ $status == 3 ]] || fail 'strict BLOCKED result did not return exit code 3'
grep -Fq 'RESULT: BLOCKED' "$work_dir/strict.out" ||
  fail 'strict no-transport run did not report BLOCKED'

set +e
ESXI_HOST=mock.example.test ESXI_INSECURE_TLS=invalid "$script" --no-ssh --no-rest \
  >"$work_dir/tls-invalid.out" 2>&1
status=$?
set -e
[[ $status == 2 ]] || fail 'invalid ESXI_INSECURE_TLS value was accepted'

printf 'PASS: multi-key trust, inventory privacy, strict result, and TLS opt-in validation\n'

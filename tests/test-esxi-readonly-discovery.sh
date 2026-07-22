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
if [[ $1 == -lf && ${2:-} != - ]]; then printf '256 SHA256:expected-fingerprint mock (ED25519)\n'; exit 0; fi
exit 1
MOCK
cat >"$mock_bin/ssh-keyscan" <<'MOCK'
#!/usr/bin/env bash
printf 'mock.example.test ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMockHostKeyMaterialOnly00000000000000\n'
MOCK
cat >"$mock_bin/ssh" <<'MOCK'
#!/usr/bin/env bash
printf 'ssh-called\n' >"${TEST_MARKER:?}"
exit 0
MOCK
cat >"$mock_bin/curl" <<'MOCK'
#!/usr/bin/env bash
printf 'curl-called\n' >"${TEST_MARKER:?}"
exit 0
MOCK
chmod +x "$mock_bin"/*

base_env=(
  PATH="$mock_bin:$PATH"
  ESXI_HOST=mock.example.test
  ESXI_USER=agent
  ESXI_SSH_KEY=/dev/null
  ESXI_KNOWN_HOSTS="$work_dir/known_hosts"
  TEST_MARKER="$work_dir/marker"
)

set +e
env "${base_env[@]}" "$script" >"$work_dir/unknown.out" 2>&1
status=$?
set -e
[[ $status -ne 0 ]] || fail 'unknown host key must stop discovery'
grep -Fq 'STOP: SSH host key is not trusted' "$work_dir/unknown.out" || fail 'unknown-key stop message missing'
[[ ! -e "$work_dir/marker" ]] || fail 'discovery contacted mocked transport before host-key acceptance'

rm -f "$work_dir/marker"
env "${base_env[@]}" ESXI_HOST_FINGERPRINT=SHA256:expected-fingerprint \
  "$script" --accept-new-host-key >"$work_dir/accepted.out" 2>&1 || fail 'explicit matching host-key acceptance should proceed'
grep -Fq 'SSH host key accepted' "$work_dir/accepted.out" || fail 'acceptance report missing'
[[ -f "$work_dir/known_hosts" ]] || fail 'accepted host key was not persisted'
[[ -e "$work_dir/marker" ]] || fail 'mocked transport was not exercised after acceptance'

printf 'PASS: mocked discovery host-key safety\n'

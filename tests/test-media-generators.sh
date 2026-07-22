#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
windows_script="$repo_root/examples/guest-autoinstall/scripts/make-windows-answer-iso.sh"
ubuntu_script="$repo_root/examples/guest-autoinstall/scripts/make-ubuntu-seed-iso.sh"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mock_bin="$work_dir/mock-bin"
mkdir -p "$mock_bin"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cat >"$mock_bin/xorriso" <<'MOCK'
#!/usr/bin/env bash
output=''
while (($#)); do
  if [[ $1 == -o ]]; then output=$2; shift 2; continue; fi
  shift
done
: "${output:?missing output}"
printf 'mock ISO\n' >"$output"
MOCK
chmod +x "$mock_bin/xorriso"

windows_input="$work_dir/windows"
ubuntu_input="$work_dir/ubuntu"
mkdir -p "$windows_input" "$ubuntu_input"
printf '%s\n' '<unattend><ProductKey>REPLACE_WITH_PRODUCT_KEY</ProductKey></unattend>' >"$windows_input/Autounattend.xml"
printf '%s\n' '#cloud-config' 'users:' '  - name: REPLACE_WITH_USER' >"$ubuntu_input/user-data"
printf '%s\n' 'instance-id: demo' >"$ubuntu_input/meta-data"

set +e
PATH="$mock_bin:$PATH" "$windows_script" "$windows_input" "$work_dir/windows.iso" >"$work_dir/windows-refuse.out" 2>&1
status=$?
set -e
[[ $status -ne 0 ]] || fail 'Windows ISO generator accepted placeholders by default'
grep -Fq 'placeholder' "$work_dir/windows-refuse.out" || fail 'Windows rejection did not explain placeholders'

PATH="$mock_bin:$PATH" "$windows_script" --allow-placeholders "$windows_input" "$work_dir/windows.iso" >"$work_dir/windows-allow.out" 2>&1 || fail 'Windows demo ISO generation failed'
[[ -f "$work_dir/windows.iso" && -f "$work_dir/windows.iso.sha256" ]] || fail 'Windows ISO or checksum missing'

set +e
PATH="$mock_bin:$PATH" "$ubuntu_script" "$ubuntu_input" "$work_dir/ubuntu.iso" >"$work_dir/ubuntu-refuse.out" 2>&1
status=$?
set -e
[[ $status -ne 0 ]] || fail 'Ubuntu ISO generator accepted placeholders by default'

PATH="$mock_bin:$PATH" "$ubuntu_script" --allow-placeholders "$ubuntu_input" "$work_dir/ubuntu.iso" >"$work_dir/ubuntu-allow.out" 2>&1 || fail 'Ubuntu demo ISO generation failed'
[[ -f "$work_dir/ubuntu.iso" && -f "$work_dir/ubuntu.iso.sha256" ]] || fail 'Ubuntu ISO or checksum missing'

set +e
PATH="$mock_bin:$PATH" "$windows_script" --allow-placeholders "$windows_input" "$work_dir/windows.iso" >"$work_dir/no-force.out" 2>&1
status=$?
set -e
[[ $status -ne 0 ]] || fail 'Windows ISO generator overwrote existing file without --force'

printf 'PASS: mocked media generator safety\n'

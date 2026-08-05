#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
validator="$repo_root/scripts/validate-packer-contract.sh"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

"$validator" >"$work_dir/static.out" || fail 'committed Packer contract did not validate'
grep -Fq 'reviewed-skeleton' "$work_dir/static.out" || fail 'static validation did not report the skeleton contract'

cat >"$work_dir/valid.pkrvars.hcl" <<'VARS'
vcenter_server = "vcsa.lab.internal"
username = "packer-agent"
password = "supplied-from-protected-local-file"
datacenter = "Lab-DC"
cluster = "Lab-Cluster"
host = "esxi-01.lab.internal"
datastore = "datastore1"
network = "VM Network"
iso_path = "ubuntu-server.iso"
iso_checksum = "sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
vm_name = "ubuntu-build-01"
insecure_connection = false
VARS

"$validator" --vars "$work_dir/valid.pkrvars.hcl" >"$work_dir/valid.out" || fail 'valid local Packer variables were rejected'

cp "$work_dir/valid.pkrvars.hcl" "$work_dir/placeholder.pkrvars.hcl"
sed -i 's/Lab-DC/REPLACE_WITH_DATACENTER/' "$work_dir/placeholder.pkrvars.hcl"
set +e
"$validator" --vars "$work_dir/placeholder.pkrvars.hcl" >"$work_dir/placeholder.out" 2>&1
status=$?
set -e
[[ $status -ne 0 ]] || fail 'placeholder variable file was accepted'
grep -Fq 'placeholders or example values' "$work_dir/placeholder.out" || fail 'placeholder rejection was not specific'

cp "$work_dir/valid.pkrvars.hcl" "$work_dir/checksum.pkrvars.hcl"
sed -i 's/sha256:[0-9a-f]*/sha256:deadbeef/' "$work_dir/checksum.pkrvars.hcl"
set +e
"$validator" --vars "$work_dir/checksum.pkrvars.hcl" >"$work_dir/checksum.out" 2>&1
status=$?
set -e
[[ $status -ne 0 ]] || fail 'invalid checksum was accepted'
grep -Fq 'exactly 64 hexadecimal' "$work_dir/checksum.out" || fail 'checksum rejection was not specific'

cp "$work_dir/valid.pkrvars.hcl" "$work_dir/insecure.pkrvars.hcl"
sed -i 's/insecure_connection = false/insecure_connection = true/' "$work_dir/insecure.pkrvars.hcl"
set +e
"$validator" --vars "$work_dir/insecure.pkrvars.hcl" >"$work_dir/insecure.out" 2>&1
status=$?
set -e
[[ $status -ne 0 ]] || fail 'insecure TLS was accepted without an explicit exception'
ALLOW_PACKER_INSECURE_TLS=1 "$validator" --vars "$work_dir/insecure.pkrvars.hcl" >/dev/null || fail 'explicit insecure-TLS exception was not honored'

printf 'PASS: Packer contract regression tests\n'

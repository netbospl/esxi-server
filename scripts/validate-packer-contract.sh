#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
packer_dir="$repo_root/examples/guest-autoinstall/packer"
vars_file=''

usage() {
  cat <<'USAGE'
Usage:
  scripts/validate-packer-contract.sh
  scripts/validate-packer-contract.sh --vars PATH

Without --vars, validate the committed reviewed-skeleton contract. With --vars,
validate a non-committed local variable file before any packer validate/build.
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

while (($#)); do
  case $1 in
    --vars)
      (($# >= 2)) || fail '--vars requires a path'
      vars_file=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

for template in "$packer_dir"/*-vsphere-iso.pkr.hcl; do
  grep -Fq 'TEMPLATE ONLY.' "$template" || fail "missing template warning: ${template#$repo_root/}"
  grep -Fq 'BUILD CONTRACT: reviewed-skeleton' "$template" || fail "missing reviewed-skeleton contract: ${template#$repo_root/}"
  grep -Fq 'UNATTENDED MEDIA: intentionally not attached' "$template" || fail "missing unattended-media boundary: ${template#$repo_root/}"
  grep -Fq 'standalone ESXi is not supported' "$template" || fail "missing standalone ESXi boundary: ${template#$repo_root/}"
  grep -Fq 'vCenter' "$template" || fail "missing vCenter boundary: ${template#$repo_root/}"
done

[[ -n $vars_file ]] || {
  printf 'PASS: committed Packer reviewed-skeleton contract\n'
  exit 0
}

[[ -f $vars_file ]] || fail "variable file not found: $vars_file"

if rg -n -i 'REPLACE_WITH|CHANGEME|example\.(com|test|invalid|local)|placeholder' "$vars_file" >/dev/null; then
  fail 'local Packer variable file contains placeholders or example values'
fi

required=(vcenter_server username password datacenter cluster host datastore network iso_path iso_checksum vm_name)
for key in "${required[@]}"; do
  line=$(rg -n "^[[:space:]]*$key[[:space:]]*=" "$vars_file" | head -n 1 || true)
  [[ -n $line ]] || fail "missing required Packer variable: $key"
  value=${line#*=}
  value=${value//[[:space:]\"]/}
  [[ -n $value ]] || fail "empty required Packer variable: $key"
done

checksum=$(sed -nE 's/^[[:space:]]*iso_checksum[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' "$vars_file" | head -n 1)
[[ $checksum =~ ^sha256:[0-9A-Fa-f]{64}$ ]] || fail 'iso_checksum must be sha256 followed by exactly 64 hexadecimal characters'

if rg -q '^[[:space:]]*insecure_connection[[:space:]]*=[[:space:]]*true([[:space:]]|$)' "$vars_file"; then
  [[ ${ALLOW_PACKER_INSECURE_TLS:-0} == 1 ]] || fail 'insecure_connection=true requires explicit ALLOW_PACKER_INSECURE_TLS=1 exception'
fi

printf 'PASS: local Packer variable preflight\n'

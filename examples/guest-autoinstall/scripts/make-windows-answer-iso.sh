#!/usr/bin/env bash
# Local Bash helper. It creates a removable answer-media ISO only.
set -euo pipefail
umask 077

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=validate-inputs.sh
source "$script_dir/validate-inputs.sh"

usage() {
  cat <<'EOF'
Usage: make-windows-answer-iso.sh [--allow-placeholders] [--force] [SOURCE_DIR] [OUTPUT_ISO]

SOURCE_DIR must contain Autounattend.xml and may contain setupcomplete.cmd.
The generator refuses unresolved placeholders by default. --allow-placeholders
creates a demonstration-only artifact; --force permits replacing OUTPUT_ISO.
EOF
}

allow_placeholders=0
force=0
while (($#)); do
  case $1 in
    --allow-placeholders) allow_placeholders=1 ;;
    --force) force=1 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) printf 'error: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    *) break ;;
  esac
  shift
done

source_dir=${1:-.}
output_iso=${2:-windows-answer.iso}
[[ -d $source_dir ]] || { printf 'error: source directory does not exist: %s\n' "$source_dir" >&2; exit 2; }
[[ -f $source_dir/Autounattend.xml ]] || { printf 'error: missing %s/Autounattend.xml\n' "$source_dir" >&2; exit 2; }
output_iso=$(prepare_output "$output_iso" "$force")
validate_xml "$source_dir/Autounattend.xml"
inputs=("$source_dir/Autounattend.xml")
[[ -f $source_dir/setupcomplete.cmd ]] && inputs+=("$source_dir/setupcomplete.cmd")
validate_placeholders "$allow_placeholders" "${inputs[@]}"

staging_dir=$(mktemp -d "${TMPDIR:-/tmp}/windows-answer-iso.XXXXXX")
trap 'rm -rf "$staging_dir"' EXIT
cp "$source_dir/Autounattend.xml" "$staging_dir/Autounattend.xml"
[[ -f $source_dir/setupcomplete.cmd ]] && cp "$source_dir/setupcomplete.cmd" "$staging_dir/setupcomplete.cmd"
cd "$staging_dir"
files=(Autounattend.xml)
[[ -f setupcomplete.cmd ]] && files+=(setupcomplete.cmd)
if command -v xorriso >/dev/null 2>&1; then
  xorriso -as mkisofs -o "$output_iso" -volid WIN_UNATTEND -J -r "${files[@]}"
elif command -v genisoimage >/dev/null 2>&1; then
  genisoimage -o "$output_iso" -volid WIN_UNATTEND -J -r "${files[@]}"
else
  printf 'error: need xorriso or genisoimage to build a Windows answer ISO\n' >&2
  exit 127
fi
write_checksum "$output_iso"
printf 'created ISO: %s\nSHA-256: %s.sha256\n' "$output_iso" "$output_iso"
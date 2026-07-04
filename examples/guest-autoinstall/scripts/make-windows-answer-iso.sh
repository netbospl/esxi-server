#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: make-windows-answer-iso.sh [SOURCE_DIR] [OUTPUT_ISO]

SOURCE_DIR must contain Autounattend.xml and may optionally contain setupcomplete.cmd.
OUTPUT_ISO defaults to ./windows-answer.iso
EOF
}

source_dir="${1:-.}"
output_iso="${2:-windows-answer.iso}"

if [[ ! -f "$source_dir/Autounattend.xml" ]]; then
  printf 'error: missing %s\n' "$source_dir/Autounattend.xml" >&2
  usage >&2
  exit 1
fi

staging_dir="$(mktemp -d)"
trap 'rm -rf "$staging_dir"' EXIT
cp "$source_dir/Autounattend.xml" "$staging_dir/Autounattend.xml"
[[ -f "$source_dir/setupcomplete.cmd" ]] && cp "$source_dir/setupcomplete.cmd" "$staging_dir/setupcomplete.cmd"

output_iso="$(python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$output_iso")"
cd "$staging_dir"
if command -v xorriso >/dev/null 2>&1; then
  files=(Autounattend.xml)
  [[ -f setupcomplete.cmd ]] && files+=(setupcomplete.cmd)
  xorriso -as mkisofs -o "$output_iso" -volid WIN_UNATTEND -J -r "${files[@]}"
  exit 0
fi

if command -v genisoimage >/dev/null 2>&1; then
  files=(Autounattend.xml)
  [[ -f setupcomplete.cmd ]] && files+=(setupcomplete.cmd)
  genisoimage -o "$output_iso" -volid WIN_UNATTEND -J -r "${files[@]}"
  exit 0
fi

printf 'error: need xorriso or genisoimage to build a Windows answer ISO\n' >&2
exit 1

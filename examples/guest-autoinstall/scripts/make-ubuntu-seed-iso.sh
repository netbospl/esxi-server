#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: make-ubuntu-seed-iso.sh [SOURCE_DIR] [OUTPUT_ISO]

SOURCE_DIR must contain user-data and meta-data.
OUTPUT_ISO defaults to ./seed.iso
EOF
}

source_dir="${1:-.}"
output_iso="${2:-seed.iso}"

if [[ ! -f "$source_dir/user-data" ]]; then
  printf 'error: missing %s\n' "$source_dir/user-data" >&2
  usage >&2
  exit 1
fi
if [[ ! -f "$source_dir/meta-data" ]]; then
  printf 'error: missing %s\n' "$source_dir/meta-data" >&2
  usage >&2
  exit 1
fi

if command -v cloud-localds >/dev/null 2>&1; then
  cloud-localds "$output_iso" "$source_dir/user-data" "$source_dir/meta-data"
  exit 0
fi

staging_dir="$(mktemp -d)"
trap 'rm -rf "$staging_dir"' EXIT
cp "$source_dir/user-data" "$staging_dir/user-data"
cp "$source_dir/meta-data" "$staging_dir/meta-data"

if command -v xorriso >/dev/null 2>&1; then
  xorriso -as mkisofs -o "$output_iso" -volid cidata -J -r "$staging_dir/user-data" "$staging_dir/meta-data"
  exit 0
fi

if command -v genisoimage >/dev/null 2>&1; then
  genisoimage -o "$output_iso" -volid cidata -J -r "$staging_dir/user-data" "$staging_dir/meta-data"
  exit 0
fi

printf 'error: need cloud-localds, xorriso, or genisoimage to build a seed ISO\n' >&2
exit 1

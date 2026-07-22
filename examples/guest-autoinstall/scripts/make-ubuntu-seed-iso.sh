#!/usr/bin/env bash
# Local Bash helper. It creates a NoCloud seed ISO only.
set -euo pipefail
umask 077

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=validate-inputs.sh
source "$script_dir/validate-inputs.sh"

usage() {
  cat <<'EOF'
Usage: make-ubuntu-seed-iso.sh [--allow-placeholders] [--force] [SOURCE_DIR] [OUTPUT_ISO]

SOURCE_DIR must contain user-data and meta-data. The generator refuses
unresolved placeholders by default. --allow-placeholders creates a
demonstration-only artifact; --force permits replacing OUTPUT_ISO.
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
output_iso=${2:-seed.iso}
[[ -d $source_dir ]] || { printf 'error: source directory does not exist: %s\n' "$source_dir" >&2; exit 2; }
[[ -f $source_dir/user-data ]] || { printf 'error: missing %s/user-data\n' "$source_dir" >&2; exit 2; }
[[ -f $source_dir/meta-data ]] || { printf 'error: missing %s/meta-data\n' "$source_dir" >&2; exit 2; }
output_iso=$(prepare_output "$output_iso" "$force")
validate_cloud_init "$source_dir/user-data"
validate_placeholders "$allow_placeholders" "$source_dir/user-data" "$source_dir/meta-data"

staging_dir=$(mktemp -d "${TMPDIR:-/tmp}/ubuntu-seed-iso.XXXXXX")
trap 'rm -rf "$staging_dir"' EXIT
cp "$source_dir/user-data" "$staging_dir/user-data"
cp "$source_dir/meta-data" "$staging_dir/meta-data"
if command -v cloud-localds >/dev/null 2>&1; then
  cloud-localds "$output_iso" "$staging_dir/user-data" "$staging_dir/meta-data"
elif command -v xorriso >/dev/null 2>&1; then
  xorriso -as mkisofs -o "$output_iso" -volid cidata -J -r "$staging_dir/user-data" "$staging_dir/meta-data"
elif command -v genisoimage >/dev/null 2>&1; then
  genisoimage -o "$output_iso" -volid cidata -J -r "$staging_dir/user-data" "$staging_dir/meta-data"
else
  printf 'error: need cloud-localds, xorriso, or genisoimage to build a seed ISO\n' >&2
  exit 127
fi
write_checksum "$output_iso"
printf 'created ISO: %s\nSHA-256: %s.sha256\n' "$output_iso" "$output_iso"
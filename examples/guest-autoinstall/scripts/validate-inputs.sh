#!/usr/bin/env bash
# Shared local Bash validation helpers for example-media generators.
# ShellCheck source=validate-inputs.sh

placeholder_matches() {
  grep -Ein -- 'REPLACE_WITH_|changeme|example\.(com|org|net|local)|sha256:(REPLACE|[[:space:]]*$)|<Value>[[:space:]]*</Value>' "$@" || true
}

validate_placeholders() {
  local allow=$1
  shift
  local matches
  matches=$(placeholder_matches "$@")
  [[ -z $matches ]] && return 0
  if [[ $allow == 1 ]]; then
    printf 'WARNING: placeholders were explicitly allowed; this ISO is demonstration-only and unsafe for deployment.\n' >&2
    printf '%s\n' "$matches" >&2
    return 0
  fi
  printf 'error: refusing to create an ISO with unresolved placeholder values. Use --allow-placeholders only for a demonstration artifact.\n' >&2
  printf '%s\n' "$matches" >&2
  return 1
}

validate_xml() {
  local file=$1
  if command -v xmllint >/dev/null 2>&1; then
    xmllint --noout "$file"
  else
    printf 'warning: xmllint is unavailable; XML well-formedness was not checked.\n' >&2
  fi
}

validate_cloud_init() {
  local user_data=$1
  if command -v cloud-init >/dev/null 2>&1; then
    cloud-init schema --config-file "$user_data"
  elif grep -Fqx '#cloud-config' "$user_data"; then
    printf 'warning: cloud-init is unavailable; only the #cloud-config header was checked.\n' >&2
  else
    printf 'error: user-data is missing the required #cloud-config header.\n' >&2
    return 1
  fi
}

prepare_output() {
  local output=$1 force=$2
  output=$(python3 -c 'import os, sys; print(os.path.abspath(sys.argv[1]))' "$output")
  [[ -d $(dirname "$output") ]] || { printf 'error: output directory does not exist: %s\n' "$(dirname "$output")" >&2; return 1; }
  if [[ -e $output && $force != 1 ]]; then
    printf 'error: refusing to overwrite existing ISO without --force: %s\n' "$output" >&2
    return 1
  fi
  printf '%s\n' "$output"
}

write_checksum() {
  local output=$1
  sha256sum "$output" >"$output.sha256"
}

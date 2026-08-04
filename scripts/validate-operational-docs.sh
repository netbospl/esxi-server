#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

if [[ ${1:-} == --file ]]; then
  [[ $# == 2 && -f $2 ]] || fail 'usage: validate-operational-docs.sh --file FILE'
  operational_files=("$2")
  credential_files=("$2")
  script_files=("$2")
  universal_files=("$2")
else
  repo_root=${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
  mapfile -t operational_files < <(
    {
      printf '%s\n' "$repo_root/SKILL.md"
      find "$repo_root/references" "$repo_root/skills" -type f -name '*.md' -print
    } | sort -u
  )
  credential_files=("$repo_root/scripts" "$repo_root/references" "$repo_root/skills")
  script_files=("$repo_root/scripts")
  universal_files=("$repo_root/SKILL.md" "$repo_root/skills")
fi

if rg -n -- '--formatter=json' "${operational_files[@]}"; then
  fail 'ESXCLI JSON formatter is unsupported; use csv, xml, or keyvalue'
fi

if rg -n --pcre2 'esxcli\s+(?!//|--formatter(?:=|\s))(?:[^`\n]|`(?!`))*--formatter(?:=|\s)' \
  "${operational_files[@]}"; then
  fail 'ESXCLI dispatcher formatter must appear before the namespace'
fi

if rg -n --pcre2 '(?:vim-cmd|esxcli|ovftool|curl|scp|ssh)[^`\n]*<[A-Za-z][A-Za-z0-9_-]*>' \
  "${operational_files[@]}"; then
  fail 'executable examples must use guarded variables, not angle-bracket targets'
fi

if rg -n --pcre2 '(?:-u|--user)(?:=|\s+)"?\$\{?ESXI_USER\}?:\$\{?ESXI_PASS\}?|args\+?=\([^\n]*-u\s+"?\$auth' \
  "${credential_files[@]}"; then
  fail 'password-bearing curl authentication must not be passed in process arguments'
fi

if rg -n -U --pcre2 "printf 'machine %s\\\\nlogin %s\\\\npassword %s\\\\n'[^\n]*\n\\s*\"\\\$ESXI_HOST\"\\s+\"\\\$ESXI_USER\"\\s+\"\\\$ESXI_PASS\"" \
  "${credential_files[@]}"; then
  fail 'netrc examples must reject control characters and escape quoted values'
fi

if rg -n --pcre2 '(?:-H|--header)(?:=|\s+)"?vmware-api-session-id:[^"\n]*\$\{?(?:session|REST_SESSION)|args\+?=\([^\n]*-H\s+"vmware-api-session-id:' \
  "${script_files[@]}"; then
  fail 'session tokens must not be passed to curl in process arguments'
fi

if rg -n -F -e '/api/vcenter/vm/{vm}/snapshot' -e '/api/esx/settings/network' \
  "${universal_files[@]}"; then
  fail 'unverified vCenter-style endpoints must not be universal standalone guidance'
fi

if [[ ${1:-} == --file ]]; then
  discovery_files=("$2")
else
  discovery_files=("$repo_root/scripts/esxi-readonly-discovery.sh")
fi
if rg -n -F -e '/api/vcenter/' -e '/rest/vcenter/' "${discovery_files[@]}"; then
  fail 'standalone discovery helpers must not guess vCenter inventory endpoints'
fi

printf 'PASS: operational documentation validator\n'

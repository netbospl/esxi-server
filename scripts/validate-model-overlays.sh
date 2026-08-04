#!/usr/bin/env bash
set -euo pipefail

command -v rg >/dev/null 2>&1 || {
  printf 'FAIL: required tool missing: rg\n' >&2
  exit 127
}

usage() {
  printf 'Usage: %s --repo ROOT | --overlay FILE\n' "$0" >&2
  exit 2
}

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  return 1
}

validate_overlay() {
  local file=$1 check_links=${2:-1} scope_root=${3:-} words link resolved
  local parent_link profile_link flattened root_real=''
  [[ -f $file ]] || { fail "overlay not found: $file"; return 1; }
  grep -Eq '^description:[[:space:]]*"?Use when' "$file" || {
    fail "$file: description must start with Use when"; return 1;
  }
  parent_link=$(sed -nE 's/^\*\*Canonical parent:\*\*.*\]\(([^)]+)\).*/\1/p' "$file" | head -n 1)
  [[ -n $parent_link && $parent_link != http://* && $parent_link != https://* ]] || {
    fail "$file: canonical parent must be a local Markdown link"; return 1;
  }
  profile_link=$(sed -nE 's/^\*\*Model profile:\*\*.*\]\(([^)]+)\).*/\1/p' "$file" | head -n 1)
  [[ -n $profile_link && $profile_link != http://* && $profile_link != https://* ]] || {
    fail "$file: model profile must be a local Markdown link"; return 1;
  }
  grep -Fq '**Load order:**' "$file" || { fail "$file: missing load order"; return 1; }
  flattened=$(tr '\n' ' ' <"$file")
  grep -Eiq '\*\*Load order:\*\*[^.]*root[^.]*canonical[^.]*model profile[^.]*overlay' <<<"$flattened" || {
    fail "$file: load order must be root, canonical parent, model profile, then overlay"; return 1;
  }
  grep -Fq '## Scope boundaries' "$file" || { fail "$file: missing scope boundaries"; return 1; }
  if rg -n --pcre2 '\b(?:vim-cmd|esxcli|ovftool|curl|scp)\b|\bssh\s+-' "$file"; then
    fail "$file: model overlay duplicates an operational command catalog"; return 1
  fi
  words=$(wc -w <"$file")
  (( words <= 500 )) || { fail "$file: overlay exceeds 500 words ($words)"; return 1; }
  if (( check_links )); then
    if [[ -n $scope_root ]]; then root_real=$(realpath -m -- "$scope_root"); fi
    while IFS= read -r link; do
      [[ $link == http://* || $link == https://* ]] && continue
      resolved=$(realpath -m -- "$(dirname "$file")/$link")
      [[ -e $resolved ]] || {
        fail "$file: local parent/profile link does not exist: $link"; return 1;
      }
      if [[ -n $root_real && $resolved != "$root_real" && $resolved != "$root_real"/* ]]; then
        fail "$file: local link escapes the repository: $link"; return 1
      fi
    done < <(sed -nE 's/.*\]\(([^)#]+)(#[^)]*)?\).*/\1/p' "$file")
  fi
}

case ${1:-} in
  --overlay)
    [[ $# == 2 ]] || usage
    validate_overlay "$2" 1
    ;;
  --repo)
    [[ $# == 2 ]] || usage
    root=$2
    while IFS= read -r overlay; do
      validate_overlay "$overlay" 1 "$root"
    done < <(find "$root/skills/nemotron-3-ultra" -mindepth 2 -maxdepth 2 -type f -name SKILL.md | sort)
    ;;
  *) usage ;;
esac

printf 'PASS: model overlay validation\n'

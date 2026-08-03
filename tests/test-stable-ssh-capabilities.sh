#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$repo_root/skills/stable-ssh-shell/scripts/detect-remote-capabilities.sh"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/bin"
touch "$work_dir/known_hosts" "$work_dir/key"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

cat >"$work_dir/bin/ssh" <<'MOCK'
#!/usr/bin/env bash
case ${MOCK_PROFILE:-linux} in
  linux)
    printf 'target=linux\nshell=bash\ntmux=yes\nnohup=yes\nruntime=yes\npty=yes\n'
    ;;
  esxi)
    printf 'target=esxi\nshell=busybox\ntmux=no\nnohup=no\nruntime=yes\npty=no\n'
    ;;
  fail) exit 255 ;;
esac
MOCK
chmod +x "$work_dir/bin/ssh"

common=(--host mock-host --known-hosts "$work_dir/known_hosts" --identity "$work_dir/key")
linux=$(env PATH="$work_dir/bin:$PATH" MOCK_PROFILE=linux "$script" "${common[@]}")
grep -Fq '"target_class":"linux"' <<<"$linux" || fail 'Linux class missing'
grep -Fq '"supported_modes":["A","B","C","D","E"]' <<<"$linux" || fail 'Linux modes missing'
grep -Fq '"builtin_ssh_compatible":true' <<<"$linux" || fail 'Hermes Linux compatibility missing'

esxi=$(env PATH="$work_dir/bin:$PATH" MOCK_PROFILE=esxi "$script" "${common[@]}")
grep -Fq '"target_class":"esxi"' <<<"$esxi" || fail 'ESXi class missing'
grep -Fq '"supported_modes":["A","E"]' <<<"$esxi" || fail 'ESXi fallback modes missing'
grep -Fq '"recommended_backend":"local"' <<<"$esxi" || fail 'ESXi local backend missing'

set +e
failed=$(env PATH="$work_dir/bin:$PATH" MOCK_PROFILE=fail "$script" "${common[@]}")
rc=$?
set -e
[[ $rc -eq 20 ]] || fail 'transport failure exit code mismatch'
grep -Fq '"recommended_mode":"E"' <<<"$failed" || fail 'transport failure must select E'

printf 'PASS: stable SSH capability and Hermes mode routing\n'

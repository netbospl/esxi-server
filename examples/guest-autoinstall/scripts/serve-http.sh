#!/usr/bin/env bash
set -euo pipefail

port="${1:-8000}"
bind_addr="${2:-127.0.0.1}"
root_dir="${3:-$(pwd)}"

case "$bind_addr" in
  127.0.0.1|localhost|::1)
    ;;
  *)
    printf 'warning: binding HTTP server to non-localhost address %s\n' "$bind_addr" >&2
    ;;
esac

printf 'Serving %s on http://%s:%s/\n' "$root_dir" "$bind_addr" "$port"
exec python3 -m http.server "$port" --bind "$bind_addr" --directory "$root_dir"

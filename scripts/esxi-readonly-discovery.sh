#!/usr/bin/env bash
set -uo pipefail

section() {
  printf '\n=== %s ===\n' "$1"
}

run_ssh() {
  local label=$1
  local remote_cmd=$2
  local output status
  if [[ -z ${ESXI_SSH_KEY:-} ]]; then
    section "$label"
    printf 'SKIPPED: ESXI_SSH_KEY is not set\n'
    return 0
  fi
  section "$label"
  if output=$(ssh -i "$ESXI_SSH_KEY" \
      -o UserKnownHostsFile="$ESXI_KNOWN_HOSTS" \
      -o StrictHostKeyChecking=yes \
      -o BatchMode=yes \
      -o ConnectTimeout=10 \
      "$ESXI_USER@$ESXI_HOST" "$remote_cmd" 2>&1); then
    printf '%s\n' "$output"
  else
    status=$?
    printf 'FAILED (%s)\n%s\n' "$status" "$output"
  fi
}

run_rest() {
  local label=$1
  local endpoint=$2
  local session output status
  section "$label"
  if [[ -z ${ESXI_PASS:-} ]]; then
    printf 'SKIPPED: ESXI_PASS is not set\n'
    return 0
  fi
  if ! session=$(curl -sk -X POST "https://$ESXI_HOST/api/session" -u "$ESXI_USER:$ESXI_PASS" -H 'Content-Type: application/json' | tr -d '"'); then
    printf 'FAILED: could not create REST session\n'
    return 0
  fi
  if [[ -z $session ]]; then
    printf 'FAILED: empty REST session token\n'
    return 0
  fi
  if output=$(curl -sk "https://$ESXI_HOST$endpoint" -H "vmware-api-session-id: $session" 2>&1); then
    printf '%s\n' "$output"
  else
    status=$?
    printf 'FAILED (%s)\n%s\n' "$status" "$output"
  fi
}

ESXI_HOST=${ESXI_HOST:-}
if [[ -z $ESXI_HOST ]]; then
  printf 'ESXI_HOST is required\n' >&2
  exit 1
fi

ESXI_USER=${ESXI_USER:-agent}
ESXI_KNOWN_HOSTS=${ESXI_KNOWN_HOSTS:-$PWD/.ssh-known-hosts/esxi_known_hosts}

section "Environment"
printf 'ESXI_HOST=%s\n' "$ESXI_HOST"
printf 'ESXI_USER=%s\n' "$ESXI_USER"
printf 'ESXI_KNOWN_HOSTS=%s\n' "$ESXI_KNOWN_HOSTS"
if [[ -n ${ESXI_SSH_KEY:-} ]]; then
  printf 'ESXI_SSH_KEY is set\n'
else
  printf 'ESXI_SSH_KEY is not set\n'
fi
if [[ -n ${ESXI_PASS:-} ]]; then
  printf 'ESXI_PASS is set\n'
else
  printf 'ESXI_PASS is not set\n'
fi

if [[ -n ${ESXI_SSH_KEY:-} ]]; then
  mkdir -p "$(dirname "$ESXI_KNOWN_HOSTS")"
  if ! ssh-keygen -F "$ESXI_HOST" -f "$ESXI_KNOWN_HOSTS" >/dev/null 2>&1; then
    if ! ssh-keyscan -H "$ESXI_HOST" >> "$ESXI_KNOWN_HOSTS" 2>/dev/null; then
      printf 'WARNING: ssh-keyscan failed; continuing with existing known-hosts file\n'
    fi
  fi
fi

run_ssh "Host version" 'vmware -v'
run_ssh "ESXi version" 'esxcli system version get'
run_ssh "Hardware memory" 'esxcli hardware memory get'
run_ssh "Storage filesystems" 'esxcli storage filesystem list'
run_ssh "VM inventory" 'vim-cmd vmsvc/getallvms'
run_ssh "Virtual switches" 'esxcli network vswitch standard list'
run_ssh "Port groups" 'esxcli network vswitch standard portgroup list'
run_ssh "IP interfaces" 'esxcli network ip interface list'
run_ssh "Firewall rulesets" 'esxcli network firewall ruleset list'
run_rest "REST VM listing" '/api/vcenter/vm'
run_rest "REST datastore listing" '/api/vcenter/datastore'
run_rest "REST network listing" '/api/vcenter/network'

section "Done"
printf 'Read-only discovery complete. Review failed sections above before acting.\n'

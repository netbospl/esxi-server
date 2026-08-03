# ESXi atomic one-shot example

Direct ESXi normally selects Mode A. Use the parent guarded discovery helper
for first contact and host-key verification. After trust and authorization are
already established, use one quoted read-only command:

```bash
: "${ESXI_HOST:?ESXI_HOST is required}"
: "${ESXI_USER:=agent}"
: "${ESXI_SSH_KEY:?ESXI_SSH_KEY is required}"
: "${ESXI_KNOWN_HOSTS:?ESXI_KNOWN_HOSTS is required}"

ssh -i "$ESXI_SSH_KEY" \
  -o IdentitiesOnly=yes \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=yes \
  -o "UserKnownHostsFile=$ESXI_KNOWN_HOSTS" \
  -o ForwardAgent=no \
  "$ESXI_USER@$ESXI_HOST" -- \
  'esxcli system version get'
```

Do not install tmux, Bash, Python, or a package manager on ESXi. State-changing
commands still require the exact R0–R3 approval defined by the parent skill.

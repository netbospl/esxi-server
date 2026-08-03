# Linux persistent-session example

Use only after host trust and capability detection confirm a compatible Linux
management host with tmux.

```bash
skill_dir=skills/stable-ssh-shell
known_hosts='<DEDICATED_KNOWN_HOSTS_PATH>'

"$skill_dir/scripts/detect-remote-capabilities.sh" \
  --host stable-management \
  --known-hosts "$known_hosts"

"$skill_dir/scripts/stable-ssh-session.sh" \
  --host stable-management \
  --known-hosts "$known_hosts" \
  --session stable-management-maintenance \
  session-start

"$skill_dir/scripts/stable-ssh-session.sh" \
  --host stable-management \
  --known-hosts "$known_hosts" \
  --session stable-management-maintenance \
  --command '<APPROVED_COMMAND>' \
  session-exec
```

The helper creates or inspects only the named session and streams the
marker-based controller to the compatible remote Bash host without installing
it. Do not reuse the example name for unrelated concurrent tasks.

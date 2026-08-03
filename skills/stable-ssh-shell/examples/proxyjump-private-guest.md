# ProxyJump private-guest example

First establish the approved VPN or dedicated-jump route in the parent
private-guest module. Put the sanitized SSH configuration shape in a protected
local file, then use its final-host alias:

```bash
skills/stable-ssh-shell/scripts/detect-remote-capabilities.sh \
  --host stable-private-guest \
  --known-hosts '<DEDICATED_GUEST_KNOWN_HOSTS_PATH>'
```

OpenSSH applies `ProxyJump` from the local SSH configuration. The final guest
still needs its own trusted key and dedicated credential. Never point these
helpers at the pfSense administrative shell as a persistence host.

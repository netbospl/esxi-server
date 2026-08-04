---
name: private-guest-shell
description: "Open a safe SSH or persistent shell to a private VM behind pfSense by using a verified VPN path, a dedicated jump VM, or a time-limited direct-recovery mapping. Use when an external Hermes agent must reach an internal ESXi guest through the secondary public pfSense endpoint without treating pfSense itself as a bastion."
---

# Private guest shell

Establish the outer network path separately from the final guest shell. The
secondary public `/32` terminates on pfSense WAN; it is never the SSH identity
of a private guest and does not authorize access to one.

## Required workflow

1. Load [`../../SKILL.md`](../../SKILL.md) for R0-R3 approvals and
   [`../../references/private-guest-access-via-pfsense.md`](../../references/private-guest-access-via-pfsense.md)
   for the network and identity gates.
2. Select exactly one outer-path mode:
   - `vpn-direct`: preferred; the agent joins the approved WireGuard, OpenVPN,
     or site-to-site path and addresses the private guest directly;
   - `dedicated-jump`: use a hardened jump VM when the agent cannot run the VPN
     client;
   - `direct-recovery`: use one temporary source-restricted port mapping to one
     guest service only for explicitly approved recovery.
3. Verify the outer path without attempting guest authentication:
   - the VPN handshake or jump endpoint has the expected peer identity;
   - the route to the guest uses the intended tunnel or jump path;
   - the exact guest address and service are reachable;
   - an unapproved source or target is still denied.
4. Verify the final guest independently by UUID/current VMID, vNIC MAC,
   lease/static mapping/internal DNS, dedicated credential, and a host key
   confirmed through an independent channel.
5. Load [`../stable-ssh-shell/SKILL.md`](../stable-ssh-shell/SKILL.md), select
   its smallest viable execution mode, and use its helpers for persistence,
   tmux/PTY control, deterministic completion, and uncertain-state recovery.
6. Report the outer mode, final guest identity, stable-shell mode, approval
   scope, result, expiry, and revocation state separately.

## Non-negotiable boundaries

- Do not use the pfSense shell, WebGUI, or secondary WAN address as a general
  SSH bastion. pfSense is the VPN/firewall/router boundary only.
- Keep pfSense WebGUI and SSH closed on WAN during normal operation.
- Keep `ForwardAgent=no`, `StrictHostKeyChecking=yes`,
  `ExitOnForwardFailure=yes`, and dedicated known-hosts files.
- Verify jump-host and final-guest keys independently. Never delete a changed
  key and continue.
- Keep ESXi, pfSense, jump-host, and guest credentials separate. Do not copy
  unrelated keys to the jump host.
- Do not add NAT to conceal an unproven return route.
- Do not turn an access-path approval into permission for a guest command.
  Guest commands inherit their own R0-R3 classification.
- STOP on ambiguous guest identity, stale VMID, changed key, missing route,
  broad rule, expired approval, unknown command state, or lost ESXi management.

## Mode gates

### `vpn-direct`

Use a protected client profile outside the repository. Before SSH, require:

1. a current handshake with the intended pfSense peer;
2. an exact route from the agent to the approved guest prefix through the VPN;
3. scoped tunnel-interface rules for the agent source, guest target, and
   service;
4. no VPN-provided replacement default route unless explicitly approved;
5. a tested peer-disable action.

After those gates pass, the final SSH target is the private guest—not pfSense.

### `dedicated-jump`

Require a minimal patched jump VM, a source-restricted public mapping, a
dedicated non-root account, and an internal rule limited to approved guests and
services. A sanitized local SSH shape is:

```sshconfig
Host private-guest
    HostName <PRIVATE_GUEST_ADDRESS>
    User <GUEST_USER>
    IdentityFile <GUEST_KEY_PATH>
    IdentitiesOnly yes
    UserKnownHostsFile <GUEST_KNOWN_HOSTS_PATH>
    StrictHostKeyChecking yes
    ForwardAgent no
    ExitOnForwardFailure yes
    ProxyJump dedicated-jump

Host dedicated-jump
    HostName <JUMP_PUBLIC_ENDPOINT>
    User <JUMP_USER>
    IdentityFile <JUMP_KEY_PATH>
    IdentitiesOnly yes
    UserKnownHostsFile <JUMP_KNOWN_HOSTS_PATH>
    StrictHostKeyChecking yes
    ForwardAgent no
    ExitOnForwardFailure yes
```

Do not substitute the pfSense WAN address as `dedicated-jump` unless that
address maps to a separate, approved jump VM service.

### `direct-recovery`

Require one known agent source, one public port, one private guest, one service,
an explicit expiry, and immediate rule removal after verification. Prefer an
atomic command; do not leave a persistent session beyond the recovery window.
This mode never opens pfSense SSH or WebGUI and must not become a permanent
automation path.

## Guest-shell invocation

Use local-only environment variables and never print their values:

```bash
: "${GUEST_HOST:?set the verified private guest address}"
: "${GUEST_USER:?set the dedicated guest user}"
: "${GUEST_SSH_KEY:?set the protected guest key path}"
: "${GUEST_KNOWN_HOSTS:?set the dedicated known-hosts path}"

ssh -o BatchMode=yes \
  -o StrictHostKeyChecking=yes \
  -o ExitOnForwardFailure=yes \
  -o ForwardAgent=no \
  -o IdentitiesOnly=yes \
  -o "UserKnownHostsFile=$GUEST_KNOWN_HOSTS" \
  -i "$GUEST_SSH_KEY" \
  "$GUEST_USER@$GUEST_HOST" -- '<APPROVED_COMMAND>'
```

Add the approved local SSH alias for `dedicated-jump`; do not splice credentials
or private addresses into a committed command.

## Completion contract

- The expected VPN or jump identity and route are proven.
- The final guest host key and credential are independently trusted.
- Only approved guest targets and services are reachable.
- pfSense WebGUI/SSH and unrelated LAN targets remain unreachable from WAN.
- ESXi management and the pfSense `/32` ownership remain unchanged.
- Disabling the VPN peer, jump mapping, or recovery rule removes access.
- Stable-shell output includes the exact result state and never replays an
  `unknown_state` command.

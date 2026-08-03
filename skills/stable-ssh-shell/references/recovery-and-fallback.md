# Recovery and fallback

## Recovery order

After a disconnect or timeout:

1. Re-establish the route and reverify the intended host identity.
2. Check the OpenSSH control socket independently, if one was used.
3. Locate the exact deterministic session and pane.
4. Inspect pane-dead state and bounded captured history.
5. Search for the matching start and done markers.
6. Return the strongest state supported by evidence.

Do not create a replacement session before inspecting the expected one; doing
so can hide a still-running command or create duplicate work.

## Retry rule

Retry only when at least one condition is true:

- the operation is declared idempotent and its repeated effects are acceptable;
- reliable evidence proves the command never emitted its start marker and did
  not otherwise begin;
- a target-native task system proves that no task was created.

If the start marker exists without a matching done marker and current execution
cannot be inspected, return `unknown_state`. Never replay automatically.

## Fallback ladder

1. Reuse a healthy transport and existing exact session.
2. Establish a fresh SSH transport and reattach to the exact session.
3. For non-interactive work, use an approved detached job/status mechanism.
4. For restricted targets, fall back to atomic one-shot commands or a
   compatible management/jump host.
5. Return Mode E and stop when persistence, trust, or state inspection cannot
   be established safely.

Mosh, Eternal Terminal, zmx, screen, zellij, and autossh are optional tools,
not automatic dependencies. Check installation, network policy, live version,
and CLI help before use. None makes unknown command state safe to replay.

## Cleanup after recovery

Remove only task-owned stale sockets and sessions after proving they are not
running approved work. Record what was removed and whether any uncertain
remote operation remains.

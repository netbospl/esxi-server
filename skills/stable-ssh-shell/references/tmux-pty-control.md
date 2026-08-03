# tmux and interactive PTY control

Use tmux only on a compatible, approved general-purpose host. A one-shot shell
command or non-interactive detached job is simpler when terminal state is not
required.

## Safe control sequence

1. Verify `tmux` exists and the version supports the planned flags.
2. Resolve the exact `session:window.pane`.
3. Confirm the session exists and the pane is not dead.
4. Capture the pane before input.
5. Inspect and classify any prompt.
6. Send ordinary text literally:

   ```bash
   tmux send-keys -t "$PANE" -l -- "$TEXT"
   tmux send-keys -t "$PANE" Enter
   ```

7. Poll captured output for an exact readiness or completion marker.
8. Capture final state and record the pane identity.

Special keys such as `C-c`, `Escape`, or arrow keys must be explicit operations
after inspecting the current pane. Do not combine untrusted text with key names
in one `send-keys` invocation.

## Prompt policy

Return `prompt_detected` when a prompt requires a decision that is not already
approved and unambiguous. Never guess the response. In particular, never send
confirmation, Enter, a password, a recovery answer, or destructive selection
merely because output contains words such as “continue” or “yes/no”.

## Polling

Use [`../scripts/wait-for-pane-text.sh`](../scripts/wait-for-pane-text.sh) for
bounded fixed-string polling. A timeout is evidence only that the marker was
not observed in the captured range; it is not proof that the command failed or
never started.

Avoid fixed sleeps as completion checks. A short polling interval is permitted
between state observations.

## Cleanup

Kill only an exact session owned by the task, after verifying that no approved
work still depends on it. Never use `tmux kill-server` for routine cleanup.

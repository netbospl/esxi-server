# SSH VM lifecycle

Start with [`../SKILL.md`](../SKILL.md). Use only with a trusted SSH path.

Resolve a fresh VMID, match it to the approved VM name and UUID, then assign it explicitly:

```bash
: "${VMID:?set from fresh verified inventory}"
vim-cmd vmsvc/power.getstate "$VMID"
vim-cmd vmsvc/get.summary "$VMID"
vim-cmd vmsvc/get.guest "$VMID"
```

Before any lifecycle change, verify current power state, relevant host RAM/capacity, dependencies, expected service impact, rollback, and the root risk gate.

After the required approval, these may be appropriate when their exact syntax is confirmed on the target:

```bash
vim-cmd vmsvc/power.on "$VMID"
vim-cmd vmsvc/power.shutdown "$VMID"
vim-cmd vmsvc/power.reboot "$VMID"
```

Graceful shutdown/reboot depends on healthy VMware Tools. Forced power-off, reset, and destroy are R2/R3 operations and must not be introduced as speculative troubleshooting.

Verify the resulting power state with a fresh read-only query and, where relevant, verify guest/application health separately.

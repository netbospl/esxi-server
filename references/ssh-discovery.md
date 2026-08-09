# SSH read-only discovery

Start with [`../SKILL.md`](../SKILL.md). Use this module when the task is bounded read-only discovery over an already trusted SSH path. If transport/trust is unknown, use `capability-probe.md` first.

Run only the subset needed to answer the current question:

```bash
vmware -v
esxcli system version get
esxcli hardware platform get
esxcli hardware cpu global get
esxcli hardware memory get
esxcli --formatter=csv storage filesystem list
vim-cmd vmsvc/getallvms
esxcli --formatter=csv network vswitch standard list
esxcli --formatter=csv network ip interface list
esxcli --formatter=csv network firewall ruleset list
```

Prefer one bounded discriminator over collecting the full inventory. Inventory is sensitive; retain only facts/IDs needed for the task and avoid copying private output into the repository.

Discovery is R0 and never authorizes a change. If a result indicates a specific lifecycle, snapshot, storage, or network task, load only that matching SSH module next.

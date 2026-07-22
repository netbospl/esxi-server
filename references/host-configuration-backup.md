# ESXi host configuration backup and restore

> **Scope:** standalone ESXi host configuration, not a VM backup. Follow the
> canonical risk and consent model in [`../SKILL.md`](../SKILL.md): backup is
> R1; restore is R3 and requires exact-target approval, verified rollback,
> maintenance window, and out-of-band management.

- **Supported scope:** standalone ESXi 7.x/8.x procedures; command availability
  and exact workflow must be checked on the target build.
- **Last validated:** documentation review, 2026-07-22.
- **Validation status:** static documentation only; no ESXi host was contacted.
- **Primary source:** [Broadcom KB 313510](https://knowledge.broadcom.com/external/article/313510/how-to-back-up-and-restore-the-esxi-host.html).

## Do not confuse these artifacts

| Artifact | Protects | Does not replace |
|---|---|---|
| Host configuration bundle | ESXi host configuration | VM disks/data, VM inventory, bootbank image |
| VM backup | Guest VM data and configuration | Host configuration bundle |
| Snapshot | Point-in-time VM disk state | A backup or host configuration bundle |
| OVF/OVA export | Portable VM export | Incremental VM backup or host configuration backup |
| Datastore file copy | Selected datastore files | Inventory consistency or host configuration backup |

## Backup runbook (R1)

1. Record host version, build, UUID, date, management address, and destination
   reference in a local protected record; do not commit inventory data.
2. Confirm adequate external storage and that the destination is **outside the
   ESXi host and outside this public repository**.
3. On the host, run the documented read/prepare steps:

   ```sh
   vim-cmd hostsvc/firmware/sync_config
   vim-cmd hostsvc/firmware/backup_config
   ```

4. Download the generated bundle only through the authenticated management
   connection using certificate validation (or an explicitly verified CA/pin),
   write it outside the host and repository with restrictive permissions, and
   calculate SHA-256 after download. Record the checksum with build, UUID, and
   date; do not put the URL, cookie, or bundle in a report or commit.
5. The operator needs privileges sufficient for host firmware configuration
   backup and for authenticated datastore/management download; verify the role
   in the current Broadcom procedure rather than assuming a read-only role.
6. Verify that the downloaded artifact is readable and that the checksum and
   metadata record are stored separately from the host.

Do not treat the bundle as a VM backup: VM inventory and bootbank are not
contained. Keep an inventory/export plan for critical VMs separately.

## Restore runbook (R3)

1. Require explicit approval naming the exact host, accepted downtime, and the
   data/access-loss risk. Ensure maintenance mode and a tested out-of-band
   console path.
2. Verify the bundle checksum, source date, exact host UUID, and the
   **identical ESXi build** before touching the host. Broadcom's restore
   requirement is not merely a “compatible build”. **STOP** on UUID mismatch,
   a different build, or uncertainty.
3. ESXi 7.0 U2 and later hosts using TPM have additional restore limitations;
   consult the current Broadcom procedure before proceeding.
4. Expect required restarts: restore can automatically reboot the host. Prepare
   a rollback path using the pre-change bundle and console access.
5. After restore/reboot, verify management reachability, version/build,
   networking, storage visibility, and required services. Re-register/re-add VM
   inventory as needed because inventory is not included in the bundle.
6. Record pre/post evidence, exit codes, deviations, and residual risk in the
   approved report template.

Never automate restore from this repository without a separately reviewed,
mock-tested procedure for the exact environment.

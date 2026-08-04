# ESXi host patch and upgrade runbook

Start with the canonical R0-R3 policy in [`../SKILL.md`](../SKILL.md). This
reference covers preparation and decision gates for standalone ESXi 7.x and
8.x. It does not provide a universal apply command: the correct workflow
depends on the exact source build, target image, hardware, boot media, and
whether vCenter Lifecycle Manager manages the host.

## Authoritative scope

- Record the installed version, build, vendor image, acceptance level, boot
  device, Secure Boot/TPM state, and management mode.
- Check the exact target release notes, interoperability matrix, hardware
  compatibility list, OEM server/firmware guidance, and licensing entitlement.
- ESXi 7.x is beyond general support. Do not imply that an available bundle
  makes the platform supported.
- Starting with ESXi 8.0 Update 2, the vendor no longer supports the older VIB
  install/update route for host upgrades. Select an image-profile or Lifecycle
  Manager workflow from current documentation for the exact build.

Current vendor entry points:

- [Patching ESXi using the command line (KB 343840)](https://knowledge.broadcom.com/external/article/343840/patching-esxi-host-using-command-line.html)
- [Upgrade with an offline ZIP bundle (KB 343425)](https://knowledge.broadcom.com/external/article/343425/upgrade-a-host-with-offline-zip-bundle.html)
- [Lifecycle Manager upgrade workflow (KB 442830)](https://knowledge.broadcom.com/external/article/442830/upgrading-esxi-hosts-using-lifecycle-man.html)
- [ESXCLI software command reference](https://developer.broadcom.com/xapis/esxcli-command-reference/latest/namespace/esxcli_software.html)
- [vSphere end-of-support dates (KB 415405)](https://knowledge.broadcom.com/external/article/415405/end-of-general-support-for-vsphere.html)

Re-open these sources immediately before planning; vendor procedures and
support boundaries can change.

## R0 evidence package

Collect and protect:

```sh
vmware -vl
esxcli software profile get
esxcli software acceptance get
esxcli software vib list
```

For a downloaded offline bundle, set an exact protected path and list its image
profiles without applying it:

```sh
: "${OFFLINE_BUNDLE:?set the verified offline-bundle path}"
esxcli software sources profile list --depot "$OFFLINE_BUNDLE"
```

Also confirm datastore space, scratch/log persistence, bootbank health,
management networking, DNS/NTP, out-of-band console access, VM inventory and
power state, and whether the host participates in vCenter, vSAN, NSX, clusters,
or vendor add-ons. Treat warnings as evidence to resolve, not flags to bypass.

## R2/R3 change gate

Before any stage, remediation, maintenance-mode, or reboot action, the plan
must name:

1. Exact host identity, current build, target build/image profile, OEM add-ons,
   signed-bundle origin, digest, and acceptance level.
2. Compatibility evidence for server, CPU, storage/NIC controllers, firmware,
   boot media, TPM/Secure Boot, vCenter, backup products, and guest workloads.
3. VM evacuation or approved shutdown, maintenance window, downtime approval,
   and a tested out-of-band console.
4. A verified host-configuration bundle stored off-host plus independent VM
   backups. A host bundle is not a VM backup.
5. The exact vendor-documented precheck/dry-run and apply commands for this
   build, expected output, abort conditions, and reboot behavior.
6. Rollback compatibility and the exact current vendor procedure for the
   alternate bootbank/recovery path. Do not assume rollback is available after
   a major upgrade or partition/schema change.

Never add force, signature-bypass, hardware-warning-bypass, downgrade, or
insecure-depot options merely to make a precheck pass. Such a deviation is a
new R3 plan requiring vendor justification and a second acknowledgement of
data/access-loss risk.

## Verification

After reboot, independently verify version/build, Secure Boot/TPM state,
management access, storage paths, NIC/uplink state, VMkernel services,
datastores, time/DNS, host services, hardware sensors, vCenter connection, and
application-level workload health. Keep the host in maintenance mode until the
planned checks pass. If state differs from the approved plan, stop, preserve
logs, and use the incident-triage skill before retrying or rolling back.

# Guest OS unattended install examples

These files are **templates**, not drop-in production artifacts.
They are designed for ESXi 7-compatible VMs and keep host details, passwords, product keys,
private IPs, and datastore names generic.

## Suggested workflow

1. Pick the guest family.
2. Copy the template into a local-only working directory.
3. Replace every `REPLACE_WITH_*` placeholder.
4. Generate answer media or seed media with the helper scripts.
5. Attach the media to a disposable VM and verify boot order.
6. Install VMware Tools or open-vm-tools after the guest comes up.

## Layout

```text
examples/guest-autoinstall/
├── windows/
│   ├── Autounattend.xml
│   ├── autounattend-win10-win11.xml
│   ├── autounattend-server2022.xml
│   ├── autounattend-local-account-snippet.xml
│   ├── oobe-local-account-notes.md
│   └── setupcomplete.cmd
├── linux/
│   ├── ubuntu/
│   │   ├── user-data
│   │   └── meta-data
│   ├── rhel-rocky-alma/
│   │   └── ks.cfg
│   └── debian/
│       └── preseed.cfg
├── packer/
│   ├── windows-vsphere-iso.pkr.hcl
│   ├── ubuntu-vsphere-iso.pkr.hcl
│   └── variables.pkrvars.example.hcl
└── scripts/
    ├── make-ubuntu-seed-iso.sh
    ├── make-windows-answer-iso.sh
    └── serve-http.sh
```

## File notes

- `windows/Autounattend.xml` is a generic baseline.
- `windows/autounattend-win10-win11.xml` is a desktop-oriented variant.
- `windows/autounattend-server2022.xml` is a server-oriented variant.
- `windows/oobe-local-account-notes.md` documents version-dependent Windows 11 local-account rescue paths.
- `windows/autounattend-local-account-snippet.xml` contains only the `UserAccounts` / `LocalAccounts` fragment.
- `windows/setupcomplete.cmd` shows a safe VMware Tools silent install attempt.
- `linux/ubuntu/user-data` and `linux/ubuntu/meta-data` form a NoCloud seed pair.
- `linux/rhel-rocky-alma/ks.cfg` is a destructive Kickstart template for disposable VMs.
- `linux/debian/preseed.cfg` is a Debian Installer preseed template.
- `packer/*.pkr.hcl` sketches `vsphere-iso` usage and the vSphere API dependency.
- `scripts/make-ubuntu-seed-iso.sh` and `scripts/make-windows-answer-iso.sh` create local ISO artifacts.
- `scripts/serve-http.sh` serves Kickstart or preseed files over localhost by default.

## Windows 11 local-account notes

- Prefer `Autounattend.xml` for repeatable builds that need a local account during setup.
- Use `windows/oobe-local-account-notes.md` when you need a rescue path for interactive Windows 11 setup on a lab VM.
- The commands documented there are version-dependent fallback methods, not guaranteed automation interfaces.
- Test against the exact Windows ISO/build because OOBE behavior changes over time.
- Keep answer files sanitized; they can contain secrets.

## Safety reminders

- Do not commit customized secrets, product keys, hashes, or private inventory.
- Do not commit generated ISO files.
- Use the templates as a starting point only.
- Check the guest OS version against the VMware/Broadcom compatibility guide before building a VM.
- Keep the ESXi host automation docs separate from these guest-install templates.

# Guest OS unattended install examples

These files are **templates**, not drop-in production artifacts. They target
ESXi-compatible lab VMs and keep host details, passwords, product keys, private
IPs, and datastore names generic.

## Suggested workflow

1. Pick the guest family and explicit Windows firmware/partitioning variant.
2. Copy the template into a local-only working directory.
3. Replace every `REPLACE_WITH_*` placeholder.
4. Generate answer or seed media with the helper scripts.
5. Attach media only to a disposable VM and verify boot order.
6. Install VMware Tools or open-vm-tools after the guest comes up.

## Layout

```text
examples/guest-autoinstall/
├── windows/
│   ├── autounattend-win10-bios-mbr.xml
│   ├── autounattend-win10-uefi-gpt.xml
│   ├── autounattend-win11-uefi-gpt.xml
│   ├── autounattend-server2022-uefi-gpt.xml
│   ├── autounattend-local-account-snippet.xml
│   ├── oobe-local-account-notes.md
│   └── setupcomplete.cmd
├── linux/{ubuntu,rhel-rocky-alma,debian}/
├── packer/
│   ├── ubuntu-vsphere-iso.pkr.hcl
│   ├── windows-vsphere-iso.pkr.hcl
│   └── variables.pkrvars.example.hcl
└── scripts/
    ├── validate-inputs.sh
    ├── make-ubuntu-seed-iso.sh
    ├── make-windows-answer-iso.sh
    └── serve-http.sh
```

## Windows variants

- `autounattend-win10-bios-mbr.xml` — Windows 10, BIOS/MBR.
- `autounattend-win10-uefi-gpt.xml` — Windows 10, UEFI/GPT.
- `autounattend-win11-uefi-gpt.xml` — Windows 11, UEFI/GPT; it does not bypass
  Windows 11 requirements or claim standalone-ESXi vTPM support.
- `autounattend-server2022-uefi-gpt.xml` — Windows Server 2022, UEFI/GPT.

All answer files can erase the target disk. Review the `WillWipeDisk` warning
and partition layout before use. `oobe-local-account-notes.md` contains only
version-dependent interactive fallback guidance.

### Build answer media from a local copy

The descriptive XML names above identify repository templates; they are not the
root filename expected by Windows Setup. Copy exactly one selected variant to a
local working directory as `Autounattend.xml` before generating media:

```bash
mkdir -p /bezpieczna/lokalna/sciezka/windows-answer
cp examples/guest-autoinstall/windows/autounattend-win11-uefi-gpt.xml \
  /bezpieczna/lokalna/sciezka/windows-answer/Autounattend.xml
```

Run `scripts/make-windows-answer-iso.sh` against that local directory. The
output media must contain `Autounattend.xml`; do not rename committed templates.

## Local media generators

`make-ubuntu-seed-iso.sh` and `make-windows-answer-iso.sh` source
`validate-inputs.sh`. They use `umask 077`, reject unresolved placeholders by
default, refuse symlink output/checksum paths, and refuse replacement of either
an ISO or its checksum unless `--force` is explicit. Checksums record only the
artifact basename, not an absolute local path. Do not commit generated ISO files
or customized answer files.

## Packer and standalone ESXi

The `vsphere-iso` examples are vCenter/licensed-vSphere-API templates. They keep
API credentials separate from guest SSH/WinRM communicator secrets and validate
TLS by default. Standalone or free ESXi may not provide reliable API automation;
use the documented manual VM and media-attachment fallback instead.

## Related validation and safety material

- [`../../tests/`](../../tests/) contains mocked discovery and media-generator tests.
- [`../../references/guest-os-autoinstall.md`](../../references/guest-os-autoinstall.md)
  contains safety and compatibility guidance.
- [`../../references/host-configuration-backup.md`](../../references/host-configuration-backup.md)
  documents the host configuration backup boundary.
- [`../../templates/change-plan.md`](../../templates/change-plan.md) and
  [`../../templates/rollback-notes.md`](../../templates/rollback-notes.md)
  provide change evidence and rollback records.

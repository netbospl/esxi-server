# Guest OS Unattended Auto-Install on ESXi 7-Compatible VMs

## Purpose

This reference covers **guest operating system installation inside a VM** on an ESXi 7.x host.
It is not the same problem as installing ESXi itself.

Use these templates when you want to bootstrap Windows, Ubuntu Server, RHEL/Rocky/Alma, Debian,
or Packer-built VMs in a safe, repeatable way.

## Compatibility checklist

- Confirm the target ESXi version and the guest OS version.
- Check the VMware/Broadcom Guest OS Compatibility Guide for the exact guest/version combination.
- Choose VM firmware deliberately: BIOS or EFI.
- Choose the correct guest OS type in the VM settings.
- Confirm datastore free space before creating answer media, seed ISOs, or template artifacts.
- Verify ISO paths, boot order, and attachment method before first power-on.
- Keep network/port-group choices safe and generic until the VM is validated.
- Sanitize answer files before committing them.
- Do not embed real passwords, product keys, tokens, SSH keys, hostnames, or private IPs.
- Plan for VMware Tools or open-vm-tools after the guest installs.

## Method matrix

| Guest / workflow | Typical automation file(s) | Delivery pattern |
|---|---|---|
| Windows 10 BIOS/MBR | [`autounattend-win10-bios-mbr.xml`](../examples/guest-autoinstall/windows/autounattend-win10-bios-mbr.xml) | Secondary ISO or removable media |
| Windows 10 UEFI/GPT | [`autounattend-win10-uefi-gpt.xml`](../examples/guest-autoinstall/windows/autounattend-win10-uefi-gpt.xml) | Secondary ISO or removable media |
| Windows 11 UEFI/GPT | [`autounattend-win11-uefi-gpt.xml`](../examples/guest-autoinstall/windows/autounattend-win11-uefi-gpt.xml) | Secondary ISO or removable media |
| Windows Server 2022 UEFI/GPT | [`autounattend-server2022-uefi-gpt.xml`](../examples/guest-autoinstall/windows/autounattend-server2022-uefi-gpt.xml) | Secondary ISO or removable media |
| Ubuntu Server | `user-data`, `meta-data` | NoCloud seed ISO, or an equivalent cloud-init delivery path |
| RHEL / Rocky / Alma | `ks.cfg` | `inst.ks=` via HTTP, ISO, or removable media |
| Debian | `preseed.cfg` | `preseed/url=`, initrd preseed, or HTTP delivery |
| Packer | `*.pkr.hcl` with `vsphere-iso` | vSphere API build path; manual fallback still documented |

## Host install vs guest install

Keep these separate:

- **ESXi host scripted install** uses `ks.cfg` for the ESXi installer itself.
- **Windows guest install** uses the selected explicit Windows answer-file variant.
- **Ubuntu guest install** uses Subiquity/cloud-init autoinstall (`user-data` + `meta-data`).
- **RHEL / Rocky / Alma guest install** uses Kickstart (`ks.cfg`).
- **Debian guest install** uses preseed (`preseed.cfg`).
- **Packer / template builds** use `vsphere-iso` and the vSphere API.

They solve different problems even though some file names are similar.

## Windows Autounattend

Windows unattended installation commonly uses the selected explicit Windows answer-file variant placed on virtual removable media or attached as a secondary ISO.
A floppy image can also work for small answer files.

Safety notes:

- Treat customized Windows answer files as sensitive; they can contain passwords, product keys, and domain join details.
- Keep product keys as placeholders only in committed examples.
- Use placeholder local administrator passwords only. Replace them immediately, or better, secure them with a safer secret-handling workflow.
- Keep `setupcomplete.cmd` focused on post-install bootstrap tasks such as VMware Tools installation.

Common Windows notes:

- Use the selected explicit Windows answer-file variant as the root answer file name for install-time discovery.
- For Windows 10 / 11 desktop installs, add OOBE suppression and generic local-account bootstrap only.
- For Windows Server 2022, keep server-oriented defaults and avoid desktop-only assumptions.
- `setupcomplete.cmd` runs after setup finishes and is a good place for a silent VMware Tools install attempt.
- A safe placeholder example is to look for `setup64.exe` on the mounted installer media and run `setup64.exe /S /v "/qn REBOOT=R"` if found.

## Windows 11 local account and OOBE notes

### Preferred method: create a local account with the matching answer-file variant

For repeatable VM builds, prefer an unattended answer file with `Microsoft-Windows-Shell-Setup`, `UserAccounts`, and `LocalAccounts`.
This is different from manually bypassing OOBE screens.

Use the answer-file method whenever possible because it is deterministic and keeps the build flow documented.

Warning: passwords in answer files are sensitive. In the repository, keep them as placeholders only and replace them with a secure local workflow before real use.

### Manual fallback: Shift + F10 OOBE commands

These commands are a manual rescue path for interactive installs, not a guaranteed automation API.

1. Disconnect the VM from the network or leave the virtual NIC disconnected.
2. At the network prompt, press `Shift + F10`.
3. Run:

```cmd
OOBE\BYPASSNRO
```

4. The VM restarts.
5. Continue setup and use an offline path if Windows offers one.
6. Create a local account.

Warning: this may not work on newer Windows 11 builds because Microsoft changes OOBE behavior over time.

### Alternate manual command

On some builds, this command may jump to local user creation:

```cmd
start ms-cxh:localonly
```

This is version-dependent and may be removed, blocked, or behave differently on newer Windows 11 builds.

### Windows 11 Pro Domain Join path

On Windows 11 Pro, during setup, choose the work/school or alternate sign-in path where available.
If the installer shows `Domain join instead`, that path can lead to local account creation.
This is not generally available in Windows 11 Home.

### Rufus-created install media

Rufus is a third-party bootable media creator.
It may offer Windows 11 setup customization options, including local-account or online-account requirement bypass options depending on the Rufus version and ISO build.
For ESXi, this is mainly useful when preparing media manually outside the unattended-answer-file path.
Do not treat Rufus as the preferred enterprise deployment method.

Common Windows notes:

- Use the selected explicit Windows answer-file variant as the root answer file name for install-time discovery.
- For Windows 10 / 11 desktop installs, add OOBE suppression and generic local-account bootstrap only.
- For Windows Server 2022, keep server-oriented defaults and avoid desktop-only assumptions.
- `setupcomplete.cmd` runs after setup finishes and is a good place for a silent VMware Tools install attempt.
- A safe placeholder example is to look for `setup64.exe` on the mounted installer media and run `setup64.exe /S /v "/qn REBOOT=R"` if found.
- Verify against the exact Windows build or ISO because OOBE behavior changes over time.

## Ubuntu Autoinstall

Ubuntu Server uses Subiquity/cloud-init autoinstall.

Recommended template components:

- `user-data`
- `meta-data`
- a NoCloud seed ISO created from those two files
- a boot parameter such as `autoinstall ds=nocloud;s=/cdrom/`

Notes:

- Verify the exact boot parameter syntax against the Ubuntu release you are installing.
- Use placeholder identity values only: hostname, username, and password hash.
- Prefer `open-vm-tools` from the Ubuntu repositories when available.
- Include `openssh-server` if the template should be remotely reachable after install.

## RHEL / Rocky / Alma Kickstart

Kickstart templates usually combine a boot-time `inst.ks=...` parameter with a `ks.cfg` file delivered by HTTP, ISO, or removable media.

Safety notes:

- Kickstart partitioning commands are destructive inside the target VM.
- Keep the example disposable and clearly marked as a template.
- Confirm the disk target and boot device before using `clearpart`, `autopart`, or custom partition directives.

Recommended contents:

- installation mode (`install`, `text`, `reboot`)
- locale, keyboard, and timezone
- DHCP networking
- root password hash placeholder
- a placeholder user
- bootloader setup
- `%packages` including `open-vm-tools`
- `%post` for light post-install setup, such as enabling services where applicable

## Debian Preseed

Debian Installer supports preseed for unattended installs.

Recommended contents:

- locale and keyboard selection
- network and mirror settings
- root and user placeholders
- timezone
- guided partitioning with an explicit destructive warning
- package selection including SSH and `open-vm-tools`
- `late_command` for light post-install tweaks

Delivery notes:

- Preseed is mainly for Debian Installer flows.
- Newer distro variants may use different automation paths, so verify the release before relying on preseed.
- You can deliver the file with `preseed/url=...`, embed it in initrd, or serve it over HTTP.

## Packer `vsphere-iso`

HashiCorp Packer's `vsphere-iso` builder creates a VM from an ISO using the vSphere API.
It is useful when you want a repeatable template build instead of hand-installing every VM.

Important caveats:

- API write access may require licensed vSphere/ESXi features.
- Standalone or free ESXi licensing may limit the API operations Packer needs.
- Keep a manual fallback documented: create the VM by hand and use answer media or seed media when API automation is unavailable.

Template guidance:

- keep boot commands generic and clearly marked for adaptation
- use placeholder credentials and network names only
- mark sensitive variables as sensitive in Packer variables when possible
- keep ISO paths and checksums generic until adapted locally

## Safety and secret-handling rules

- No real product keys.
- No real passwords or password hashes.
- No real hostnames, private IPs, or DNS names.
- No real API tokens, SSH keys, or session IDs.
- No copied private inventory data.
- No logs containing secrets.

## Troubleshooting checklist

- Answer file not detected
- Wrong boot firmware
- Wrong boot order
- ISO not connected at boot
- Missing VMware Tools or open-vm-tools
- Cloud-init seed not found
- Kickstart / preseed URL unreachable
- ESXi free-license API limitations

## Source docs to consult

- Microsoft Windows Unattended Setup Reference: https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/
- Microsoft answer-file and component documentation: check the Windows setup automation docs for `Microsoft-Windows-Shell-Setup`, `UserAccounts`, and `LocalAccounts` details.
- Canonical Ubuntu Server autoinstall docs: https://ubuntu.com/server/docs/install/autoinstall
- Red Hat RHEL automatic installation docs: https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/automatically_installing_rhel/index
- Debian Installer preseed appendix: https://www.debian.org/releases/stable/amd64/apbs02.en.html
- HashiCorp Packer docs: https://developer.hashicorp.com/packer/docs
- VMware/Broadcom Guest OS Compatibility Guide: consult the current VMware/Broadcom compatibility guide for the exact ESXi 7 guest/version matrix
- VMware Tools / open-vm-tools docs: prefer vendor or distro packaging guidance for the guest OS you are installing
- Manual Windows 11 OOBE fallback behavior: if you mention `OOBE\BYPASSNRO`, `start ms-cxh:localonly`, or Rufus, treat those as version-dependent community/manual notes rather than official deployment guidance.

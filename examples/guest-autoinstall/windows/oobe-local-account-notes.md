# Windows 11 OOBE Local Account Notes for ESXi VMs

## Scope

This note covers local account creation during Windows 11 guest setup inside an ESXi 7-compatible VM.

It does not cover activation bypassing, license circumvention, or Microsoft account credential handling.

## Preferred: answer-file local account

For repeatable VM builds, prefer `Autounattend.xml` with `Microsoft-Windows-Shell-Setup` → `UserAccounts` → `LocalAccounts`.

This is the preferred automation path when you want the installer to create a local account during unattended setup.

Keep in mind:

- Answer files can contain passwords, product keys, and other secrets.
- Committed examples must keep those values as placeholders only.
- Use the answer-file path instead of relying on manual OOBE bypass tricks when possible.

## Manual fallback methods

The commands below are manual rescue methods for interactive installs. They are version-dependent and may stop working on newer Windows 11 builds.

### Method A: `OOBE\BYPASSNRO`

1. Disconnect the VM from the network, or leave the virtual NIC disconnected.
2. At the network prompt, press `Shift + F10`.
3. Run:

```cmd
OOBE\BYPASSNRO
```

4. The VM restarts.
5. Continue setup and choose the offline path if Windows offers it.
6. Create a local account.

### Method B: `start ms-cxh:localonly`

On some Windows 11 builds, this command may jump to a local account flow:

```cmd
start ms-cxh:localonly
```

This is also version-dependent and may be removed, blocked, or behave differently on newer builds.

### Method C: Windows 11 Pro “Domain join instead”

If the edition and setup flow expose it, Windows 11 Pro may offer a work/school or alternate sign-in path that leads to local account creation.

This option is not generally available on Windows 11 Home.

### Method D: Rufus-prepared media

Rufus is a third-party tool for preparing bootable install media.
It may offer Windows 11 customization options, including local-account or online-account requirement bypass options depending on the Rufus version and ISO build.

For ESXi workflows, this is mainly useful for manual media prep outside the unattended-answer-file path.
Do not treat Rufus as the primary enterprise deployment method.

## ESXi VM tips

- Temporarily disconnect the VM network adapter if you are testing offline OOBE behavior.
- Snapshot a disposable test VM before experimenting with OOBE flows.
- Keep the answer ISO attached during setup if you are using `Autounattend.xml`.
- Verify VM firmware and boot order before first power-on.
- Test against the exact Windows ISO/build you plan to deploy.
- Use a clean test VM before turning the process into a template.

## Quick troubleshooting checklist

- Confirm the Windows edition: Home, Pro, or Server.
- Verify the exact build/ISO because OOBE behavior changes over time.
- Prefer the answer-file local-account path for repeatable builds.
- If a manual bypass command fails, retry only on a disposable lab VM and re-check the build version.
- Reconnect networking only after you are done testing offline OOBE.
- Do not add activation bypasses or licensing workarounds.
- Keep the answer file sanitized before sharing or committing it.

# Certificates and Let's Encrypt

ESXi commonly uses a self-signed HTTPS certificate. SSH host keys and HTTPS
certificates are separate trust mechanisms. Follow the R1–R3 plan/review/apply/
verify policy in [`../SKILL.md`](../SKILL.md); replacement that risks management
access is R2/R3.

## Guidance

- Do not disable SSH host-key verification just because the HTTPS certificate is self-signed.
- Treat certificate replacement as a change that needs approval and rollback notes.
- Verify the target ESXi version before following any certificate procedure.
- Use official ESXi documentation for the exact version when changing certificates.
- Do not assume a command or file path that works on one major version will work on another.

## Let's Encrypt note

Let's Encrypt-based workflows may be possible on some setups, but they are not universal. Validate the exact renewal and installation path on the target host before relying on it.

## Before changing certificates

- Discover the current certificate, issuer, hostname/SANs, expiry, and all
  Host Client/automation clients that validate or pin it.
- Back up the current certificate material and any related configuration.
- Back up host configuration when appropriate and record the rollback artifact.
- Confirm how you will restore the previous state if the new certificate fails.
- Check whether the change affects the Host Client, automation, or other clients.
- A self-signed TLS exception must be narrowly time-scoped and explicitly
  approved; it never authorizes disabling SSH host-key verification.

## After changing certificates

- Re-test HTTPS access.
- Re-test any automation that pins or validates the certificate.
- Confirm that SSH host-key verification still uses the expected known-hosts file.
- Restore any temporary firewall changes and record partial/failed deployment
  handling before retrying. STOP and roll back if Host Client or automation
  verification fails.

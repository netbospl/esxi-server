# Certificates and Let's Encrypt

ESXi commonly uses a self-signed HTTPS certificate. SSH host keys and HTTPS certificates are separate trust mechanisms.

## Guidance

- Do not disable SSH host-key verification just because the HTTPS certificate is self-signed.
- Treat certificate replacement as a change that needs approval and rollback notes.
- Verify the target ESXi version before following any certificate procedure.
- Use official ESXi documentation for the exact version when changing certificates.
- Do not assume a command or file path that works on one major version will work on another.

## Let's Encrypt note

Let's Encrypt-based workflows may be possible on some setups, but they are not universal. Validate the exact renewal and installation path on the target host before relying on it.

## Before changing certificates

- Back up the current certificate material and any related configuration.
- Confirm how you will restore the previous state if the new certificate fails.
- Check whether the change affects the Host Client, automation, or other clients.

## After changing certificates

- Re-test HTTPS access.
- Re-test any automation that pins or validates the certificate.
- Confirm that SSH host-key verification still uses the expected known-hosts file.

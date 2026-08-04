# Certificates and Let's Encrypt

ESXi commonly uses a self-signed HTTPS certificate. SSH host keys and HTTPS
certificates are separate trust mechanisms. Follow the R1–R3 plan/review/apply/
verify policy in [`../SKILL.md`](../SKILL.md); replacement that risks management
access is R2/R3.

## Guidance

- Do not disable SSH host-key verification just because the HTTPS certificate is self-signed.
- Treat certificate replacement as a change that needs approval and rollback notes.
- Verify the target ESXi version before following any certificate procedure.
- Use the current [Broadcom CA-signed certificate procedure (KB 341649)](https://knowledge.broadcom.com/external/article/341649/configuring-ca-signed-certificates-for-e.html)
  for the exact version and management mode. Re-open it immediately before the
  change; do not copy file paths or service actions from an older build.
- Do not assume a command or file path that works on one major version will work on another.

## Let's Encrypt note

Let's Encrypt-based workflows may be possible, but ESXi is not a general
ACME-client host. Keep account keys and private keys off the hypervisor, use an
approved external ACME client, and treat each installation/renewal as the same
R2/R3 certificate replacement until a tested, build-specific automation and
rollback path exists. Never expose a management interface or loosen firewall
rules solely to satisfy an ACME challenge without a separate network plan.

## Before changing certificates

- Discover the current certificate, issuer, hostname/SANs, expiry, and all
  Host Client/automation clients that validate or pin it.
- Identify standalone versus vCenter-managed mode, vSAN participation, and
  whether vCenter certificate mode would replace a custom host certificate.
- Require a unique certificate with the exact host FQDN/SANs, Server
  Authentication usage, the full CA chain, and a matching unencrypted private
  key in the format required by the current procedure. Wildcards are not a
  safe default and are not supported by the cited procedure.
- Back up the current certificate material and any related configuration.
- Back up host configuration when appropriate and record the rollback artifact.
- Confirm how you will restore the previous state if the new certificate fails.
- Confirm tested DCUI/out-of-band access before any service restart or host
  disconnect, and name the exact maintenance/reconnect steps in the plan.
- Check whether the change affects the Host Client, automation, or other clients.
- A self-signed TLS exception must be narrowly time-scoped and explicitly
  approved; it never authorizes disabling SSH host-key verification.

Bounded R0 inspection from the management workstation:

```bash
: "${ESXI_HOST:?}" "${ESXI_FQDN:?set the verified certificate hostname}"
(
  set -o pipefail
  timeout 15 openssl s_client \
    -connect "$ESXI_HOST:443" -servername "$ESXI_FQDN" -showcerts </dev/null |
    openssl x509 -noout -subject -issuer -serial -dates -fingerprint -sha256 \
      -ext subjectAltName -ext extendedKeyUsage
)
```

Save protected pre-change evidence when required, but never commit a private
key, certificate bundle tied to private inventory, or unredacted scan output.
Treat a nonzero pipeline result or connection diagnostic as a failed probe;
do not infer certificate state from partial output.
The apply plan must take its exact paths, ownership, service action, and
standalone/vCenter/vSAN branch from KB 341649 for the observed build. Do not
substitute a remembered file-copy/restart recipe.

## After changing certificates

- Re-test HTTPS access.
- Inspect the served certificate from an independent client: subject/SANs,
  issuer chain, expiry, key usage, hostname validation, and expected thumbprint.
- Re-test any automation that pins or validates the certificate.
- Confirm that SSH host-key verification still uses the expected known-hosts file.
- Restore any temporary firewall changes and record partial/failed deployment
  handling before retrying. STOP and roll back if Host Client or automation
  verification fails.

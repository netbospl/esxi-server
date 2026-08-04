# ESXi file transfers

Start with [`../SKILL.md`](../SKILL.md) and use exact datastore/path values from
a protected local profile. Transfer data and remote names are untrusted.

## Preflight and risk

Confirm target identity, TLS or SSH trust, datastore UUID, mounted state, free
space, destination path, file type/size/digest, overwrite behavior, and VM
power state. Uploading a new file is normally R1; overwriting a datastore object
or transferring a live VM disk can be R2/R3. Never copy an active VMDK as if it
were a consistent backup.

Prefer, in order, the Host Client datastore browser, a proven authenticated
`/folder/` route, OVF Tool for OVF/OVA, or guarded SCP when SSH is already an
approved capability. `/folder/` success does not prove REST API support.

## Protected HTTPS credentials

Do not put a password in a URL, command argument, report, or shell history. Use
a secret manager or a mode-0600 temporary netrc file created inside the
protected execution environment, and remove it on exit:

```bash
: "${ESXI_HOST:?}" "${ESXI_USER:?}" "${ESXI_PASS:?}" "${ESXI_CA_BUNDLE:?}"
: "${LOCAL_FILE:?}" "${REMOTE_URL:?}"
NETRC_FILE=$(mktemp "${TMPDIR:-/tmp}/esxi-transfer-netrc.XXXXXX")
trap 'rm -f "$NETRC_FILE"' EXIT
chmod 600 "$NETRC_FILE"
netrc_quote() {
  local value=$1
  [[ $value != *$'\n'* && $value != *$'\r'* ]] || return 1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  printf '"%s"' "$value"
}
HOST_TOKEN=$(netrc_quote "$ESXI_HOST") || exit 2
USER_TOKEN=$(netrc_quote "$ESXI_USER") || exit 2
PASS_TOKEN=$(netrc_quote "$ESXI_PASS") || exit 2
printf 'machine %s\nlogin %s\npassword %s\n' \
  "$HOST_TOKEN" "$USER_TOKEN" "$PASS_TOKEN" >"$NETRC_FILE"
curl --fail --show-error --cacert "$ESXI_CA_BUNDLE" \
  --netrc-file "$NETRC_FILE" --upload-file "$LOCAL_FILE" "$REMOTE_URL"
```

Construct `REMOTE_URL` from separately validated datastore and path values.
Do not copy query strings from untrusted output. A narrowly approved temporary
TLS exception must use a verified certificate fingerprint and a protected
network; it is never the default.

## SCP

```bash
: "${ESXI_HOST:?}" "${ESXI_USER:?}" "${ESXI_SSH_KEY:?}"
: "${ESXI_KNOWN_HOSTS:?}" "${LOCAL_FILE:?}" "${REMOTE_PATH:?}"
[[ $ESXI_HOST =~ ^[A-Za-z0-9.-]+$ ]] || exit 2
[[ $ESXI_USER =~ ^[A-Za-z0-9._-]+$ ]] || exit 2
[[ $LOCAL_FILE == /* && -f $LOCAL_FILE && ! -L $LOCAL_FILE ]] || exit 2
[[ $REMOTE_PATH =~ ^/vmfs/volumes/[A-Za-z0-9._/-]+$ ]] || exit 2
[[ $REMOTE_PATH != *'/../'* && $REMOTE_PATH != *'/..' ]] || exit 2
scp -i "$ESXI_SSH_KEY" \
  -o UserKnownHostsFile="$ESXI_KNOWN_HOSTS" \
  -o StrictHostKeyChecking=yes \
  -- "$LOCAL_FILE" "$ESXI_USER@$ESXI_HOST:$REMOTE_PATH"
```

Legacy SCP can pass the remote path through a remote command parser. The
example therefore rejects whitespace and metacharacters and only permits an
absolute datastore path. It also requires an absolute, existing regular local
file and rejects local symlinks, preventing SCP from interpreting a colon in a
source as another remote host. For other names or symlink policies, use the
Host Client, authenticated HTTPS, or a structured SFTP client after proving its
path semantics; do not weaken the validation ad hoc.

Do not loop on closed port 22, auth failure, or a changed host key. Use an
already-proven alternative and record why.

## Verification and cleanup

Compare byte size and a strong digest at both ends when the interface allows
it. For an OVF package, also verify its manifest/signature and every referenced
disk. Re-check datastore free space and ensure no partial file is mistaken for
a complete artifact. Delete a partial or superseded remote object only under
its own exact-target approval.

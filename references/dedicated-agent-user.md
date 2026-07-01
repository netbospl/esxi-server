# Dedicated ESXi automation user: `agent`

A dedicated local ESXi user is safer than reusing `root` for routine automation.

## Why this is safer

- Limits blast radius if credentials or a key are exposed.
- Makes audit trails easier to read.
- Lets you grant only the permissions required for the workflow.
- Allows you to rotate automation credentials without changing the host's administrative account.

## Recommended model

- Create or use a dedicated local ESXi user named `agent`.
- Prefer SSH key authentication for that user.
- Store the private key outside the repository, such as `~/.ssh/esxi-agent`.
- Keep the public key as an administrator-installed value on the host.
- Keep API credentials and SSH credentials separate if the host or workflow requires both.

Example environment model:

```bash
ESXI_HOST="esxi.example.local"
ESXI_USER="agent"
ESXI_SSH_KEY="$HOME/.ssh/esxi-agent"
ESXI_KNOWN_HOSTS="$PWD/.ssh-known-hosts/esxi_known_hosts"
```

## Least privilege

Grant only the permissions required for the task. Do not assume a universal ESXi permission recipe is safe on every version or deployment.

- Read-only discovery should require only read access.
- VM lifecycle work should be granted only when needed.
- Networking, snapshot, and datastore-write permissions should be added only after explicit human approval.

Any creation of the `agent` user or permission changes on the ESXi host must be explicitly approved by a human in the current task.

## Key rotation and storage

- Rotate the SSH key on a regular schedule or after any suspected exposure.
- Keep private keys in a user home directory or secret manager, never in Git.
- Keep known-hosts data in a dedicated file if the workflow needs isolation from the user's global SSH config.
- Do not commit private keys, public keys that reveal sensitive infrastructure details, or shell logs containing authentication material.

## Validation checks

Before using the account in automation, verify that:

- the host accepts the public key for `agent`
- the account can run the intended read-only checks
- the account cannot perform more than the intended scope
- the known-hosts entry matches the expected ESXi host key
- the workflow still functions after a key rotation

## Rollback and removal notes

If the automation account must be removed or disabled:

1. Remove or disable the `agent` account on the host after confirming the impact.
2. Remove the matching SSH public key from the host.
3. Revoke or rotate any API credentials that were paired with the workflow.
4. Update the local profile and secret store.
5. Verify that the host no longer accepts the automation key.

If a host-specific permission command is needed, verify it against the target ESXi version and the local admin policy before applying it.

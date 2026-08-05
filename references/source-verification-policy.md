# Source verification policy

Use this policy when adding or materially changing an ESXi, vCenter, pfSense,
Packer, guest-installer, operating-system, or provider-specific procedure.
It is a maintainer rule; it does not grant permission to operate a host.

## Source hierarchy

Use the first available source that directly matches the target and claim:

1. Exact-version vendor documentation or product manual.
2. Vendor knowledge base, release notes, lifecycle notice, or security advisory.
3. Official source repository, schema, plugin documentation, or maintained
   example pinned to a reviewed commit or version.
4. Reproducible lab evidence that records the exact product version and build.
5. Community material only as supplementary context, clearly labelled as such.

Do not use search-result snippets, AI summaries, stale blog posts, or a similar
product's documentation as primary evidence for an operational command.

## Required evidence record

For every non-obvious operational claim, record enough information to review it:

```text
target_product:
target_version_or_build:
claim_or_command:
source_title:
source_url_or_repository_path:
source_version_or_commit:
reviewed_on:
lab_validated: yes | no
limitations_or_conflicts:
```

The record may live beside the procedure, in an upstream-sources reference, or
in the pull-request description. Never include private host inventory or
credentials in the evidence record.

## Conflict and uncertainty rules

- Exact target evidence wins over a generic or newer-product example.
- Standalone ESXi and vCenter are distinct targets. A vCenter endpoint does not
  become a standalone capability because the products share a UI or SDK name.
- Product edition, licensing, provider routing, virtual-MAC, and gateway rules
  must be proven for the actual environment.
- When official sources disagree, state the conflict and stop before a
  state-changing recommendation until the exact target is resolved.
- Mark an unverified procedure `UNVERIFIED` and keep it out of R1-R3 execution
  guidance. Confidence is not evidence.
- Re-check sources when a pinned version, product lifecycle, plugin version, or
  linked vendor page changes.

## Implementation checklist

- [ ] Exact product, edition, version, and build were identified.
- [ ] A primary official source was reviewed for each operational claim.
- [ ] The source version or commit was recorded where possible.
- [ ] Deprecated or removed behaviour was checked.
- [ ] Standalone ESXi and vCenter boundaries remained explicit.
- [ ] Lab evidence, when available, records its exact target and limitations.
- [ ] Unverified material is labelled and cannot authorize R1-R3 execution.
- [ ] New behaviour has a regression test or an explicit reason why a static
      test cannot represent it.

# ADR-0001: Keep standalone ESXi and vCenter capabilities separate

- **Status:** Accepted
- **Date:** 2026-08-05

## Context

The products share terminology and SDK heritage, but vCenter exposes inventory
and automation surfaces that are not automatically available on a standalone
ESXi host. Guessing `/api/vcenter/*` routes or treating a vCenter-oriented
builder as standalone support creates false confidence and can turn capability
detection into unsafe trial-and-error.

## Decision

Identify the target before selecting an interface. Use only an exact REST
operation proven on that target; otherwise use the SOAP SDK or guarded SSH with
canonical `esxcli`/`vim-cmd` guidance. Keep committed Packer `vsphere-iso`
examples explicitly vCenter-oriented and label them reviewed skeletons.

## Consequences

- Documentation and tests must preserve the boundary.
- Generic VMware examples require target-specific verification.
- Standalone workflows may be more manual, but unsupported automation is never
  presented as available.

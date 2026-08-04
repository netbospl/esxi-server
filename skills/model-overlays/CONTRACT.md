# Model overlay contract

Model overlays adapt presentation and reasoning behavior. Canonical parent
skills and references exclusively own commands, API routes, risk classes,
approval gates, rollback, and verification.

## Required load order

```text
root policy → canonical task reference/skill → model profile
            → optional harness adapter → matching task overlay
```

An overlay must not be loaded by itself. If any parent or model profile cannot
be loaded, continue with model-agnostic guidance or stop; never reconstruct the
missing procedure from the overlay.

## Required fields

Every overlay is a `SKILL.md` with:

- a frontmatter description beginning with `Use when`;
- `Canonical parent`, `Model profile`, and `Load order` declarations;
- a `Scope boundaries` section;
- no more than 500 words.

The canonical parent declaration must name the exact task skill or reference.
An overlay may add bounded evidence framing, context budgeting, checkpointing,
or output structure. It may not duplicate executable operational commands,
endpoint catalogs, credentials, host facts, risk tables, or approval wording.

## Conflict and stale-context rules

Parent policy always wins. On conflict, report the mismatch and ignore the
overlay. Re-read fresh target identity and task facts after context compaction,
transport recovery, approval expiry, or any state change. A model-generated
summary is not approval or proof of current ESXi state.

Harness adapters describe tool semantics only. They cannot relax target trust,
make a restricted hypervisor shell persistent, infer whether a lost command
completed, or convert a read-only result into change authorization.

## Validation

Run `scripts/validate-model-overlays.sh --repo .`. The validator rejects
missing declarations, command duplication, non-trigger descriptions, and
oversized overlays. All repository tests remain local and mock-only.

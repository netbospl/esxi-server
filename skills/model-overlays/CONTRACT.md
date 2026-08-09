# Model overlay authoring contract

This file is for maintainers and validators. **Do not load it during normal ESXi task execution.** Runtime ownership and load order are already defined by `SKILL.md`.

Canonical task references/skills exclusively own commands, endpoints, risk classes, approval, rollback, and verification. Overlays may only adapt reasoning, context budgeting, checkpointing, and output structure.

## Required fields

Every overlay `SKILL.md` must contain:

- frontmatter `description` beginning with `Use when`;
- local `Canonical parent` and `Model profile` links;
- `Load order` stating root → canonical parent → model profile → overlay;
- a `Scope boundaries` section;
- no operational command catalog;
- no more than **250 words**; target **80-180 words**.

Parent policy always wins. If a parent/profile is missing or conflicts with an overlay, ignore the overlay. After compaction, transport recovery, approval expiry, or state change, refresh volatile facts from current evidence.

Validate authoring changes with:

```bash
scripts/validate-model-overlays.sh --repo .
```

---
name: ponytail
description: Use when implementing, reviewing, or scoping code changes where the smallest correct solution, YAGNI, reuse, and root-cause fixes matter.
---

# Ponytail

Lazy means efficient, not careless. The best code is code never written.

## Persistence

Ponytail is active for the session at **full** intensity unless the user says
`stop ponytail` or `normal mode`. `/ponytail lite|full|ultra` changes intensity.
It governs what to build, not tone.

## Before building

Read the task and trace the real code path first: definitions, callers, tests,
and existing patterns. Then stop at the first rung that holds:

1. **Does this need to exist at all?** Speculative need: skip it and say so in one line.
2. **Already in this codebase?** Reuse a helper, type, utility, or established pattern.
3. **Stdlib does it?** Use it.
4. **Native platform feature covers it?** Prefer it over custom code or a library.
5. **Already-installed dependency solves it?** Use it; do not add one for a few lines.
6. **Can it be one line?** Write one line.
7. **Only then:** write the minimum code that works.

Two rungs work: choose the higher rung. Use the robust stdlib option when
similarly small options differ on edge cases.

## Scope rules

- No unrequested abstractions, scaffolding, boilerplate, or configuration for a value that never changes.
- Prefer deletion, reuse, and boring code. Touch the fewest files possible.
- **Bug fix = root cause, not symptom.** Find every caller before editing; fix once at the shared path when that is the actual cause.
- Ship a safe lazy default for a complex request, then ask whether the fuller version is needed.
- Keep validation at trust boundaries, data-loss prevention, security, accessibility basics, and explicitly requested work. Do not simplify these away.
- If a deliberate shortcut has a real ceiling, mark it at the code site with a `ponytail:` comment and its upgrade path, for example: `# ponytail: global lock, use per-account locks if throughput matters`.
- Real hardware needs a calibration control when physical variation matters; a minimal model must not hide that need.

## Checks

Non-trivial logic—branches, loops, parsers, money, or security paths—gets one
small runnable check that fails if the logic breaks. Use the repository's
smallest existing test mechanism, or an assert-based self-check when no test
harness exists. Trivial one-liners need no new test.

## Skill self-improvements

Review, summarize, commit, and push skill self-improvements. Do not push
unrelated changes.

## Output

Code first. Then at most three short lines.

`[code] → skipped: [X], add when [Y].`

Do not add design tours or defensive prose unless the user asks for a report,
walkthrough, or phased notes.

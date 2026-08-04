# Model overlay and incident triage design

## Purpose

Extend the repository with a reusable contract for model-specific guidance,
close the highest-value Nemotron coverage gaps, and add model-agnostic incident
triage without creating parallel sources of operational truth.

The next release will deliver a focused implementation plus a ranked backlog.
It will preserve the repository's documentation-first design, canonical R0-R3
approval model, local-only secret handling, and mock-only test boundary.

## Design principles

1. Canonical operational skills and references remain the sole authority for
   ESXi commands, risk classification, approvals, rollback, and verification.
2. Model overlays adapt reasoning, context use, tool selection, and known model
   failure modes. They do not become standalone operational runbooks.
3. Harness-specific behavior is distinct from model behavior. Tool names,
   approval mechanics, terminal persistence, and session semantics belong to a
   harness adapter rather than a model profile.
4. A task overlay is added only for an observed, repeatable model-specific need.
5. All validation is local and mock-only. No repository test may contact an
   ESXi host, pfSense appliance, guest, or management endpoint.

## Architecture

### Canonical operational layer

The root `SKILL.md`, model-agnostic child skills, and task references own all
operational procedure. The task router selects the smallest relevant canonical
module and retains the repository's parent-first loading order.

The new model-agnostic `incident-triage` child skill will own:

- evidence preservation and sensitive-output handling;
- observed facts separated from hypotheses;
- one bounded R0 discriminator at a time;
- explicit stop conditions and escalation criteria;
- R1-R3 change gates delegated to the root policy;
- handoff and completion-state reporting.

It will route to an existing task reference only after the failing layer has
been narrowed. It will not reproduce ESXi command catalogs.

### Model overlay contract

A repository contract will define the required structure for every model
overlay. Each overlay must declare:

- model family and accepted model-ID patterns;
- required canonical parent skill and task references;
- scope boundaries and prohibited responsibilities;
- model/runtime context assumptions and their evidence status;
- model-specific reasoning and tool-use adaptations;
- known failure modes addressed by the overlay;
- validation and completion gates.

The contract will require this load order:

```text
root canonical skill
  -> task-specific canonical child or reference
  -> model profile
  -> harness adapter when applicable
  -> matching thin task overlay
```

An overlay may summarize a safety gate for emphasis, but must link to the
canonical policy and must not redefine R0-R3 meanings, approvals, commands, or
rollback procedures.

### Model profiles and harness adapters

Model profiles contain only stable or explicitly observed model/runtime facts,
such as model-ID matching, context constraints, reasoning tendencies, and
known failure patterns. Published model ceilings must remain distinct from an
active deployment's observed context limit.

Harness adapters contain tool vocabulary and execution semantics, including:

- filesystem and reference-loading tools;
- terminal invocation and quoting behavior;
- approval and confirmation mechanisms;
- persistent-session support and uncertain-command recovery;
- batching and output-size constraints.

This separation prevents a model profile from incorrectly assuming that every
deployment uses Hermes, Codex, or another specific tool surface.

### File layout

The implementation will use these locations:

- `skills/model-overlays/CONTRACT.md` for the overlay contract;
- `skills/model-overlays/harnesses/hermes.md` for Hermes-only tool semantics;
- `scripts/validate-model-overlays.sh` for the local validator;
- `tests/fixtures/model-overlays/` for sanitized positive and negative cases;
- `tests/test-model-overlay-contract.sh` for validator regression coverage;
- `skills/incident-triage/SKILL.md` for canonical incident handling;
- `skills/nemotron-3-ultra/incident-triage/SKILL.md` for its thin Nemotron
  overlay;
- `skills/nemotron-3-ultra/private-guest-shell/SKILL.md` for its thin Nemotron
  overlay.

### Thin task overlays

The focused release adds:

1. A Nemotron incident-triage overlay that supplies concise structured
   reasoning, bounded hypothesis discrimination, and context-control patterns.
2. A Nemotron private-guest-shell overlay that adapts the canonical
   `vpn-direct`, `dedicated-jump`, and `direct-recovery` modes while leaving
   pfSense and SSH procedure in their model-agnostic parents.

Existing Nemotron overlays will receive only contract-driven fixes needed to
remove contradictions, duplicated authority, harness coupling, unsafe
placeholder examples, or unsupported capability claims.

## Routing and data flow

For an operational request, the agent will:

1. Identify the target class and task category without executing a change.
2. Load the root safety policy.
3. Load one model-agnostic task child or the minimum relevant reference set.
4. Detect the active model family and load its shared model profile.
5. Load a harness adapter only when tool-specific guidance is needed.
6. Load the matching task overlay only when one exists.
7. Perform read-only discovery and preserve evidence.
8. Stop at the canonical approval gate before any R1-R3 action.
9. Verify through the canonical task module and report the final state.

Missing optional overlays fall back safely to model-agnostic guidance. Missing
canonical parents, ambiguous targets, invalid routing, or failed trust checks
are stop conditions rather than fallback-to-guessing conditions.

## Validation and error handling

A local validator and policy tests will check every model overlay for:

- required metadata and headings;
- existing canonical parent and model-profile links;
- documented load order and scope boundaries;
- root-router and documentation-index registration;
- prohibited duplicated-policy or unsafe command patterns;
- restricted-target routing, especially ESXi and pfSense persistence;
- unresolved executable placeholders and missing local links.

Tests will include valid and invalid fixtures so each diagnostic is exercised.
Failures will name the overlay, rule, and corrective action. The validator will
not parse local profiles, inspect secrets, or perform network access.

Existing repository checks remain authoritative. The final implementation must
pass the complete `make check` suite in a local Linux environment, with optional
tools reported according to the current Makefile behavior.

## Focused release deliverables

The focused release contains four workstreams:

1. Overlay framework: contract, directory convention, initial Hermes adapter,
   local validator, and sanitized validator fixtures.
2. Canonical incident triage: the model-agnostic child skill and its routing
   and policy tests.
3. Nemotron coverage: incident-triage and private-guest-shell overlays plus
   only the corrections to existing overlays required for contract compliance.
4. Integration: root router, README, documentation index, changelog, Makefile,
   and policy-test updates.

## Non-goals for the focused release

- No live ESXi, pfSense, guest, SDK, REST, or SSH validation.
- No new state-changing helper.
- No new named model profile beyond Nemotron.
- No rewrite of canonical task references.
- No attempt to provide complete task overlays for every model and ESXi task.
- No host-specific data, credentials, private inventory, or generated logs.

## Ranked future backlog

1. Certificate lifecycle and trust-chain operations.
2. Artifact transfer plus VM import/export.
3. ESXi patch/upgrade readiness, maintenance, and rollback planning.
4. Router/pfSense and single-public-IP migration overlays.
5. Datastore capacity, snapshot consolidation, and reclamation workflows.
6. Read-only security posture audit.
7. Evaluation fixtures for GPT/Codex, Claude, and Gemini, followed by named
   profiles only where observed behavior justifies them.

Each backlog item will use its own specification, plan, implementation, and
review cycle.

## Acceptance criteria

The focused release is complete when:

- every model overlay passes the new contract validator;
- the task router selects canonical incident triage before a model overlay;
- Nemotron private-guest access never treats pfSense as a general bastion or
  persistent-shell target;
- model profiles contain no harness-specific tool API assumptions;
- unsupported standalone ESXi capabilities are not presented as universal;
- executable examples contain no unresolved target placeholders;
- root documentation and indexes expose all new modules;
- all tests are mock-only and the full local quality suite passes;
- no secret, private inventory, or local artifact is committed.

## Rollout and rollback

Implementation will be split into small commits: contract/validator,
model-agnostic incident triage, Nemotron overlays, and integration cleanup.
Each step must leave local tests passing. If a contract rule proves too broad,
the rule and its fixtures will be reverted together rather than weakening an
individual overlay silently.

Because these are repository documentation and local validation changes,
rollback is a normal Git revert. No ESXi state is touched.

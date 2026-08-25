# my-utils:bugfix — diagnosis-tier skill (design)

- Date: 2026-08-25
- Status: approved

## Goal

A `my-utils:bugfix` skill for the tier the library is missing: **bugs that need
root-cause investigation.** It sits between `super-quick` (known-fix chores) and
`new-feature` (new capability), and under `long-running-job` (endurance).

## Decisions

1. **Scope boundary — diagnosis-required bugs.** bugfix owns any bug that needs
   root-cause investigation. `super-quick` keeps trivial known-fix chores;
   `new-feature` keeps new capabilities. The distinguishing test: "do I already
   know the one-line fix, or do I need to find out *why* it's broken?"

2. **Escalation — `/gsd-debug` as the single gate.** A bug that outgrows
   single-fix scope (architectural root cause, or too many files/days) routes to
   `/gsd-debug`, which decides `new-feature` vs `long-running-job`. Same gate at
   3+ failed fixes — that's a wrong architecture, not a bug. bugfix never
   auto-promotes and never re-plans.

3. **Regression test — one invariant, two forms.** Every fix ships with proof:
   a failing-then-passing automated test when the bug is unit-testable; else a
   written reproduction + manual-verify checklist (actually run). No proof, no
   commit. This is not a "carve-out" — the test and the repro/verify checklist
   are the same thing (a repeatable check), in two concrete forms.

4. **Structure — lean glue.** The SKILL.md is a tier boundary that invokes
   `superpowers:systematic-debugging` (Phases 1–3, root cause) then
   `superpowers:test-driven-development` (Phase 4, failing test), and adds the
   scope gate, escalation gate, kanban lifecycle, `/linus` review, and closeout.
   Methodology stays in superpowers; no re-inlining.

## Contract (the SKILL.md)

```markdown
---
name: my-utils:bugfix
description: "Use for bugs that need root-cause investigation — too complex for super-quick's known-fix chores, but still a single fix (not new capability). Pipeline: reproduce → systematic-debugging (root cause) → failing-test-first fix → /linus review → closeout. Outgrows single-fix scope → /gsd-debug gate. Trigger via /my-utils:bugfix."
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Agent
triggers:
  - bug
  - bugfix
  - fix this
  - something's broken
  - debug
---

# Bug Fix — diagnosis tier

Something's already broken. Find the root cause, prove the fix, don't patch the symptom.

## Flow

1. **Scope gate (hard)** — this skill owns bugs that need diagnosis. Already know
   the one-line fix (no investigation) → /my-utils:super-quick. New capability →
   /my-utils:new-feature.
2. **Kanban start** — find-or-create the card on Project #1 → In Progress
   (same `gh project` commands as super-quick/new-feature).
3. **Reproduce + root cause** — invoke superpowers:systematic-debugging, Phases 1–3:
   read the error, reproduce consistently, check recent changes, trace data flow.
   NO fix before root cause. Can't reproduce → gather data, don't guess.
4. **Fix with proof** — invoke superpowers:test-driven-development. One invariant:
   failing-then-passing automated test when unit-testable; else a written
   reproduction + manual-verify checklist (actually run it). No proof, no commit.
5. **Escalation gate** — outgrows single-fix scope (architectural root cause, or too
   many files/days) → STOP, route to /gsd-debug (it decides new-feature vs
   long-running-job). Same gate at 3+ failed fixes: that's wrong architecture, not a bug.
6. **Verify** — the fix's test green + full suite green (test command from project
   CLAUDE.md / package.json).
7. **Commit** — one atomic conventional commit (`fix:`); body carries the root cause
   in one plain-language sentence + the proof (test name, or repro steps).
8. **/linus review (always)** — invoke linus on the diff. Fix real findings, re-run
   tests, commit. Dismiss style noise.
9. **Kanban closeout** — card → Done.

## Hard rules

- No fix before root cause. Symptom patches are failure.
- No proof, no commit — automated test OR written repro + manual verify.
- Never modify a test to make it pass.
- 3+ failed fixes → /gsd-debug (wrong architecture, not a bug).
- Never expand scope mid-fix — outgrows single-fix → /gsd-debug.
- No STATE.md write — bugfix is transactional; git log is the record. Architectural
  changes route through /gsd-debug → new-feature, which owns STATE.md.
```

## Notes

- **No STATE.md write.** bugfix is transactional (like `super-quick`); the commit
  body's root-cause line is the record. Anything architectural — which would touch
  STATE.md — routes out to `/gsd-debug` → `new-feature`, which owns STATE.md.
- **`allowed-tools`** includes `Write`/`Agent` (for tests and repro scripts),
  heavier than `super-quick`, matching `new-feature`/`long-running-job`.
- **`triggers`** deliberately uses `debug` (not `debugging`) to avoid colliding
  with `/gsd-debug`'s trigger space.

## Files

- Create: `skills/bugfix/SKILL.md` (content above)
- Symlink: `~/.claude/skills/bugfix` → `skills/bugfix` (via `setup.sh`)
- Update: `README.md` skills list

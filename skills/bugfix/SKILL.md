---
name: my-utils:bugfix
description: "Use for bugs that need root-cause investigation — too complex for super-quick's known-fix chores, but still a single fix (not new capability). Pipeline: reproduce → systematic-debugging (root cause) → failing-test-first fix → my-utils:fan-out-review (linus subagent per affected component, plus a conformance pass against the root cause) → closeout. Outgrows single-fix scope → /gsd-debug gate. Trigger via /my-utils:bugfix."
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
2. **Kanban start** — find-or-create the card, then move it to In Progress.
   ```bash
   ~/.claude/my-utils/kanban.sh find-or-create "<bug>" "<1-2 sentences>"
   ~/.claude/my-utils/kanban.sh move "<bug>" in-progress
   ```
   Optional: no config or no `gh` exits 0 silently and the fix proceeds.
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
8. **Fan-out review (always)** — `~/.claude/my-utils/kanban.sh move "<bug>" review`
   first, then invoke my-utils:fan-out-review with `base` = the commit before
   the fix, and the root cause statement plus the failing test as its
   requirements source. It returns findings per component and a conformance
   verdict — never scan the diff as one blob. Fix every surviving finding,
   re-run the full suite green, commit.
9. **Kanban closeout** — `~/.claude/my-utils/kanban.sh move "<bug>" done`.

## Fallbacks

A missing dependency degrades the step; it never silently skips it. Escalation
exits are the one exception — they STOP, because improvising past a handoff
gate defeats the gate. `~/.claude/my-utils/doctor.sh` reports what this machine has.

| Dependency | Absent → |
|---|---|
| `superpowers:systematic-debugging` | Run the phases inline: read the error, reproduce it consistently, check recent changes, trace the data flow. The invariant holds — no fix before root cause. |
| `superpowers:test-driven-development` | Write the failing test yourself, watch it fail, then fix until it passes. The invariant holds — no proof, no commit. |
| `/gsd-debug` | **STOP.** Report the root cause found so far and why it outgrew a single fix, then hand back to the user. Do not improvise past the escalation gate. Offer `./setup.sh --with-deps` to install GSD. |
| `my-utils:fan-out-review` | Authored in my-utils — `./setup.sh` is the fix. Still missing: run its flow inline — build the scan set from the diff plus importers/callers (`graphify query`, else grep the import path + symbol), one subagent per component invoking `linus`, one conformance subagent against the same requirements, then verify each finding in the code before fixing. |
| `my-utils:super-quick` | Authored in my-utils — `./setup.sh` is the fix. Still missing: stay in this tier and make the known fix here; diagnosis is a superset of the chore flow. Never skip the review. |
| `my-utils:new-feature` | Authored in my-utils — `./setup.sh` is the fix. Still missing: **STOP.** Report what the task needs that this tier does not cover, then hand back to the user. Do not improvise past a promotion gate. |
| `linus` | Vendored here — `./setup.sh` is the fix. Still missing: run the same per-component fan-out, each subagent reviewing against data structure, special cases, gratuitous complexity, and breakage of existing callers. |
| `graphify` | Build the scan set with grep over the import path + symbol. Already the documented path when the repo has no graph. |
| Kanban / `gh` (the board) | Skip every card step silently — the only dependency that degrades to nothing, because bookkeeping never gates work. |

## Hard rules

- No fix before root cause. Symptom patches are failure.
- No proof, no commit — automated test OR written repro + manual verify.
- Never modify a test to make it pass.
- 3+ failed fixes → /gsd-debug (wrong architecture, not a bug).
- Never expand scope mid-fix — outgrows single-fix → /gsd-debug.
- Never review the diff as one blob — every affected component gets its own scan.
- No STATE.md write — bugfix is transactional; git log is the record. Architectural
  changes route through /gsd-debug → new-feature, which owns STATE.md.

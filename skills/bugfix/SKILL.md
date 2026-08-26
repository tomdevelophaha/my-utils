---
name: my-utils:bugfix
description: "Use for bugs that need root-cause investigation — too complex for super-quick's known-fix chores, but still a single fix (not new capability). Pipeline: reproduce → systematic-debugging (root cause) → failing-test-first fix → /linus fan-out review (subagent per affected component) → closeout. Outgrows single-fix scope → /gsd-debug gate. Trigger via /my-utils:bugfix."
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
8. **/linus fan-out review (always)** — never scan the diff as one blob.
   a. **Scan set** — edited files from `git diff --name-only <base>..HEAD`, plus
      the blast radius: importers/callers of every changed symbol, the routes or
      UI that consume it, its tests. `graphify query` when the repo has a graph,
      else grep the import path + symbol. Group into components (module/feature
      units), not raw files. Cap ~8 — over that, merge the thinnest ones.
   b. **Fan out** — ONE subagent per component, all dispatched in a single
      message so they run concurrently. Each invokes the `linus` skill scoped to
      its component — that component's diff hunks plus the code they touch — and
      returns findings ONLY (severity, `file:line`, one-line fix direction). No
      file dumps, no prose.
   c. **Consolidate** — dedupe across agents, drop style noise, keep real
      findings. One component in the scan set → skip the fan-out, run linus inline.
   d. **Fix** — real findings fixed, full suite re-run green, committed.
9. **Kanban closeout** — card → Done.

## Hard rules

- No fix before root cause. Symptom patches are failure.
- No proof, no commit — automated test OR written repro + manual verify.
- Never modify a test to make it pass.
- 3+ failed fixes → /gsd-debug (wrong architecture, not a bug).
- Never expand scope mid-fix — outgrows single-fix → /gsd-debug.
- Never review the diff as one blob — every affected component gets its own scan.
- No STATE.md write — bugfix is transactional; git log is the record. Architectural
  changes route through /gsd-debug → new-feature, which owns STATE.md.

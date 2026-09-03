---
name: my-utils:new-feature
description: "Use for feature work — new capabilities like Apple login, library integrations, UI subsystems. Pipeline: superpowers brainstorming → GSD plan-only breakdown (plan carries test list; double gate: plan + test list approved) → superpowers executing-plans with TDD (user reads core diff at checkpoint) → my-utils:fan-out-review (linus subagent per affected component, plus a conformance pass against the spec and test list) → state closeout (spec Outcome line). Context: the spec and plan on disk are the state — /clear at each gate, `resume <topic>` reconciles the plan's task table against git log. Plan too big for one context window → /my-utils:long-running-job. Modes: collaborative (default), --offload (autonomous, worktree), optional --hand-first modifier. Trigger via /my-utils:new-feature."
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Agent
triggers:
  - new feature
  - new-feature
---

# New Feature — feature tier

The main work pipeline. GSD breaks down; superpowers executes. Never let a GSD
command auto-execute the plan.

## Modes

- **collaborative (default)** — checkpoint with the user after each gate:
  spec approved, plan + test list approved, core diff read, review done.
- **`--offload`** — autonomous. Isolate in a worktree, run all gates, the
  fan-out review at the end, then report back with the diff summary and merge
  decision.
- **`--hand-first`** (modifier, composable with the above) — for algorithmic or
  high-risk logic: before breakdown, the user hand-sketches the core approach
  in the spec's design section. Execution may not start until the sketch
  exists. Opt-in; default off.

## Context

The spec and the plan on disk are the state. The conversation is not — it is
disposable, and every gate is a place to drop it.

- **Clear points** — after the spec is approved (step 2), after the plan + test
  list are approved (step 3), and after the core-diff gate (step 5). At each,
  the artifact must be able to restart the next step ON ITS OWN. If it cannot,
  fix the artifact before clearing — never a chat summary standing in for it.
- **Progress lives in the plan** — each task row carries a status and its commit
  hash, written as the commit lands. No second state file: a job file is the
  endurance tier's artifact, not this one's.
- **Resume** — `/my-utils:new-feature resume <topic>` after a /clear or a lost
  session: read the spec, then the plan, reconcile the task table against
  `git log`, continue at the first task not done. Reality wins over the table.
  Full protocol: `references/context-and-resume.md`.
- **Budget** — past ~60% context, stop at the next gate and clear; never push
  through a gate to save a round trip.

## Flow

1. **Kanban start** — find-or-create the card, then move it to In Progress.
   ```bash
   ~/.claude/my-utils/kanban.sh find-or-create "<feature>" "<1-2 sentences>"
   ~/.claude/my-utils/kanban.sh move "<feature>" in-progress
   ```
   The board is optional: no config, no `gh`, or no auth exits 0 silently and
   the feature proceeds. Enable it once per machine with `./setup.sh --configure`.
2. **Design** — superpowers:brainstorming. Spec lands in
   `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and is committed.
   Collaborative: user approves the spec. `--hand-first`: the spec's design
   section carries the user's hand-sketch of the core approach — no breakdown
   until it exists.
3. **Breakdown (PLAN ONLY)** — GSD decomposes the spec into tasks. Run
   `/gsd-quick` with the explicit instruction "PLAN ONLY — write the plan, stop
   before execution". If gsd-quick cannot stop, or GSD is not
   installed, use the `## Fallbacks` row for it — the plan still carries the
   task table and the test list.
   Plan lands in `docs/superpowers/plans/YYYY-MM-DD-<topic>.md`.
   The plan MUST include a test list per task (test name + asserted behavior)
   and a task table — `| # | task | status | commit |`, statuses
   `pending` → `next` → `done`, first row `next`. That is the same shape
   /my-utils:long-running-job uses for units, so a handover copies across.
   Plan approval is a hard double gate: plan approved AND test list approved —
   execution may not start until both. Offload: the user approves plan + test
   list BEFORE the worktree starts; no further approval mid-run.
4. **Scale check** — two escalations on different axes; both can fire:
   - **Plan shape** — exceeds plan-file scale (multi-week, cross-cutting) → wrap
     as a GSD phase instead: `/gsd-plan-phase` (ROADMAP line + phases/NN-*),
     then execution continues through /gsd-execute-phase + superpowers TDD.
   - **Endurance** — the approved plan will not execute inside one context
     window (bulk mechanical edits across many files, an overnight run) → STOP
     at the plan gate and hand the plan to /my-utils:long-running-job. Do not
     start executing and hope to finish. The approved plan + test list transfer
     as-is; that tier requires exactly this artifact and never re-plans.
     Discovered late instead (a clear is needed INSIDE one task) → hand over
     mid-flight per `references/context-and-resume.md`; landed commits stay landed.
   Both firing → wrap as a GSD phase first, then run that phase's plan as a job.
5. **Execute** — superpowers:executing-plans, superpowers TDD inside each task,
   commit per task; mark that task's row `done` + short hash and the next row
   `next` as each commit lands — before starting the next task, never in a
   batch at the end. Offload: `superpowers:using-git-worktrees` first.
   Collaborative hard gate: the agent lists the core diff files; the user
   reads them and confirms read (not the summary). The review may not start
   until confirmed.
6. **Review — fan-out** — `~/.claude/my-utils/kanban.sh move "<feature>" review`
   first, then invoke my-utils:fan-out-review with `base` = the ref the work
   branched from, and the spec plus the plan's task table and test list as its
   requirements source. It returns findings per component and a conformance
   verdict — never scan the diff as one blob. Fix every surviving finding,
   tests green, commit. Collaborative checkpoints here; offload reports the
   CONSOLIDATED findings with the summary. The offload report MUST include a
   read-first section: 3-5 `file:line` pointers into the diff, one line each on
   what changed and why.
7. **Closeout** —
   - `~/.claude/my-utils/kanban.sh move "<feature>" done`.
   - Delete the executed plan file (`git rm docs/superpowers/plans/<file>.md`) —
     git is the archive. The SPEC stays.
   - STATE.md: ONE Decisions line ONLY if an architectural choice changed
     (one line + path pointer to the spec). Otherwise nothing.
   - Spec Outcome line: append `Outcome: shipped as planned` or
     `Outcome: diverged — <what> (commit <short-hash>)` to the spec. Spec-side
     only; STATE.md stays index-only.

## Fallbacks

Before invoking any dependency below, if it is not installed, follow its row
instead of improvising. A missing dependency degrades the step; it never
silently skips it. Two exceptions: escalation exits STOP rather than improvise,
because improvising past a handoff gate defeats it; and the Kanban board is
optional bookkeeping. `~/.claude/my-utils/doctor.sh` reports what is installed.

| Dependency | Absent → |
|---|---|
| `superpowers:brainstorming` | Ask the unanswered questions inline, one decision at a time, then write the same spec to the same path. The gate holds — no breakdown until the user approves it. |
| `superpowers:writing-plans` | Write the plan by hand in GSD form: task table, atomic commit per task, and a test list naming each test and the behavior it asserts. The double gate holds — the user approves plan AND test list before execution. |
| `superpowers:executing-plans` | Execute the plan task by task, one atomic commit each, in the planned order. |
| `superpowers:test-driven-development` | Write each task's failing test first, watch it fail, then implement. The invariant holds — execution never starts without an approved test list. |
| `superpowers:using-git-worktrees` | `git worktree add ../<slug> -b <branch>` directly (`--offload` only). |
| `/gsd-quick`, `/gsd-plan-phase`, `/gsd-execute-phase` | Breakdown falls back to writing the plan by hand as above. For a phase-scale wrap with no GSD installed, **STOP** and tell the user, rather than inventing a phase structure. |
| `my-utils:fan-out-review` | Authored in my-utils — `./setup.sh` is the fix. Still missing: run its flow inline — build the scan set from the diff plus importers/callers (`graphify query`, else grep the import path + symbol), one subagent per component invoking `linus`, one conformance subagent against the same requirements, then verify each finding in the code before fixing. |
| `my-utils:long-running-job` | Authored in my-utils — `./setup.sh` is the fix. Still missing: **STOP** at the plan gate. Report that the plan will not execute inside one context window and hand back to the user. Never start executing and hope to finish. |
| `linus` | Vendored here — `./setup.sh` is the fix. Still missing: run the same per-component fan-out, each subagent reviewing against data structure, special cases, gratuitous complexity, and breakage of existing callers. |
| `graphify` | Build the scan set with grep over the import path + symbol. |
| Kanban / `gh` (the board) | Skip every card step silently — the only dependency that degrades to nothing, because bookkeeping never gates work. |

## Hard rules

- GSD never executes feature plans — breakdown only.
- Execution never starts without an approved test list.
- Never skip the review pass, and never collapse it to one whole-diff scan —
  every affected component gets its own subagent, and conformance is checked
  against the spec and test list.
- Never leave the executed plan file behind; never delete the spec.
- The plan's task table is updated as each commit lands, never retroactively.
- On resume, reconcile the table against `git log` before doing any work —
  reality wins over the table.
- STATE.md stays index-only: if `git log` can tell you, it doesn't go in.

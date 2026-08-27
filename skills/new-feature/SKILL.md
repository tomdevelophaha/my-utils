---
name: my-utils:new-feature
description: "Use for feature work — new capabilities like Apple login, library integrations, UI subsystems. Pipeline: superpowers brainstorming → GSD plan-only breakdown (plan carries test list; double gate: plan + test list approved) → superpowers executing-plans with TDD (user reads core diff at checkpoint) → /linus fan-out review (subagent per affected component) → state closeout (spec Outcome line). Plan too big for one context window → /my-utils:long-running-job. Modes: collaborative (default), --offload (autonomous, worktree), optional --hand-first modifier. Trigger via /my-utils:new-feature."
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
- **`--offload`** — autonomous. Isolate in a worktree, run all gates, /linus at
  the end, then report back with the diff summary and merge decision.
- **`--hand-first`** (modifier, composable with the above) — for algorithmic or
  high-risk logic: before breakdown, the user hand-sketches the core approach
  in the spec's design section. Execution may not start until the sketch
  exists. Opt-in; default off.

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
   The plan MUST include a test list per task (test name + asserted behavior).
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
   Both firing → wrap as a GSD phase first, then run that phase's plan as a job.
5. **Execute** — superpowers:executing-plans, superpowers TDD inside each task,
   commit per task. Offload: `superpowers:using-git-worktrees` first.
   Collaborative hard gate: the agent lists the core diff files; the user
   reads them and confirms read (not the summary). `/linus` review may not
   start until confirmed.
6. **Review — /linus fan-out** — `~/.claude/my-utils/kanban.sh move "<feature>" review`
   first, then never scan the diff as one blob.
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
   d. **Fix** — real findings fixed, tests green, committed. Collaborative
      checkpoints here; offload reports the CONSOLIDATED findings with the
      summary. The offload report MUST include a read-first section: 3-5
      `file:line` pointers into the diff, one line each on what changed and why.
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
| `linus` | Vendored here — `./setup.sh` is the fix. Still missing: run the same per-component fan-out, each subagent reviewing against data structure, special cases, gratuitous complexity, and breakage of existing callers. |
| `graphify` | Build the scan set with grep over the import path + symbol. |
| Kanban / `gh` (the board) | Skip every card step silently — the only dependency that degrades to nothing, because bookkeeping never gates work. |

## Hard rules

- GSD never executes feature plans — breakdown only.
- Execution never starts without an approved test list.
- Never skip the /linus pass, and never collapse it to one whole-diff scan —
  every affected component gets its own subagent.
- Never leave the executed plan file behind; never delete the spec.
- STATE.md stays index-only: if `git log` can tell you, it doesn't go in.

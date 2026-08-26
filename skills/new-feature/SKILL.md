---
name: my-utils:new-feature
description: "Use for feature work — new capabilities like Apple login, library integrations, UI subsystems. Pipeline: superpowers brainstorming → GSD plan-only breakdown (plan carries test list; double gate: plan + test list approved) → superpowers executing-plans with TDD (user reads core diff at checkpoint) → /linus fan-out review (subagent per affected component) → state closeout (spec Outcome line). Modes: collaborative (default), --offload (autonomous, worktree), optional --hand-first modifier. Trigger via /my-utils:new-feature."
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

1. **Kanban start** — find-or-create the card on Project #1 → In Progress.
   Create (no card yet): `gh project item-create 1 --owner "@me" --title "<feature>" --body "<1-2 sentences>"`
   Move (Status is single-select — `--value` does NOT work):
   `gh project item-edit --id <item-id> --project-id <project-id> --field-id <status-field-id> --single-select-option-id <option-id>`
   (ids via `gh project field-list 1 --owner "@me" --format json`; project id via `gh project list --owner "@me"`)
2. **Design** — superpowers:brainstorming. Spec lands in
   `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and is committed.
   Collaborative: user approves the spec. `--hand-first`: the spec's design
   section carries the user's hand-sketch of the core approach — no breakdown
   until it exists.
3. **Breakdown (PLAN ONLY)** — GSD decomposes the spec into tasks. Run
   `/gsd-quick` with the explicit instruction "PLAN ONLY — write the plan, stop
   before execution". If gsd-quick cannot stop, fall back to
   superpowers:writing-plans with GSD conventions (task table, atomic commits).
   Plan lands in `docs/superpowers/plans/YYYY-MM-DD-<topic>.md`.
   The plan MUST include a test list per task (test name + asserted behavior).
   Plan approval is a hard double gate: plan approved AND test list approved —
   execution may not start until both. Offload: the user approves plan + test
   list BEFORE the worktree starts; no further approval mid-run.
4. **Scale check** — plan exceeds plan-file scale (multi-week, cross-cutting) →
   wrap as a GSD phase instead: `/gsd-plan-phase` (ROADMAP line + phases/NN-*),
   then execution continues through gsd-execute-phase + superpowers TDD.
5. **Execute** — superpowers:executing-plans, superpowers TDD inside each task,
   commit per task. Offload: `superpowers:using-git-worktrees` first.
   Collaborative hard gate: the agent lists the core diff files; the user
   reads them and confirms read (not the summary). `/linus` review may not
   start until confirmed.
6. **Review — /linus fan-out** — never scan the diff as one blob.
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
   - Kanban card → Done.
   - Delete the executed plan file (`git rm docs/superpowers/plans/<file>.md`) —
     git is the archive. The SPEC stays.
   - STATE.md: ONE Decisions line ONLY if an architectural choice changed
     (one line + path pointer to the spec). Otherwise nothing.
   - Spec Outcome line: append `Outcome: shipped as planned` or
     `Outcome: diverged — <what> (commit <short-hash>)` to the spec. Spec-side
     only; STATE.md stays index-only.

## Hard rules

- GSD never executes feature plans — breakdown only.
- Execution never starts without an approved test list.
- Never skip the /linus pass, and never collapse it to one whole-diff scan —
  every affected component gets its own subagent.
- Never leave the executed plan file behind; never delete the spec.
- STATE.md stays index-only: if `git log` can tell you, it doesn't go in.

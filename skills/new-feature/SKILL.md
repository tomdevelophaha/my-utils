---
name: my-utils:new-feature
description: "Use for feature work — new capabilities like Apple login, library integrations, UI subsystems. Pipeline: superpowers brainstorming → GSD plan-only breakdown → superpowers executing-plans with TDD → /linus review → state closeout. Modes: collaborative (default) or --offload (autonomous, worktree). Trigger via /my-utils:new-feature."
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
  spec approved, plan approved, execution complete, review done.
- **`--offload`** — autonomous. Isolate in a worktree, run all gates, /linus at
  the end, then report back with the diff summary and merge decision.

## Flow

1. **Kanban start** — find-or-create the card on Project #1 → In Progress.
   Create (no card yet): `gh project item-create 1 --owner "@me" --title "<feature>" --body "<1-2 sentences>"`
   Move (Status is single-select — `--value` does NOT work):
   `gh project item-edit --id <item-id> --project-id <project-id> --field-id <status-field-id> --single-select-option-id <option-id>`
   (ids via `gh project field-list 1 --owner "@me" --format json`; project id via `gh project list --owner "@me"`)
2. **Design** — superpowers:brainstorming. Spec lands in
   `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and is committed.
   Collaborative: user approves the spec.
3. **Breakdown (PLAN ONLY)** — GSD decomposes the spec into tasks. Run
   `/gsd-quick` with the explicit instruction "PLAN ONLY — write the plan, stop
   before execution". If gsd-quick cannot stop, fall back to
   superpowers:writing-plans with GSD conventions (task table, atomic commits).
   Plan lands in `docs/superpowers/plans/YYYY-MM-DD-<topic>.md`.
4. **Scale check** — plan exceeds plan-file scale (multi-week, cross-cutting) →
   wrap as a GSD phase instead: `/gsd-plan-phase` (ROADMAP line + phases/NN-*),
   then execution continues through gsd-execute-phase + superpowers TDD.
5. **Execute** — superpowers:executing-plans, superpowers TDD inside each task,
   commit per task. Offload: `superpowers:using-git-worktrees` first.
6. **Review** — /linus on the full diff. Fix real findings, tests green,
   collaborative checkpoints here; offload reports findings with the summary.
7. **Closeout** —
   - Kanban card → Done.
   - Delete the executed plan file (`git rm docs/superpowers/plans/<file>.md`) —
     git is the archive. The SPEC stays.
   - STATE.md: ONE Decisions line ONLY if an architectural choice changed
     (one line + path pointer to the spec). Otherwise nothing.

## Hard rules

- GSD never executes feature plans — breakdown only.
- Never skip the /linus pass.
- Never leave the executed plan file behind; never delete the spec.
- STATE.md stays index-only: if `git log` can tell you, it doesn't go in.

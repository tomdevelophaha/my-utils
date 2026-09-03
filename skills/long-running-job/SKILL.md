---
name: my-utils:long-running-job
description: "Use for coding jobs too big for one context window — overnight refactors, multi-hour migrations, bulk changes. Entered directly, or handed off from /my-utils:new-feature when a plan outgrows one context window — at its plan gate or mid-flight, in which case landed commits are reconciled, never re-run. Endurance layer only: plan-first hard gate, job-file state at .claude/jobs/, fresh session per unit via rewritten Handoff, verification gates per unit, quota pause/resume, --tmux detached mode. Execution inside units is superpowers:executing-plans + TDD; final review my-utils:fan-out-review (linus subagent per affected component, plus a conformance pass against the plan). Trigger via /my-utils:long-running-job."
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Agent
triggers:
  - long running job
  - long-running-job
  - overnight
  - run this overnight
---

# Long-Running Job — endurance tier

Supervisor loop around disposable workers. The job file is the state;
sessions are interchangeable. The job never depends on any session's memory.

## Modes

- **collaborative (default)** — current session executes one unit, then hands off.
- **--tmux** — detached: generated launcher loops headless units overnight
  (recipe: references/tmux-mode.md).

## Flow

1. **Gate (hard refusal)** — a job may NOT start without:
   - an approved plan at `docs/superpowers/plans/*.md`
   - an approved test list inside that plan
   Missing either → route the user to /my-utils:new-feature, which owns
   discovery and planning and carries its own fallbacks, then STOP. Do not
   "just start".
   Usual entry is /my-utils:new-feature's scale check handing the plan over
   once it will not execute inside one context window; its approved plan +
   test list satisfy this gate as-is — never re-approve or re-plan them.
2. **Init** —
   - ensure `.claude/jobs/` is gitignored in the target repo (append to
     .gitignore if absent; job files are runtime state, never committed)
   - create `.claude/jobs/<YYYY-MM-DD>-<slug>.md` from the contract below;
     record the plan file's sha256 (`shasum -a 256`) and `git rev-parse HEAD`
     as `base` — the closeout review diffs against it, and no later session
     can work it out for itself
   - the plan carries a task table in the same `pending`/`next`/`done`
     vocabulary — copy its rows into `## Units` as-is. Mid-flight handover from
     /my-utils:new-feature means some rows already say `done` with a commit:
     reconcile them against `git log` exactly as step 4 does, then start at
     `next`. Never re-run a landed unit, and never re-approve the test list.
   - find-or-create the Kanban card → In Progress:
     `~/.claude/my-utils/kanban.sh find-or-create "<slug>" "<1 line>"`
     `~/.claude/my-utils/kanban.sh move "<slug>" in-progress`
     (optional — exits 0 silently when no board is configured)
3. **Unit loop** — for the unit whose status is `next`:
   a. Execute via superpowers:executing-plans + superpowers:test-driven-development.
      ONE atomic commit per unit.
   b. **Gates**: typecheck + lint + the unit's tests. Commands come from the
      project CLAUDE.md; if absent, ask the user ONCE and record them in the
      job file Log.
   c. Gates green → mark the unit `done` + its commit hash; mark the next
      unit `next`; reset frontmatter `fix-attempts: 0`. Gates red → fix
      within the unit and increment `fix-attempts`; at `fix-attempts: 2` →
      frontmatter `status: paused-failed`, surface to the user, STOP.
   d. **Boundary** — rewrite `## Handoff` (decisions, gotchas, next unit's
      first action), append one Log line, then end the turn with exactly:
      `Unit N done. /clear, then: /my-utils:long-running-job resume <slug>`
4. **Resume** (`/my-utils:long-running-job resume <slug>`) — read the job
   file FIRST, then:
   - plan sha256 mismatch → re-gate before continuing
   - reconcile `## Units` against `git log` (a row claims `done` with no
     matching commit → back to `next`; a commit exists but row says
     `pending` → mark `done`). Reality wins; fix the table, log the repair.
   - `status: paused-quota` → if reset time has passed, set `running` and
     continue; else end with exactly: `Quota pause — resets <time>. Return
     then and run: /my-utils:long-running-job resume <slug>`
   - `status: paused-failed` → show the failure context and offer:
     fix manually then `resume <slug>`; abort (delete job file + launcher);
     or skip the unit (mark `done` with commit `-`) if it is optional
   - continue the unit loop at `next`
5. **Quota pause** — on a limit error mid-unit: frontmatter
   `status: paused-quota`, Log the reset time if the error states one, else
   Log `reset time unknown` (resume then re-attempts), end the turn with
   the quota stop message from step 4.
6. **Closeout — fan-out review** — all units done →
   `~/.claude/my-utils/kanban.sh move "<slug>" review`, then invoke
   my-utils:fan-out-review with `base` = the job file's `base`, and the plan's
   task table and test list as its requirements source. It returns
   findings per component and a conformance verdict — never scan the whole
   job's diff as one blob. Fix every surviving finding, gates green, commit.
   Then: `~/.claude/my-utils/kanban.sh move "<slug>" done` → delete `.claude/jobs/<slug>*` (file and launcher
   dir; git is the archive) → delete the executed plan file per new-feature
   convention; the SPEC stays with its Outcome line → STATE.md one Decisions
   line ONLY if architectural.

## Fallbacks

Before invoking any dependency below, if it is not installed, follow its row
instead of improvising. The plan gate never degrades — a job without an
approved plan and test list is refused regardless of what is installed. The
Kanban board is optional bookkeeping and skips silently.
`~/.claude/my-utils/doctor.sh` reports what is installed.

| Dependency | Absent → |
|---|---|
| `superpowers:executing-plans` | Execute the unit's plan tasks in order, one atomic commit per unit, exactly as the plan states. |
| `superpowers:test-driven-development` | Write each task's failing test first, watch it fail, then implement. The invariant holds — never modify a test to make it pass. |
| `my-utils:fan-out-review` | Authored in my-utils — `./setup.sh` is the fix. Still missing: run its flow inline — build the scan set from the diff plus importers/callers (`graphify query`, else grep the import path + symbol), one subagent per component invoking `linus`, one conformance subagent against the same requirements, then verify each finding in the code before fixing. |
| `my-utils:new-feature` | Authored in my-utils — `./setup.sh` is the fix. Still missing: **STOP.** The plan gate never degrades — report that an approved plan and test list are required first, then hand back to the user. |
| `linus` | Vendored here — `./setup.sh` is the fix. Still missing: run the same per-component fan-out, each subagent reviewing against data structure, special cases, gratuitous complexity, and breakage of existing callers. |
| `graphify` | Build the scan set with grep over the import path + symbol. |
| Kanban / `gh` (the board) | Skip every card step silently — the only dependency that degrades to nothing, because bookkeeping never gates work. |

## Job file contract

Path: `.claude/jobs/<YYYY-MM-DD>-<slug>.md` (gitignored). This file plus the
plan is ALL a fresh session gets.

    ---
    job: <slug>
    created: YYYY-MM-DD HH:MM
    mode: collaborative
    plan: docs/superpowers/plans/<file>.md
    plan-sha256: <sha>
    base: <git rev-parse HEAD at init>
    test-list: approved YYYY-MM-DD
    fix-attempts: 0
    status: running
    units-total: N
    ---
    ## Units

    | # | unit (plan task refs) | status | commit |
    |---|-----------------------|--------|--------|
    | 1 | <one-line desc> | next | - |
    | 2 | <one-line desc> | pending | - |

    ## Handoff

    (REWRITTEN at every boundary — replaces context, never summarizes it)

    - Decisions: <none yet>
    - Gotchas: <none yet>
    - Next action: <first action of the current unit>

    ## Log

    - YYYY-MM-DD HH:MM job created

Unit statuses (table column): `pending` → `next` → `done`. Frontmatter
`status`: `running` | `paused-quota` | `paused-failed` | `done` — only these.

## Hard rules

- Never start a job without an approved plan + test list.
- `base` is recorded at init and never recomputed — a closeout session has only
  the job file, and a skipped unit's commit is `-`.
- Handoff is REWRITTEN at boundaries, never appended.
- Fresh session per unit — never carry one unit's context into the next.
- Never modify a test to make it pass; that is an automatic `paused-failed`.
- Reconcile against git log on every resume; reality wins over the file.
- Job files are never committed; launchers are deleted at closeout.
- This skill never re-plans (GSD/superpowers own that) and never skips review.
- Closeout review is never one whole-diff scan — every affected component gets
  its own subagent, and conformance is checked against the plan.

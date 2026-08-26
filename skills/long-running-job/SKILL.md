---
name: my-utils:long-running-job
description: "Use for coding jobs too big for one context window — overnight refactors, multi-hour migrations, bulk changes. Endurance layer only: plan-first hard gate, job-file state at .claude/jobs/, fresh session per unit via rewritten Handoff, verification gates per unit, quota pause/resume, --tmux detached mode. Execution inside units is superpowers:executing-plans + TDD; final review /linus fan-out (subagent per affected component). Trigger via /my-utils:long-running-job."
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
   Missing either → route the user to superpowers:brainstorming +
   superpowers:writing-plans, then STOP. Do not "just start".
2. **Init** —
   - ensure `.claude/jobs/` is gitignored in the target repo (append to
     .gitignore if absent; job files are runtime state, never committed)
   - create `.claude/jobs/<YYYY-MM-DD>-<slug>.md` from the contract below;
     record the plan file's sha256 (`shasum -a 256`)
   - find-or-create the Kanban card → In Progress:
     create: gh project item-create 1 --owner "@me" --title "<slug>" --body "<1 line>"
     move: gh project item-edit --id <item-id> --project-id <pid> --field-id <fid> --single-select-option-id <oid>
     (ids via: gh project field-list 1 --owner "@me" --format json)
     skip silently if gh unavailable
3. **Unit loop** — for the unit whose status is `next`:
   a. Execute via superpowers:executing-plans + TDD. ONE atomic commit per unit.
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
6. **Closeout — /linus fan-out** — all units done, then never scan the whole
   job's diff as one blob:
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
   d. **Fix** — real findings fixed, gates green, committed.
   Then: Kanban card Done → delete `.claude/jobs/<slug>*` (file and launcher
   dir; git is the archive) → delete the executed plan file per new-feature
   convention; the SPEC stays with its Outcome line → STATE.md one Decisions
   line ONLY if architectural.

## Job file contract

Path: `.claude/jobs/<YYYY-MM-DD>-<slug>.md` (gitignored). This file plus the
plan is ALL a fresh session gets.

    ---
    job: <slug>
    created: YYYY-MM-DD HH:MM
    mode: collaborative
    plan: docs/superpowers/plans/<file>.md
    plan-sha256: <sha>
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
- Handoff is REWRITTEN at boundaries, never appended.
- Fresh session per unit — never carry one unit's context into the next.
- Never modify a test to make it pass; that is an automatic `paused-failed`.
- Reconcile against git log on every resume; reality wins over the file.
- Job files are never committed; launchers are deleted at closeout.
- This skill never re-plans (GSD/superpowers own that) and never skips /linus.
- Closeout review is never one whole-diff scan — every affected component gets
  its own subagent.

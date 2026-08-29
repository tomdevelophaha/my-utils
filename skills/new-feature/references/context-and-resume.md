# Context and resume — new-feature tier

Loaded when a session is cleared mid-feature, when `resume` is invoked, or when
execution turns out not to fit one context window.

## The rule this tier borrows from the endurance tier

/my-utils:long-running-job survives context loss because its job file, not the
session, is the state. This tier takes the principle and not the artifact: it
already writes two durable files, so it needs no third one.

| Artifact | Path | Answers |
|---|---|---|
| Spec | `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` | why, and what "done" means |
| Plan | `docs/superpowers/plans/YYYY-MM-DD-<topic>.md` | the tasks, their tests, and how far they got |
| `git log` | — | what actually landed |

A job file appearing in this tier means the work outgrew it. Escalate instead
of inventing one.

## The task table

Written at breakdown (step 3), inside the plan, above the per-task detail:

    | # | task | status | commit |
    |---|------|--------|--------|
    | 1 | <one-line desc> | next    | -       |
    | 2 | <one-line desc> | pending | -       |

Statuses are `pending` → `next` → `done`, the same vocabulary
/my-utils:long-running-job uses for units — a handover copies the rows across
unchanged.

Update it as each commit lands: that row `done` + short hash, the following row
`next`. Never in a batch at the end — a batch update is exactly the write that
is lost when the context is.

## Clearing at a gate

Before `/clear`, the artifact must be able to restart the next step on its own.
Check, in this order:

1. The spec (or plan) is committed — uncommitted state is not durable state.
2. The next step's input is IN the file, not in the conversation. A decision
   made in chat and never written down does not survive; write it into the
   spec's design section or the plan's task notes first.
3. The task table matches `git log`.

Failing any of these is fixed in the file. A summary posted in the chat is not
a fix — the next session does not read the chat.

## Resume protocol

`/my-utils:new-feature resume <topic>`

1. Read the spec. Then the plan. In that order, and before touching any code.
2. Reconcile the task table against `git log`:
   - a row says `done` with no matching commit → set it back to `next`
   - a commit exists for a row still `pending`/`next` → set it `done` + hash
   - reality wins; fix the table, then continue
3. No plan file → the feature never passed the plan gate. Restart at step 3 of
   the flow, not at execution.
4. No task marked `next` and rows remain → set the first unfinished row `next`.
5. All rows `done` → jump to the review fan-out (step 6), not to closeout;
   `git log` shows whether /linus already ran.
6. Continue at `next` under superpowers:executing-plans + TDD as normal.

`--offload` resumes identically inside its worktree — same two artifacts, and
`git log` is the worktree's branch.

## When resume is the wrong answer

Resume recovers a session. It does not rescue work that does not fit the tier.

Hand the plan to /my-utils:long-running-job when either holds:

- a second clear is needed **inside one task's** execution — the unit itself
  exceeds a context window
- the remaining tasks plainly will not finish in the window that is left, and
  clearing at a task boundary only defers the same wall

Handover mid-flight: commit the current task, reconcile the table, leave the
plan and spec in place, then start the job on that same plan. Landed commits
stay landed — that tier's init reads the table's `done` rows and reconciles
them against `git log` like any other resume. It never re-plans and never
re-approves the test list.

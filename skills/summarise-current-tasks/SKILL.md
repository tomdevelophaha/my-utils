---
name: my-utils:summarise-current-tasks
description: Use when a plan's tasks need approving before any of them run — you ask what the tasks are, what is about to happen, to walk through the plan, or to list the work for sign-off. Renders the active plan's task table as one bold header line plus one or two sentences of plain prose per task, keeping the plan's own numbering, marking only the tasks that are not an ordinary commit, and closing by offering to run them in order. Also invoked explicitly as /my-utils:summarise-current-tasks.
---

# Summarise Current Tasks

Render the active plan's task table as a short list that can be approved before
any of it runs.

This is the approval view of a plan, not a summary of one. The plan is already
on disk with its rationale, file lists and test lists. What is missing is a
reader-sized answer to "what is about to happen, and which of it is hard to
undo". Compress every task to that.

## Where the tasks come from

- The task table of the plan for the work in flight — a phase `PLAN.md`, a plan
  file under `docs/plans/` or `docs/*/plans/`, or the unit list in a job file
  under `.claude/jobs/`. Several candidates → the one the current work belongs
  to.
- Reconcile against `git log` first. A task already committed is reality
  whatever its row says: it drops out of the list, the tasks that remain keep
  their original plan numbers, and the closing line names the real first and
  last of those — plus what already landed, so a list starting at 4 is not a
  silent gap.
- No plan file → say so in one line and stop. Never invent a task list.

## Output

Per task, exactly two lines, then a blank line:

```
**<n> — <terse task name>** *(annotation, only when it earns one)*
<one or two sentences of plain prose>
```

Then a blank line and one closing sentence offering to proceed:
`Say go and I'll run 1–10 in order.` When earlier tasks have already landed, the
same sentence says so: `Say go and I'll run 4–10 in order; 1–3 are already
committed.`

## Rules

- **The plan's numbers, unchanged.** Same numbers, same order. No renumbering,
  merging, splitting, or padding the list back out with finished work.
- **Dashes are not interchangeable.** An em dash `—` (U+2014) separates the
  number from the name; an en dash `–` (U+2013) joins ranges (`001–005`,
  `1–10`). This gets read side by side with the plan.
- **Name: component prefix, colon, the change** — `neon-target: exports +
  main-guard`. Backtick identifiers, files and flags: `` `selectBranch` ``,
  `` `.env.example` ``, `` `--baseline` ``. Drop the prefix when the task is not
  scoped to one component (`Baseline develop 001–005`, `Prod --status`).
- **Annotate only what is not an ordinary code or docs commit.** Italic,
  parenthesised, appended to the header line after a space. There are exactly
  three:
  - `*(database, irreversible)*` — writes state that cannot be trivially undone
  - `*(secrets)*` — generates or sets credentials
  - `*(read-only)*` — verifies something, changes nothing

  Everything that only lands a commit gets none. Never invent a fourth kind to
  look thorough; if none of the three fits, use none.
- **Body: one or two sentences.** The first says what the task does. The second,
  when there is one, carries the consequence or the reassurance — what stays
  safe, what it does not touch, why it matters. Two is the ceiling, not the
  target. No bullet, no label, no "This task will…".
- **Compress, never copy.** The plan's own section for a task is the input;
  plain prose for someone who has not read the plan is the output. Rewrite it
  even when that section is already two sentences.
- **Nothing else.** No heading, table, sub-bullet, preamble, file list, test
  list, or restatement of the plan's rationale.

## Example

> **1 — neon-target: `selectBranch`**
> Fix the branch-name collision. Production is addressed by project id + branch; an ambiguous name errors instead of silently picking the test project.
>
> **2 — migrate: prod from the Neon API**
> `--target prod` mints its connection string at run time and holds it in memory. `DATABASE_URL_PROD` is deleted — no production credential is stored anywhere.
>
> **3 — Baseline develop 001–005** *(database, irreversible)*
> Record the five migrations the schema proves are applied, with no schema changes. 006 and 007 stay pending because they genuinely are.
>
> **4 — Admin credentials to Vercel** *(secrets)*
> Generate the password, set `ADMIN_HOST` / `ADMIN_USER` / `ADMIN_PASSWORD` on preview and production, and hand you the password. Nothing enters the diff.
>
> **5 — Prod `--status`** *(read-only)*
> Check production reports 001–005 applied and 006–007 pending. Reads the migration table and changes nothing.
>
> Say go and I'll run 1–5 in order.

## Red flags

Start over if you catch yourself doing these:

- Renumbering, reordering or merging tasks so the list reads better
- A body over two sentences, or one that grew a sub-bullet
- An annotation on a task that only lands a commit — or a fourth annotation kind
- An en dash in a header, an em dash in a range
- Describing work `git log` shows is already committed as still ahead
- Dropping the closing line, or a range that is not the real first and last
- Pasting the plan's own wording instead of compressing it

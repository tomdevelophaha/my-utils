# summarise-current-tasks — design

- Date: 2026-09-09
- Status: approved

## Goal

Render the active plan's task table as a short list the user can approve
*before* any of it runs. The plan file itself is the wrong artifact to approve
from — it carries rationale, file lists, test lists and acceptance criteria,
none of which answer "what is about to happen to my machine". This is the
approval view of a plan, not a summary of one.

## Decision

**A fixed two-line shape per task, and nothing else.**

```
**<n> — <terse task name>**<optional annotation>
<one or two sentences of plain prose>
```

The format was demonstrated live and approved verbatim; the skill exists to
make that exact shape repeatable. Three parts carry the weight:

1. **Plan numbers, never renumbered.** The user reads this next to the plan.
   A number that means different things in the two documents makes the review
   worthless.
2. **A closed set of three annotations** — `*(database, irreversible)*`,
   `*(secrets)*`, `*(read-only)*`. They mark the tasks where "go" means
   something other than "land a commit". Ordinary tasks get none, so the marked
   ones stand out; an open-ended annotation vocabulary would erase that signal
   within one render.
3. **Two sentences, compressed not copied.** Sentence one is what it does;
   sentence two, when present, is the consequence or the reassurance. The
   ceiling exists because the plan is already available — anything longer is
   the plan again, and the user stops reading.

Rejected alternatives:

- **Render the plan's task table as a table.** Scannable, but a table column
  cannot hold the reassurance sentence, which is the part that earns the "go".
- **Per-task sub-bullets** (files, tests, risk). Complete, and unreviewable —
  ten tasks becomes eighty lines and the reader skims.
- **Free-form prose summary of the plan.** Loses the 1:1 mapping to task
  numbers, so approving it approves nothing specific.

## Invariants

- Reconcile against `git log` before rendering. A committed task is reality
  whatever its row says; already-landed work never appears as upcoming. It
  drops out and the survivors keep their original numbers.

  This is the one place the approved format did not cover, and dropping tasks
  silently produces a list that starts at 4 with nothing saying why. "Nothing
  else" rules out a preamble, so the closing line — already the only sentence
  carrying meta-information about the range — carries the landed range too, as
  one sentence. When nothing has landed it is unchanged from the gold standard.
- Em dash `—` separates number from name; en dash `–` joins numeric ranges
  (`001–005`, `1–10`). The user reviews these side by side, so the two are not
  interchangeable.
- No plan file → one line saying so, then stop. Inventing a task list produces
  an approval for work nobody planned.

## Note on the reference output

The approved gold standard's baseline task ran to three sentences, over the
stated two-sentence ceiling. The skill's example compresses it to two rather
than shipping an example that contradicts its own rule.

## Dependencies

None. It reads plan files and `git log` — no external skill, no board, no shell
helper — so no `## Fallbacks` table.

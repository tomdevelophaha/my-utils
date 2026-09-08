---
name: my-utils:summarise-current-tasks
description: Use when several pieces of work are on the table — a multi-part request, or a to-do list already in flight — and the user wants to read what will be done before any of it starts. Produces one short line per task in execution order, lifts every unmade decision and unresolved unknown out of those lines into a list of questions, and stops for approval without changing a file. Not for re-orienting mid-session or recapping what was just done — that is my-utils:quick-summary. Trigger via /my-utils:summarise-current-tasks, "summarise current tasks", "describe the tasks", or "for my review before going ahead".
triggers:
  - summarise current tasks
  - summarize current tasks
  - summarise the tasks
  - summarize the tasks
  - describe the tasks
  - tasks for my review
  - for my review before going ahead
---

# Summarise Current Tasks

The user is about to authorise a batch of work and wants to read it first. What
they approve **is** the list, so the list has to be checkable: short enough to
take in at a glance, honest about everything still undecided.

The job is not to prove the work is understood. It is to expose, cheaply, the
places where it might be *mis*understood — before any of it gets built.

## Before writing the list

Read whatever you need — the files, the tests, the to-do list already in flight.
Reading is what stops the list being guesswork. **Change nothing:** no edits, no
new files, no commits. The turn ends at the list.

## Output

Numbered lines, one per task, ordered the way they would actually run —
anything that unblocks another task comes first. Each line is:

`<what will be true afterwards, ≤ 12 words> — <where it lands>`

Then, only if any exist, the line `— Needs your call —` and one bullet per open
question. Each is one line: a single question in the user's terms, ending in the
one concrete default you will take if they say nothing. Past three, keep the
three that most change what gets built and add a final bullet naming the rest
("plus 2 unknowns in the PDF renderer") — never drop one silently.

Then one sentence stating that nothing starts until they reply.

No headers, no per-task rationale, no closing summary.

## Rules

- **Describe the after, not the before.** The line says what will be true once
  the task is done. Current state — "currently returns the whole table", "only
  prints the subtotal" — is diagnosis, not description. It doubles the length of
  every line to answer a question nobody asked. When a current-state fact would
  genuinely change the user's answer, it is not context, it is a decision: put
  it under **Needs your call**.
- **A choice you made goes below the list, never inside it.** "Add limit/offset
  (or cursor) params" is not a description, it is an unmade decision wearing
  one — approving that line approves a choice the user never saw. The task line
  reads `Paginate the invoice list`; the choice moves down to
  `Pagination style — default: offset, page size 50`.
- **What you could not find out is the most valuable line in the list.** Give it
  its own bullet and ask the question you actually need answered. Never dissolve
  it into "…with the current env var" or "whatever replaced it" — phrasing like
  that reads as a plan while meaning "I don't know", which is the one thing a
  review gate must never hide.
- **A default is the one option you would actually take and defend.** Not the
  most cautious-sounding one. "Add the endpoint but leave it unmounted" is legal
  phrasing and a useless outcome — it hands back a task the user approved that
  does nothing. It is also *one* option: `default: offset, page size 50`, never
  `offset or cursor`, never ``assume `inv.tax`/`inv.taxRate` ``. A default still
  carrying alternatives is the same undecided question moved one line down,
  where it is even easier to nod past. Two things you cannot confirm are two
  bullets.
- **Task lines read as though every default holds.** A line promising "README
  documents the current env var" above a default that deletes the entry hands
  the user the opposite of what they approved. Write each line for what will
  really happen if they say nothing; the questions exist to change that, not to
  quietly contradict it.
- **`(not asked)` is only for work that is safe to strike.** An independent
  cleanup you judged worth doing gets a task line tagged `(not asked)`, so one
  word removes it. A *prerequisite* is not that: something the user did ask for
  depends on it, and striking it in one word silently breaks the task above it.
  Prerequisites go below the list, as the question they actually are, carrying
  the default that builds them.
- **One line per unit of work, not per clause of the request.** An ask that is
  really three separate changes gets three lines. Four asks that turn out to be
  one edit get one line saying so.
- **The count is the whole scope.** Never "…and a few small fixes". A long list
  stays long; trimming it to look tidy is the one edit that defeats the review.

## Example

Asked for: tax breakdown on the invoice PDF, reminders that stop once an invoice
is paid, pagination on a slow `/invoices` endpoint, and a stale `BILLING_KEY`
entry in the README.

> 1. Skip reminders for invoices already paid — `src/jobs/reminder.ts`
> 2. Paginate the invoice list endpoint — `src/routes/invoice.ts`
> 3. Show the tax breakdown on the invoice PDF — `src/lib/pdf.ts`
> 4. Remove the stale `BILLING_KEY` entry — `README.md`
> 5. Delete the unused `legacy.ts` helper — `src/db/legacy.ts` `(not asked)`
>
> — Needs your call —
> · Reminders need a paid flag the schema has none of — default: add `status` to the invoice table
> · Pagination style — default: offset, page size 50
> · `BILLING_KEY` is named in no source file — default: delete the entry as stale
>
> Nothing starts until you reply.

The schema field task 1 needs is a *question*, not a task line: it is a
prerequisite, so offering it as strikable `(not asked)` work would let one word
leave task 1 unbuildable. Only task 5 — an independent cleanup nothing depends
on — is safe to carry that tag. Task 4 says *remove*, matching its own default,
rather than the softer "update the env var docs" that would have promised the
user something else entirely.

## Red flags

Start over if you catch yourself doing these:

- A line beginning "currently", or carrying both a diagnosis and a plan
- Two sentences on one task
- A slash or a "(or …)" anywhere — in a task line *or* inside a default
- A bullet that runs past one line, or asks two questions at once
- A task line promising something its own default would not deliver
- A default that makes its own task line pointless
- An unknown you found and did not list
- A prerequisite tagged `(not asked)` — striking it would break the task above
- "whatever", "the appropriate one", "as needed" — a gap dressed as a plan
- A file changed, or a command with side effects run, at any point in this turn
- A list tidier and shorter than the work it stands for

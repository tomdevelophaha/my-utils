# summarise-current-tasks — design

- Date: 2026-09-09
- Status: approved

## Goal

A review gate. Several pieces of work are on the table — a multi-part request,
or a to-do list already in flight — and the user wants to read what will be done
before any of it starts. What they approve *is* the list, so the list has to be
checkable in one pass and honest about what is still undecided.

## What the baseline actually got wrong

Five runs of the same request without the skill (three text-only, two with tools
against a fixture repo). The results reframed the design:

1. **The gate was never the problem.** Both tool-enabled runs changed zero
   files. When the user says "before going ahead", models already stop. So this
   is a *shaping* skill, not a discipline skill — built as a positive recipe
   rather than a wall of prohibitions.
2. **Investigation inflates the description.** Reading the code made every run
   prepend a diagnosis clause per task — "currently prints Subtotal/Total only",
   "fetches the entire table with no limit" — drifting to two sentences each.
   The better the research, the longer the "very short" list got.
3. **Unmade decisions were presented as plans.** All five wrote
   "limit/offset **(or cursor)**"; one added "sane defaults" and "cap the max
   page size" — scope never requested, stated as settled. Approving that line
   approves a choice the user never saw.
4. **The one genuine blocker got buried.** `BILLING_KEY` appears in no source
   file. Every run dissolved that into "…with the current env var" or "whatever
   replaced it" — phrasing that reads as a plan and means "I don't know".
5. **No execution ordering.** All five mirrored the user's clause order.

## Decision

**A fixed two-part contract: numbered one-line tasks in dependency order, then
`— Needs your call —`.**

Each task line is `<what will be true afterwards, ≤ 12 words> — <where>`. The
"after, not before" framing is what kills finding 2 without a word-count rule:
current state is diagnosis, and diagnosis has nowhere to live in the line.

Everything the agent had to *choose* or could not *find out* is routed below the
list as a one-line question with a single concrete default. That is the whole
mechanism against findings 3 and 4 — the list stays short because the
uncertainty has somewhere honest to go, instead of being compressed into a
confident-sounding clause.

Rejected alternatives:

- **Prohibitions ("don't speculate", "never pad").** The skill-writing guidance
  is explicit that prohibitions backfire on shaping failures — under a competing
  incentive the agent negotiates with them. A recipe leaves nothing to negotiate.
- **`allowed-tools` restricted to read-only.** Structurally enforces "change
  nothing", but the baseline showed that failure does not occur, and it would
  hamper the follow-on work once the user approves. Solving a non-problem at the
  cost of a real one.
- **Naming the work tiers as the post-approval route.** Would add four
  `## Fallbacks` rows of boilerplate for skills this one does not actually call.
  The skill ends at approval and hands back to the user.

## What re-testing changed

With the first draft, both runs lifted the pagination choice out of the list and
surfaced the unknown as its own question — but two new leaks appeared, in both:

- **Ambiguity migrated into the defaults.** The "no slash / no (or …)" rule was
  scoped to task lines, so it escaped one line down: ``default: assume
  `inv.tax`/`inv.taxRate` ``. Fixed by requiring a default to be one concrete
  choice, and by widening the red flag to "anywhere".
- **Task lines contradicted their own defaults.** Both promised "README
  documents the current env var" above a default that *deleted* the entry. Fixed
  by "task lines read as though every default holds" — the questions exist to
  change the plan, not to quietly contradict it.

The worked example was rewritten to obey the contract it teaches; two of its
bullets originally had no default at all.

Four runs with the skill all produced the contract shape and changed no files
(confirmed by `git status` on the fixtures, not by the agents' own claims). Two
caveats on that evidence:

- The run given the *same* scenario as the worked example reproduced it almost
  verbatim, so it is not independent evidence. The generalisation signal comes
  from the run on an unrelated scenario, which held the shape without borrowing
  the example's content.
- One residual defect showed up: on a task line reading "Add a `/health`
  endpoint returning 200 OK", the default below it was "leave it unmounted" —
  which a load balancer cannot reach. See the review below; this turned out not
  to be a wording problem.

## What review changed

A `/linus` pass found the contract weighted onto the wrong half. Four fixes:

- **The questions block could silently lose entries.** It was capped at three
  bullets with no overflow rule, while the task list was explicitly
  un-trimmable — so the half this skill exists for was the half allowed to drop
  things, and a rule permitting "one bullet naming the one that actually blocks
  the work" told it how. Now: one bullet per question, and past three, the rest
  are *named*, never dropped — the treatment `plain-english` already gives its
  detail block.
- **The worked example taught a trap.** It tagged a schema change `(not asked)`
  while the task below depended on it, so "skip 1" left task 2 unbuildable —
  and the commentary stated both facts without noticing they conflict.
  `(not asked)` is now reserved for genuinely independent cleanups; a
  prerequisite goes below the list as a question carrying the default that
  builds it.
- **The unmounted-endpoint defect was a definition problem, not wording.** A
  default was specified by form (one option, no alternatives) but never by
  quality, so "leave it unmounted" was legal — and an agent could even comply by
  weakening the task line to match it. A default is now *the option you would
  actually take and defend*, which makes that case illegal on its face rather
  than merely less likely.
- **Routing collided with `quick-summary`.** Both descriptions claimed "what
  still needs doing" with no boundary, and the global default report shape makes
  `quick-summary` the higher-prior route — so a user asking for a gate could get
  a recap and approve a plan whose unknowns were never surfaced. Both
  descriptions now name the other skill and the axis: recap vs. gate.

Also tightened: the bare trigger `before going ahead` (ordinary conversational
glue — a false positive on a *stop-and-wait* skill halts work nobody asked to
halt), and a red flag that said "before the user replied" as though a
post-approval phase existed, contradicting "the turn ends at the list".

## Invariants

- Read freely, change nothing. Reading is what stops the list being guesswork;
  the turn still ends at the list.
- A description never carries a decision. Every choice and every unknown lives
  below the list, one line each, with one concrete default.
- The count is the whole scope — a long list stays long. Trimming it to look
  tidy is the single edit that defeats the review.
- Work nobody asked for may appear, tagged `(not asked)`, so it can be struck in
  one word.

## Dependencies

None. No external skill, no board, no shell helper — so no `## Fallbacks` table.

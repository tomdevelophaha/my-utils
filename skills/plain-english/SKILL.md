---
name: my-utils:plain-english
description: Use when a coding report needs to land for a non-engineer — you ask what I actually did, say "in plain English" / "explain simply" / "ELI5 that", or paste a report, PR description, commit message, or another agent's summary you want decoded. Rewrites it as a few everyday-language sentences followed by a compact detail block that keeps the files touched, the root cause, what was actually verified, and what is still at risk. Trigger via /my-utils:plain-english, "plain english", "explain simply", "in layman's terms", or "what did you actually do".
triggers:
  - plain english
  - explain simply
  - layman
  - eli5
  - what did you actually do
---

# Plain English

Rewrite a technical coding report so someone who does not code follows what
happened — without deleting the facts that let them check it or ask a good
follow-up question.

Simplifying is not summarizing. A summary drops detail; this drops *jargon* and
keeps detail. What blocks a non-engineer is rarely the file path — it is
unexplained terms, assumed architecture, and a missing "so what does that mean
for me". So: keep the nouns, translate the verbs, lead with the effect.

Explain it the way a good mechanic explains a repair — "your alternator was
dying, that's why the lights kept dimming; I swapped it and test-drove it" —
not "alternator replacement performed."

## Output

Two parts, always in this order.

**Plain part** — 2-5 short sentences in everyday words:

1. What the person actually experienced — the broken thing, or the new thing
   that now works.
2. Why it happened, as cause and effect.
3. What was done about it, and whether it is confirmed or still unproven.

**Detail block** — the line `— Detail —`, then 3-6 terse bullets carrying:

- files or functions touched, by real path
- the root cause, or why this approach over the obvious alternative
- what was actually run and what it printed — exact command, exact numbers
- what is not covered: untested paths, assumptions, what to watch in production

## Rules

- **Verified and assumed never blur.** A test result appears only if a command
  ran and its output was seen. Otherwise the bullet says "not run". A report
  that sounds confident about work nobody checked is worse than no report.
- **Numbers stay exact.** "34 tests passed", not "tests passed".
- **Jargon budget.** A technical term survives in the plain part only if the
  reader already owns it (their feature, their file, their bug) or it is
  explained in the same sentence. Everything else moves down verbatim into the
  detail block, where precision is the whole point — the exact paths and
  commands are what make the plain part trustworthy rather than a nice story.
- **Decoding someone else's report** (pasted PR text, an agent's summary): carry
  only what it says. If it never states whether anything was run, that is the
  bullet — "the report doesn't say what was verified". Never close a gap by
  inference.
- **Caps: 5 sentences, 6 bullets.** They exist so the pressure to shorten lands
  on prose, not on facts. Going over usually means narrative is being padded in
  — cut the prose.
- **A genuinely large report gets grouped, never trimmed.** When there are more
  real changes than bullets, one bullet covers one cluster of related changes,
  and a final bullet names what did not fit ("plus 4 smaller changes across the
  API routes"). Silently dropping a change to hit the cap defeats the whole
  point of the detail block.

## Example

Source report: *"Refactored the income aggregation to key off `performedAt`
rather than `paidAt` in the monthly reducer, since the prior implementation
conflated accrual and cash-basis semantics. Test suite green."*

> Your monthly totals were counting a job in the month the client paid you,
> not the month you actually did the work. That's why a job you did in June
> showed up in July's income. I changed that rule so it now counts by the date
> you worked, and the existing tests still pass.
>
> — Detail —
> · `src/lib/income.ts` — the monthly total now reads the work date
>   (`performedAt`) instead of the payment date (`paidAt`)
> · Root cause: the two dates were treated as interchangeable; for any job paid
>   in a later month they are not
> · `npm test` → 34 passed
> · Not covered: jobs split across months, and multi-currency jobs — no test
>   exercises either path

## Red flags

Start over if you catch yourself doing these:

- A term in the plain part you never explained ("we refactored the repository
  layer", "added a migration")
- A detail block that restates the plain part instead of adding paths, commands
  and numbers
- "Should work" / "tests should pass" — it either ran or it didn't; say which
- The explanation running longer than the report it explains
- Leading with what you did instead of what the reader experienced

# plain-english — design

- Date: 2026-08-28
- Status: approved

## Goal

Turn a technical coding report into something a non-engineer follows, without
losing the facts that make it checkable. Applies both to my own report at the
end of a task and to a report pasted in from elsewhere (a PR body, a commit
message, another agent's summary).

## Decision

**Two-part output: a plain narrative, then a `— Detail —` block.**

The framing that matters: this is *not* a summarizer. A summary drops detail to
get shorter. This drops jargon and keeps detail — the plain part carries the
cause-and-effect story, the detail block carries the paths, commands, numbers
and gaps. Splitting them is what lets the prose stay genuinely plain without
the output becoming unverifiable.

Four things must always survive the translation (chosen by the user):

1. files / functions touched
2. root cause, or why this approach
3. verified vs. assumed — what actually ran
4. risks and what is not covered

Rejected alternatives:

- **One flowing narrative.** Reads better, but jargon leaks back into the prose
  because paths and commands have nowhere else to live.
- **Fixed labeled sections** (What was wrong / What I changed / …). Predictable,
  but the headers dominate short reports and turn a three-sentence answer into a
  form. The plain part already implies that order.

## Invariants

- Verified and assumed never blur. No test result without a command that ran.
- Caps (5 sentences, 6 bullets) exist so the pressure falls on prose, not
  detail — over the cap, cut narrative. A report with more real changes than
  bullets groups them one cluster per bullet and names the remainder; it never
  drops a change to fit.
- Decoding someone else's report never fills a gap by inference; a silent source
  produces an explicit "the report doesn't say" bullet.

## Dependencies

None. No external skill, no board, no shell helper — so no `## Fallbacks` table.

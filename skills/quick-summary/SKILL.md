---
name: my-utils:quick-summary
description: Use when the user asks what we were just doing, for a quick recap, what's next, what still needs doing, or to re-orient after returning to this session. Not for gating a batch of work before it starts — when the user wants to approve task descriptions before anything is touched, that is my-utils:summarise-current-tasks. Also invoked explicitly as /my-utils:quick-summary.
---

# Quick Summary

Give a quick recap of what we were just doing, then the upcoming to-do list — nothing else.

## Rules

- Start with exactly one recap paragraph: 3-5 simple sentences on the most recent work (what we changed + why, or current state).
- Then a bullet list of next steps: 3-6 items, verb-first, ordered by what unblocks what.
- No headers, tables, or extra prose. No filler.
- Recap covers only the most recent work, not the whole session. Mention at most one or two key file paths.
- List only work still ahead, never what's already done.

## Example

> We switched logging in `/api/chat` from pino to Axiom so prod logs ship reliably again. The code swap is committed. Next:
> - Deploy to Vercel
> - Confirm logs arrive in Axiom
> - Re-test token streaming on mobile

Red flags — start over if you catch yourself doing these:
- More than one recap paragraph, or a missing bullet list
- Padding the recap with whole-session history
- Bullets that explain each item or include already-done work

---
name: my-utils:quick-summary
description: Use when the user asks what we were just doing, for a quick recap, or to re-orient after returning to this session. Also invoked explicitly as /my-utils:quick-summary.
---

# Quick Summary

Give a quick recap of what we were just doing — **one short, well-structured paragraph, nothing else**.

## Rules

- Exactly one paragraph: 3-5 simple sentences that flow together.
- Plain, easy words. Straight to the point — no filler, no jargon.
- No headers, no bullets, no tables, no sections.
- Cover only the most recent work in this session (or the last thing before a pause/compact), not the whole session history.
- Structure it as: what we were changing + why, or current state + immediate next step. End with the next step if there is one.
- Do not list tool calls or every file path — mention at most one or two key ones.

## Example

> We were switching the logging in `/api/chat` from pino to Axiom so prod logs ship reliably again. The code swap is done and committed. The one thing still unchecked is whether logs actually arrive in Axiom after a deploy. Next step is deploying, then looking for new entries in the Axiom dataset.

Red flags — start over if you catch yourself doing these:
- Writing a header, bullet list, or more than one paragraph
- Padding with background or summarizing the whole session
- Using complex words when simple ones say the same thing

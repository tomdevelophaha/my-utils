# where-we-left-off — design note

## Problem

`/resume` shows sessions one at a time. After a few days away, finding out
what the last week of sessions in a project was about means opening each one.
The transcripts already hold the answer.

## Shape

A status-only utility, same weight as `quick-summary`. One inline snippet
reads `~/.claude/projects/<slug>/*.jsonl` for the current directory, keeps
only the user's own prompts (typed text, not tool results or attachments),
and prints per session: time span, branch, prompt count, first prompt, last
prompt. Claude turns that into roughly ten plain lines.

Default 10 sessions, cap 20. Sorted by the time of each session's last
prompt, not file mtime — a `/resume` fork rewrites an old file and would
otherwise float to the top.

## Deliberate limits

- Read-only. It never resumes, edits, or runs anything else.
- Prompts only. Assistant turns and tool output would say what was *tried*;
  the user's prompts say what was *asked for*, which is what "what were we
  working on" means. Whether the work landed is `git log`'s job.
- Inline snippet, not a `bin/` helper. `bin/` is for shell several skills
  share; nothing else reads transcripts, and a helper would need an installer
  path, a doctor row, and a test suite for ten lines of glue.
- Machine-local by construction. Transcripts never leave the machine, so this
  cannot see sessions run elsewhere. The skill says so instead of guessing.

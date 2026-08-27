---
name: my-utils:jot-down-task-github
description: Use when the user says "Jot down task: <name>" or asks to add a task, TODO, or item to this machine's configured GitHub Projects Kanban board. Reports plainly when no board is configured rather than silently dropping the task.
allowed-tools:
  - Bash
triggers:
  - jot down task
  - add a task to the board
  - add to kanban
  - new board item
---

# Jot Down Task

Create a draft item on this machine's configured GitHub Projects V2 Kanban board.

## Command

```bash
~/.claude/my-utils/kanban.sh find-or-create "<task name>" "<1-2 sentence what + why>"
```

Cold jot — title only, no body:

```bash
~/.claude/my-utils/kanban.sh find-or-create "<task name>"
```

- Draft items land in the board's default `Todo` column.
- The board is whichever one `~/.claude/my-utils.config` names, written once
  per machine by `./setup.sh --configure`. No board id is hardcoded here.
- A title that already exists is returned rather than duplicated.

## Confirm it landed

Silence is not success. The helper prints the item id when the card exists or
was created, and prints nothing when this machine simply has no board — those
look identical on stdout, so never assume.

- **An id was printed** → the task is captured. Say so.
- **Nothing on stdout, nothing on stderr** → there is no board configured here.
  Tell the user plainly and point at `./setup.sh --configure` in the my-utils
  checkout.
- **Nothing on stdout but a `kanban:` line on stderr** → there IS a board and
  the write failed (expired auth, no network, deleted board). Report that
  reason; do NOT tell the user to re-run `--configure`, which would be wrong
  advice. `~/.claude/my-utils/doctor.sh` shows which it is.

Never claim a task was captured when no id came back.

## Fallbacks

| Dependency | Absent → |
|---|---|
| Kanban / `gh` (the board) | Nothing is captured. Unlike the work tiers — where the card is optional bookkeeping — capture IS this skill's entire job, so say plainly that the task was not recorded rather than failing silently. Offer to note it in the conversation or a file instead. |

## Body rule

Write a **1–2 sentence** body: what the task is + why it matters, using *only*
context actually present in the current conversation. A concrete reference (file
path, branch, error, PR) may appear inline in prose when it is genuinely part of
that context — never as a bare link, never invented.

**Cold jot (no surrounding context) → omit `--body` entirely.** Never fabricate a
"why" — a wrong "why" is worse than a bare title.

## When to use

- User types "Jot down task: X" (or "add a task X to the board").
- A quick TODO should be captured on the Kanban board.

## Not for

- Full issues/PRs — use `gh issue create` / `gh pr create`.
- Editing existing items — use `~/.claude/my-utils/kanban.sh move "<title>"
  in-progress|review|done`, which the work tiers call for their card lifecycle.

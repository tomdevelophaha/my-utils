---
name: my-utils:jot-down-task-github
description: Use when the user says "Jot down task: <name>" or asks to add a task, TODO, or item to the project's GitHub Projects Kanban board.
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

## No board configured

The helper exits 0 silently when there is no config, no `gh`, or no auth.
That is indistinguishable from success, so when the user asked for a jot,
confirm it landed:

```bash
~/.claude/my-utils/kanban.sh find-or-create "<task name>" "<body>"   # prints the item id
```

No id printed → no board on this machine. Say so plainly and tell the user to
run `./setup.sh --configure` (or `./doctor.sh` to see why). Never claim a task
was captured when it was not.

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

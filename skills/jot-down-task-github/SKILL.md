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

Create a draft item on the project's GitHub Projects V2 Kanban board.

## Command

Cold jot — title only:

```bash
gh project item-create 1 --owner "@me" --title "<task name>"
```

With surrounding context — add a body:

```bash
gh project item-create 1 --owner "@me" --title "<task name>" --body "<1-2 sentence what + why>"
```

- Board: "redacted-project Board" — https://github.com/users/OWNER/projects/N
- Draft items land in the default `Todo` column.

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
- Editing existing items — use `gh project item-edit --id <item-id> ...`
  (Status is single-select; see super-quick step 1 for the full flag set).

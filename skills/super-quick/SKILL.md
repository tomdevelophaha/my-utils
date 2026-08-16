---
name: my-utils:super-quick
description: Use for chores and tiny fixes — a few lines, field/title updates, small tweaks. Runs edit → tests → atomic commit → /linus micro-review, with GitHub Kanban card lifecycle. Trigger via /my-utils:super-quick, "super quick", or "quick chore".
allowed-tools:
  - Bash
  - Read
  - Edit
triggers:
  - super quick
  - quick chore
  - super-quick
---

# Super Quick — chore tier

Few-line tasks only. No GSD, no TDD ceremony, no STATE.md writes. Git log is the record.

## Flow

1. **Kanban start** — if a card on Project #1 clearly matches this task, move it
   to In Progress. No matching card → skip silently, create nothing.
   ```bash
   gh project field-list 1 --owner tomdevelophaha          # find Status field id once
   gh project item-list 1 --owner tomdevelophaha --format json | jq '.items[] | select(.title=="<task>") | .id'
   gh project item-edit --id <item-id> --field-id <status-field-id> --value "In Progress"
   ```
2. **Scope check** — if the change will exceed a few lines or touch logic beyond
   the trivial, STOP. Tell the user to run /my-utils:new-feature instead. Do not
   half-do it.
3. **Edit** — make the change directly.
4. **Verify** — run the project's test command (discover from `package.json`
   scripts, e.g. `npm test`); everything must pass. No test script → run
   typecheck (`npx tsc --noEmit`) or build.
5. **Commit** — one atomic conventional commit (`fix:` / `chore:` / `feat:`).
6. **/linus micro-review (always)** — invoke the linus skill on the diff of the
   new commit. Fix real findings, re-run tests, commit fixes. Dismiss style noise
   on a chore.
7. **Kanban closeout** — card existed → move to Done (`gh project item-edit`
   as above, `--value "Done"`). No card → nothing.

## Hard rules

- Never write to .planning/STATE.md for super-quick work.
- Never expand scope mid-task — promote to /my-utils:new-feature instead.

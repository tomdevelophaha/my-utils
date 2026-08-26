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
   # ids baked for speed (board #1). If a command 404s, re-resolve:
   #   gh project list --owner "@me" --format json | jq -r '.projects[] | select(.number==1) | .id'
   #   gh project field-list 1 --owner "@me" --format json    # Status field id + option ids
   ITEM=$(gh project item-list 1 --owner "@me" --format json \
     | jq -r '.items[] | select(.title | test("<task>")) | .id' | head -1)
   gh project item-edit --id "$ITEM" --project-id PVT_xxxxxxxxxxxxxxxx \
     --field-id PVTSSF_xxxxxxxxxxxxxxxxxxxxxxxxxxxx --single-select-option-id xxxxxxxx   # In Progress
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
7. **Kanban closeout** — card existed → move to Done (same `gh project
   item-edit` shape as step 1, `--single-select-option-id zzzzzzzz` for Done).
   No card → nothing.

## Hard rules

- Never write to .planning/STATE.md for super-quick work.
- Never expand scope mid-task — promote to /my-utils:new-feature instead.

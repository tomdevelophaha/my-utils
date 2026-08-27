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

1. **Kanban start** — if a card matches this task, move it to In Progress.
   Never create one at this tier.
   ```bash
   ~/.claude/my-utils/kanban.sh move "<task>" in-progress
   ```
   The board is optional: no config, no `gh`, or no matching card exits 0
   silently. Never let a card step block the work.
2. **Scope check (hard cap)** — more than 20 changed lines (diff stat) or more
   than 2 files, or logic beyond the trivial → STOP. Tell the user to run
   /my-utils:new-feature instead. Do not half-do it. Behavior trigger: the
   change alters runtime behavior (not copy, titles, config) and no test covers
   it → promote, regardless of size.
3. **Edit** — make the change directly.
4. **Verify** — run the project's test command (discover from `package.json`
   scripts, e.g. `npm test`); everything must pass. No test script → run
   typecheck (`npx tsc --noEmit`) or build.
5. **Commit** — one atomic conventional commit (`fix:` / `chore:` / `feat:`)
   whose body carries one plain-language sentence on WHY. A prefix alone is
   not enough.
6. **/linus micro-review (always)** — `~/.claude/my-utils/kanban.sh move "<task>" review`
   first, then invoke the linus skill on the diff of the new commit. Fix real
   findings, re-run tests, commit fixes. Dismiss style noise on a chore.
7. **Kanban closeout** — `~/.claude/my-utils/kanban.sh move "<task>" done`.

## Fallbacks

A missing dependency degrades the step; it never silently skips it.
Run `./doctor.sh` to see what this machine actually has.

| Dependency | Absent → |
|---|---|
| `linus` | It is vendored here, so `./setup.sh` is the whole fix. If it is still missing, review the diff yourself against: does this belong in the data structure, is it a special case that should not exist, is anything gratuitously complex, does it break an existing caller. |
| Kanban (`gh` / config) | Skip every card step silently. |

## Hard rules

- Never write to .planning/STATE.md for super-quick work.
- Never expand scope mid-task — promote to /my-utils:new-feature instead.
- A behavior change with no test to run is a promotion trigger, regardless of size.

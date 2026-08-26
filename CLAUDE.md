# CLAUDE.md — my-utils (private skill library · brownfield / per-visit finite)

Markdown skill definitions only. No runtime code, no build. A change here
alters Claude's behavior on every machine that has run `setup.sh` — treat every
edit as a behavior change, not a docs edit.

## Commands

```bash
./setup.sh              # symlink skills/* into ~/.claude/skills/ (idempotent)
./tests/test-setup.sh   # must print PASS — run after ANY setup.sh change
```

There is no test suite for skill content. Verification for a `SKILL.md` change
is: re-read the flow end to end and confirm every referenced skill, command,
and path exists.

## Hard constraints

- Edit `skills/<name>/SKILL.md` in this repo. Never edit
  `~/.claude/skills/<name>` — it is a symlink back here, and editing through it
  hides the change from git.
- Directory name is bare (`bugfix`); frontmatter `name:` is namespaced
  (`my-utils:bugfix`). Never prefix the directory.
- Added a new `skills/<name>/` directory → run `./setup.sh` before claiming it
  works. Edits to an existing skill need no re-run.
- `SKILL.md` stays short. Anything over ~150 lines moves to
  `skills/<name>/references/*.md` and gets loaded lazily.
- The frontmatter `description` is the only routing signal Claude sees before
  loading the skill. It must state when to use it, the pipeline in one line,
  and the explicit trigger. Never shorten it to a title.
- Never invent a skill, command, or board id in a flow. Every `/gsd-*`,
  `superpowers:*`, `/linus`, and `gh project` reference must be one that
  actually exists.

## Tier invariants

The four work tiers (`super-quick`, `bugfix`, `new-feature`,
`long-running-job`) form one escalation chain:

```
super-quick --(>20 lines | >2 files | untested behavior change)--> new-feature
bugfix      --(architectural root cause | 3+ failed fixes)-------> /gsd-debug
new-feature --(exceeds one context window)----------------------> long-running-job
```

- Change one tier's boundary → update the tiers on both sides of it, their
  frontmatter descriptions, and the README table in the same commit.
- Every tier keeps the same spine: Kanban card In Progress → real verification
  before the commit → card Ready For Review → `/linus` review → card Done. The
  board has four columns and the card visits three of them; a card that jumps
  In Progress straight to Done means the review stage was skipped.
  `super-quick` only moves a card that already matches and never creates one;
  the heavier tiers find-or-create.
- Review is never a whole-diff blob scan above the chore tier: `bugfix`,
  `new-feature`, and `long-running-job` fan out one subagent per affected
  component.
- superpowers is the sole TDD authority inside every tier. Never write a tier
  that runs its own test loop.
- Only `new-feature` and `long-running-job` may write STATE.md, and only for
  architectural decisions. `super-quick` and `bugfix` are transactional — git
  log is the record.

## Pipeline for work in THIS repo

```
tweak a skill        → /my-utils:super-quick
new skill / redesign → docs/ design note (see docs/design.md, docs/bugfix-design.md)
                       → write SKILL.md → ./setup.sh → /linus → commit
```

Design notes land in `docs/`; plans in `docs/plans/`. Both are committed — they
are the only record of why a tier boundary sits where it does.

## Session hygiene

- Context past ~60% → summarize WIP and `/clear` before the next skill edit.
- Reading more than 3 `SKILL.md` files for an audit → delegate to a subagent
  that reports a summary back.

# my-utils

Personal Claude Code skills, version-controlled here and symlinked into
`~/.claude/skills/` on every machine I use. Plain git repo + symlinks — not a
plugin, not a marketplace (see `docs/design.md` for why).

## Install

```bash
git clone git@github.com:tomdevelophaha/my-utils.git ~/Desktop/Project/claude-skills
~/Desktop/Project/claude-skills/setup.sh
```

`setup.sh` symlinks every `skills/*/` into `~/.claude/skills/`. It is
idempotent, and it never clobbers a real directory that already sits at the
target name — it prints `skip:` and moves on. Override the paths with
`MY_UTILS_SKILLS_DIR` / `MY_UTILS_TARGET_DIR`.

## Sync

```bash
cd ~/Desktop/Project/claude-skills && git pull && ./setup.sh
```

New skills need the `./setup.sh` re-run; edits to an existing skill are picked
up through the symlink with no re-run.

## Test

```bash
./tests/test-setup.sh   # prints PASS
```

## Skills

### Work tiers — pick by scope, escalate when you outgrow it

| Skill | Use when | Hard boundary |
|---|---|---|
| `super-quick` | Chore or tiny known fix. No investigation needed. | > 20 changed lines or > 2 files, or untested behavior change → `new-feature` |
| `bugfix` | Something is broken and the root cause is unknown. Single fix. | Architectural root cause, or 3+ failed fixes → `/gsd-debug` |
| `new-feature` | New capability — integrations, UI subsystems, login flows. | Too big for one context window → `long-running-job` |
| `long-running-job` | Overnight refactors, migrations, bulk changes across sessions. | Never re-plans; requires an approved plan + test list up front |

The tiers share a spine: a GitHub Projects card moved through In Progress →
Ready For Review → Done, a real verification step before the commit, and a
`/linus` review before closeout.
`super-quick` runs the micro version — it only moves a card that already
matches, and reviews inline. The three heavier tiers find-or-create the card,
fan the review out across one subagent per affected component, and delegate
execution to superpowers (brainstorming, TDD, executing-plans) with breakdown
by GSD.

### Utilities

- `quick-summary` — one recap paragraph + a short next-steps list, nothing else.
- `jot-down-task-github` — draft an item on the GitHub Projects V2 board (#1).

## Add a skill

1. Create `skills/<name>/SKILL.md`. The directory name is bare (`bugfix`); the
   frontmatter `name:` carries the namespace (`my-utils:bugfix`).
2. Long supporting material goes in `skills/<name>/references/*.md`, loaded
   lazily — keep `SKILL.md` itself short.
3. Run `./setup.sh` to link it locally, then commit and push.
4. On other machines: `git pull && ./setup.sh`.

## Layout

```
my-utils/
├── CLAUDE.md            # conventions for Claude working in this repo
├── setup.sh             # symlink installer
├── skills/<name>/       # SKILL.md (+ optional references/)
├── docs/                # design records and plans
└── tests/test-setup.sh  # installer behavior test
```

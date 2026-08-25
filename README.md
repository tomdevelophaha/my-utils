# my-utils

Personal Claude Code skills, version-controlled and symlinked into
`~/.claude/skills/` across my machines.

## Install

```bash
git clone git@github.com:tomdevelophaha/my-utils.git ~/Desktop/Project/claude-skills
~/Desktop/Project/claude-skills/setup.sh
```

## Sync

```bash
cd ~/Desktop/Project/claude-skills && git pull && ./setup.sh
```

## Add a skill

1. Create `skills/<name>/SKILL.md` with frontmatter `name: my-utils:<name>`.
2. Commit and push.
3. On other machines: `git pull && ./setup.sh`.

## Skills

- `quick-summary` — one-paragraph recap of the current session.
- `super-quick` — chores / tiny known-fix edits (≤20 lines, 2 files).
- `bugfix` — bugs needing root-cause diagnosis, single-fix scope.
- `new-feature` — feature work (brainstorm → spec → plan → TDD).
- `long-running-job` — endurance tier, jobs too big for one context window.
- `jot-down-task-github` — draft an item on the GitHub Projects V2 Kanban board.

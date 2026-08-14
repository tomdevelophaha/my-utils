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
- `jot-down-task-github` — draft an item on the GitHub Projects V2 Kanban board.

# my-utils

Personal Claude Code skills, version-controlled and symlinked into
`~/.claude/skills/` across my machines.

## Install

```bash
git clone git@github.com:tomdevelophaha/my-utils.git ~/repos/my-utils
~/repos/my-utils/setup.sh
```

## Sync

```bash
cd ~/repos/my-utils && git pull && ./setup.sh
```

## Add a skill

1. Create `skills/<name>/SKILL.md` with frontmatter `name: my-utils:<name>`.
2. Commit and push.
3. On other machines: `git pull && ./setup.sh`.

## Skills

- `quick-summary` — one-paragraph recap of the current session.

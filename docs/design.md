# my-utils — personal skill library (design)

- Date: 2026-08-15
- Status: approved (Approach B)

## Goal

A private, version-controlled library of personal Claude Code skills, usable
across multiple machines. Not a plugin, not a marketplace — a plain git repo
with symlinks into `~/.claude/skills/`.

## Decision

**Approach B: git repo + symlinks.**

Rejected the alternatives:

- **A — plugin + marketplace**: solves a distribution problem that doesn't exist
  for a single private user. It also adds a version-bump tax to every new skill
  (`plugin.json` + `marketplace.json` must be bumped or updates don't propagate).
- **C — plugin repo via local path**: real namespacing, but manual clone +
  `git pull` on every machine — no better than B, with more files.

## Repo structure

```
my-utils/
├── README.md
├── setup.sh                  # symlinks every skills/* into ~/.claude/skills/
└── skills/
    ├── quick-summary/
    │   └── SKILL.md          # name: my-utils:quick-summary
    └── <next-util>/
        └── SKILL.md          # name: my-utils:<next-util>
```

## Install (per machine)

```
git clone git@github.com:tomdevelophaha/my-utils.git ~/repos/my-utils
~/repos/my-utils/setup.sh
```

`setup.sh` symlinks each `skills/<name>` directory into `~/.claude/skills/<name>`
and is idempotent (safe to rerun).

## Sync

```
cd ~/repos/my-utils && git pull && ./setup.sh
```

Rerunning `setup.sh` picks up newly added skills.

## Add a skill

1. Write `skills/<name>/SKILL.md` with `name: my-utils:<name>` in the frontmatter.
2. Commit and push.
3. On other machines: `git pull && ./setup.sh`.

No version field anywhere.

## Namespacing

Each skill's `name` field carries the `my-utils:` prefix directly (e.g.
`my-utils:quick-summary`). Symlinked skills are already proven to work here —
`find-skills`, `grilling`, `handoff`, `grill-me` are all symlinks in
`~/.claude/skills/` today.

## Open verification

One fact is unverified: whether the `my-utils:` frontmatter prefix survives a
skill reload (the current session still shows `quick-summary` bare, since skills
load at session start). Verify after the first reload.

**Fallback if it doesn't survive:** add a single `.claude-plugin/plugin.json`
(name `my-utils`) to the repo root — that's Approach C, still no `marketplace.json`.

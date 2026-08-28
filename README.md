# my-utils

Personal Claude Code skills, version-controlled here and symlinked into
`~/.claude/skills/` on every machine I use. Plain git repo + symlinks — not a
plugin, not a marketplace (see `docs/design.md` for why).

## Install

On a new machine:

```bash
git clone git@github.com:tomdevelophaha/my-utils.git ~/Desktop/Project/claude-skills
cd ~/Desktop/Project/claude-skills
./setup.sh --with-deps      # link the skills, then install what they depend on
./setup.sh --configure      # optional: point the Kanban steps at this machine's board
./doctor.sh                 # confirm what is actually present
```

`setup.sh` symlinks every `skills/*/` and `vendor/skills/*/` into
`~/.claude/skills/`, and installs the Kanban helper at
`~/.claude/my-utils/kanban.sh`. It is idempotent, and it never clobbers a real
directory already sitting at the target name — it prints `skip:` and moves on.
Override the paths with `MY_UTILS_SKILLS_DIR` / `MY_UTILS_VENDOR_DIR` /
`MY_UTILS_TARGET_DIR`.

Plain `./setup.sh` does no network I/O. Only `--with-deps` installs anything.

## Dependencies

The work tiers delegate to skills this repo does not own. What happens when
they are absent is written into each skill — a missing dependency **degrades**
the step, it never silently skips it.

| Dependency | How it is obtained | Absent → |
|---|---|---|
| `superpowers` | `./setup.sh --with-deps` → Claude plugin marketplace | each tier runs the step inline; the invariant (no proof no commit, no fix before root cause) still holds |
| `gsd-core` | `./setup.sh --with-deps` → `npx @opengsd/gsd-core@latest --claude --global` | escalation exits STOP and report instead of handing off |
| `linus` | vendored in `vendor/skills/`; plain `./setup.sh` links it | n/a once linked |
| `graphify` | not installed here | review scan sets fall back to grep |
| Kanban (`gh` + a board) | `./setup.sh --configure` | every card step is skipped silently; the tier runs unchanged |

Run `./doctor.sh` to see the real state. It reports, and never installs or
fails. It also distinguishes a plugin that is **installed but disabled** —
which ships no skills while looking installed — from one that is missing,
because the fix differs (`claude plugin enable` vs. install).

`tests/test-fallbacks.sh` fails if any skill names a dependency without
declaring a fallback for it, so this table cannot quietly drift out of date —
for the dependency families it knows (`superpowers:*`, `gsd-*`, `linus`,
`graphify`, `kanban`/`gh`). Adding a dependency outside those names means
adding its pattern to the guard too.

## Kanban is optional

No board ids are hardcoded in any skill. `./setup.sh --configure` resolves this
machine's board, Status field, and column ids once into
`~/.claude/my-utils.config`; the skills call `~/.claude/my-utils/kanban.sh`,
which exits 0 silently when there is no config, no `gh`, no auth, or no
matching card. Bookkeeping never gates the work.

## Sync

```bash
cd ~/Desktop/Project/claude-skills && git pull && ./setup.sh
```

New skills need the `./setup.sh` re-run; edits to an existing skill are picked
up through the symlink with no re-run.

## Test

```bash
./tests/test-setup.sh      # installer: linking, offline default, bootstrap
./tests/test-kanban.sh     # board helper: optionality and id threading
./tests/test-doctor.sh     # doctor reports, never gates
./tests/test-fallbacks.sh  # every dependency has a declared fallback
```

Each prints `PASS`. Run all four after any change to `setup.sh`, `doctor.sh`,
`bin/`, or a skill's dependency list.

## Skills

### Work tiers — pick by scope, escalate when you outgrow it

| Skill | Use when | Hard boundary |
|---|---|---|
| `super-quick` | Chore or tiny known fix. No investigation needed. | > 20 changed lines or > 2 files, or untested behavior change → `new-feature` |
| `bugfix` | Something is broken and the root cause is unknown. Single fix. | Architectural root cause, or 3+ failed fixes → `/gsd-debug` |
| `new-feature` | New capability — integrations, UI subsystems, login flows. | Too big for one context window → `long-running-job` |
| `long-running-job` | Overnight refactors, migrations, bulk changes across sessions. | Never re-plans; requires an approved plan + test list up front |

The tiers share a spine: a real verification step before the commit, and a
`/linus` review before closeout. Where a board is configured, a card mirrors
that spine (In Progress → Ready For Review → Done); where none is, the card
steps are silent and nothing else changes.
`super-quick` runs the micro version — it only moves a card that already
matches, and reviews inline. The three heavier tiers find-or-create the card,
fan the review out across one subagent per affected component, and delegate
execution to superpowers (brainstorming, TDD, executing-plans) with breakdown
by GSD.

### Utilities

- `quick-summary` — one recap paragraph + a short next-steps list, nothing else.
- `jot-down-task-github` — draft an item on this machine's configured board,
  and say so plainly when there isn't one.
- `plain-english` — rewrite a coding report for a non-engineer: a short plain
  narrative, then a detail block keeping files, root cause, what actually ran,
  and what is still at risk.

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
├── setup.sh             # symlink installer (+ --with-deps, --configure)
├── doctor.sh            # what this machine has and what it is missing
├── bin/kanban.sh        # the one code path for the optional Kanban board
├── skills/<name>/       # SKILL.md (+ optional references/)
├── vendor/skills/       # third-party skills with no installable upstream
├── docs/                # design records and plans
└── tests/               # installer, kanban, doctor, and fallback-drift tests
```

# Plan — plug-and-play portability

Spec: `docs/portability-design.md` (approved 2026-08-26)
Convention: one atomic commit per task. Tests are bash assertions under `tests/`.

## Open decision — blocks task 3

The spec removes hardcoded board ids from four SKILL.md files. Two ways to land it:

- **A. `bin/kanban.sh` helper** — one shell code path (`find-or-create`, `move`),
  called by all four tiers. The optionality lives in one testable place.
  **Conflicts with CLAUDE.md's "Markdown skill definitions only. No runtime code."**
  Taking it means amending that constraint in task 10.
- **B. Inline snippet per SKILL.md** — each tier sources `~/.claude/my-utils.config`
  and guards on it. Honors the constraint; keeps four copies of the logic, which
  is what made the ids brittle in the first place.

Recommend **A**. `setup.sh` and `tests/` are already shell; the constraint's intent
is "no build step, no app code", and a 40-line helper that four skills share is
strictly less fragile than four copies. Task 10 amends CLAUDE.md to say so.

## Tasks

| # | Task | Files | Commit |
|---|---|---|---|
| 1 | Vendor `linus` | `vendor/skills/linus/SKILL.md` | `chore: vendor the linus review skill` |
| 2 | `setup.sh` links `vendor/skills/*` too | `setup.sh` | `feat: link vendored skills alongside authored ones` |
| 3 | Kanban config + helper (A or B) | `bin/kanban.sh`, `setup.sh` | `feat: make the Kanban board configurable per machine` |
| 4 | `setup.sh --with-deps` | `setup.sh` | `feat: add opt-in dependency bootstrap` |
| 5 | `doctor.sh` | `doctor.sh` | `feat: add a dependency doctor` |
| 6 | Fallbacks in the 4 tiers | `skills/{super-quick,bugfix,new-feature,long-running-job}/SKILL.md` | `feat: declare a fallback for every external dependency` |
| 7 | De-hardcode `jot-down-task-github` | `skills/jot-down-task-github/SKILL.md` | `fix: drop the hardcoded board from jot-down-task-github` |
| 8 | Drift guard | `tests/test-fallbacks.sh` | `test: fail when a skill adds a dependency with no fallback` |
| 9 | Extend installer test | `tests/test-setup.sh` | `test: cover vendored linking and offline default` |
| 10 | Docs | `README.md`, `CLAUDE.md` | `docs: document the plug-and-play install path` |

## Test list

**T1 — vendored skill links** (`test-setup.sh`)
`setup.sh` over a source tree with `vendor/skills/linus/` creates a symlink at
`$TARGET/linus`. Asserts vendored deps reach `~/.claude/skills/`.

**T2 — vendored skill never clobbers a real one** (`test-setup.sh`)
A real (non-symlink) `$TARGET/linus` directory survives `setup.sh` untouched, and
the run still exits 0. Asserts a machine with its own linus keeps it.

**T3 — default setup.sh does no network I/O** (`test-setup.sh`)
Run with `PATH` stripped of `npx`/`claude`; must still exit 0 and link skills.
Asserts bootstrap is genuinely opt-in.

**T4 — `--with-deps` is a no-op when deps are present** (`test-setup.sh`)
With stub `claude`/`npx` on PATH recording their argv, a second `--with-deps` run
after a detected-present state invokes neither. Asserts idempotence.

**T5 — `--with-deps` calls the verified install commands** (`test-setup.sh`)
With stubs and nothing installed, the recorded argv contains
`plugin install superpowers@claude-plugins-official --yes` and
`@opengsd/gsd-core@latest --claude --global`. Asserts the exact non-interactive
forms, so a typo in either can't ship.

**T6 — Kanban absent is silent success** (`test-kanban.sh`)
`kanban.sh move "x" in-progress` with no config file and no `gh` on PATH exits 0
and prints nothing to stderr. Asserts the tier is never blocked by a missing board.

**T7 — Kanban present issues the right edit** (`test-kanban.sh`)
With a config file and a stub `gh` recording argv, `move` produces one
`project item-edit` carrying `--single-select-option-id` for the requested column.
Asserts config values are actually threaded through.

**T8 — `--configure` writes a complete config** (`test-kanban.sh`)
With a stub `gh` returning canned project/field JSON, `setup.sh --configure`
writes a file defining project id, status field id, and all three option ids.
Asserts no id is left unresolved.

**T9 — drift guard catches an undeclared dependency** (`test-fallbacks.sh`)
A fixture SKILL.md referencing `superpowers:executing-plans` with no matching
`## Fallbacks` row makes the guard exit non-zero naming the file and the
dependency. **This is the regression test for the bug that motivated the feature.**

**T10 — drift guard passes the real skills** (`test-fallbacks.sh`)
The guard over `skills/` exits 0. Asserts task 6 and 7 actually completed.

**T11 — doctor reports missing without failing** (`test-doctor.sh`)
With `PATH` stripped of `claude`/`gh` and an empty skills dir, `doctor.sh` exits 0
and its output names each missing dependency plus its install command. Asserts
doctor diagnoses rather than gates.

## Sequencing

1 → 2 → 3 → 4 → 5 are independent of the skill edits and land first (the
machinery). 6 and 7 depend on 3 (they reference the config/helper). 8 depends on
6 and 7. 9 depends on 2 and 4. 10 last.

## Out of scope

graphify install; installing or authenticating `gh`; any tier boundary,
escalation, or review-shape change.

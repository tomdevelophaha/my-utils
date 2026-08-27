# CLAUDE.md — my-utils (private skill library · brownfield / per-visit finite)

Markdown skill definitions, plus shell in exactly three places: `bin/` for
helpers several skills share, `tests/` for the suites, and the two root
installers (`setup.sh`, `doctor.sh`). No build step, no application code. A change here alters Claude's behavior on every machine
that has run `setup.sh` — treat every edit as a behavior change, not a docs
edit.

## Commands

```bash
./setup.sh                 # link skills/* and vendor/skills/* (idempotent, offline)
./setup.sh --with-deps     # also install superpowers + gsd-core (opt-in, network)
./setup.sh --configure     # resolve this machine's Kanban board into ~/.claude/my-utils.config
./doctor.sh                # report what is present, missing, or disabled
./tests/test-setup.sh      # must print PASS — run after ANY setup.sh change
./tests/test-kanban.sh     # must print PASS — run after ANY bin/kanban.sh change
./tests/test-doctor.sh     # must print PASS — run after ANY doctor.sh change
./tests/test-fallbacks.sh  # must print PASS — run after ANY change to a skill's dependencies
```

The only automated check on skill *content* is the fallback drift guard. Flow
correctness is still verified by hand: re-read the flow end to end and confirm
every referenced skill, command, and path exists — then run
`./tests/test-fallbacks.sh`.

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
  `superpowers:*`, `/linus`, vendored-skill, and `kanban.sh` verb
  (`find-or-create`, `move in-progress|review|done`) must be one that actually
  exists.

## Portability

Every machine is assumed to be missing something. See `docs/portability-design.md`.

- **No skill may hardcode a board id, project number, or repo path.** The Kanban
  board lives in `~/.claude/my-utils.config`. Skills run from the *user's
  project* directory, so anything they invoke needs an absolute path — a
  relative `./doctor.sh` does not exist there. The two installed entry points
  are the only absolute paths a skill may name:
  `~/.claude/my-utils/kanban.sh` and `~/.claude/my-utils/doctor.sh`.
- **Every external dependency a skill names needs a row in that skill's
  `## Fallbacks` table.** `tests/test-fallbacks.sh` enforces this for the
  dependency families it knows: `superpowers:*`, `gsd-*`, `linus`, `graphify`,
  and the Kanban board (`kanban`/`gh`). A dependency outside those names is
  invisible to it — **add the pattern when you add the dependency**, or the
  guard silently stops guarding.
- **A missing dependency degrades the step; it never silently skips it.** Keep
  the invariant, drop the mechanism — without the TDD skill you still write the
  failing test first. Two exceptions: escalation exits (`/gsd-*`) **STOP**
  rather than improvise, because improvising past a handoff gate defeats it;
  and Kanban is explicitly optional.
- **Vendor only what has no upstream.** `superpowers` and `gsd-core` both have
  installers and belong in `--with-deps`, never in `vendor/`.

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
- Every tier keeps the same spine: **real verification before the commit →
  `/linus` review → closeout.** That spine does not depend on a board. Where one
  is configured the card mirrors it (In Progress → Ready For Review → Done) and
  never gates the work; where none is, the card steps are silent and the spine
  is unchanged. `super-quick` only moves a card that already matches and never
  creates one; the heavier tiers find-or-create. Whether the review actually ran
  is answered by `git log`, which exists on every machine — never by which
  column a card sits in.
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
                       → write SKILL.md → ./setup.sh
                       → ./tests/test-fallbacks.sh → /linus → commit
shell (bin/, tests/,  → edit → the matching tests/*.sh prints PASS
setup.sh, doctor.sh)    → /linus → commit
```

A change to a SKILL.md is reviewed by `/linus`; a change to this file or to the
skill set's shape is better served by `claude-md-best-practice`, which reads
rules as constraints rather than as code.

Design notes land in `docs/`; plans in `docs/plans/`. Both are committed — they
are the only record of why a tier boundary sits where it does.

## Session hygiene

- Context past ~60% → summarize WIP and `/clear` before the next skill edit.
- Reading more than 3 `SKILL.md` files for an audit → delegate to a subagent
  that reports a summary back.

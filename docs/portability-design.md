# my-utils — plug-and-play portability (design)

- Date: 2026-08-26
- Status: approved

## Goal

Make this repo usable on a machine that has none of the skills it depends on.
Today a fresh `git clone && ./setup.sh` links six skills that call out to
`superpowers:*`, `/gsd-*`, `linus`, and a GitHub Projects board — none of which
the clone provides.

This is not hypothetical. On the authoring machine, **superpowers is not
installed at all** (not in `~/.claude/skills`, not a plugin), so every tier's
TDD, brainstorming, and executing-plans step already resolves to nothing. The
failure is silent: Claude improvises instead of stopping.

## Dependency audit

| Dependency | Where used | Source | Missing means |
|---|---|---|---|
| `superpowers:*` (6 skills) | **inside** every tier | plugin, `claude-plugins-official` | tiers silently improvise |
| `/gsd-*` (3 commands) | escalation exits only | npm `@opengsd/gsd-core` | escalation has nowhere to land |
| `linus` | every tier's review step ("never skip") | **no upstream** — one local SKILL.md | mandatory gate no-ops |
| `graphify` | review scan set | CLI + skill | nothing — text already says "when the repo has a graph" |
| `gh` + board #1 | card lifecycle in 4 skills | account-bound ids | 404 or wrong board on any other account |

All six referenced superpowers skills exist upstream (`brainstorming`,
`writing-plans`, `executing-plans`, `test-driven-development`,
`systematic-debugging`, `using-git-worktrees`).

## Decisions

1. **Per-dependency handling, matched to the source that actually exists.**
   One strategy for all four is wrong because their sources differ:

   - **superpowers** → install via the Claude CLI, non-interactive:
     `claude plugin install superpowers@claude-plugins-official --yes`,
     falling back to `claude plugin marketplace add obra/superpowers-marketplace`
     when the official marketplace is unavailable.
   - **gsd** → `npx @opengsd/gsd-core@latest --claude --global`. The bare
     installer is interactive; those two flags are the documented
     non-interactive path.
   - **linus** → **vendored** into `vendor/skills/linus/`. It is a single
     SKILL.md with no upstream anywhere, and it backs a step every tier marks
     "never skip". A mandatory gate may not depend on a file that exists on
     exactly one laptop. Provenance is unknown; it is carried, not forked.
     *(Superseded 2026-09: rewritten as first-party text — see `vendor/README.md`.)*
   - **graphify** → untouched. Already conditional in every call site.

2. **Vendored deps live outside `skills/`.** `skills/` stays exactly what
   CLAUDE.md says it is — skills authored here, namespaced `my-utils:*`.
   `vendor/skills/` carries third-party skills under their own bare names.
   `setup.sh` links both, and its existing never-clobber rule means a machine
   with a real `~/.claude/skills/linus` keeps its own copy.

3. **Bootstrap is opt-in.** `./setup.sh` stays pure symlinking and offline —
   `git pull && ./setup.sh` must never start fetching third-party code.
   `./setup.sh --with-deps` performs the network install.

4. **Kanban is optional, not required.** The board ids move out of the four
   SKILL.md files into `~/.claude/my-utils.config`, written once per machine by
   `./setup.sh --configure` (resolves board + status field + option ids via
   `gh`). No config, no `gh`, no auth, or no board → **every card step is
   skipped silently and the rest of the tier runs unchanged.** Kanban is
   bookkeeping; it never gates work. This also removes the hardcoded board
   name from `jot-down-task-github`.

5. **Every external call site declares a fallback.** Each SKILL.md that
   references an external dependency carries a `## Fallbacks` table naming what
   the step does when that dependency is absent. The rule is uniform: a missing
   dependency **degrades the step, never skips it**, except Kanban, which is
   explicitly optional.

   The fallbacks preserve each step's invariant rather than its mechanism:

   | Absent | Step becomes |
   |---|---|
   | `superpowers:test-driven-development` | write the failing test first by hand, watch it fail, then fix — invariant "no proof, no commit" holds |
   | `superpowers:systematic-debugging` | reproduce → recent changes → trace data flow, inline — invariant "no fix before root cause" holds |
   | `superpowers:brainstorming` | ask the unanswered questions inline, then write the spec |
   | `superpowers:executing-plans` | execute the plan task-by-task, one atomic commit per task |
   | `superpowers:writing-plans` | write the plan with the task table + test list by hand |
   | `superpowers:using-git-worktrees` | `git worktree add` directly |
   | `linus` | review against the vendored copy's criteria *(2026-09: the five-layer structure went in the rewrite; shipped rows name data structure, special cases, gratuitous complexity, breakage of callers)* |
   | `/gsd-debug`, `/gsd-quick`, `/gsd-plan-phase` | **STOP** and report — escalation exits are handoffs, so improvising past them defeats the gate. Tell the user to run `./setup.sh --with-deps`. |
   | Kanban | skip silently |

6. **A drift guard makes the contract enforceable.** `tests/test-fallbacks.sh`
   extracts every reference belonging to a known dependency family
   (`superpowers:*`, `gsd-*`, `my-utils:*`, `linus`, `graphify`, `kanban`/`gh`)
   from every SKILL.md and fails if any lacks a row in that file's
   `## Fallbacks` table. A family the pattern does not name is invisible to it. This is the check that would have
   caught superpowers rotting unnoticed, and it is what keeps a future skill
   from adding a dependency without a degradation path.

7. **`./doctor.sh` reports the truth.** Prints each dependency as present or
   missing with the exact command to fix it, plus Kanban config status. First
   thing to run on a new machine; also the fast answer to "why did that step
   behave oddly".

## Rejected

- **Vendoring gsd (66 skills) and superpowers (14).** Both have real,
  maintained upstreams with non-interactive installers. Vendoring forks work
  the user did not author and inherits its maintenance forever.
- **Auto-installing deps inside `setup.sh`.** Makes the routine sync command
  network-dependent and pulls unreviewed third-party changes on every run.
- **Resolving board ids at runtime on every card move.** Two extra API
  round-trips per move, and it discards the "ids baked for speed" property.
- **Dropping Kanban entirely.** It works and is wanted on the authoring
  machine; optional is strictly better than absent.

## Scope

Five SKILL.md files (quick-summary has no dependencies), `setup.sh` (`--with-deps`, `--configure`), new
`doctor.sh`, new `vendor/skills/linus/`, new `tests/test-fallbacks.sh`,
README + CLAUDE.md.

## Non-goals

- Installing `graphify` (optional at every call site, and its CLI is a
  separate concern).
- Installing `gh` or authenticating it — doctor reports, the user decides.
- Any change to a tier's boundaries, escalation chain, or review shape.

## Outcome

Shipped, then substantially corrected by review (commit 67a2ab5 onward).

The portability design held. The verification did not: a seven-agent `/linus`
fan-out found five criticals and proved three of the four test suites vacuous by
mutation — T3 passed with `with_deps` running on every invocation, and doctor's
gsd and linus checks passed when hardcoded to `if true`. The drift guard, the
centrepiece of this design, passed on a repo containing zero skills and could
not see bare `gsd-*` or Kanban references, so `jot-down-task-github` shipped
with no fallback table at all while the guard reported clean.

Also corrected: `setup.sh` never repaired a stale symlink, so moving the repo
silently disconnected every skill — the exact operation portability is meant to
survive; the Kanban helper returned 1 when it had no id, aborting any tier
running under `set -e`, and created a duplicate card on any transient read
failure; and CLAUDE.md declared an unconditional card lifecycle that the same
change had just made optional.

The lesson worth keeping: every one of those defects was in the code that
*checks*, not the code that *works*. A guard nobody has tried to fool is a
guard that passes.

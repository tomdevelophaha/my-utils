# claude-md-best-practice — adoption

- Date: 2026-09-11
- Status: approved

Records the move of an already-designed skill into this library. It does not
re-argue the skill's own design — the eight layers, the 2x2 matrix and the
generator arrived intact from `~/.claude/skills/claude-md-best-practice/`.

## Goal

CLAUDE.md said a change to the skill set's shape is "better served by
`claude-md-best-practice`", while that skill existed only as an unversioned
directory on one machine. The rule pointed at a file no other machine had.
Moving it here makes the rule true everywhere `setup.sh` has run.

## Decisions

**`skills/`, not `vendor/skills/`.** Vendor is for names the tiers invoke bare,
and for third-party text carried as-is. Neither applies: no tier invokes this
skill, and the text is first-party. So it takes the namespace like every other
authored skill — `name: my-utils:claude-md-best-practice`.

**The bare trigger stays.** The directory name is bare either way, so the move
breaks no caller. `ios-dev-setup` routes its pipeline/CLAUDE.md findings here by
the bare name in five places; it is not this repo's to edit, and the bare
trigger row keeps that routing working. The namespaced trigger is added
alongside, not in place of it.

**The `.bak` did not come along.** A `SKILL.md.v1.2.0.bak` sat next to the
skill as a private undo buffer. Git is that now, and a public repo should not
carry a second copy of a file nobody loads.

**The fallback rows say "not invoked".** The guard sees `gsd-map-codebase`,
`gsd-ingest-docs` and `linus` in the body and demands rows. But Layer 7 only
*checks whether the audited project declares them* — it never runs them. The
rows say so, and give the honest degrade: audit for the criterion (brownfield
onboarding declared at all, a blunt taste review in the tail) rather than for
the command name, and never BLOCK a repo for not naming a command its machine
cannot run.

## Migration (one-time, per machine)

`setup.sh` never clobbers a real directory sitting at a target name — it prints
`skip:` and moves on (`setup.sh:199`). Every machine that already carries the
pre-move `~/.claude/skills/claude-md-best-practice/` as a real directory will
therefore keep its own stale, un-namespaced copy forever, and `doctor.sh` has no
row that would catch it. Delete it once, then link:

```bash
rm -rf ~/.claude/skills/claude-md-best-practice && ./setup.sh
```

## Known exception

`SKILL.md` is 213 lines against this repo's "~150 lines, then move it to
`references/`" rule. The skill already lazy-loads five reference files; what is
left is the rubric itself, and splitting it further would change when each
layer loads, which is a behavior change, not a move. Recorded as an exception
rather than smuggled through: trimming the core is its own task.

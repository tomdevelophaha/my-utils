# my-utils:fan-out-review — shared review skill (design)

- Date: 2026-09-04
- Status: approved

## Goal

Make the review step of the four work tiers catch what it currently cannot,
without paying for the improvement three times.

Two problems, one structural and one substantive:

**Structural.** `bugfix`, `new-feature`, and `long-running-job` each carry the
same 13-line fan-out block. Steps a–c are byte-identical across all three; only
line d ("Fix") legitimately varies (`full suite re-run green` / `tests green` +
offload reporting / `gates green`). Every review improvement is a 3x edit, and
`tests/test-fallbacks.sh` cannot see the three copies drifting apart — it checks
that dependencies have fallback rows, not that step bodies still agree.

**Substantive.** Review is single-axis. `linus` grades taste: data structure,
special cases, gratuitous complexity, breakage of callers. Nothing checks
conformance — whether the diff does what the spec, plan, or root cause said it
would. And the global CLAUDE.md declares superpowers two-stage review the
PRIMARY reviewer with `/linus` feeding into it; all four tiers make `/linus`
terminal. The repo contradicts the pipeline it declares.

## Decisions

1. **Extract a–c into a skill, not a reference file.** A `references/*.md`
   shared across tiers can only be named by path, and skills run from the
   *user's* project directory — a relative path does not resolve there, and the
   portability rule allows exactly two absolute paths (`kanban.sh`,
   `doctor.sh`). A skill is addressed by name, so `my-utils:fan-out-review`
   works from anywhere. It is also the only form the drift guard can see.

2. **The shared skill ends at the findings; the caller fixes.** The extracted
   part is precisely the part that was identical. Step d differs per tier for
   real reasons (bugfix re-runs the full suite; new-feature has collaborative
   checkpoints and an offload report contract; long-running-job runs unit
   gates), so it stays in the tier. `fan-out-review` therefore never edits
   files — `allowed-tools` is Bash, Read, Agent.

3. **Add a conformance pass, because absence has no component.** A requirement
   nobody implemented produces no diff. It belongs to no component, so no
   per-component reviewer can structurally see it. That is the gap `linus`
   cannot close no matter how many subagents run. One subagent via
   `superpowers:requesting-code-review`, given the requirements pointer, asked
   for exactly three lists: promised-but-missing, present-but-unpromised,
   promised-but-diverged.

   This does not violate "review is never a whole-diff blob scan". That
   invariant is about *defect* review, which fails when 40 files of diff go into
   one head. Checking a requirements list for absence is a different question
   with a small answer surface, and the skill states explicitly that quality
   findings are dropped from this pass — they are the fan-out's job.

4. **Triage gets a discipline.** "Dedupe across agents, drop style noise, keep
   real findings" was the most failure-prone line in all three tiers: the model
   grading its own homework with no rule for what counts as real.
   `superpowers:receiving-code-review` is that rule — verify each finding
   against the codebase before accepting it, drop what does not reproduce,
   reasoned pushback over performative agreement.

   Together, 3 and 4 are the superpowers two-stage review the global CLAUDE.md
   requires, with `/linus` feeding into it rather than terminating the pipeline.

5. **`super-quick` is untouched.** Its reason to exist is being cheap. It keeps
   the inline `linus` micro-review. The conformance axis is also weakest exactly
   there — a chore has no requirements document to conform to.

6. **The drift guard learns the `my-utils` family.** A dependency outside the
   guard's known names is invisible to it, so naming `my-utils:fan-out-review`
   without extending the pattern would silently stop guarding. Adding
   `/?my-utils:[a-z-]+` also brings the cross-tier promotion targets under the
   guard, which is correct: a tier that promotes to a missing tier should say
   what to do instead. Self-references are excluded — a tier that names itself
   ("outgrows this tier → /my-utils:x" inside x) depends on nothing, and without
   the exclusion every tier would have to declare a fallback for its own
   absence.

## Rejected

- **Duplicating a `references/fan-out-review.md` into each tier.** Same three
  copies, same silent drift, and now in files the guard does not scan at all.
- **Adding `/code-review`, gstack `codex`, or a security pass now.** Each is a
  new guard family and a new portability tax, and `codex` needs an OpenAI
  account — the least portable thing the library could depend on. They are
  modifiers, not steps; revisit once the shared skill exists and adding an axis
  is a one-file change.
- **A literal `my-utils:fan-out-review` guard pattern instead of the family.**
  A special case, in a library whose review doctrine is that special cases
  should not exist. The next shared skill would need another literal.

## Files

- `skills/fan-out-review/SKILL.md` — new.
- `skills/bugfix/SKILL.md` — step 8 delegates; fallback rows added.
- `skills/new-feature/SKILL.md` — step 6 delegates; fallback rows added.
- `skills/long-running-job/SKILL.md` — step 6 delegates; fallback rows added.
- `skills/super-quick/SKILL.md` — fallback row for its promotion target only.
- `tests/test-fallbacks.sh` — `my-utils` family, self-reference exclusion,
  self-test coverage for both.
- `README.md` — tier table note.

## Outcome

Shipped 2026-09-04. All four suites PASS. The guard change was verified
negatively: removing the `my-utils:fan-out-review` row from `bugfix` makes
`tests/test-fallbacks.sh` fail naming that exact dependency.

`/linus` caught two defects before the commit, both fixed here:

1. **Dispatch contradiction.** The conformance pass was told to ride in "the
   same message as step 2" — but step 2 has an inline escape for a
   single-component scan set, leaving no message to ride in. Dispatch is one
   decision, so it now lives in step 2 alone and the conformance pass runs
   either way.

2. **`base` was unrecoverable in the endurance tier.** Promoting `base` to an
   explicit contract parameter surfaced a gap the old inline block hid behind an
   undefined `<base>`: a long-running job's closeout session holds only the job
   file and the plan, and a skipped unit records commit `-`, so the start ref
   cannot be derived after the fact. The job file now records `base` at init.

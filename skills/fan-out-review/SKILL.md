---
name: my-utils:fan-out-review
description: "Use at the review step of a my-utils work tier — the shared component fan-out the heavier tiers delegate to, never a whole-diff blob scan. Pipeline: scan set (components, cap ~8) → one linus subagent per component for defects → one superpowers:requesting-code-review subagent against the requirements for what was promised and is not here → superpowers:receiving-code-review triage → return the surviving findings. Returns findings only; the calling tier does the fixing. Invoked by /my-utils:bugfix, /my-utils:new-feature and /my-utils:long-running-job, or directly via /my-utils:fan-out-review."
allowed-tools:
  - Bash
  - Read
  - Agent
triggers:
  - fan-out review
  - fan out review
---

# Fan-Out Review — the shared review step

Two axes, because one cannot see the other. The fan-out finds defects in what
changed. The conformance pass finds what was promised and never changed at all.

## Contract

The caller supplies:

- **`base`** — the ref the diff starts from (`git diff --name-only <base>..HEAD`).
- **`requirements`** — what the conformance pass checks the diff against:

  | Caller | Requirements source |
  |---|---|
  | diagnosis tier | the root cause statement + the failing test from the commit body |
  | feature tier | the spec, plus the plan's task table and test list |
  | endurance tier | the plan's task table and test list, plus each unit's gates |

Returns the surviving findings (severity, `file:line`, one-line fix direction)
and the conformance verdict. **Nothing here edits files** — the caller's fix
step does that, because what "green" means differs per tier.

## Flow

1. **Scan set** — edited files from `git diff --name-only <base>..HEAD`, plus
   the blast radius: importers/callers of every changed symbol, the routes or
   UI that consume it, its tests. `graphify query` when the repo has a graph,
   else grep the import path + symbol. Group into components (module/feature
   units), not raw files. Cap ~8 — over that, merge the thinnest ones.

2. **Defect fan-out** — ONE subagent per component, dispatched together with
   step 3's conformance subagent in a single message so they all run
   concurrently. Each invokes the `linus` skill scoped to its component — that
   component's diff hunks plus the code they touch — and returns findings ONLY
   (severity, `file:line`, one-line fix direction). No file dumps, no prose.
   One component in the scan set → skip the fan-out and run linus inline; the
   conformance pass still runs.

3. **Conformance pass** — ONE subagent via superpowers:requesting-code-review.
   It answers what the fan-out structurally cannot: **a requirement nobody implemented produces no diff**,
   so it belongs to no component and no per-component reviewer can see it.
   Give it the requirements source and the diff, and ask for exactly three
   lists: promised-but-missing, present-but-unpromised, promised-but-diverged.
   Quality findings are step 2's job and are dropped here.

4. **Triage** — apply superpowers:receiving-code-review to everything that came
   back, before any of it reaches the caller:
   - dedupe across agents; drop style noise
   - verify each surviving finding against the codebase, not against the
     reviewer's confidence. One that does not reproduce is dropped, and the
     drop is stated
   - reasoned pushback beats performative agreement — "the reviewer is wrong
     because X" is a valid outcome and is recorded with its reason
   - a finding you do not understand is a question for the user, never a guess
     at an implementation

5. **Return** — hand back the surviving findings and the conformance verdict,
   grouped by component. Say plainly when a pass was skipped and why.

## Fallbacks

Before invoking any dependency below, if it is not installed, follow its row
instead of improvising. A missing dependency degrades the step; it never
silently skips it. `~/.claude/my-utils/doctor.sh` reports what this machine has.

| Dependency | Absent → |
|---|---|
| `linus` | Vendored in my-utils — `./setup.sh` is the fix. Still missing: run the same per-component fan-out, each subagent reviewing against data structure, special cases, gratuitous complexity, and breakage of existing callers. |
| `superpowers:requesting-code-review` | Dispatch the conformance subagent yourself, asking for the same three lists. The invariant holds — absence is checked against the requirements, never inferred from the diff. |
| `superpowers:receiving-code-review` | Triage inline against the same bar: verify each finding in the code before accepting it, drop what does not reproduce, record pushback with its reason. |
| `graphify` | Build the scan set with grep over the import path + symbol. Already the documented path when the repo has no graph. |

## Hard rules

- Never scan the whole diff as one blob — every component gets its own subagent.
- The conformance pass is about absence and divergence. It is never a second
  defect scan, and it never infers intent from the diff it is reviewing.
- No requirements source supplied → run steps 1, 2 and 4, and report that the
  conformance pass was skipped for lack of one. Never invent the requirements.
- Never accept a finding that does not reproduce in the code.
- This skill never edits files and never commits. It returns findings.

# CLAUDE.md — {{project}} (canonical pipeline · cell {{cell}})

## Stack — the three-layer authority boundary
Complementary, not alternative. Each owns ONE axis. No layer re-does another's job.

| Layer | Authority | Axis |
|---|---|---|
| **GSD** | spec, context, plan, execute waves, verify | WHY/WHAT — the spine |
| **superpowers** | brainstorm-before-spec, TDD inside tasks, two-stage subagent review | HOW code is written |
| **gstack** | CEO / Designer / Eng-Manager / Reviewer roles that challenge at gates | WHO interrogates the work |

## Hard rules (non-negotiable)
1. **Discovery ordering.** superpowers brainstorm DRIVES (unanswered questions first). GSD spec is the OUTPUT FORMAT. gstack CEO fires ONE "should we even build this?" challenge at the end. Never in parallel.
2. **Plan vs TDD.** GSD owns PLAN.md + wave decomposition + atomic commits. superpowers owns the TDD loop INSIDE each task. GSD does not write tests. superpowers does not restructure the plan.
3. **Review consolidation.** superpowers two-stage review is the PRIMARY reviewer. {{tail}} + `gsd-code-review` feed INTO it, never as separate passes.
   - {{tail-web: Web — `/linus` REPLACES gstack Reviewer. `/linus` + `gsd-code-review` feed superpowers two-stage.}}
   - {{tail-native: Native/iOS — gstack Reviewer + `gsd-code-review` feed superpowers two-stage.}}

## Canonical pipeline
```
DISCOVER superpowers:brainstorming → SPEC gsd-spec-phase → PLAN gsd-plan-phase
→ EXECUTE gsd-execute-phase → REVIEW superpowers two-stage ← {{tail}} + gsd-code-review
→ SHIP gsd-verify-work / gsd-ship
```

## TDD authority
superpowers is the SOLE TDD authority. When a task needs tests, superpowers TDD runs them. GSD verify checks the phase goal was met; it does NOT duplicate the test loop.

## Session context hygiene (keep context < 60%)
- When context exceeds ~60%, summarize work-in-progress and `/clear` (or `/compact`) before starting a new subtask.
- Research or audits spanning more than 3 files run in a subagent that reports a summary back — never drag that output through the main thread.

## Scenario block (cell {{cell}})
{{cell-specific-block: insert greenfield-snippet | brownfield-snippet | longrunning-snippet per the resolved cell}}

# Scenario Matrix (Layer 7 reference)

The audit spine is a 2×2 matrix. The reviewer classifies the project into one cell, then audits against THAT cell's required pipeline.

| | **Finite** (~1 context window) | **Long-running** (spans resets/sessions) |
|---|---|---|
| **Greenfield** | **Cell A** — `new-project` → one phase → `ship`. Light context hygiene. | **Cell C** — `new-project` + `thread`/`workstreams` + `pause/resume-work` + resume-on-boot. Survival = handoff + checkpoint discipline. |
| **Brownfield** | **Cell B** — `map-codebase` + `ingest-docs` → one phase → `ship`. Onboarding = critical path. | **Cell D** — brownfield entry + long-running survival + `improve-codebase-architecture` before heavy refactors. Hardest cell. |

## Per-cell audit criteria

- **Cell A (greenfield / finite):** Is the GSD spine declared? Is exactly one TDD authority named? Minimal context rules suffice.
- **Cell B (brownfield / finite):** Does `.planning/codebase/` exist (mapped)? Are existing ADRs/PRDs/SPECs ingested rather than re-derived? Is the canonical pipeline ADAPTED to the codebase, not copy-pasted?
- **Cell C (greenfield / long-running):** Is a thread/handoff/resume mechanism declared? A compaction trigger (<60% → `/compact` + checkpoint)? A subagent-delegation rule for >3-file reads?
- **Cell D (brownfield / long-running):** All of B + all of C, plus: is `improve-codebase-architecture` wired in BEFORE architectural refactors? Is the 60%-rule enforced by habit AND tool, not just stated?

# Canonical Pipeline (Layer 7 reference)

One pipeline, parameterized by cell. The generator stamps a cell-specific instance into `CLAUDE.md`.

```
DISCOVER  superpowers:brainstorming (DRIVES; unanswered questions first)
        ↳ gstack /grilling + /plan-ceo-review (ONE "should we build this?" challenge, end of discover)
SPEC     gsd-spec-phase (OUTPUT FORMAT)
         [brownfield B/D: gsd-map-codebase + gsd-ingest-docs FIRST, before spec]
PLAN     gsd-plan-phase (PLAN.md, wave decomposition)
        ↳ gstack /plan-eng-review, /plan-design-review, /plan-devex-review, /autoplan
         superpowers TDD owns the loop INSIDE each task; GSD does NOT write tests
EXECUTE  gsd-execute-phase → superpowers:test-driven-development per task, atomic commits
REVIEW   superpowers two-stage review (PRIMARY)
        ← /linus [web tail] OR gstack Reviewer [native tail] + gsd-code-review FEED IN
SHIP     gsd-verify-work → gsd-ship
```

**Always-on constraint layer:** `karpathy-guidelines` overlays the whole pipeline (surgical changes, surface assumptions, verifiable success criteria). Not a gate.

## Greenfield flow
`gsd-new-project` → `gsd-new-milestone` → per-phase loop (`gsd-spec-phase` → `gsd-discuss-phase` → `gsd-plan-phase` → `gsd-execute-phase` → `gsd-verify-work` → `gsd-ship`) → `gsd-complete-milestone`.

## Brownfield entry (replaces/precedes new-project)
`gsd-map-codebase` (parallel mapper agents → `.planning/codebase/`) + `gsd-ingest-docs` (bootstrap `.planning/` from existing ADRs/PRDs/SPECs with LOCKED-conflict detection) + `gsd-import` (ingest external plans with conflict detection).

## Long-running survival (cells C/D)
`gsd-thread`, `gsd-pause-work` / `gsd-resume-work`, `gsd-workstreams`, `gsd-workspace`, `gsd-manager`, `gsd-progress`, `gsd-autonomous`, plus `handoff`, `context-save` / `context-restore`.

## Three collision-zone rules (silence = BLOCK)
1. **Discovery ordering:** superpowers brainstorm DRIVES; GSD spec is output format only. Never parallel.
2. **Plan vs TDD:** GSD owns PLAN.md + waves + atomic commits; superpowers owns the TDD loop INSIDE each task. Neither crosses.
3. **Review consolidation:** superpowers two-stage review is PRIMARY. `/linus` (web tail) or gstack Reviewer (native tail) + `gsd-code-review` FEED IN. Never a separate pass.

## mattpocock improve-codebase-architecture (cells B/D, before heavy refactors) — VERIFIED
> **Source status: verified against raw SKILL.md** (`skills/engineering/improve-codebase-architecture/SKILL.md`, fetched 2026-08-02).

Repo's own description: "Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick." Aim: **testability and AI-navigability**. Brownfield-only (scans commit history for hot spots; reads CONTEXT.md + ADRs). Emits a self-contained HTML report to the OS temp dir (no repo artifacts). Uses the `/codebase-design` architecture vocabulary exactly — **module, interface, depth, seam, adapter, leverage, locality** — and forbids drifting into "component/service/API/boundary." Dependencies: `/codebase-design` (vocab), `/grilling` (step 3), `/domain-modeling`, plus `CONTEXT.md` + `docs/adr/`. **User-invoked only** (`disable-model-invocation: true` — invoke as `/improve-codebase-architecture`). Install: `npx skills@latest add mattpocock/skills` (interactive; select `improve-codebase-architecture`). Claude Code alternative: `claude plugins install mattpocock-skills`.

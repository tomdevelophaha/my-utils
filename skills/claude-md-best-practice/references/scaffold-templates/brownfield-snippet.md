# Brownfield block (cells B, D)
- BEFORE spec: run `gsd-map-codebase` (→ `.planning/codebase/`) and `gsd-ingest-docs` (ingest existing ADRs/PRDs/SPECs with LOCKED-conflict detection). Never re-derive decisions the repo already encodes.
- `gsd-import` external plans with conflict detection before writing.
- Before architectural refactors: install + run `/improve-codebase-architecture` (install: `npx skills@latest add mattpocock/skills`, interactive, select `improve-codebase-architecture`; or Claude Code `claude plugins install mattpocock-skills`). It scans for "deepening" opportunities, emits an HTML report to the OS temp dir, then grills the one you pick; uses `/codebase-design` vocabulary (module, interface, depth, seam, adapter, leverage, locality); depends on `/codebase-design` + `/grilling` + `/domain-modeling` + `CONTEXT.md` + `docs/adr/`. User-invoked only.
- ADAPT the canonical pipeline to this codebase — do not copy-paste a greenfield template.

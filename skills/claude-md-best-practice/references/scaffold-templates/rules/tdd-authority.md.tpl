---
paths:
  - "src/**"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.py"
  - "**/*.swift"
---
# TDD authority (path-scoped to source edits)

superpowers:test-driven-development is the SOLE TDD authority for this repo.

- Write the failing test first. Run it. Watch it fail for the right reason.
- Minimal implementation to pass. Refactor only on green.
- GSD verify checks the phase goal was met; it does NOT duplicate the test loop.
- Never commit code without a passing test covering the changed behavior.

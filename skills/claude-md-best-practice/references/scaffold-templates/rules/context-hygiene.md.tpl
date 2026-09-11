---
paths:
  - "**/*"
---
# Session context hygiene

- When context exceeds ~60%, summarize work-in-progress and `/clear` (or `/compact`) before starting a new subtask.
- Research or audits spanning more than 3 files run in a subagent that reports a summary back — never drag that output through the main thread.
- `/clear` aggressively after each completed subtask rather than dragging stale tool output forward.

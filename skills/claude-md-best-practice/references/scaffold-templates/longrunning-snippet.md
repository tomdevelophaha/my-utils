# Long-running block (cells C, D)
- Declare a compaction trigger: when context exceeds ~60%, summarize WIP and `/clear` (or `/compact`) before the next subtask.
- Use `gsd-thread` for persistent cross-session context; `gsd-pause-work` / `gsd-resume-work` for mid-phase handoffs.
- Use `gsd-workstreams` for parallel tracks; `gsd-manager` / `gsd-progress` to coordinate.
- Delegate read-heavy work (>3 files) to a subagent; use `handoff` / `context-save` + `context-restore` across hard resets.
- Accuracy across sessions = checkpoint discipline. Every pause writes a handoff; every resume reads it.

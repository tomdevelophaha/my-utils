# `.claude/` Directory Audit (Layer 3 reference)

> Moved out of SKILL.md. The reviewer loads this when running the directory audit.

### Layer 3: `.claude/` Directory Audit (10 Subdirectories)
> "Bad programmers worry about the code. Good programmers worry about data structures."

The `.claude/` directory is the project's AI operating system. Audit EVERY subdirectory
that should exist, not just `rules/` and `memory/`. The community consensus (ComputingForGeeks,
Claude Code Docs, Daily Dose of Data Science) defines 10 subdirectories. Audit each one:

**10-Subdirectory Audit Checklist:**

| # | Directory | What it does | Should exist when |
|---|-----------|-------------|-------------------|
| 1 | `rules/` | Path-scoped modular instructions with `paths:` YAML frontmatter | CLAUDE.md > 150 lines, or domain-specific rules exist |
| 2 | `agents/` | Isolated context windows that spend their OWN budget (tool allowlists, model preference) | ANY task that does broad reads/research/audit — keeps the main thread clean |
| 3 | `skills/` | Auto-invoked workflows (Claude triggers on description match) | Complex multi-step workflows invoked by task description |
| 4 | `commands/` | Custom slash commands with `!` shell injection | Repeated manual workflows need one-command triggers |
| 5 | `workflows/` | Dynamic multi-agent orchestration scripts (saved from `/workflows`) | Multi-agent fan-out patterns are used regularly |
| 6 | `agent-memory/` | Persistent subagent memory (`user`/`project`/`local` scope) | Subagents accumulate knowledge across sessions |
| 7 | `hooks/` | Event-driven automation (SessionStart, PostToolUse, etc.) | Automated triggers needed (lint on save, deploy on push) |
| 8 | `output-styles/` | Custom system-prompt sections controlling response formatting | Non-default output format required (JSON-only, terse, etc.) |
| 9 | `memory/` | Auto memory — Claude self-writes learnings to MEMORY.md | Should virtually always be active (on by default since v2.1.59) |
| 10 | `settings.json` | Permissions (allow/deny), env vars, hooks config, model defaults | Every project should have one |

**Also audit these files outside `.claude/`:**

| File | What it does | Should exist when |
|------|-------------|-------------------|
| `CLAUDE.local.md` | Personal per-project overrides (gitignored) | Developer-specific preferences differ from team defaults |
| `~/.claude/CLAUDE.md` | Global personal preferences across all projects | Developer has cross-project conventions |
| `.mcp.json` | MCP server configurations (project root) | External MCP servers are used |

**Smell test per subdirectory:**

- **`rules/` missing but CLAUDE.md > 150 lines:** paying context tax. Split now.
- **`agents/` missing but repeated "review this PR" patterns:** context pollution. Each review session carries prior review state.
- **`commands/` missing but repeated manual workflows:** wasted keystrokes. A 3-line `.md` with `!` backticks replaces the repeated prompt.
- **`skills/` empty but project has complex workflows:** missed automation. Skills auto-invoke; you don't need to remember to call them.
- **`agent-memory/` missing but project uses subagents:** amnesia. Subagents restart from zero every session.
- **`settings.json` missing:** no permission allowlist. Every tool call requires manual approval.
- **`CLAUDE.local.md` missing but developer has personal preferences:** preferences polluting git history or being re-stated verbally every session.
- **`memory/` (auto memory) disabled:** Claude forgets everything between sessions. Re-enable with `/memory` or `autoMemoryEnabled: true`.
- **`.mcp.json` lists unused servers:** context tax before the first prompt. Every server consumes budget the moment the session starts, not when it is called. Prune to only the servers this project's session types actually need (per r/ClaudeCode daily-tips consensus).

**For each missing directory, ask: is the project paying the cost of not having it?**
The answer is not always "create it" — small projects need fewer directories. But the
cost must be named explicitly. "Project is too small for agents" is valid. Silence is not.

A CLAUDE.md with zero lines beginning "Never" or "Always" has never been
updated after a real mistake. That is a red flag.

**Monolithic vs. modular check:** If the CLAUDE.md is over 150 lines and
no `.claude/rules/` directory exists, the project is paying context tax on
rules Claude does not need for every session type. Generic behavioral
guidelines (editorial style, thinking discipline) belong in
`.claude/rules/` with `paths:` glob patterns so they only load during code-editing
sessions, not research or data-analysis sessions. Project-specific hard
constraints (schemas, prohibitions, architecture) stay in CLAUDE.md.

**Two modular mechanisms exist — pick deliberately, do not mix them up:**
- Nested `CLAUDE.md` in a subfolder auto-loads by working directory. Use for
  module-scoped conventions Claude always needs while editing inside that folder.
- `.claude/rules/*.md` with a `paths:` glob loads on file match. Use for
  cross-cutting style rules that apply only to certain file types regardless of
  where they live. Do not duplicate the same rule in both places.

**Taxonomy check (skills vs. commands vs. agents):** The most common modular mistake
is using the wrong component type for the job. Verify the project's `.claude/` directory
is not misusing these:
- **Commands** = manually triggered (`/project:review`), single `.md` file, good for repeated manual workflows.
- **Skills** = auto-invoked by Claude based on description matching, folder with `SKILL.md`, good for context-aware automatic workflows.
- **Agents** = isolated context windows, do work independently, compress and report back. Good for review/audit/security tasks.
- **Workflows** = dynamic `.js` scripts from `/workflows` command, good for multi-agent orchestration.

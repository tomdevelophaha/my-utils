# Consensus Best Practices Reference

> Moved out of SKILL.md to keep the core lean. Cite these by number from the reviewer.

## Consensus Best Practices Reference (Cite These)

When justifying findings, reference the specific source:

1. **Errors as Assets (Boris Cherny):** every mistake → a rule in CLAUDE.md. Never verbally correct without writing it down.
2. **Six-Section Structure (Builder.io, Tembo):** Commands, Architecture, Code Style, Hard Constraints, Testing, Gotchas.
3. **Specific Checkable Rules (camelCase YT, AlfredoLab):** rules must be verifiable. No "aim for," "prefer," "try to."
4. **Under 200 Lines (Tembo, HN consensus):** above this, adherence drops. Every line is a context cost.
5. **Defense in Depth / Hooks Mandatory (Anthropic, SmartScope 2026):** Hooks are Mandatory, CLAUDE.md is Advisory. CLAUDE.md + linters + `.claude/hooks/` + reviewer agent. Rules alone are not enough.
6. **CLAUDE.md is AI Onboarding (Anthropic Help Center, Claude Code Docs):** not human documentation. Not README. Not CONTRIBUTING.md.
7. **Trigger-Action Pattern:** "When [TRIGGER], ALWAYS [ACTION]." Claude follows patterns, not prose.
8. **Hard Constraints Section:** "Never," "Always," "Do not" — the rules that matter most go here.
9. **Modular `.claude/` Directory (10 subdirectories):** rules/, agents/, skills/, commands/, workflows/, agent-memory/, hooks/, output-styles/, memory/, settings.json — plus CLAUDE.local.md. Audit all 10, not just rules/ and memory/. The right modular component for the right job. Per Claude Code Docs, ComputingForGeeks, Daily Dose of Data Science.
10. **Correct Component Taxonomy:** Commands = manual trigger (single `.md`). Skills = auto-invoke on description match (folder with SKILL.md). Agents = isolated context that spends its own budget, independent work, compressed report. Workflows = dynamic `.js` multi-agent orchestration. Using the wrong one wastes context and keystrokes. Per arps18 (HN, 451pts), code.claude.com.
11. **Session Context Hygiene (GritAI Studio, Claude Code Docs, r/ClaudeCode):** the file is the floor, not the ceiling. Encode a compaction trigger (~60% → /compact or /clear), clear between subtasks, and delegate read-heavy work to subagents. Per Anthropic, "How Claude Code works in large codebases."
12. **Subagents for Context Isolation (r/ClaudeAI, PubNub):** the primary value of a subagent is spending its own context window on broad research/audit so the main thread stays clean — not just "dedicated context for repeated workflows."
13. **MCP Pruning (r/ClaudeCode daily-tips):** unused MCP servers consume context budget before the first prompt. Every server in `.mcp.json` must map to a session type the project actually runs.
14. **Context Engineering as the Unifying Discipline (Anthropic "Effective context engineering for AI agents"):** be ruthless about what enters the context window — compaction, subagents, and targeted retrieval beat dumping everything in.
15. **Agentic Workflow & Pipeline Boundary (multi-skill-ecosystem projects):** when a project is driven by ≥2 skill ecosystems (GSD, superpowers, gstack, /linus), the CLAUDE.md MUST declare the canonical pipeline, resolve the three collision zones (discovery ordering, plan-vs-TDD, review consolidation), and name a single TDD authority. Extends Errors-as-Assets (#1) and Specific Checkable (#3) to the workflow layer. Silence here means the ecosystems collide silently.
16. **Reviewer Discipline (Andrej Karpathy, LLM-coding pitfalls):** the reviewer itself obeys the four disciplines — surface assumptions (never silently pick an interpretation), surgical fixes (every recommended edit traces to a real defect; never refactor what is not broken), simplicity over speculation (minimum non-speculative change), and verifiable success criteria (every fix states how to verify it). Bias caution over speed; trivial reviews may use judgment.

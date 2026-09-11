{
  "_comment": "No native <60% compaction-trigger hook exists in Claude Code yet; the rule is enforced via CLAUDE.md + rules/context-hygiene.md.tpl (discipline), not here. If a Stop/PreCompact hook ships, wire it under 'hooks'.",
  "permissions": {
    "allow": [
      "Bash(git status)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Read(**)"
    ],
    "deny": [],
    "ask": [
      "Bash(git push:*)",
      "Bash(rm:*)"
    ]
  },
  "hooks": {
  }
}

---
name: my-utils:where-we-left-off
description: Use when the user wants to know what the last few Claude sessions in this project worked on without opening /resume one by one — "where were we", "where did we leave off", "what have we been working on", "catch me up". Lists the last 10 sessions (up to 20 on request) for the current directory from the local transcripts and returns a short digest. Status check only, never resumes or edits anything. Trigger via /my-utils:where-we-left-off.
triggers:
  - where were we
  - where did we leave off
  - what have we been working on
  - catch me up
---

# Where We Left Off

Read the local Claude Code transcripts for the current project directory and
tell the user what the recent sessions were about. Status only. Do not resume
a session, do not touch files, do not act on anything you find.

## Steps

1. Pick the count: 10 by default, or the number the user asked for, capped
   at 20.
2. Run the snippet below from the project directory (replace `10` with the
   count). It prints one block per session, newest first: when it ran, the
   branch, how many prompts, the first prompt and the last.

   ```bash
   python3 - 10 <<'PY'
   import glob, json, os, re, sys
   from datetime import datetime
   n = min(int(sys.argv[1]), 20)
   slug = ''.join(c if c.isalnum() else '-' for c in os.getcwd())
   here = os.environ.get('CLAUDE_CODE_SESSION_ID', '')
   local = lambda t: datetime.fromisoformat(t.replace('Z', '+00:00')).astimezone().strftime('%Y-%m-%d %H:%M')
   rows = []
   for f in glob.glob(os.path.expanduser(f'~/.claude/projects/{slug}/*.jsonl')):
       prompts, ts, branch = [], [], ''
       for line in open(f, errors='replace'):
           try: d = json.loads(line)
           except ValueError: continue
           c = d.get('message', {}).get('content') if d.get('type') == 'user' else None
           if not isinstance(c, str): continue
           if c.startswith('<command-'):   # typed slash command: keep name + args, drop bare /clear etc.
               name = re.search(r'<command-name>(.*?)</command-name>', c, re.S)
               args = re.search(r'<command-args>(.*?)</command-args>', c, re.S)
               if not (name and args and args.group(1).strip()): continue
               c = name.group(1) + ' ' + args.group(1)
           elif c.startswith('<'): continue   # tool results, attachments, system text
           prompts.append(' '.join(c.split())[:160])
           ts.append(d.get('timestamp', '')); branch = d.get('gitBranch') or branch
       if prompts: rows.append((ts[-1], ts[0], branch, prompts, os.path.basename(f).startswith(here) if here else False))
   for last, first, branch, prompts, cur in sorted(rows, reverse=True)[:n]:
       print(f"{local(first)} → {local(last)[11:]}  branch={branch}  prompts={len(prompts)}{'  (this session)' if cur else ''}")
       print(f"  first: {prompts[0]}")
       if len(prompts) > 1: print(f"  last:  {prompts[-1]}")
   PY
   ```

3. Answer with one line per session, newest first: date, branch if it is not
   the main one, and what it was about in plain words. Merge sessions that
   are obviously the same piece of work (a `/resume` fork repeats the first
   prompt). Skip the current session. Close with one sentence naming the most
   recent unfinished thread, if any is visible — a last prompt like "delete
   this" or "so how do I trigger it" is a hint, not proof, so say "looks like".

## Rules

- No table, no headers, no recap of the whole project. Around ten short
  lines.
- Transcripts are on this machine only, keyed by the directory Claude was
  started in. A different directory is a different project. If the directory
  has no transcripts, say so and stop.
- The snippet reads only user prompts. It cannot tell whether a session
  finished its work; `git log` can. Do not claim a thread is done or undone
  beyond what the prompts show.
- Never quote a prompt at length. Paraphrase.

## Fallbacks

| Dependency | Absent |
|---|---|
| `python3` | Fall back to `ls -t ~/.claude/projects/<slug>/*.jsonl \| head` and `grep -o '"content":"[^"]\{0,160\}' <file> \| head -3` per file — same digest, rougher input. |

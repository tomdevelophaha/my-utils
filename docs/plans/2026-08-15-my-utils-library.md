# my-utils Library Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the `my-utils` private git repo with an idempotent symlink installer, migrate the existing `quick-summary` skill into it, and push to GitHub.

**Architecture:** A plain git repo. `setup.sh` symlinks each `skills/<name>/` directory into `~/.claude/skills/<name>`. Skills are namespaced via their own `name: my-utils:<name>` frontmatter. No plugin.json, no marketplace.

**Tech Stack:** bash (setup.sh + test), git, GitHub.

**Repo:** `~/repos/my-utils` (git already initialized; `docs/design.md` committed).

---

## File structure

- `setup.sh` — idempotent symlinker; env-overridable source/target dirs so it's testable
- `tests/test-setup.sh` — exercises link-new, don't-clobber-real-dir, and idempotency
- `skills/quick-summary/SKILL.md` — migrated from `~/.claude/skills/quick-summary/`
- `README.md` — install / sync / add-a-skill instructions
- `.gitignore` — ignore `.DS_Store`

---

### Task 1: setup.sh (TDD)

**Files:**
- Create: `tests/test-setup.sh`
- Create: `setup.sh`

- [ ] **Step 1: Write the failing test**

```bash
cat > tests/test-setup.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

src="$tmp/src"; tgt="$tmp/target"
mkdir -p "$src/skill-a" "$tgt"
mkdir -p "$tgt/skill-b"   # real dir that must NOT be clobbered

MY_UTILS_SKILLS_DIR="$src" MY_UTILS_TARGET_DIR="$tgt" bash ./setup.sh

[[ -L "$tgt/skill-a" ]] || { echo "FAIL: skill-a not symlinked"; exit 1; }
[[ -d "$tgt/skill-b" && ! -L "$tgt/skill-b" ]] || { echo "FAIL: skill-b clobbered"; exit 1; }

MY_UTILS_SKILLS_DIR="$src" MY_UTILS_TARGET_DIR="$tgt" bash ./setup.sh
[[ -L "$tgt/skill-a" ]] || { echo "FAIL: idempotency broke skill-a"; exit 1; }

echo "PASS"
EOF
chmod +x tests/test-setup.sh
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-setup.sh`
Expected: FAIL — `setup.sh` does not exist (`No such file or directory`).

- [ ] **Step 3: Write the implementation**

```bash
cat > setup.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

SOURCE_DIR="${MY_UTILS_SKILLS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills}"
TARGET_DIR="${MY_UTILS_TARGET_DIR:-$HOME/.claude/skills}"

mkdir -p "$TARGET_DIR"

for skill in "$SOURCE_DIR"/*/; do
  skill="${skill%/}"
  name="$(basename "$skill")"
  link="$TARGET_DIR/$name"

  if [[ -L "$link" ]]; then
    continue
  elif [[ -e "$link" ]]; then
    echo "skip: $link already exists (not a symlink)" >&2
    continue
  fi

  ln -s "$skill" "$link"
  echo "linked: $name"
done
EOF
chmod +x setup.sh
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test-setup.sh`
Expected: `PASS`

- [ ] **Step 5: Commit**

```bash
git add setup.sh tests/test-setup.sh
git commit -m "feat: idempotent symlink installer"
```

---

### Task 2: Migrate quick-summary skill

**Files:**
- Create: `skills/quick-summary/SKILL.md` (content from `~/.claude/skills/quick-summary/SKILL.md`)
- Modify: `~/.claude/skills/quick-summary` → real dir removed, replaced by symlink

- [ ] **Step 1: Move SKILL.md into the repo**

```bash
mkdir -p skills/quick-summary
cp ~/.claude/skills/quick-summary/SKILL.md skills/quick-summary/SKILL.md
```

- [ ] **Step 2: Replace the real dir with a symlink**

```bash
rm -rf ~/.claude/skills/quick-summary
ln -s ~/repos/my-utils/skills/quick-summary ~/.claude/skills/quick-summary
```

- [ ] **Step 3: Verify the symlink resolves**

Run: `ls -la ~/.claude/skills/quick-summary/`
Expected: symlink `-> ~/repos/my-utils/skills/quick-summary`, and `SKILL.md` visible through it.

- [ ] **Step 4: Commit**

```bash
git add skills/quick-summary/SKILL.md
git commit -m "feat: add quick-summary skill"
```

---

### Task 3: README + .gitignore

**Files:**
- Create: `README.md`
- Create: `.gitignore`

- [ ] **Step 1: Write README.md**

```bash
cat > README.md <<'EOF'
# my-utils

Personal Claude Code skills, version-controlled and symlinked into
`~/.claude/skills/` across my machines.

## Install

```bash
git clone git@github.com:tomdevelophaha/my-utils.git ~/repos/my-utils
~/repos/my-utils/setup.sh
```

## Sync

```bash
cd ~/repos/my-utils && git pull && ./setup.sh
```

## Add a skill

1. Create `skills/<name>/SKILL.md` with frontmatter `name: my-utils:<name>`.
2. Commit and push.
3. On other machines: `git pull && ./setup.sh`.

## Skills

- `quick-summary` — one-paragraph recap of the current session.
EOF
```

- [ ] **Step 2: Write .gitignore**

```bash
printf '.DS_Store\n' > .gitignore
```

- [ ] **Step 3: Commit**

```bash
git add README.md .gitignore
git commit -m "docs: README and gitignore"
```

---

### Task 4: Push to GitHub

**Files:**
- None (remote only)

- [ ] **Step 1: Create the private remote repo**

```bash
gh repo create my-utils --private --source ~/repos/my-utils --remote origin --push
```

Expected: remote repo created and local `main` pushed.

- [ ] **Step 2: Verify**

Run: `git -C ~/repos/my-utils remote -v && git -C ~/repos/my-utils log --oneline`
Expected: `origin` points at `github.com/tomdevelophaha/my-utils`, all commits present.

---

## Post-reload verification (not part of these tasks)

After the next Claude Code session start, confirm the skill appears as
`my-utils:quick-summary` (namespaced) rather than bare `quick-summary`. If the
prefix does not survive, add a `.claude-plugin/plugin.json` (`name: my-utils`) —
see `docs/design.md`.

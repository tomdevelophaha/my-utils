#!/usr/bin/env bash
# Drift guard: every external dependency a skill names must have a declared
# fallback. This is the check that would have caught superpowers going
# unavailable without a single skill noticing.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Print every external dependency referenced in a SKILL.md, one per line.
# Only the body counts; the frontmatter description names skills descriptively.
refs() {
  awk 'BEGIN{fm=0} /^---$/{fm++; next} fm>=2' "$1" \
    | grep -oE 'superpowers:[a-z-]+|/gsd-[a-z-]+|\blinus\b|\bgraphify\b' \
    | sed 's/^\///' \
    | sort -u
}

# The rows of the file's "## Fallbacks" section.
declared() {
  awk '/^## Fallbacks/{f=1; next} /^## /{f=0} f' "$1"
}

check() {   # $1 = SKILL.md ; prints failures, returns 1 if any
  local file="$1" rc=0 dep
  local body decl
  body="$(refs "$file")"
  [[ -z "$body" ]] && return 0
  decl="$(declared "$file")"
  if [[ -z "$decl" ]]; then
    echo "  $file: references external dependencies but has no '## Fallbacks' section"
    return 1
  fi
  while read -r dep; do
    [[ -z "$dep" ]] && continue
    grep -qF "$dep" <<<"$decl" || { echo "  $file: no fallback declared for '$dep'"; rc=1; }
  done <<<"$body"
  return $rc
}

# --- self-test: a fixture with an undeclared dependency must be caught -------
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/SKILL.md" <<'FIX'
---
name: fixture
---
# Fixture
Execute via superpowers:executing-plans.
## Fallbacks
| Dependency | Absent |
|---|---|
| Kanban | skip |
FIX
if out="$(check "$tmp/SKILL.md")"; then
  echo "FAIL: T9: guard passed a skill with an undeclared dependency"; exit 1
fi
grep -q 'superpowers:executing-plans' <<<"$out" \
  || { echo "FAIL: T9: guard did not name the undeclared dependency"; exit 1; }

# --- T10: the real skills must all declare their fallbacks ------------------
rc=0
for f in "$ROOT"/skills/*/SKILL.md; do
  check "$f" || rc=1
done
if [[ $rc -ne 0 ]]; then
  echo "FAIL: T10: a skill names an external dependency with no declared fallback"
  exit 1
fi

echo "PASS"

#!/usr/bin/env bash
# Drift guard: every external dependency a skill names must have a declared
# fallback. This is the check that would have caught superpowers going
# unavailable without a single skill noticing.
set -uo pipefail
shopt -s nullglob

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Print every external dependency referenced in a SKILL.md, one per line.
# Only the body counts; the frontmatter description names skills descriptively.
# Returns non-zero when the file cannot be parsed — "no dependencies found" and
# "could not read it" must never look the same.
refs() {
  local file="$1" body delims self found
  delims="$(tr -d '\r' < "$file" | grep -c '^---$' || true)"
  [[ "$delims" -ge 2 ]] || return 1
  body="$(tr -d '\r' < "$file" | awk 'BEGIN{fm=0} /^---$/{fm++; next} fm>=2')"
  [[ -n "$body" ]] || return 1
  # Bare `gsd-x` counts as much as `/gsd-x`; so does an unprefixed kanban or gh
  # dependency, which is what let jot-down-task-github pass with no table.
  # `|| true`: a skill with no dependencies is not a parse failure. Under
  # pipefail, grep's no-match exit would otherwise be read as one.
  found="$( { grep -oE 'superpowers:[a-z-]+|/?gsd-[a-z-]+|/?my-utils:[a-z-]+|\blinus\b|\bgraphify\b|\bkanban\b|\bgh\b' <<<"$body" || true; } \
    | sed 's|^/||' | sort -u )"
  # A skill that names ITSELF — "outgrows this tier → /my-utils:x" inside x — is
  # not depending on anything. Without this, the my-utils family above would
  # make every tier declare a fallback for its own absence.
  self="$(tr -d '\r' < "$file" | sed -n '2,/^---$/s/^name:[[:space:]]*//p' | head -1)"
  [[ -n "$self" ]] && found="$(grep -vxF -- "$self" <<<"$found" || true)"
  printf '%s\n' "$found"
}

# The TABLE ROWS of the file's "## Fallbacks" section — rows only, so a mention
# in the surrounding prose cannot stand in for a declared fallback.
declared() {
  tr -d '\r' < "$1" | awk '/^## Fallbacks/{f=1; next} /^## /{f=0} f' | grep '^|' || true
}

check() {   # $1 = SKILL.md ; prints failures, returns 1 if any
  local file="$1" rc=0 dep body decl
  if ! body="$(refs "$file")"; then
    echo "  $file: could not parse frontmatter/body — the guard cannot see its dependencies"
    return 1
  fi
  [[ -z "$body" ]] && return 0
  decl="$(declared "$file")"
  if [[ -z "$decl" ]]; then
    echo "  $file: references external dependencies but has no '## Fallbacks' table"
    return 1
  fi
  while read -r dep; do
    [[ -z "$dep" ]] && continue
    # Must appear inside a row, delimited — so a row for `superpowers:foo-v2`
    # does not satisfy a dependency on `superpowers:foo`.
    grep -qEi "^\|[^|]*(^|[^a-zA-Z0-9:_-])${dep//./\\.}([^a-zA-Z0-9:_-]|$)" <<<"$decl" \
      || { echo "  $file: no fallback row declared for '$dep'"; rc=1; }
  done <<<"$body"
  return $rc
}

# --- self-test: one undeclared dependency of EVERY supported form -----------
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
selftest_fail() { echo "FAIL: $*"; exit 1; }

cat > "$tmp/undeclared.md" <<'FIX'
---
name: fixture
---
# Fixture
Execute via superpowers:executing-plans, escalate to gsd-execute-phase and
/gsd-debug, promote to /my-utils:new-feature, review with linus, scan with
graphify, card via kanban and gh.
## Fallbacks
| Dependency | Absent |
|---|---|
| nothing | nothing |
FIX
if out="$(check "$tmp/undeclared.md")"; then
  selftest_fail "guard passed a skill with undeclared dependencies"
fi
for form in 'superpowers:executing-plans' 'gsd-execute-phase' 'gsd-debug' \
            'my-utils:new-feature' linus graphify kanban gh; do
  grep -q -- "$form" <<<"$out" || selftest_fail "guard did not name the undeclared '$form'"
done

# a file whose deps ARE declared must pass
cat > "$tmp/declared.md" <<'FIX'
---
name: fixture
---
# Fixture
Execute via superpowers:executing-plans.
## Fallbacks
| Dependency | Absent |
|---|---|
| `superpowers:executing-plans` | run the tasks in order |
FIX
check "$tmp/declared.md" >/dev/null || selftest_fail "guard rejected a correctly declared skill"

# a near-miss row must NOT satisfy the real dependency
cat > "$tmp/nearmiss.md" <<'FIX'
---
name: fixture
---
# Fixture
Execute via superpowers:executing-plans.
## Fallbacks
| Dependency | Absent |
|---|---|
| `superpowers:executing-plans-v2` | wrong skill |
FIX
check "$tmp/nearmiss.md" >/dev/null && selftest_fail "a near-miss row satisfied a different dependency"

# naming ITSELF is not a dependency; naming a SIBLING still is
cat > "$tmp/selfref.md" <<'FIX'
---
name: my-utils:fixture
---
# Fixture
Outgrows this tier → /my-utils:fixture keeps the rest; bigger → /my-utils:other.
## Fallbacks
| Dependency | Absent |
|---|---|
| nothing | nothing |
FIX
if out="$(check "$tmp/selfref.md")"; then
  selftest_fail "guard passed a skill with an undeclared sibling dependency"
fi
grep -q -- 'my-utils:other' <<<"$out" || selftest_fail "guard did not name the undeclared sibling"
grep -q -- 'my-utils:fixture' <<<"$out" && selftest_fail "guard made a skill its own dependency"

# an unparseable file must fail loudly, not pass by finding nothing
printf 'no frontmatter here\nsuperpowers:brainstorming\n' > "$tmp/broken.md"
check "$tmp/broken.md" >/dev/null && selftest_fail "an unparseable skill passed silently"

# CRLF line endings must not hide a dependency
printf -- '---\r\nname: fixture\r\n---\r\n\r\nUse superpowers:brainstorming.\r\n' > "$tmp/crlf.md"
check "$tmp/crlf.md" >/dev/null && selftest_fail "a CRLF file hid its undeclared dependency"

# a skill with NO dependencies is fine and must not be called unparseable
printf -- '---\nname: fixture\n---\n\nJust prose, no dependencies.\n' > "$tmp/nodeps.md"
check "$tmp/nodeps.md" >/dev/null || selftest_fail "a dependency-free skill was reported as broken"

# --- T10: the real skills must all declare their fallbacks ------------------
rc=0; count=0
for f in "$ROOT"/skills/*/SKILL.md; do
  count=$((count + 1))
  check "$f" || rc=1
done
# Without a floor the whole guard passes on an empty skills/ directory.
if [[ "$count" -lt 4 ]]; then
  echo "FAIL: only $count skills checked — the guard is not seeing the library"
  exit 1
fi
if [[ $rc -ne 0 ]]; then
  echo "FAIL: a skill names an external dependency with no declared fallback"
  exit 1
fi

echo "PASS ($count skills checked)"

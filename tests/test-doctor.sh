#!/usr/bin/env bash
set -euo pipefail

fail() { echo "FAIL: $*"; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/skills"

# T11 — everything missing: doctor diagnoses, it does not gate
set +e
out="$(env PATH=/usr/bin:/bin MY_UTILS_TARGET_DIR="$tmp/skills" \
       MY_UTILS_CONFIG="$tmp/nope.config" bash "$ROOT/doctor.sh" 2>&1)"
rc=$?
set -e
[[ $rc -eq 0 ]] || fail "T11: exited $rc with dependencies missing — doctor must report, not fail"

for dep in superpowers gsd linus kanban; do
  grep -qi "$dep" <<<"$out" || fail "T11: never mentions $dep"
done
grep -q -- '--with-deps' <<<"$out" || fail "T11: no install command offered for the missing deps"
grep -q -- '--configure' <<<"$out" || fail "T11: no fix offered for the unconfigured board"
grep -qiE 'missing|not installed|absent' <<<"$out" || fail "T11: does not say anything is missing"

# T11b — present dependencies are reported as present
mkdir -p "$tmp/skills/superpowers" "$tmp/skills/gsd-quick" "$tmp/skills/linus"
out="$(env PATH=/usr/bin:/bin MY_UTILS_TARGET_DIR="$tmp/skills" \
       MY_UTILS_CONFIG="$tmp/nope.config" bash "$ROOT/doctor.sh" 2>&1)" \
  || fail "T11b: exited non-zero"
grep -qiE 'ok|present|✓' <<<"$out" || fail "T11b: never reports anything as present"

# T11c — an installed-but-DISABLED plugin is unavailable, and needs enable, not install
bin="$tmp/bin"; mkdir -p "$bin"
cat > "$bin/claude" <<'STUB'
#!/usr/bin/env bash
[[ "$*" == *"plugin list"* ]] && printf '  superpowers@claude-plugins-official\n    Version: 6.3.0\n    Status: disabled\n'
exit 0
STUB
chmod +x "$bin/claude"
rm -rf "$tmp/skills/superpowers"
out="$(env PATH="$bin:/usr/bin:/bin" MY_UTILS_TARGET_DIR="$tmp/skills" \
       MY_UTILS_CONFIG="$tmp/nope.config" bash "$ROOT/doctor.sh" 2>&1)" \
  || fail "T11c: exited non-zero"
grep -qiE 'disabled' <<<"$out" || fail "T11c: does not report superpowers as disabled"
grep -q 'plugin enable' <<<"$out" || fail "T11c: offers no enable command"
grep -qE 'ok +superpowers' <<<"$out" && fail "T11c: reports a disabled plugin as ok"

echo "PASS"

#!/usr/bin/env bash
set -euo pipefail

fail() { echo "FAIL: $*"; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
# HOME is sandboxed for the whole suite, not per call site: setup.sh, doctor.sh
# and bin/kanban.sh each derive paths from it, and an invocation that forgets one
# MY_UTILS_* override would otherwise reach the real ~/.claude.
export HOME="$tmp/home"; mkdir -p "$HOME"
mkdir -p "$tmp/skills"

# T11 — everything missing: doctor diagnoses, it does not gate
set +e
out="$(env PATH=/usr/bin:/bin MY_UTILS_TARGET_DIR="$tmp/skills" \
       MY_UTILS_CONFIG="$tmp/nope.config" bash "$ROOT/doctor.sh" 2>&1)"
rc=$?
set -e
[[ $rc -eq 0 ]] || fail "T11: exited $rc with dependencies missing — doctor must report, not fail"

for dep in superpowers gsd linus fan-out-review kanban; do
  grep -qE "^ +MISSING +$dep" <<<"$out" || fail "T11: $dep is absent but not reported MISSING"
done
grep -q -- '--with-deps' <<<"$out" || fail "T11: no install command offered for the missing deps"
grep -q -- '--configure' <<<"$out" || fail "T11: no fix offered for the unconfigured board"
grep -qiE 'missing|not installed|absent' <<<"$out" || fail "T11: does not say anything is missing"

# T11b — present dependencies are reported as present
mkdir -p "$tmp/skills/superpowers" "$tmp/skills/gsd-quick" "$tmp/skills/linus" \
         "$tmp/skills/fan-out-review"
out="$(env PATH=/usr/bin:/bin MY_UTILS_TARGET_DIR="$tmp/skills" \
       MY_UTILS_CONFIG="$tmp/nope.config" bash "$ROOT/doctor.sh" 2>&1)" \
  || fail "T11b: exited non-zero"
for dep in superpowers gsd linus fan-out-review; do
  grep -qE "^ +ok +$dep" <<<"$out" || fail "T11b: $dep is present but not reported ok"
done

# T11c — an installed-but-DISABLED plugin is unavailable, and needs enable, not install
bin="$tmp/bin"; mkdir -p "$bin"
# Real `claude plugin list` emits four lines per block, and neighbouring blocks
# are what a fixed -A window misreads.
plugin_stub() {   # $1 = full listing body
  cat > "$bin/claude" <<STUB
#!/usr/bin/env bash
[[ "\$*" == *"plugin list"* ]] && cat <<'OUT'
Installed plugins:

$1
OUT
exit 0
STUB
  chmod +x "$bin/claude"
}
plugin_stub '  ❯ superpowers@claude-plugins-official
    Version: 6.3.0
    Scope: user
    Status: ✘ disabled

  ❯ zeta@other
    Version: 1.0.0
    Scope: user
    Status: ✔ enabled'
rm -rf "$tmp/skills/superpowers"
out="$(env PATH="$bin:/usr/bin:/bin" MY_UTILS_TARGET_DIR="$tmp/skills" \
       MY_UTILS_CONFIG="$tmp/nope.config" bash "$ROOT/doctor.sh" 2>&1)" \
  || fail "T11c: exited non-zero"
grep -qiE 'disabled' <<<"$out" || fail "T11c: does not report superpowers as disabled"
grep -q 'plugin enable' <<<"$out" || fail "T11c: offers no enable command"
grep -qE 'ok +superpowers' <<<"$out" && fail "T11c: reports a disabled plugin as ok"

# T11d — an ENABLED plugin next to a DISABLED neighbour must not be misread.
# A fixed -A3 window bleeds the neighbour's status into the answer.
plugin_stub '  ❯ superpowers@claude-plugins-official
    Version: 6.3.0
    Scope: user
    Status: ✔ enabled

  ❯ superpowers-extra@somewhere
    Version: 1.0.0
    Scope: user
    Status: ✘ disabled'
out="$(env PATH="$bin:/usr/bin:/bin" MY_UTILS_TARGET_DIR="$tmp/skills" \
       MY_UTILS_CONFIG="$tmp/nope.config" bash "$ROOT/doctor.sh" 2>&1)"
grep -qE '^ +ok +superpowers' <<<"$out" \
  || fail "T11d: an enabled plugin was misreported because a neighbour is disabled"

# T11e — a disabled plugin whose NAME merely contains the target must not be
# mistaken for the target itself.
plugin_stub '  ❯ notes@superpowers-marketplace
    Version: 1.0.0
    Scope: user
    Status: ✘ disabled'
out="$(env PATH="$bin:/usr/bin:/bin" MY_UTILS_TARGET_DIR="$tmp/skills" \
       MY_UTILS_CONFIG="$tmp/nope.config" bash "$ROOT/doctor.sh" 2>&1)"
grep -qE '^ +MISSING +superpowers' <<<"$out" \
  || fail "T11e: an unrelated plugin sharing the name string was read as superpowers"

# T11f — a config missing option ids is INCOMPLETE, not ok. Reporting ok here
# means every card move silently no-ops at runtime.
printf 'MY_UTILS_PROJECT_NUMBER=1\nMY_UTILS_PROJECT_ID=PVT_x\n' > "$tmp/partial.config"
cat > "$bin/gh" <<'G'
#!/usr/bin/env bash
exit 0
G
chmod +x "$bin/gh"
out="$(env PATH="$bin:/usr/bin:/bin" MY_UTILS_TARGET_DIR="$tmp/skills" \
       MY_UTILS_CONFIG="$tmp/partial.config" bash "$ROOT/doctor.sh" 2>&1)"
grep -qE '^ +ok +kanban' <<<"$out" && fail "T11f: reported ok on a config missing its option ids"

# T11g — doctor never fails, even on a hostile config
printf 'exit 3\n' > "$tmp/evil.config"
env PATH="$bin:/usr/bin:/bin" MY_UTILS_TARGET_DIR="$tmp/skills" \
    MY_UTILS_CONFIG="$tmp/evil.config" bash "$ROOT/doctor.sh" >/dev/null 2>&1 \
  || fail "T11g: a config containing 'exit 3' took doctor down"

echo "PASS"

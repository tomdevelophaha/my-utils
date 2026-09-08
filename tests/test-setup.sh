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

# The vendored dependency must actually exist; every tier's linus fallback and
# doctor.sh both assume it does.
[[ -d "$ROOT/vendor/skills/linus" ]] || { echo "FAIL: vendor/skills/linus is missing"; exit 1; }

src="$tmp/src"; vnd="$tmp/vendor"; tgt="$tmp/target"
mkdir -p "$src/skill-a" "$vnd/linus" "$tgt"
mkdir -p "$tgt/skill-b"   # real dir that must NOT be clobbered

run() { env MY_UTILS_SKILLS_DIR="$src" MY_UTILS_VENDOR_DIR="$vnd" \
        MY_UTILS_TARGET_DIR="$tgt" bash "$ROOT/setup.sh" "$@"; }

run
[[ -L "$tgt/skill-a" ]] || fail "skill-a not symlinked"
[[ -d "$tgt/skill-b" && ! -L "$tgt/skill-b" ]] || fail "skill-b clobbered"

# T1 — vendored skills reach the target too
[[ -L "$tgt/linus" ]] || fail "T1: vendored linus not symlinked"

run
[[ -L "$tgt/skill-a" ]] || fail "idempotency broke skill-a"

# T2 — a real vendored-name dir on the machine survives untouched
rm "$tgt/linus"; mkdir -p "$tgt/linus"; echo mine > "$tgt/linus/SKILL.md"
run
[[ -d "$tgt/linus" && ! -L "$tgt/linus" ]] || fail "T2: real linus clobbered"
[[ "$(cat "$tgt/linus/SKILL.md")" == mine ]] || fail "T2: real linus overwritten"

# T13 — a stale or repointed symlink is REPAIRED, not silently left dangling.
# Moving or re-cloning the repo must not quietly disconnect every skill.
ln -sfn "$tmp/gone/skill-a" "$tgt/skill-a"
run >/dev/null
[[ -e "$tgt/skill-a" ]] || fail "T13: dangling symlink not repaired — a moved repo stays broken"
[[ "$(readlink "$tgt/skill-a")" == "$src/skill-a" ]] || fail "T13: symlink not repointed at the current checkout"

# T14 — an unknown flag is rejected, never silently treated as a plain run
run --with-deeps >/dev/null 2>&1 && fail "T14: a typo'd flag exited 0, so a user believes deps were installed"

# T12 — the kanban helper is installed at a stable absolute path, because
# skills execute from the user's project directory, not from this repo.
helper="$tmp/home/.claude/my-utils/kanban.sh"
env MY_UTILS_SKILLS_DIR="$src" MY_UTILS_VENDOR_DIR="$vnd" \
    MY_UTILS_TARGET_DIR="$tgt" bash "$ROOT/setup.sh" >/dev/null
[[ -e "$helper" ]] || fail "T12: helper not installed at ~/.claude/my-utils/kanban.sh"
[[ -x "$helper" ]] || fail "T12: installed helper is not executable"
[[ -L "$helper" ]] || fail "T12: helper is not a symlink"
[[ "$(readlink "$helper")" == "$ROOT/bin/kanban.sh" ]] || fail "T12: helper points outside this checkout"
[[ -e "$tmp/home/.claude/my-utils/doctor.sh" ]] || fail "T12: doctor.sh not installed at an absolute path (skills reference it)"
( cd "$tmp" && "$helper" move "x" done ) || fail "T12: helper not runnable from another cwd"

# --- bootstrap stubs -------------------------------------------------------
bin="$tmp/bin"; mkdir -p "$bin"; log="$tmp/argv.log"
cat > "$bin/claude" <<STUB
#!/usr/bin/env bash
echo "claude \$*" >> "$log"
STUB
cat > "$bin/npx" <<STUB
#!/usr/bin/env bash
echo "npx \$*" >> "$log"
STUB
chmod +x "$bin/claude" "$bin/npx"

# T3 — the DEFAULT run installs nothing, asserted on behavior rather than on
# the absence of words. The old version stripped PATH so the install branches
# were unreachable, and passed even when with_deps ran on every invocation.
: > "$log"
env PATH="$bin:/usr/bin:/bin" MY_UTILS_SKILLS_DIR="$src" \
    MY_UTILS_VENDOR_DIR="$vnd" MY_UTILS_TARGET_DIR="$tgt" bash "$ROOT/setup.sh" >/dev/null
[[ ! -s "$log" ]] || fail "T3: the default run invoked an installer: $(cat "$log")"

# T5 — --with-deps issues the verified non-interactive commands
: > "$log"
env PATH="$bin:/usr/bin:/bin" MY_UTILS_SKILLS_DIR="$src" MY_UTILS_VENDOR_DIR="$vnd" \
    MY_UTILS_TARGET_DIR="$tgt" bash "$ROOT/setup.sh" --with-deps >/dev/null
grep -q -- 'plugin install superpowers@claude-plugins-official --yes' "$log" \
  || fail "T5: superpowers install command wrong or missing"
grep -q -- '@opengsd/gsd-core@latest --claude --global' "$log" \
  || fail "T5: gsd install command wrong or missing"
grep -q -- 'npx --yes' "$log" \
  || fail "T5: npx lacks --yes and will prompt, hanging a fresh-machine bootstrap"

# T4 — deps already present → --with-deps installs nothing
mkdir -p "$tgt/gsd-quick" "$tgt/superpowers"
: > "$log"
env PATH="$bin:/usr/bin:/bin" MY_UTILS_SKILLS_DIR="$src" MY_UTILS_VENDOR_DIR="$vnd" \
    MY_UTILS_TARGET_DIR="$tgt" bash "$ROOT/setup.sh" --with-deps >/dev/null
[[ ! -s "$log" ]] || fail "T4: reinstalled deps that were already present: $(cat "$log")"

# T5b — a disabled plugin is enabled, never reinstalled
cat > "$bin/claude" <<STUB
#!/usr/bin/env bash
echo "claude \$*" >> "$log"
[[ "\$*" == *"plugin list"* ]] && printf '  superpowers@claude-plugins-official\\n    Status: disabled\\n'
exit 0
STUB
chmod +x "$bin/claude"
rm -rf "$tgt/superpowers"
: > "$log"
env PATH="$bin:/usr/bin:/bin" MY_UTILS_SKILLS_DIR="$src" MY_UTILS_VENDOR_DIR="$vnd" \
    MY_UTILS_TARGET_DIR="$tgt" bash "$ROOT/setup.sh" --with-deps >/dev/null
grep -q 'plugin enable' "$log" || fail "T5b: did not enable the disabled plugin"
grep -q 'plugin install' "$log" && fail "T5b: reinstalled a plugin that was merely disabled"

# T5c — a plugin merely NAMED like superpowers is not superpowers. The old
# `grep -A3 -i superpowers` matched any line containing the word anywhere in the
# listing, so `notes@superpowers-marketplace` made --with-deps skip the install
# entirely. doctor.sh solved this already; setup.sh must give the same answer.
cat > "$bin/claude" <<STUB
#!/usr/bin/env bash
echo "claude \$*" >> "$log"
[[ "\$*" == *"plugin list"* ]] && printf '  notes@superpowers-marketplace\\n    Status: enabled\\n'
exit 0
STUB
chmod +x "$bin/claude"
rm -rf "$tgt/superpowers"
: > "$log"
env PATH="$bin:/usr/bin:/bin" MY_UTILS_SKILLS_DIR="$src" MY_UTILS_VENDOR_DIR="$vnd" \
    MY_UTILS_TARGET_DIR="$tgt" bash "$ROOT/setup.sh" --with-deps >/dev/null 2>&1
grep -q 'plugin install superpowers' "$log" \
  || fail "T5c: a plugin named *superpowers-marketplace was mistaken for superpowers itself"

# T5d — when the official install fails, the third-party marketplace is NOT added
# behind the user's back, and the real error is not swallowed. The failure can be
# a transient network blip, and `marketplace add` outlives the setup run.
cat > "$bin/claude" <<STUB
#!/usr/bin/env bash
echo "claude \$*" >> "$log"
case "\$*" in
  *"plugin list"*) exit 0 ;;
  *"install superpowers@claude-plugins-official"*) echo "error: network unreachable" >&2; exit 1 ;;
  *) exit 0 ;;
esac
STUB
chmod +x "$bin/claude"
: > "$log"
out="$(env PATH="$bin:/usr/bin:/bin" MY_UTILS_SKILLS_DIR="$src" MY_UTILS_VENDOR_DIR="$vnd" \
    MY_UTILS_TARGET_DIR="$tgt" bash "$ROOT/setup.sh" --with-deps 2>&1)"
grep -q 'marketplace add' "$log" \
  && fail "T5d: silently registered a third-party marketplace after a transient failure"
grep -qi 'network unreachable' <<<"$out" \
  || fail "T5d: swallowed the real install error, so the user cannot tell what failed"
grep -qi 'obra/superpowers-marketplace' <<<"$out" \
  || fail "T5d: did not name the third-party option it is declining to take"

# T5e — the fallback still exists, but only when explicitly asked for, and it says so
: > "$log"
out="$(env PATH="$bin:/usr/bin:/bin" MY_UTILS_SKILLS_DIR="$src" MY_UTILS_VENDOR_DIR="$vnd" \
    MY_UTILS_TARGET_DIR="$tgt" bash "$ROOT/setup.sh" --with-deps \
    --allow-third-party-marketplace 2>&1)"
grep -q 'marketplace add obra/superpowers-marketplace' "$log" \
  || fail "T5e: opting in did not reach the third-party marketplace"
grep -qi 'third-party' <<<"$out" \
  || fail "T5e: used a third-party source without saying so"

echo "PASS"

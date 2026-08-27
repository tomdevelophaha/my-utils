#!/usr/bin/env bash
set -euo pipefail

fail() { echo "FAIL: $*"; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

src="$tmp/src"; vnd="$tmp/vendor"; tgt="$tmp/target"
mkdir -p "$src/skill-a" "$vnd/linus" "$tgt"
mkdir -p "$tgt/skill-b"   # real dir that must NOT be clobbered

run() { MY_UTILS_SKILLS_DIR="$src" MY_UTILS_VENDOR_DIR="$vnd" \
        MY_UTILS_TARGET_DIR="$tgt" bash ./setup.sh "$@"; }

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

# T3 — the default run performs no network install, even with no tooling present
out="$(env PATH=/usr/bin:/bin MY_UTILS_SKILLS_DIR="$src" MY_UTILS_VENDOR_DIR="$vnd" \
        MY_UTILS_TARGET_DIR="$tgt" bash ./setup.sh 2>&1)" \
  || fail "T3: default run failed without npx/claude on PATH"
grep -qiE 'install|fetch|clon' <<<"$out" && fail "T3: default run attempted an install"

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

# T5 — --with-deps issues the verified non-interactive commands
: > "$log"
env PATH="$bin:/usr/bin:/bin" MY_UTILS_SKILLS_DIR="$src" MY_UTILS_VENDOR_DIR="$vnd" \
    MY_UTILS_TARGET_DIR="$tgt" bash ./setup.sh --with-deps >/dev/null
grep -q -- 'plugin install superpowers@claude-plugins-official --yes' "$log" \
  || fail "T5: superpowers install command wrong or missing"
grep -q -- '@opengsd/gsd-core@latest --claude --global' "$log" \
  || fail "T5: gsd install command wrong or missing"

# T4 — deps already present → --with-deps installs nothing
mkdir -p "$tgt/gsd-quick" "$tgt/superpowers"
: > "$log"
env PATH="$bin:/usr/bin:/bin" MY_UTILS_SKILLS_DIR="$src" MY_UTILS_VENDOR_DIR="$vnd" \
    MY_UTILS_TARGET_DIR="$tgt" bash ./setup.sh --with-deps >/dev/null
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
    MY_UTILS_TARGET_DIR="$tgt" bash ./setup.sh --with-deps >/dev/null
grep -q 'plugin enable' "$log" || fail "T5b: did not enable the disabled plugin"
grep -q 'plugin install' "$log" && fail "T5b: reinstalled a plugin that was merely disabled"

echo "PASS"

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

echo "PASS"

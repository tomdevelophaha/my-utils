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

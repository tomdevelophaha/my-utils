#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${MY_UTILS_SKILLS_DIR:-$ROOT/skills}"
VENDOR_DIR="${MY_UTILS_VENDOR_DIR:-$ROOT/vendor/skills}"
TARGET_DIR="${MY_UTILS_TARGET_DIR:-$HOME/.claude/skills}"

mkdir -p "$TARGET_DIR"

# Link both the skills authored here and the vendored third-party skills they
# depend on. Same rule for both: never clobber a real directory already sitting
# at the target name.
for skill in "$SOURCE_DIR"/*/ "$VENDOR_DIR"/*/; do
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

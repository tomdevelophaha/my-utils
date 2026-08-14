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

#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${MY_UTILS_SKILLS_DIR:-$ROOT/skills}"
VENDOR_DIR="${MY_UTILS_VENDOR_DIR:-$ROOT/vendor/skills}"
TARGET_DIR="${MY_UTILS_TARGET_DIR:-$HOME/.claude/skills}"
CONFIG="${MY_UTILS_CONFIG:-$HOME/.claude/my-utils.config}"

# Resolve this machine's GitHub Projects board once and write it to CONFIG, so
# no board id is ever baked into a skill. Kanban is optional: if anything here
# is unavailable the tiers simply skip their card steps.
configure() {
  local number="${1:-1}"
  if ! command -v gh >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    echo "configure: needs gh and jq on PATH" >&2; return 1
  fi
  gh auth status >/dev/null 2>&1 || { echo "configure: gh is not authenticated" >&2; return 1; }

  local project_id fields status_field
  project_id="$(gh project list --owner "@me" --format json \
    | jq -r --argjson n "$number" '.projects[] | select(.number == $n) | .id')"
  [[ -n "$project_id" ]] || { echo "configure: no project #$number for @me" >&2; return 1; }

  fields="$(gh project field-list "$number" --owner "@me" --format json)"
  status_field="$(jq -r '.fields[] | select(.name == "Status") | .id' <<<"$fields")"
  [[ -n "$status_field" ]] || { echo "configure: project #$number has no Status field" >&2; return 1; }

  opt() { jq -r --arg n "$1" \
    '.fields[] | select(.name == "Status") | .options[]? | select(.name == $n) | .id' <<<"$fields"; }

  mkdir -p "$(dirname "$CONFIG")"
  cat > "$CONFIG" <<CFG
# Written by setup.sh --configure. Per-machine; never committed.
MY_UTILS_PROJECT_NUMBER=$number
MY_UTILS_PROJECT_ID=$project_id
MY_UTILS_STATUS_FIELD=$status_field
MY_UTILS_OPT_IN_PROGRESS=$(opt "In Progress")
MY_UTILS_OPT_REVIEW=$(opt "Ready For Review")
MY_UTILS_OPT_DONE=$(opt "Done")
CFG
  echo "configured: $CONFIG (project #$number)"
}

# Install the dependencies that HAVE an upstream. Opt-in only: a plain
# ./setup.sh must never touch the network. Anything already present is left
# alone. A failed install is reported, not fatal — the skills degrade.
with_deps() {
  local sp_state=absent
  if [[ -d "$TARGET_DIR/superpowers" ]]; then
    sp_state=enabled
  elif command -v claude >/dev/null 2>&1; then
    sp_state="$(claude plugin list 2>/dev/null | grep -A3 -i superpowers || true)"
    if [[ -z "$sp_state" ]]; then sp_state=absent
    elif grep -qi disabled <<<"$sp_state"; then sp_state=disabled
    else sp_state=enabled; fi
  fi

  if [[ "$sp_state" == enabled ]]; then
    echo "present: superpowers"
  elif [[ "$sp_state" == disabled ]]; then
    # Installed but disabled ships no skills. Enable it; do not reinstall.
    echo "enabling: superpowers (installed but disabled)"
    claude plugin enable superpowers@claude-plugins-official 2>/dev/null \
      || echo "  failed — enable by hand: claude plugin enable superpowers@claude-plugins-official" >&2
  elif command -v claude >/dev/null 2>&1; then
    echo "installing: superpowers"
    claude plugin install superpowers@claude-plugins-official --yes 2>/dev/null \
      || { claude plugin marketplace add obra/superpowers-marketplace 2>/dev/null \
           && claude plugin install superpowers@superpowers-marketplace --yes 2>/dev/null; } \
      || echo "  failed — install by hand: claude plugin install superpowers@claude-plugins-official" >&2
  else
    echo "skipped: superpowers (no claude CLI on PATH)" >&2
  fi

  if compgen -G "$TARGET_DIR/gsd-*" >/dev/null; then
    echo "present: gsd-core"
  elif command -v npx >/dev/null 2>&1; then
    echo "installing: gsd-core"
    npx @opengsd/gsd-core@latest --claude --global \
      || echo "  failed — install by hand: npx @opengsd/gsd-core@latest --claude --global" >&2
  else
    echo "skipped: gsd-core (no npx on PATH)" >&2
  fi
}

case "${1:-}" in
  --configure) configure "${2:-1}"; exit $? ;;
esac

mkdir -p "$TARGET_DIR"

# Skills execute from the user's project directory, never from this repo, so
# they cannot reach the helper by a relative path. Install it at a stable
# absolute one every SKILL.md can name.
HELPER_DIR="${MY_UTILS_HELPER_DIR:-$HOME/.claude/my-utils}"
if [[ -f "$ROOT/bin/kanban.sh" ]]; then
  mkdir -p "$HELPER_DIR"
  if [[ -L "$HELPER_DIR/kanban.sh" || ! -e "$HELPER_DIR/kanban.sh" ]]; then
    ln -sfn "$ROOT/bin/kanban.sh" "$HELPER_DIR/kanban.sh"
  fi
fi

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

case "${1:-}" in
  --with-deps) with_deps ;;
esac

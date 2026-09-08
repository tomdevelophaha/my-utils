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
status_option() {   # $1 = field-list json, $2 = column name -> option id
  jq -r --arg n "$2" \
    '.fields[] | select(.name == "Status") | .options[]? | select(.name == $n) | .id' <<<"$1"
}

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

  local in_progress review done_id
  in_progress="$(status_option "$fields" "In Progress")"
  review="$(status_option "$fields" "Ready For Review")"
  done_id="$(status_option "$fields" "Done")"

  # Write nothing unless every id resolved. A config with an empty option id
  # makes the matching card move a silent no-op — worse than no config at all.
  local missing=""
  [[ -z "$in_progress" ]] && missing+=" 'In Progress'"
  [[ -z "$review" ]] && missing+=" 'Ready For Review'"
  [[ -z "$done_id" ]] && missing+=" 'Done'"
  if [[ -n "$missing" ]]; then
    echo "configure: project #$number has no Status column named:$missing" >&2
    echo "configure: rename the columns to match, or edit $CONFIG by hand" >&2
    return 1
  fi

  mkdir -p "$(dirname "$CONFIG")"
  cat > "$CONFIG.tmp" <<CFG
# Written by setup.sh --configure. Per-machine; never committed.
MY_UTILS_PROJECT_NUMBER=$number
MY_UTILS_PROJECT_ID=$project_id
MY_UTILS_STATUS_FIELD=$status_field
MY_UTILS_OPT_IN_PROGRESS=$in_progress
MY_UTILS_OPT_REVIEW=$review
MY_UTILS_OPT_DONE=$done_id
CFG
  mv "$CONFIG.tmp" "$CONFIG"
  echo "configured: $CONFIG (project #$number)"
}

# Install the dependencies that HAVE an upstream. Opt-in only: a plain
# ./setup.sh must never touch the network. Anything already present is left
# alone. A failed install is reported, not fatal — the skills degrade.
# Read the listing block by block and anchor on the name BEFORE the '@'. A fixed
# -A window around a grep for the name matches any plugin whose name merely
# contains it — `notes@superpowers-marketplace` was enough to make --with-deps
# skip installing superpowers entirely. doctor.sh:19-33 carries the same
# algorithm. They are kept honest by tests/test-setup.sh T5f, which feeds one
# fixture set to BOTH scripts and fails if their verdicts differ — per-suite tests
# cannot catch that, because each only ever exercises one of the two.
# The awk must not `exit`: setup.sh runs with -e and pipefail, so closing the pipe
# early kills the whole installer with SIGPIPE on any long listing.
plugin_state() {   # $1 = plugin name -> enabled | disabled | absent
  claude plugin list 2>/dev/null | awk -v want="$1" '
    /@/ && $0 !~ /^[[:space:]]*(Version|Scope|Status):/ {
      cur = 0
      for (i = 1; i <= NF; i++) {
        if (index($i, "@")) { split($i, p, "@"); cur = (p[1] == want); break }
      }
      next
    }
    !found && cur && /Status:/ {
      print (index($0, "disabled") ? "disabled" : "enabled"); found = 1
    }
    END { if (!found) print "absent" }'
}

with_deps() {
  local sp_state=absent
  if [[ -d "$TARGET_DIR/superpowers" ]]; then
    sp_state=enabled
  elif command -v claude >/dev/null 2>&1; then
    # `|| true`: a claude that is unauthenticated or too old exits non-zero here,
    # and under -e that would abort the installer over an OPTIONAL dependency.
    sp_state="$(plugin_state superpowers || true)"
  fi

  if [[ "$sp_state" == enabled ]]; then
    echo "present: superpowers"
  elif [[ "$sp_state" == disabled ]]; then
    # Installed but disabled ships no skills. Enable it; do not reinstall.
    echo "enabling: superpowers (installed but disabled)"
    claude plugin enable superpowers@claude-plugins-official \
      || echo "  failed — enable by hand: claude plugin enable superpowers@claude-plugins-official" >&2
  elif command -v claude >/dev/null 2>&1; then
    echo "installing: superpowers (source: claude-plugins-official)"
    # stderr is NOT suppressed: the reason the official install failed is the
    # only thing that tells a user whether to retry or to act. And the fallback
    # below is opt-in, because it registers a third-party plugin source that
    # outlives this run and the trigger here can be a transient network blip.
    if ! claude plugin install superpowers@claude-plugins-official --yes; then
      if [[ $ALLOW_THIRD_PARTY -eq 1 ]]; then
        echo "  official install failed — falling back to the third-party source obra/superpowers-marketplace (--allow-third-party-marketplace)" >&2
        claude plugin marketplace add obra/superpowers-marketplace \
          && claude plugin install superpowers@superpowers-marketplace --yes \
          || echo "  failed — install by hand: claude plugin install superpowers@claude-plugins-official" >&2
      else
        echo "  failed — retry, or install by hand: claude plugin install superpowers@claude-plugins-official" >&2
        echo "  a third-party source (obra/superpowers-marketplace) also publishes it; setup.sh will NOT register it unless you pass --allow-third-party-marketplace" >&2
      fi
    fi
  else
    echo "skipped: superpowers (no claude CLI on PATH)" >&2
  fi

  if compgen -G "$TARGET_DIR/gsd-*" >/dev/null; then
    echo "present: gsd-core"
  elif command -v npx >/dev/null 2>&1; then
    echo "installing: gsd-core"
    npx --yes @opengsd/gsd-core@latest --claude --global \
      || echo "  failed — install by hand: npx @opengsd/gsd-core@latest --claude --global" >&2
  else
    echo "skipped: gsd-core (no npx on PATH)" >&2
  fi
}

DO_CONFIGURE=0; DO_DEPS=0; PROJECT_ARG=1; ALLOW_THIRD_PARTY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --configure) DO_CONFIGURE=1; [[ "${2:-}" =~ ^[0-9]+$ ]] && { PROJECT_ARG="$2"; shift; } ;;
    --with-deps) DO_DEPS=1 ;;
    --allow-third-party-marketplace) ALLOW_THIRD_PARTY=1 ;;
    -h|--help)
      echo "usage: setup.sh [--with-deps [--allow-third-party-marketplace]] [--configure [project-number]]"; exit 0 ;;
    *)
      echo "setup.sh: unknown argument '$1'" >&2
      echo "usage: setup.sh [--with-deps [--allow-third-party-marketplace]] [--configure [project-number]]" >&2
      exit 2 ;;
  esac
  shift
done

if [[ $ALLOW_THIRD_PARTY -eq 1 && $DO_DEPS -eq 0 ]]; then
  echo "setup.sh: --allow-third-party-marketplace only modifies --with-deps" >&2
  echo "usage: setup.sh [--with-deps [--allow-third-party-marketplace]] [--configure [project-number]]" >&2
  exit 2
fi

mkdir -p "$TARGET_DIR"

# Skills execute from the user's project directory, never from this repo, so
# they cannot reach the helper by a relative path. Install it at a stable
# absolute one every SKILL.md can name.
HELPER_DIR="${MY_UTILS_HELPER_DIR:-$HOME/.claude/my-utils}"
if [[ -f "$ROOT/bin/kanban.sh" ]]; then
  mkdir -p "$HELPER_DIR"
  for h in kanban.sh doctor.sh; do
    src_h="$ROOT/bin/$h"; [[ "$h" == doctor.sh ]] && src_h="$ROOT/doctor.sh"
    [[ -f "$src_h" ]] || continue
    if [[ -L "$HELPER_DIR/$h" || ! -e "$HELPER_DIR/$h" ]]; then
      ln -sfn "$src_h" "$HELPER_DIR/$h"
    else
      echo "skip: $HELPER_DIR/$h already exists (not a symlink)" >&2
    fi
  done
fi

# Link both the skills authored here and the vendored third-party skills they
# depend on. Same rule for both: never clobber a real directory already sitting
# at the target name.
for skill in "$SOURCE_DIR"/*/ "$VENDOR_DIR"/*/; do
  skill="${skill%/}"
  name="$(basename "$skill")"
  link="$TARGET_DIR/$name"

  if [[ -L "$link" ]]; then
    # A symlink pointing somewhere else (moved or re-cloned repo) is repaired,
    # not skipped — otherwise every skill silently dangles after a move.
    [[ "$(readlink "$link")" == "$skill" ]] && continue
    ln -sfn "$skill" "$link"
    echo "relinked: $name"
    continue
  elif [[ -e "$link" ]]; then
    echo "skip: $link already exists (not a symlink)" >&2
    continue
  fi

  ln -s "$skill" "$link"
  echo "linked: $name"
done

[[ $DO_CONFIGURE -eq 1 ]] && { configure "$PROJECT_ARG" || exit $?; }
[[ $DO_DEPS -eq 1 ]] && with_deps
exit 0

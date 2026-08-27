#!/usr/bin/env bash
# What this machine has, and what it is missing. Reports only — never fails,
# never installs. Run it first on a new machine, or when a skill step behaved
# oddly and you want to know whether a dependency was actually there.
set -uo pipefail

TARGET_DIR="${MY_UTILS_TARGET_DIR:-$HOME/.claude/skills}"
CONFIG="${MY_UTILS_CONFIG:-$HOME/.claude/my-utils.config}"

ok()   { printf '  ok       %-14s %s\n' "$1" "${2:-}"; }
warn() { printf '  DISABLED %-14s %s\n' "$1" "$2"; }

# An installed-but-disabled plugin ships no skills — as unavailable as a missing
# one, but the fix is enable, not install.
#
# Read the listing block by block. A fixed -A window bleeds a neighbouring
# plugin's Status into the answer, and an unanchored name match reports
# `notes@superpowers-marketplace` as superpowers.
plugin_state() {   # $1 = plugin name -> enabled | disabled | absent
  claude plugin list 2>/dev/null | awk -v want="$1" '
    # A block header is the line carrying the name@marketplace token. Find that
    # token by scanning fields, so a leading marker glyph does not matter.
    /@/ && $0 !~ /^[[:space:]]*(Version|Scope|Status):/ {
      cur = 0
      for (i = 1; i <= NF; i++) {
        if (index($i, "@")) { split($i, p, "@"); cur = (p[1] == want); break }
      }
      next
    }
    cur && /Status:/ {
      print (index($0, "disabled") ? "disabled" : "enabled"); found = 1; exit
    }
    END { if (!found) print "absent" }'
}
miss() { printf '  MISSING  %-14s %s\n' "$1" "$2"; }
note() { printf '  optional %-14s %s\n' "$1" "$2"; }

echo "my-utils doctor"
echo
echo "Dependencies used inside the work tiers:"

if [[ -d "$TARGET_DIR/superpowers" ]]; then
  ok superpowers "brainstorming, TDD, executing-plans, systematic-debugging"
else
  case "$(plugin_state superpowers)" in
    enabled)  ok superpowers "brainstorming, TDD, executing-plans, systematic-debugging" ;;
    disabled) warn superpowers "installed but disabled — its skills are NOT available. Fix: claude plugin enable superpowers@claude-plugins-official" ;;
    *)        miss superpowers "run ./setup.sh --with-deps  (tiers fall back to their inline contracts)" ;;
  esac
fi

if compgen -G "$TARGET_DIR/gsd-*" >/dev/null 2>&1; then
  ok gsd "escalation targets: /gsd-debug, /gsd-quick, /gsd-plan-phase"
else
  miss gsd "run ./setup.sh --with-deps  (escalations STOP instead of handing off)"
fi

if [[ -e "$TARGET_DIR/linus" ]]; then
  ok linus "review gate"
else
  miss linus "run ./setup.sh  (vendored here; linking it is all that is needed)"
fi

echo
echo "Kanban (optional — every card step is skipped when absent):"
if [[ ! -f "$CONFIG" ]]; then
  miss kanban "no config — run ./setup.sh --configure to enable the board"
elif ! command -v gh >/dev/null 2>&1; then
  miss kanban "config present but gh is not on PATH"
elif ! gh auth status >/dev/null 2>&1; then
  miss kanban "gh is installed but not authenticated — run: gh auth login"
else
  # Read the config in a subshell: sourcing it here lets a stray line in a
  # hand-edited file take down a tool whose contract is that it never fails.
  cfg_vals="$( . "$CONFIG" >/dev/null 2>&1
    for v in MY_UTILS_PROJECT_NUMBER MY_UTILS_PROJECT_ID MY_UTILS_STATUS_FIELD \
             MY_UTILS_OPT_IN_PROGRESS MY_UTILS_OPT_REVIEW MY_UTILS_OPT_DONE; do
      printf '%s\n' "${!v:-}"
    done )" || cfg_vals=""
  IFS=$'\n' read -r -d '' c_num c_proj c_field c_prog c_rev c_done \
    <<<"$cfg_vals"$'\n' || true

  # All six or none: an empty option id makes the matching card move a silent
  # no-op, which looks exactly like success.
  missing=""
  [[ -z "${c_proj:-}" ]]  && missing+=" project-id"
  [[ -z "${c_field:-}" ]] && missing+=" status-field"
  [[ -z "${c_prog:-}" ]]  && missing+=" in-progress"
  [[ -z "${c_rev:-}" ]]   && missing+=" ready-for-review"
  [[ -z "${c_done:-}" ]]  && missing+=" done"
  if [[ -n "$missing" ]]; then
    miss kanban "config incomplete ($missing) — re-run ./setup.sh --configure"
  else
    ok kanban "project #${c_num:-?} ($c_proj)"
  fi
fi

echo
echo "Optional tooling:"
command -v gh  >/dev/null 2>&1 && ok gh "" || note gh "needed only for the Kanban card steps"
command -v jq  >/dev/null 2>&1 && ok jq "" || note jq "needed only for the Kanban card steps"
command -v graphify >/dev/null 2>&1 \
  && ok graphify "review scan set uses it when a graph exists" \
  || note graphify "reviews fall back to grep; nothing else changes"

echo
exit 0

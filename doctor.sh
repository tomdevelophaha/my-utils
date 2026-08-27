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
plugin_state() {   # $1 = plugin name -> enabled | disabled | absent
  local line
  line="$(claude plugin list 2>/dev/null | grep -A3 -i "$1" || true)"
  [[ -z "$line" ]] && { echo absent; return; }
  grep -qi disabled <<<"$line" && echo disabled || echo enabled
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
  # shellcheck source=/dev/null
  . "$CONFIG"
  ok kanban "project #${MY_UTILS_PROJECT_NUMBER:-?} (${MY_UTILS_PROJECT_ID:-unset})"
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

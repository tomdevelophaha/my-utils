#!/usr/bin/env bash
# Kanban card lifecycle for the my-utils work tiers.
#
# The board is OPTIONAL. No config file, no gh, no auth, or no matching card
# means this exits 0 silently and the tier carries on. Bookkeeping never gates
# work — every failure path here is a quiet success.
#
#   kanban.sh find-or-create "<title>" "<body>"   -> prints the item id, or nothing
#   kanban.sh move           "<title>" <column>   -> in-progress | review | done
set -euo pipefail

CONFIG="${MY_UTILS_CONFIG:-$HOME/.claude/my-utils.config}"

# Any missing precondition ends the run quietly.
[[ -f "$CONFIG" ]] || exit 0
# shellcheck source=/dev/null
. "$CONFIG"
command -v gh >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0
[[ -n "${MY_UTILS_PROJECT_ID:-}" && -n "${MY_UTILS_STATUS_FIELD:-}" ]] || exit 0
PROJECT_NUMBER="${MY_UTILS_PROJECT_NUMBER:-1}"

find_item() {   # $1 = title; prints the id of the first title match, or nothing
  gh project item-list "$PROJECT_NUMBER" --owner "@me" --format json 2>/dev/null \
    | jq -r --arg t "$1" '.items[]? | select(.title == $t) | .id' 2>/dev/null \
    | head -1
}

case "${1:-}" in
  find-or-create)
    title="${2:?title required}"; body="${3:-}"
    item="$(find_item "$title")" || true
    if [[ -z "$item" ]]; then
      if [[ -n "$body" ]]; then
        item="$(gh project item-create "$PROJECT_NUMBER" --owner "@me" \
                  --title "$title" --body "$body" --format json --jq .id 2>/dev/null)" || true
      else
        item="$(gh project item-create "$PROJECT_NUMBER" --owner "@me" \
                  --title "$title" --format json --jq .id 2>/dev/null)" || true
      fi
    fi
    [[ -n "$item" ]] && echo "$item"
    ;;
  move)
    title="${2:?title required}"; column="${3:?column required}"
    case "$column" in
      in-progress) option="${MY_UTILS_OPT_IN_PROGRESS:-}" ;;
      review)      option="${MY_UTILS_OPT_REVIEW:-}" ;;
      done)        option="${MY_UTILS_OPT_DONE:-}" ;;
      *)           exit 0 ;;
    esac
    [[ -n "$option" ]] || exit 0
    item="$(find_item "$title")" || true
    # No card by that title: nothing to move, and nothing to say about it.
    [[ -n "$item" ]] || exit 0
    gh project item-edit --id "$item" --project-id "$MY_UTILS_PROJECT_ID" \
      --field-id "$MY_UTILS_STATUS_FIELD" --single-select-option-id "$option" \
      >/dev/null 2>&1 || true
    ;;
  *)
    exit 0
    ;;
esac

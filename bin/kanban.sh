#!/usr/bin/env bash
# Kanban card lifecycle for the my-utils work tiers.
#
# The board is OPTIONAL and this script NEVER blocks its caller: every path
# exits 0, including when gh fails. Callers run it inside `set -e` blocks.
#
#   kanban.sh find-or-create "<title>" "<body>"   -> prints the item id on success
#   kanban.sh move           "<title>" <column>   -> in-progress | review | done
#
# Silence on stdout is not proof of success. When the board IS configured but
# the call failed, the reason goes to stderr, so a caller that needs to confirm
# a write (jot-down-task-github) can tell "no board here" from "the write
# failed" instead of guessing.
set -uo pipefail

CONFIG="${MY_UTILS_CONFIG:-$HOME/.claude/my-utils.config}"
LIMIT="${MY_UTILS_ITEM_LIMIT:-500}"

# Not configured is not an error, and never says anything.
[[ -f "$CONFIG" ]] || exit 0
# shellcheck source=/dev/null
. "$CONFIG" 2>/dev/null || exit 0
command -v gh >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0
[[ -n "${MY_UTILS_PROJECT_ID:-}" && -n "${MY_UTILS_STATUS_FIELD:-}" ]] || exit 0
PROJECT_NUMBER="${MY_UTILS_PROJECT_NUMBER:-1}"
OWNER="${MY_UTILS_OWNER:-@me}"

# Past this point the board IS configured, so a failure is worth reporting.
oops() { echo "kanban: $1" >&2; exit 0; }

items=""
# Load the board once. Distinguishing "the read failed" from "no such card" is
# the whole game: conflating them makes find-or-create duplicate a card on
# every transient error. --limit because the default page size is 30.
load_items() {
  items="$(gh project item-list "$PROJECT_NUMBER" --owner "$OWNER" \
             --limit "$LIMIT" --format json 2>/dev/null)" || return 1
  [[ -n "$items" ]] || return 1
  jq -e . >/dev/null 2>&1 <<<"$items" || return 1
}

# Exact title match wins. Falls back to a case-insensitive LITERAL substring,
# because the tiers fill "<task>" from a description that rarely matches a card
# byte for byte. Literal, not regex: a title containing ( [ + * used to make the
# old `test()` call throw.
find_item() {
  jq -r --arg t "$1" '
    [ .items[]? | select(.title == $t) ] as $exact
    | [ .items[]? | select(.title | ascii_downcase | contains($t | ascii_downcase)) ] as $loose
    | ( if ($exact | length) > 0 then $exact else $loose end )
    | .[0].id // empty' <<<"$items" 2>/dev/null
}

case "${1:-}" in
  find-or-create)
    title="${2:-}"; body="${3:-}"
    [[ -n "$title" ]] || exit 0
    load_items || oops "could not read the board (gh failed) — nothing was created"
    item="$(find_item "$title")"
    if [[ -z "$item" ]]; then
      if [[ -n "$body" ]]; then
        item="$(gh project item-create "$PROJECT_NUMBER" --owner "$OWNER" \
                  --title "$title" --body "$body" --format json --jq .id 2>/dev/null)" \
          || oops "creating the card failed"
      else
        item="$(gh project item-create "$PROJECT_NUMBER" --owner "$OWNER" \
                  --title "$title" --format json --jq .id 2>/dev/null)" \
          || oops "creating the card failed"
      fi
    fi
    [[ -n "$item" ]] || oops "the board returned no item id"
    echo "$item"
    exit 0
    ;;
  move)
    title="${2:-}"; column="${3:-}"
    [[ -n "$title" && -n "$column" ]] || exit 0
    case "$column" in
      in-progress) option="${MY_UTILS_OPT_IN_PROGRESS:-}" ;;
      review)      option="${MY_UTILS_OPT_REVIEW:-}" ;;
      done)        option="${MY_UTILS_OPT_DONE:-}" ;;
      *)           exit 0 ;;
    esac
    [[ -n "$option" ]] || oops "no column id for '$column' — re-run ./setup.sh --configure"
    load_items || oops "could not read the board (gh failed) — no card was moved"
    item="$(find_item "$title")"
    # No card by that title is normal at this tier, and says nothing.
    [[ -n "$item" ]] || exit 0
    gh project item-edit --id "$item" --project-id "$MY_UTILS_PROJECT_ID" \
      --field-id "$MY_UTILS_STATUS_FIELD" --single-select-option-id "$option" \
      >/dev/null 2>&1 || oops "moving the card to '$column' failed"
    exit 0
    ;;
esac
exit 0

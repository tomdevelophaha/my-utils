#!/usr/bin/env bash
# Sandbox guard: running a suite must never write into the real $HOME.
#
# setup.sh resolves TARGET_DIR (setup.sh:8), CONFIG (:9) and HELPER_DIR (:128)
# against $HOME; doctor.sh (:7, :8) and bin/kanban.sh (:16) do the same. A suite
# that leaves any of them at its default relinks the user's live ~/.claude/skills
# and ~/.claude/my-utils at whatever clone the suite ran from. Once this repo is
# public that is a working attack on anyone who runs the tests to vet a pull
# request: the PR's SKILL.md files become the reviewer's installed skills.
#
# Each suite closes this by exporting HOME once, near its mktemp — a property of
# the suite rather than something every call site must remember. This guard
# proves that property still holds.
set -uo pipefail
shopt -s nullglob

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

rc=0; count=0
for suite in "$ROOT"/tests/test-*.sh; do
  name="$(basename "$suite")"
  [[ "$name" == "test-sandbox.sh" ]] && continue   # never recurse into itself
  count=$((count + 1))
  canary="$tmp/$name-home"; mkdir -p "$canary"

  # MY_UTILS_* are unset for the run. Inherited from the caller they override the
  # very $HOME-derived defaults this guard polices, so a developer who has ever
  # exported one would get a green guard over a live escape.
  env -u MY_UTILS_TARGET_DIR -u MY_UTILS_CONFIG -u MY_UTILS_HELPER_DIR \
      -u MY_UTILS_SKILLS_DIR -u MY_UTILS_VENDOR_DIR \
      HOME="$canary" bash "$suite" >/dev/null 2>&1
  suite_rc=$?

  # A suite that dies before reaching its leaking line writes nothing and would
  # otherwise be scored clean — the vacuous pass this guard must never give.
  if [[ $suite_rc -ne 0 ]]; then
    echo "  $name did not complete (exit $suite_rc) — it cannot vouch for itself"
    rc=1
  fi

  # "canary unreadable" and "canary clean" must never look the same.
  if [[ ! -d "$canary" ]]; then
    echo "  $name destroyed its canary HOME — counted as a leak"
    rc=1; continue
  fi
  if ! leaked="$(find "$canary" -mindepth 1 2>/dev/null)"; then
    echo "  $name: canary HOME could not be read — counted as a leak"
    rc=1; continue
  fi
  if [[ -n "$leaked" ]]; then
    echo "  $name wrote into \$HOME:"
    while IFS= read -r line; do echo "    ${line//$canary/<HOME>}"; done <<<"$leaked"
    rc=1
  fi
done

# Exact, not a floor: a floor below the real count tolerates precisely the silent
# suite-drop it exists to catch. Bump this when a suite is added.
if [[ "$count" -ne 4 ]]; then
  echo "FAIL: $count suites checked, expected 4 — a suite was added, renamed, or lost"
  exit 1
fi
if [[ $rc -ne 0 ]]; then
  echo "FAIL: a suite could not be proven sandboxed — see the lines above"
  exit 1
fi
echo "PASS ($count suites checked)"

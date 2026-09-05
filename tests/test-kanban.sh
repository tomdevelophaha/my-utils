#!/usr/bin/env bash
set -euo pipefail

fail() { echo "FAIL: $*"; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
# HOME is sandboxed for the whole suite, not per call site: setup.sh, doctor.sh
# and bin/kanban.sh each derive paths from it, and an invocation that forgets one
# MY_UTILS_* override would otherwise reach the real ~/.claude.
export HOME="$tmp/home"; mkdir -p "$HOME"

bin="$tmp/bin"; mkdir -p "$bin"; log="$tmp/argv.log"
cfg="$tmp/my-utils.config"

stub_gh() {   # $1 = canned stdout for any invocation
  cat > "$bin/gh" <<STUB
#!/usr/bin/env bash
echo "gh \$*" >> "$log"
cat <<'OUT'
$1
OUT
STUB
  chmod +x "$bin/gh"
}

# T6 — no config and no gh: silent success, never blocks the tier
out="$(env PATH=/usr/bin:/bin MY_UTILS_CONFIG="$tmp/nonexistent" \
       bash "$ROOT/bin/kanban.sh" move "some task" in-progress 2>&1)" \
  || fail "T6: exited non-zero with no board configured"
[[ -z "$out" ]] || fail "T6: not silent, printed: $out"

# ...and configured but gh missing is also silent success
cat > "$cfg" <<CFG
MY_UTILS_PROJECT_NUMBER=1
MY_UTILS_PROJECT_ID=PVT_test
MY_UTILS_STATUS_FIELD=PVTSSF_test
MY_UTILS_OPT_IN_PROGRESS=aaa111
MY_UTILS_OPT_REVIEW=bbb222
MY_UTILS_OPT_DONE=ccc333
CFG
out="$(env PATH=/usr/bin:/bin MY_UTILS_CONFIG="$cfg" \
       bash "$ROOT/bin/kanban.sh" move "some task" done 2>&1)" \
  || fail "T6: exited non-zero when gh is absent"
[[ -z "$out" ]] || fail "T6: not silent without gh, printed: $out"

# T7 — configured and gh present: one item-edit carrying the right option id
: > "$log"
stub_gh '{"items":[{"id":"PVTI_abc","title":"some task"}]}'
env PATH="$bin:/usr/bin:/bin" MY_UTILS_CONFIG="$cfg" \
    bash "$ROOT/bin/kanban.sh" move "some task" review >/dev/null \
  || fail "T7: move failed with gh present"
grep -q 'project item-edit' "$log" || fail "T7: no item-edit issued"
grep -q -- '--id PVTI_abc' "$log" || fail "T7: wrong item id"
grep -q -- '--project-id PVT_test' "$log" || fail "T7: project id not threaded through"
grep -q -- '--field-id PVTSSF_test' "$log" || fail "T7: status field not threaded through"
grep -q -- '--single-select-option-id bbb222' "$log" || fail "T7: wrong column option id"
[[ "$(grep -c 'project item-edit' "$log")" == 1 ]] || fail "T7: more than one item-edit"

# T7b — a title with no matching card is a silent no-op for `move`
: > "$log"
stub_gh '{"items":[]}'
out="$(env PATH="$bin:/usr/bin:/bin" MY_UTILS_CONFIG="$cfg" \
       bash "$ROOT/bin/kanban.sh" move "absent task" done 2>&1)" \
  || fail "T7b: exited non-zero for an unmatched title"
[[ -z "$out" ]] || fail "T7b: not silent for an unmatched title: $out"
grep -q 'item-edit' "$log" && fail "T7b: edited a card that does not exist"

# T7c — find-or-create creates when absent, and returns the id when present
: > "$log"
stub_gh '{"items":[],"id":"PVTI_new"}'
env PATH="$bin:/usr/bin:/bin" MY_UTILS_CONFIG="$cfg" \
    bash "$ROOT/bin/kanban.sh" find-or-create "brand new" "why it matters" >/dev/null \
  || fail "T7c: find-or-create failed"
grep -q 'project item-create' "$log" || fail "T7c: did not create a missing card"
: > "$log"
stub_gh '{"items":[{"id":"PVTI_abc","title":"brand new"}]}'
env PATH="$bin:/usr/bin:/bin" MY_UTILS_CONFIG="$cfg" \
    bash "$ROOT/bin/kanban.sh" find-or-create "brand new" "why" >/dev/null
grep -q 'item-create' "$log" && fail "T7c: duplicated an existing card"

# T8 — setup.sh --configure resolves and writes every id
: > "$log"
cat > "$bin/gh" <<STUB
#!/usr/bin/env bash
echo "gh \$*" >> "$log"
case "\$*" in
  *"project list"*)  echo '{"projects":[{"number":1,"id":"PVT_resolved","title":"Board"}]}' ;;
  *"field-list"*)    echo '{"fields":[{"id":"PVTSSF_resolved","name":"Status","options":[{"id":"opt-todo","name":"Todo"},{"id":"opt-prog","name":"In Progress"},{"id":"opt-rev","name":"Ready For Review"},{"id":"opt-done","name":"Done"}]}]}' ;;
  *"auth status"*)   exit 0 ;;
esac
STUB
chmod +x "$bin/gh"
written="$tmp/written.config"
env PATH="$bin:/usr/bin:/bin" MY_UTILS_CONFIG="$written" \
    bash "$ROOT/setup.sh" --configure >/dev/null || fail "T8: --configure failed"
[[ -f "$written" ]] || fail "T8: no config written"
for k in MY_UTILS_PROJECT_ID=PVT_resolved \
         MY_UTILS_STATUS_FIELD=PVTSSF_resolved \
         MY_UTILS_OPT_IN_PROGRESS=opt-prog \
         MY_UTILS_OPT_REVIEW=opt-rev \
         MY_UTILS_OPT_DONE=opt-done; do
  grep -q "^$k\$" "$written" || fail "T8: missing or unresolved $k"
done

# --- gh present but FAILING (auth expiry, network, rate limit) ----------------
# The contract is "never block the tier", so this must still exit 0. But a read
# failure must NOT be mistaken for "no card" — that mistake creates duplicates.
cat > "$bin/gh" <<STUB
#!/usr/bin/env bash
echo "gh \$*" >> "$log"
echo "error: HTTP 401" >&2
exit 1
STUB
chmod +x "$bin/gh"

# T9 — a failing gh never aborts the caller, even under set -e
: > "$log"
env PATH="$bin:/usr/bin:/bin" MY_UTILS_CONFIG="$cfg" \
  bash -c 'set -e; "$1" find-or-create "t" "b" >/dev/null; echo CONTINUED' _ "$ROOT/bin/kanban.sh" \
  | grep -q CONTINUED || fail "T9: a failing gh aborted a caller using set -e"
env PATH="$bin:/usr/bin:/bin" MY_UTILS_CONFIG="$cfg" \
  bash -c 'set -e; "$1" move "t" done; echo CONTINUED' _ "$ROOT/bin/kanban.sh" \
  | grep -q CONTINUED || fail "T9: move aborted a caller using set -e"

# T10 — a READ failure must not fall through into creating a duplicate card
grep -q 'item-create' "$log" && fail "T10: created a card after the lookup failed — duplicates every transient error"

# T11 — a failing gh explains itself on stderr while staying silent on stdout,
# so jot-down can tell "no board" from "the write failed"
err="$(env PATH="$bin:/usr/bin:/bin" MY_UTILS_CONFIG="$cfg" \
       bash "$ROOT/bin/kanban.sh" find-or-create "t" "b" 2>&1 >/dev/null)"
[[ -n "$err" ]] || fail "T11: configured-but-failed is silent, indistinguishable from having no board"

# T12 — an empty title is a no-op, not a crash
for verb in 'move "" done' 'find-or-create "" "b"'; do
  out="$(eval env PATH=/usr/bin:/bin MY_UTILS_CONFIG=\"$cfg\" bash "$ROOT/bin/kanban.sh" $verb 2>&1)" \
    || fail "T12: '$verb' exited non-zero on an empty title"
  [[ -z "$out" ]] || fail "T12: '$verb' leaked output on an empty title: $out"
done

# T13 — the board is paged; a card past the default page must still be found
: > "$log"
big='{"items":['
for i in $(seq 1 40); do big+="{\"id\":\"PVTI_$i\",\"title\":\"card $i\"},"; done
big="${big%,}]}"
stub_gh "$big"
env PATH="$bin:/usr/bin:/bin" MY_UTILS_CONFIG="$cfg" \
    bash "$ROOT/bin/kanban.sh" move "card 38" done >/dev/null
grep -qE 'item-list.*--limit' "$log" || fail "T13: no --limit; cards past the default page size are invisible"

# T14 — find-or-create prints the bare item id, which jot-down depends on
: > "$log"
cat > "$bin/gh" <<STUB
#!/usr/bin/env bash
echo "gh \$*" >> "$log"
case "\$*" in
  *item-list*)   echo '{"items":[]}' ;;
  *item-create*) [[ "\$*" == *"--jq .id"* ]] && echo 'PVTI_created' || echo '{"id":"PVTI_created"}' ;;
esac
STUB
chmod +x "$bin/gh"
out="$(env PATH="$bin:/usr/bin:/bin" MY_UTILS_CONFIG="$cfg" \
       bash "$ROOT/bin/kanban.sh" find-or-create "brand new" "why")"
[[ "$out" == "PVTI_created" ]] || fail "T14: expected a bare item id, got '$out'"

# T15 — a config whose last line returns non-zero must not take the helper down
printf 'MY_UTILS_PROJECT_ID=PVT_test\nMY_UTILS_STATUS_FIELD=PVTSSF_test\nMY_UTILS_OPT_DONE=ccc333\nfalse\n' > "$tmp/bad.config"
env PATH=/usr/bin:/bin MY_UTILS_CONFIG="$tmp/bad.config" \
    bash "$ROOT/bin/kanban.sh" move "x" done || fail "T15: a non-zero line in the config took the helper down"

echo "PASS"

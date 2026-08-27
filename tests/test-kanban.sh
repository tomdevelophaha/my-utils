#!/usr/bin/env bash
set -euo pipefail

fail() { echo "FAIL: $*"; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

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

echo "PASS"

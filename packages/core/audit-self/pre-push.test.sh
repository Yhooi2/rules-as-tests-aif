#!/usr/bin/env bash
# packages/core/audit-self/pre-push.test.sh
# Paired-negative tests for .husky/pre-push §7 pa_check_trailer() and §9 s17_check_trailer() substance arms.
# Covers Wave 8.3 (§9 substance), Wave 8.4 (§7 substance), Wave 8.5 (historical-cutoff bypass).
# Mirrors audit-ai-docs.test.sh pattern.
# Usage: bash packages/core/audit-self/pre-push.test.sh
# Exit: 0 = all pass, 1 = at least one failure.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/../../../.husky/pre-push"
if [ -t 1 ]; then RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
else RED=''; GREEN=''; NC=''; fi
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1"; FAIL=$((FAIL+1)); }
TMPD=$(mktemp -d); trap 'rm -rf "$TMPD"' EXIT
# Mock git: returns $MOCK_BODY for `git show` calls; delegates everything else.
cat > "$TMPD/git" << 'EOF'
#!/usr/bin/env bash
if [ "$1" = "show" ]; then printf '%s' "$MOCK_BODY"; else command git "$@"; fi
EOF
chmod +x "$TMPD/git"; export PATH="$TMPD:$PATH"
# Source §9 and §7 functions from the hook.
eval "$(sed -n '/^  s17_is_discipline_introducing()/,/^  }/p; /^  s17_check_trailer()/,/^  }/p; /^  pa_check_trailer()/,/^  }/p' "$HOOK")"
GENERIC="§1.7: forward-check applied — Checked all rules, compliant. Backward-check — complete sweep performed."
CITATION="§1.7: forward-check: packages/core/principles/02-paired-negative-test.test.ts:82 mutation arm verified; backward: 0 new .md files"
BOOTSTRAP="§1.7 Bootstrap: introduces substance arm for §1.7 trailer with 2026-06-10 calibration window"
PA_SKIPPED="Prior-art: skipped — refactor only, no new capability"
PA_CITATION="Prior-art: prior-art-evaluations.md#38 (CodeRabbit, verdict DEFER — code-review focus, no overlap with capability-commit gate)"
# 1. Negative: generic stub without file:line → exit 2 (substance failure).
test_s17_substance_negative() {
  export MOCK_BODY="feat(test): dummy

$GENERIC"
  export S17_SUBSTANCE_WARN_ONLY=false
  local rc=0; s17_check_trailer "deadbeef00" >/dev/null 2>&1 || rc=$?
  unset S17_SUBSTANCE_WARN_ONLY
  [ "$rc" -eq 2 ] && pass "substance_negative (rc=2 on generic stub)" \
    || fail "substance_negative: expected rc=2, got $rc"
}
# 2. Positive: trailer with file:line citation → exit 0.
test_s17_substance_positive() {
  export MOCK_BODY="feat(test): dummy

$CITATION"
  export S17_SUBSTANCE_WARN_ONLY=false
  local rc=0; s17_check_trailer "deadbeef00" >/dev/null 2>&1 || rc=$?
  unset S17_SUBSTANCE_WARN_ONLY
  [ "$rc" -eq 0 ] && pass "substance_positive (rc=0 on cited trailer)" \
    || fail "substance_positive: expected rc=0, got $rc"
}
# 3. Bootstrap path unaffected by substance check.
test_s17_substance_bootstrap_unaffected() {
  export MOCK_BODY="feat(test): dummy

$BOOTSTRAP"
  export S17_SUBSTANCE_WARN_ONLY=false
  local rc=0; s17_check_trailer "deadbeef00" >/dev/null 2>&1 || rc=$?
  unset S17_SUBSTANCE_WARN_ONLY
  [ "$rc" -eq 0 ] && pass "substance_bootstrap_unaffected (rc=0 on Bootstrap:)" \
    || fail "substance_bootstrap_unaffected: expected rc=0, got $rc"
}
# 4. Warn-only default (S17_SUBSTANCE_WARN_ONLY unset): function still signals rc=2
# so the outer router can emit a warning without blocking push.
test_s17_substance_warn_only_default() {
  export MOCK_BODY="feat(test): dummy

$GENERIC"
  unset S17_SUBSTANCE_WARN_ONLY 2>/dev/null || true
  local rc=0; s17_check_trailer "deadbeef00" >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 2 ] && pass "substance_warn_only_default (rc=2; outer router warns only)" \
    || fail "substance_warn_only_default: expected rc=2, got $rc"
}
# §7 pa_check_trailer substance tests (Wave 8.4).
# 5. Negative: skipped escape-hatch in capability context → exit 2 (substance failure).
test_pa_substance_negative() {
  export MOCK_BODY="feat(test): dummy

$PA_SKIPPED"
  export PA_SUBSTANCE_WARN_ONLY=false
  local rc=0; pa_check_trailer "deadbeef00" >/dev/null 2>&1 || rc=$?
  unset PA_SUBSTANCE_WARN_ONLY
  [ "$rc" -eq 2 ] && pass "pa_substance_negative (rc=2 on skipped trailer in capability context)" \
    || fail "pa_substance_negative: expected rc=2, got $rc"
}
# 6. Positive: real SSOT citation → exit 0.
test_pa_substance_positive() {
  export MOCK_BODY="feat(test): dummy

$PA_CITATION"
  export PA_SUBSTANCE_WARN_ONLY=false
  local rc=0; pa_check_trailer "deadbeef00" >/dev/null 2>&1 || rc=$?
  unset PA_SUBSTANCE_WARN_ONLY
  [ "$rc" -eq 0 ] && pass "pa_substance_positive (rc=0 on SSOT-cited trailer)" \
    || fail "pa_substance_positive: expected rc=0, got $rc"
}
# 7. Non-capability commit: outer router skips pa_check_trailer entirely — no substance failure.
test_pa_substance_noncapability_unaffected() {
  export MOCK_BODY="feat(test): dummy

$PA_SKIPPED"
  export PA_SUBSTANCE_WARN_ONLY=false
  # Simulate non-capability: mock pa_detect_capability_reason to return 1.
  pa_detect_capability_reason() { return 1; }
  local failures="" reason="" err="" rc=0
  if reason=$(pa_detect_capability_reason "deadbeef00"); then
    err=$(pa_check_trailer "deadbeef00") || rc=$?
    [ "$rc" -ne 0 ] && failures="rc=$rc"
  fi
  unset PA_SUBSTANCE_WARN_ONLY
  unset -f pa_detect_capability_reason 2>/dev/null || true
  [ -z "$failures" ] && pass "pa_substance_noncapability_unaffected (outer skips check on non-cap)" \
    || fail "pa_substance_noncapability_unaffected: unexpected failure $failures"
}
# 8. Warn-only default (PA_SUBSTANCE_WARN_ONLY unset): function signals rc=2; outer router warns only.
test_pa_substance_warn_only_default() {
  export MOCK_BODY="feat(test): dummy

$PA_SKIPPED"
  unset PA_SUBSTANCE_WARN_ONLY 2>/dev/null || true
  local rc=0; pa_check_trailer "deadbeef00" >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 2 ] && pass "pa_substance_warn_only_default (rc=2; outer router warns only)" \
    || fail "pa_substance_warn_only_default: expected rc=2, got $rc"
}
# Wave 8.5 historical cutoff tests.
# 9. §9 s17_check_trailer: commit with author-date before S17_HISTORICAL_CUTOFF
# must return 0 regardless of trailer content (pre-Wave-8 history replay protection).
# MOCK_BODY starts with the date string so cut -d' ' -f1 extracts the ISO date.
test_s17_historical_cutoff() {
  export MOCK_BODY="2026-05-01 00:00:00 +0000"
  export S17_SUBSTANCE_WARN_ONLY=false
  local rc=0; s17_check_trailer "deadbeef00" >/dev/null 2>&1 || rc=$?
  unset S17_SUBSTANCE_WARN_ONLY
  unset MOCK_BODY
  [ "$rc" -eq 0 ] && pass "s17_historical_cutoff (rc=0 on pre-cutoff author-date)" \
    || fail "s17_historical_cutoff: expected rc=0, got $rc"
}
# Wave 9.4 body-prose §1.7 detection tests.
# 10. Negative (Case A): body has §1.7 in prose, no trailer line → exit 2 (substance failure).
test_s17_body_prose_negative() {
  export MOCK_BODY="feat(test): dummy

I performed §1.7 forward and backward checks per the rule."
  export S17_SUBSTANCE_WARN_ONLY=false
  local rc=0; s17_check_trailer "deadbeef00" >/dev/null 2>&1 || rc=$?
  unset S17_SUBSTANCE_WARN_ONLY
  [ "$rc" -eq 2 ] && pass "body_prose_negative (rc=2 on prose §1.7 without trailer)" \
    || fail "body_prose_negative: expected rc=2, got $rc"
}
# 11. Positive (Case B): body has prose §1.7 mention AND valid §1.7: trailer → exit 0.
test_s17_body_prose_positive() {
  export MOCK_BODY="feat(test): dummy

I performed §1.7 forward and backward checks per the rule.
§1.7: forward-check: packages/core/principles/02-paired-negative-test.test.ts:82 verified; backward: 0 new .md files"
  export S17_SUBSTANCE_WARN_ONLY=false
  local rc=0; s17_check_trailer "deadbeef00" >/dev/null 2>&1 || rc=$?
  unset S17_SUBSTANCE_WARN_ONLY
  [ "$rc" -eq 0 ] && pass "body_prose_positive (rc=0 on prose + valid trailer)" \
    || fail "body_prose_positive: expected rc=0, got $rc"
}
# 12. Bootstrap unaffected (Case C): body has prose §1.7 mention AND Bootstrap: line → exit 0.
test_s17_body_prose_bootstrap_unaffected() {
  export MOCK_BODY="feat(test): dummy

I performed §1.7 forward and backward checks per the rule.
§1.7 Bootstrap: introduces body-prose substance arm; B1 exemption — this is the discipline-bearing artifact"
  export S17_SUBSTANCE_WARN_ONLY=false
  local rc=0; s17_check_trailer "deadbeef00" >/dev/null 2>&1 || rc=$?
  unset S17_SUBSTANCE_WARN_ONLY
  [ "$rc" -eq 0 ] && pass "body_prose_bootstrap_unaffected (rc=0 on prose + Bootstrap:)" \
    || fail "body_prose_bootstrap_unaffected: expected rc=0, got $rc"
}
# 13. No §1.7 mention (Case D): body without §1.7 anywhere → exit 1 (current behavior preserved).
test_s17_body_prose_no_mention() {
  export MOCK_BODY="feat(test): dummy

This commit has no reference to the discipline check whatsoever."
  export S17_SUBSTANCE_WARN_ONLY=false
  local rc=0; s17_check_trailer "deadbeef00" >/dev/null 2>&1 || rc=$?
  unset S17_SUBSTANCE_WARN_ONLY
  [ "$rc" -eq 1 ] && pass "body_prose_no_mention (rc=1 on body without §1.7)" \
    || fail "body_prose_no_mention: expected rc=1, got $rc"
}
# Wave 9.4 refinement: §1.7 regex tightened with (^|[^/])§1\.7 to exclude URL/path
# embeddings. The discourse case stays caught; URL-only mentions no longer fire.
# 14. URL false-positive excluded: body with §1.7 only inside a URL path → exit 1
# (current behavior preserved — equivalent to "no §1.7 mention" since URL is not
# discourse).
test_s17_body_prose_url_excluded() {
  export MOCK_BODY="feat(test): dummy

See https://example.com/rules/§1.7-spec for the canonical definition."
  export S17_SUBSTANCE_WARN_ONLY=false
  local rc=0; s17_check_trailer "deadbeef00" >/dev/null 2>&1 || rc=$?
  unset S17_SUBSTANCE_WARN_ONLY
  [ "$rc" -eq 1 ] && pass "body_prose_url_excluded (rc=1 on §1.7 inside URL only)" \
    || fail "body_prose_url_excluded: expected rc=1, got $rc"
}
# 15. Punctuation-preceded §1.7 still caught: body with §1.7 after non-slash punctuation
# (e.g. period, parenthesis) still fires as theatre-shaped prose → exit 2.
test_s17_body_prose_punctuation_caught() {
  export MOCK_BODY="feat(test): dummy

Discipline applied.§1.7 forward and backward checks done."
  export S17_SUBSTANCE_WARN_ONLY=false
  local rc=0; s17_check_trailer "deadbeef00" >/dev/null 2>&1 || rc=$?
  unset S17_SUBSTANCE_WARN_ONLY
  [ "$rc" -eq 2 ] && pass "body_prose_punctuation_caught (rc=2 on §1.7 after non-slash punctuation)" \
    || fail "body_prose_punctuation_caught: expected rc=2, got $rc"
}
# 16. §7 pa_check_trailer: same mechanism — pre-cutoff commits bypass the Prior-art check.
test_pa_historical_cutoff() {
  export MOCK_BODY="2026-05-01 00:00:00 +0000"
  local rc=0; pa_check_trailer "deadbeef00" >/dev/null 2>&1 || rc=$?
  unset MOCK_BODY
  [ "$rc" -eq 0 ] && pass "pa_historical_cutoff (rc=0 on pre-cutoff author-date)" \
    || fail "pa_historical_cutoff: expected rc=0, got $rc"
}
echo "── Running §7+§9 substance + Wave 8.5 historical-cutoff tests ──"
test_s17_substance_negative
test_s17_substance_positive
test_s17_substance_bootstrap_unaffected
test_s17_substance_warn_only_default
test_pa_substance_negative
test_pa_substance_positive
test_pa_substance_noncapability_unaffected
test_pa_substance_warn_only_default
test_s17_historical_cutoff
test_s17_body_prose_negative
test_s17_body_prose_positive
test_s17_body_prose_bootstrap_unaffected
test_s17_body_prose_no_mention
test_s17_body_prose_url_excluded
test_s17_body_prose_punctuation_caught
test_pa_historical_cutoff
echo ""; echo "$PASS pass / $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1; exit 0

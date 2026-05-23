#!/usr/bin/env bash
# Behaviour test for the factual-claim scan added to .claude/hooks/end-of-turn-reminder.sh
# (spec: docs/meta-factory/research-patches/2026-05-21-autonomous-self-audit-triggering.md §11.1).
#
# Independence: the canonical hook at $REPO_ROOT/.claude/hooks/end-of-turn-reminder.sh is
# the single source of truth — exercised through a subprocess against synthetic transcript
# fixtures in an isolated tmpdir. No inlined logic copy.
#
# Sub-tests:
#   1. positive numeric        — short turn "поправил 4 files" → fires, reason enumerates "4 files"
#   2. positive file:line      — "foo.ts:42" → fires, reason enumerates "foo.ts:42"
#   3. positive neg-existence  — "no production tool exists" → fires, reason enumerates it
#   4. negative (silent)       — short, no claim, no question → exit 0, empty stdout
#   5. valid JSON              — every fire emits jq-parseable JSON with decision=block
#   6. mutation                — break the numeric regex → sub-test 1 must STOP enumerating (kills test)
#
# CI: invoked from .github/workflows/audit-self.yml.

set -uo pipefail

REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
HOOK_FILE="${EOT_HOOK_FILE:-$REPO_ROOT/.claude/hooks/end-of-turn-reminder.sh}"

PASS=0
FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ✓ $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  ✗ $1"; }

# make_transcript <text>  → echoes path to a JSONL transcript whose last assistant
# message carries <text>. Built with jq so arbitrary text is safely escaped.
make_transcript() {
  local text="$1" dir
  dir=$(mktemp -d)
  jq -cn '{type:"user",message:{content:"test goal anchor"}}'                 >  "$dir/t.jsonl"
  jq -cn --arg t "$text" '{type:"assistant",message:{content:[{type:"text",text:$t}]}}' >> "$dir/t.jsonl"
  echo "$dir/t.jsonl"
}

# run_hook <hook> <transcript>  → echoes hook stdout (exit code not propagated across
# command substitution; sub-test 4 captures rc inline where it needs it).
run_hook() {
  local hook="$1" tr="$2" stdin
  stdin=$(jq -cn --arg p "$tr" '{stop_hook_active:false, transcript_path:$p}')
  printf '%s' "$stdin" | bash "$hook" 2>/dev/null
}

echo "eot-claim-scan.test.sh"

# ── 1. positive numeric ──────────────────────────────────────────────────────
tr=$(make_transcript "готово, поправил 4 files")
out=$(run_hook "$HOOK_FILE" "$tr")
reason=$(printf '%s' "$out" | jq -r '.reason // ""' 2>/dev/null)
if printf '%s' "$reason" | grep -qiE '4 files'; then ok "numeric claim enumerated on short turn"; else bad "numeric claim NOT enumerated (out: ${out:0:80})"; fi

# ── 2. positive file:line ────────────────────────────────────────────────────
tr=$(make_transcript "смотри foo.ts:42 там всё")
out=$(run_hook "$HOOK_FILE" "$tr")
reason=$(printf '%s' "$out" | jq -r '.reason // ""' 2>/dev/null)
if printf '%s' "$reason" | grep -qiE 'foo\.ts:42'; then ok "file:line citation enumerated"; else bad "file:line NOT enumerated (out: ${out:0:80})"; fi

# ── 3. positive negative-existence ───────────────────────────────────────────
tr=$(make_transcript "выяснил: no production tool exists for this")
out=$(run_hook "$HOOK_FILE" "$tr")
reason=$(printf '%s' "$out" | jq -r '.reason // ""' 2>/dev/null)
if printf '%s' "$reason" | grep -qiE 'negative-existence'; then ok "negative-existence claim enumerated"; else bad "negative-existence NOT enumerated (out: ${out:0:80})"; fi

# ── 4. negative (silent on a claim-free short turn) — capture rc inline ──────
tr=$(make_transcript "готово, поправил конфиг")
stdin=$(jq -cn --arg p "$tr" '{stop_hook_active:false, transcript_path:$p}')
out=$(printf '%s' "$stdin" | bash "$HOOK_FILE" 2>/dev/null); rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then ok "claim-free short turn stays silent"; else bad "fired on a claim-free short turn (rc=$rc out: ${out:0:80})"; fi

# ── 5. valid JSON on fire ────────────────────────────────────────────────────
tr=$(make_transcript "поправил 10 tests")
out=$(run_hook "$HOOK_FILE" "$tr")
if printf '%s' "$out" | jq -e '.decision=="block" and (.reason|length>0)' >/dev/null 2>&1; then ok "fire emits valid block JSON with non-empty reason"; else bad "fire JSON invalid/incomplete (out: ${out:0:80})"; fi

# ── 6. mutation — break the count-noun alternation; sub-test 1 must FAIL to enum ──
mut=$(mktemp)
# Drop "files?|tests?|cases?" from the count-noun alternation so the numeric pattern
# can no longer match "4 files". Shape-robust: targets the noun list, not the full
# regex (survives the recall/precision rewrite that changed the number-prefix shape).
sed -E "s/files\?\|tests\?\|cases\?/ZZZ_NO_MATCH_ZZZ/" "$HOOK_FILE" > "$mut"
if ! grep -q 'ZZZ_NO_MATCH_ZZZ' "$mut"; then
  bad "mutation sed did not apply (regex shape changed?) — review test"
else
  tr=$(make_transcript "готово, поправил 4 files")
  out=$(run_hook "$mut" "$tr")
  reason=$(printf '%s' "$out" | jq -r '.reason // ""' 2>/dev/null)
  if printf '%s' "$reason" | grep -qiE '4 files'; then bad "MUTATION SURVIVED — numeric regex broken but '4 files' still enumerated (test has no substance)"; else ok "mutation killed — broken numeric regex stops enumeration"; fi
fi
rm -f "$mut"

# ── 7. RECALL — numeric claim with intervening tokens ("6 discipline rules") ──
# Q-E4 fix: v1 regex required adjacency and MISSED this (empirical-patch §6.4).
tr=$(make_transcript "готово, поправил 6 discipline rules в проекте")
out=$(run_hook "$HOOK_FILE" "$tr")
reason=$(printf '%s' "$out" | jq -r '.reason // ""' 2>/dev/null)
if printf '%s' "$reason" | grep -qiE '6 discipline rules'; then ok "recall: intervening-token numeric claim enumerated"; else bad "recall MISS: '6 discipline rules' not enumerated (out: ${out:0:80})"; fi

# ── 8. PRECISION — number inside a fenced code block (drafted prompt) is IGNORED ─
tr=$(make_transcript "$(printf 'Итоговая строка без цифр.\n```\nNew session: touch 9 files and run 3 tests\n```\nготово')")
stdin=$(jq -cn --arg p "$tr" '{stop_hook_active:false, transcript_path:$p}')
out=$(printf '%s' "$stdin" | bash "$HOOK_FILE" 2>/dev/null); rc=$?
if printf '%s' "$out" | grep -qiE '9 files|3 tests'; then bad "precision: fenced-code number wrongly enumerated (out: ${out:0:80})"; else ok "precision: fenced-code numbers ignored"; fi

# ── 9. PRECISION — file:line inside a markdown link TARGET is IGNORED ──────────
tr=$(make_transcript "детали см. [the plan](docs/meta-factory/EXECUTION-PLAN.md:45) дальше")
out=$(run_hook "$HOOK_FILE" "$tr")
reason=$(printf '%s' "$out" | jq -r '.reason // ""' 2>/dev/null)
if printf '%s' "$reason" | grep -qiE 'EXECUTION-PLAN\.md:45'; then bad "precision: markdown link-target citation wrongly enumerated"; else ok "precision: markdown link-target citation ignored"; fi

# ── 10. MAJOR-2a: idle-suppression fires — turn N produced ## 🟢, turn N+1 is same question ──
# Turn N: assistant produced a "## 🟢" recap block.
# Turn N+1 (current): short question-only, same content as in previous turn → should be SUPPRESSED.
{
  dir=$(mktemp -d)
  prev_question="Хочешь ли продолжить?"
  jq -cn '{type:"user",message:{content:"test anchor"}}' > "$dir/t.jsonl"
  # Turn N: previous assistant with ## 🟢 recap + the same question text embedded
  jq -cn --arg t "$(printf '## 🟢 Простыми словами\nПредыдущий пересказ.\nХочешь ли продолжить?')" \
    '{type:"assistant",message:{content:[{type:"text",text:$t}]}}' >> "$dir/t.jsonl"
  # Turn N+1 (last): short question, same text
  jq -cn --arg t "$prev_question" \
    '{type:"assistant",message:{content:[{type:"text",text:$t}]}}' >> "$dir/t.jsonl"
  stdin=$(jq -cn --arg p "$dir/t.jsonl" '{stop_hook_active:false, transcript_path:$p}')
  out=$(printf '%s' "$stdin" | bash "$HOOK_FILE" 2>/dev/null); rc=$?
  if [ "$rc" -eq 0 ] && [ -z "$out" ]; then ok "MAJOR-2a: idle-suppression suppresses repeat question after ## 🟢 recap"; else bad "MAJOR-2a: idle-suppression did NOT suppress repeat question (rc=$rc out: ${out:0:80})"; fi
}

# ── 11. MAJOR-2b: idle-suppression does NOT fire — turn N+1 is a genuinely NEW question ──
# Turn N: assistant produced "## 🟢" recap.
# Turn N+1 (current): NEW question never seen in previous turn → must NOT be suppressed.
{
  dir=$(mktemp -d)
  jq -cn '{type:"user",message:{content:"test anchor"}}' > "$dir/t.jsonl"
  # Turn N: previous assistant with ## 🟢 recap (no mention of the new question)
  jq -cn --arg t "$(printf '## 🟢 Простыми словами\nПредыдущий пересказ про файл X.')" \
    '{type:"assistant",message:{content:[{type:"text",text:$t}]}}' >> "$dir/t.jsonl"
  # Turn N+1 (last): genuinely new question about something different
  jq -cn --arg t "$(printf 'Совершенно новый вопрос: что делать с веткой Y?')" \
    '{type:"assistant",message:{content:[{type:"text",text:$t}]}}' >> "$dir/t.jsonl"
  out=$(run_hook "$HOOK_FILE" "$dir/t.jsonl")
  if [ -n "$out" ] && printf '%s' "$out" | jq -e '.decision=="block"' >/dev/null 2>&1; then ok "MAJOR-2b: idle-suppression does NOT suppress a genuinely new question"; else bad "MAJOR-2b: idle-suppression wrongly suppressed a new question (out: ${out:0:80})"; fi
}

# ── 12. MAJOR-2c: glance-line — systemMessage carries 🎯 anchor and claim count ──
{
  tr=$(make_transcript "поправил 4 files в проекте")
  out=$(run_hook "$HOOK_FILE" "$tr")
  sys_msg=$(printf '%s' "$out" | jq -r '.systemMessage // ""' 2>/dev/null)
  if printf '%s' "$sys_msg" | grep -qE '^(🎯|\xF0\x9F\x8E\xAF)'; then ok "MAJOR-2c: systemMessage starts with 🎯 glance anchor"; else bad "MAJOR-2c: systemMessage missing 🎯 prefix (msg: ${sys_msg:0:80})"; fi
  if printf '%s' "$sys_msg" | grep -qE '[0-9]+ факт'; then ok "MAJOR-2c: systemMessage includes claim count when claims present"; else bad "MAJOR-2c: claim count missing from systemMessage (msg: ${sys_msg:0:80})"; fi
}

# ── 13. MAJOR-2d: glance-line — no claim count when no claims ──
{
  tr=$(make_transcript "готово, поправил конфиг — всё ок, вопросов нет")
  # This is a short claim-free turn with no question — should be silent (exit 0)
  stdin=$(jq -cn --arg p "$tr" '{stop_hook_active:false, transcript_path:$p}')
  out=$(printf '%s' "$stdin" | bash "$HOOK_FILE" 2>/dev/null); rc=$?
  if [ "$rc" -eq 0 ] && [ -z "$out" ]; then ok "MAJOR-2d: claim-free turn stays silent (no glance-line test needed — hook silent)"; else
    sys_msg=$(printf '%s' "$out" | jq -r '.systemMessage // ""' 2>/dev/null)
    if printf '%s' "$sys_msg" | grep -qE 'факт'; then bad "MAJOR-2d: claim count in systemMessage on claim-free turn (msg: ${sys_msg:0:80})"; else ok "MAJOR-2d: no claim count in systemMessage on claim-free turn"; fi
  fi
}

# ── 14. B2: AskUserQuestion-only turn after ## 🟢 recap must NOT be suppressed ──
# B2 fix: idle-suppression must short-circuit when text is empty (tool-only turn).
# A model firing AskUserQuestion with no text block is a NEW question — never idle repeat.
{
  dir=$(mktemp -d)
  jq -cn '{type:"user",message:{content:"test anchor"}}' > "$dir/t.jsonl"
  # Turn N: previous assistant with ## 🟢 recap
  jq -cn --arg t "$(printf '## 🟢 Простыми словами\nПредыдущий пересказ.')" \
    '{type:"assistant",message:{content:[{type:"text",text:$t}]}}' >> "$dir/t.jsonl"
  # Turn N+1 (last): AskUserQuestion tool-only, empty text block — must FIRE (not suppressed)
  jq -cn '{type:"assistant",message:{content:[{type:"tool_use",id:"toolu_1",name:"AskUserQuestion",input:{question:"Продолжить?"}}]}}' >> "$dir/t.jsonl"
  stdin=$(jq -cn --arg p "$dir/t.jsonl" '{stop_hook_active:false, transcript_path:$p}')
  out=$(printf '%s' "$stdin" | bash "$HOOK_FILE" 2>/dev/null); rc=$?
  if [ -n "$out" ] && printf '%s' "$out" | jq -e '.decision=="block"' >/dev/null 2>&1; then ok "B2: AskUserQuestion-only turn after ## 🟢 fires (not suppressed)"; else bad "B2: AskUserQuestion-only turn was wrongly suppressed (rc=$rc out: ${out:0:80})"; fi
}

echo "── eot-claim-scan: $PASS passed, $FAIL failed ──"
[ "$FAIL" -eq 0 ]

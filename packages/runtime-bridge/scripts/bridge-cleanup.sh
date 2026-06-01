#!/usr/bin/env bash
# bridge-cleanup.sh — nuke the test/probe junk the bridge accrues each session.
#
# WHY (qloop-ux-probe 2026-06-01): probe/smoke runs leave orphan aif tasks,
# /tmp ManualBackend kickoffs, and dedup-store cruft behind every session. This
# is the one-command sweep so it stops piling up. It deletes ONLY clearly-test
# artefacts (title matches the test allowlist); real work is never touched.
#
# Targets (all opt-out via flags):
#   - aif tasks whose title matches the TEST allowlist (UXPROBE / smoke / probe)
#   - /tmp/runtime-bridge-*.md  (ManualBackend kickoffs) older than KEEP_DAYS
#   - /tmp/runtime-bridge-dedup.jsonl.bak-*  (manual backups)
#
# It does NOT touch: the live dedup store, any container git state (a container
# stash is REPORTED, never dropped — that is the operator's git), real tasks.
#
# Usage: bash bridge-cleanup.sh [--dry-run]
set -uo pipefail

AIF_URL="${RUNTIME_BRIDGE_AIF_URL:-http://localhost:3009}"
# Title regex for DELETABLE test tasks. Extend via env for new probe prefixes.
TEST_TASK_RE="${RUNTIME_BRIDGE_TEST_TASK_RE:-^UXPROBE:|^qloop-ux-probe$|runtime-bridge-smoke|^PROBE:}"
KEEP_DAYS="${RUNTIME_BRIDGE_KEEP_DAYS:-1}"
DRY=0; [[ "${1:-}" == "--dry-run" ]] && DRY=1

note() { printf '  %s\n' "$*"; }
act()  { if [[ "$DRY" -eq 1 ]]; then printf '  [dry-run] would %s\n' "$*"; else printf '  %s\n' "$*"; fi; }

printf '=== bridge-cleanup%s ===\n' "$([[ $DRY -eq 1 ]] && echo ' (dry-run)')"

# ── 1. Delete test/probe aif tasks ───────────────────────────────────────────
printf '\n-- aif test tasks (title ~ /%s/) --\n' "$TEST_TASK_RE"
ids=$(curl -s -m6 "$AIF_URL/tasks" 2>/dev/null \
  | TEST_RE="$TEST_TASK_RE" python3 -c 'import sys,json,os,re
rx=re.compile(os.environ["TEST_RE"])
try: ts=json.load(sys.stdin)
except Exception: ts=[]
[print(t["id"]) for t in ts if rx.search(t.get("title","") or "")]' 2>/dev/null)
if [[ -z "$ids" ]]; then
  note "none"
else
  for id in $ids; do
    if [[ "$DRY" -eq 1 ]]; then act "DELETE task $id"; else
      code=$(curl -s -m6 -o /dev/null -w '%{http_code}' -X DELETE "$AIF_URL/tasks/$id")
      printf '  deleted %s → HTTP %s\n' "$id" "$code"
    fi
  done
fi

# ── 2. Old /tmp ManualBackend kickoffs + dedup backups ───────────────────────
printf '\n-- /tmp bridge files (older than %s day(s)) --\n' "$KEEP_DAYS"
found=0
while IFS= read -r f; do
  found=1; act "rm $f"; [[ "$DRY" -eq 0 ]] && rm -f "$f"
done < <(find /tmp -maxdepth 1 -name 'runtime-bridge-*.md' -mtime "+$KEEP_DAYS" 2>/dev/null)
while IFS= read -r f; do
  found=1; act "rm $f"; [[ "$DRY" -eq 0 ]] && rm -f "$f"
done < <(find /tmp -maxdepth 1 -name 'runtime-bridge-dedup.jsonl.bak-*' 2>/dev/null)
[[ "$found" -eq 0 ]] && note "none"

# ── 3. Report container stash (NOT dropped — operator's git) ─────────────────
printf '\n-- container stash (reported, never auto-dropped) --\n'
agent="$(docker ps --filter 'name=agent' --format '{{.Names}}' 2>/dev/null | grep -i aif | head -1)"
if [[ -n "$agent" ]]; then
  st="$(docker exec "$agent" sh -c 'cd /home/www/rules-as-tests-aif && git stash list' 2>/dev/null)"
  if [[ -n "$st" ]]; then
    printf '%s\n' "$st" | sed 's/^/    /'
    note "→ drop yourself if superseded: docker exec $agent sh -c 'cd /home/www/rules-as-tests-aif && git stash drop'"
  else note "none"; fi
else note "no agent container"; fi

printf '\n=== done ===\n'

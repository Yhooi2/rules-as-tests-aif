#!/usr/bin/env bash
# Test: setup.d/companions.manifest parses as a TAB-delimited 4-field table.
# Tab (not pipe) per kickoff §4 T-OCI-A: detect_cmd rows contain inner pipes,
# so -F'|' splitting contradicts the manifest's own rows (NF=5 on superpowers).
set -uo pipefail
REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
MANIFEST="$REPO_ROOT/setup.d/companions.manifest"
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ✓ $1"; }
bad() { FAIL=$((FAIL+1)); echo "  ✗ $1"; }

[ -f "$MANIFEST" ] && ok "manifest exists" || bad "manifest missing"
# Every non-comment line has exactly 4 TAB-delimited fields
awk -F'\t' '!/^#/ && NF && NF!=4 {bad=1} END{exit bad}' "$MANIFEST" && ok "all rows have 4 fields" || bad "a row does not have 4 fields"
# Superpowers row present (portable: GNU grep treats \t in -E pattern as literal 't')
awk -F'\t' '$1=="superpowers"{f=1} END{exit !f}' "$MANIFEST" && ok "superpowers row present" || bad "no superpowers row"
# No version pins (no '@x.y.z' style) in install commands
grep -qE '@[0-9]+\.[0-9]+' "$MANIFEST" && bad "manifest pins a version" || ok "no version pin"

echo ""; echo "PASS=$PASS FAIL=$FAIL"; [ "$FAIL" -eq 0 ]

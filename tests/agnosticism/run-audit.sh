#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
export RECORD_FILE="$REPO_ROOT/tests/agnosticism/conformance-record.tsv"
: > "$RECORD_FILE"
printf 'surface\tprobe\tcmd\texit\tverdict\n' >> "$RECORD_FILE"
for p in "$REPO_ROOT"/tests/agnosticism/probes/*.sh; do bash "$p"; done
echo "── conformance record ──"; column -t -s$'\t' "$RECORD_FILE"
echo ""; echo "── non-PORTABLE findings (deterministic half) ──"
grep -vE '\tPORTABLE$' "$RECORD_FILE" | grep -v '^surface' || echo "(none)"

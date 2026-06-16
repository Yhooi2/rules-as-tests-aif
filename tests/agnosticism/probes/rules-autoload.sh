#!/usr/bin/env bash
# Surface 7 — off-CC there is no .claude/rules auto-load. Record the count a portable consumer must
# read manually = the degradation magnitude (a DEGRADED finding, with the number as evidence).
set -uo pipefail
REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
source "$REPO_ROOT/tests/agnosticism/_cc-absent-lib.sh"

n=$(find "$REPO_ROOT/.claude/rules" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
record rules-autoload manual-read-burden "count .claude/rules/*.md" 0 "DEGRADED:${n}-rules"

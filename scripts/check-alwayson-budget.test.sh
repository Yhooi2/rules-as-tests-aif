#!/usr/bin/env bash
# Test the drift-guard: under ceiling → exit 0; over → exit 1.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# Huge ceiling → must pass (exit 0)
AIF_ALWAYSON_CEILING=999999999 "$DIR/check-alwayson-budget.sh" >/dev/null 2>&1 || { echo "FAIL: under-ceiling should exit 0"; exit 1; }
# Zero ceiling → must fail (exit 1)
if AIF_ALWAYSON_CEILING=0 "$DIR/check-alwayson-budget.sh" >/dev/null 2>&1; then echo "FAIL: over-ceiling should exit 1"; exit 1; fi
echo "PASS"

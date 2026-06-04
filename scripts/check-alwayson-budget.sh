#!/usr/bin/env bash
# Standing drift-guard: fail if the always-on context baseline exceeds the ceiling set by
# C1-Audit. Keeps the cleaned surface from re-bloating after the umbrella closes.
# Ceiling source: $AIF_ALWAYSON_CEILING (env) — wired into pre-push by a C1-I fix once the
# real ceiling is known. Deterministic; no paid LLM (no-paid-llm-in-ci.md).
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
CEILING="${AIF_ALWAYSON_CEILING:-200000}"   # placeholder default; C1-Audit sets the real value
total="$("$DIR/measure-always-on.sh" | jq -r '.total_bytes')"
if (( total > CEILING )); then
  echo "DRIFT: always-on context ${total}B exceeds ceiling ${CEILING}B" >&2
  exit 1
fi
echo "OK: always-on ${total}B within ceiling ${CEILING}B"

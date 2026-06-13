#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ✓ $1"; }
bad() { FAIL=$((FAIL+1)); echo "  ✗ $1"; }

BRIDGE_LIB_ONLY=1 source "$REPO_ROOT/setup.d/bridge-guided.sh"

# Health check keys on the URL responding, not on docker. Use a curl stub.
curl() { case "$*" in *"/health"*) return 0 ;; *) return 1 ;; esac; }
export -f curl
bridge_health_ok "http://localhost:3009" && ok "health ok → reachable (docker-agnostic)" || bad "health check failed"

curl() { return 1; }  # nothing responds
export -f curl
bridge_health_ok "http://localhost:3009" && bad "health ok despite no response" || ok "no response → not reachable"

# diagnose returns 'up' when health ok
curl() { case "$*" in *"/health"*) return 0 ;; *) return 1 ;; esac; }
export -f curl
[ "$(bridge_diagnose http://localhost:3009)" = "up" ] && ok "diagnose=up when reachable" || bad "diagnose not up"

# --- S5 cases: state=up delegation resolves root via BASH_SOURCE, degrades ---
# --- gracefully on consumer checkouts (no packages/runtime-bridge present). ---
# NOTE: these re-source a COPY of the lib (redefines its functions), so they
# must stay AFTER the 3 cases above.

# Paired-negative (consumer: script absent): source a copy of the lib from a
# temp root that has NO packages/ tree → state=up must NOT hard-fail; it must
# point at the manual-setup doc and return 0.
TMP_NEG=$(mktemp -d)
mkdir -p "$TMP_NEG/setup.d"
cp "$REPO_ROOT/setup.d/bridge-guided.sh" "$TMP_NEG/setup.d/"
BRIDGE_LIB_ONLY=1 source "$TMP_NEG/setup.d/bridge-guided.sh"
curl() { case "$*" in *"/health"*) return 0 ;; *) return 1 ;; esac; }
export -f curl
out=$(bridge_guided_run); rc=$?
[ "$rc" -eq 0 ] && ok "consumer (script absent): state=up returns 0, no hard fail" || bad "consumer (script absent): rc=$rc"
case "$out" in *"docs/runtime-bridge-setup.md"*) ok "consumer (script absent): output points at docs/runtime-bridge-setup.md" ;; *) bad "consumer (script absent): no manual-setup pointer in output: $out" ;; esac
case "$out" in *"reachable at"*) ok "consumer (script absent): state=up branch taken (reachable line present)" ;; *) bad "consumer (script absent): state=up branch not taken: $out" ;; esac
rm -rf "$TMP_NEG"

# Positive (framework repo: script present): separate temp root WITH a stubbed
# packages/runtime-bridge/scripts/setup-runtime-bridge.sh → must execute it by
# absolute path (cwd-independent).
TMP_POS=$(mktemp -d)
mkdir -p "$TMP_POS/setup.d" "$TMP_POS/packages/runtime-bridge/scripts"
cp "$REPO_ROOT/setup.d/bridge-guided.sh" "$TMP_POS/setup.d/"
echo 'echo "STUB-BRIDGE-SETUP-RAN"' > "$TMP_POS/packages/runtime-bridge/scripts/setup-runtime-bridge.sh"
BRIDGE_LIB_ONLY=1 source "$TMP_POS/setup.d/bridge-guided.sh"
curl() { case "$*" in *"/health"*) return 0 ;; *) return 1 ;; esac; }
export -f curl
out=$(cd /tmp && bridge_guided_run); rc=$?
[ "$rc" -eq 0 ] && ok "framework (script present): state=up returns 0" || bad "framework (script present): rc=$rc"
case "$out" in *"STUB-BRIDGE-SETUP-RAN"*) ok "framework (script present): setup-runtime-bridge.sh executed via absolute path (cwd=/tmp)" ;; *) bad "framework (script present): stub not executed: $out" ;; esac
rm -rf "$TMP_POS"

echo ""; echo "PASS=$PASS FAIL=$FAIL"; [ "$FAIL" -eq 0 ]

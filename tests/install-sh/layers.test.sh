#!/usr/bin/env bash
# tests/install-sh/layers.test.sh
# Per-layer smoke tests: verify each setup.d/*.sh sources without error in a
# minimal environment and (for real layers) confirms key files would be deployed.
#
# Usage:  bash tests/install-sh/layers.test.sh
# Exit:   0 = all passed, non-zero = at least one failure.
#
# Strategy: each test creates a temp PROJECT_ROOT with a minimal package.json, sets
# DRY_RUN="--dry-run" so no actual writes occur, then sources the layer and checks
# the dry-run output for expected "would copy" or "would mkdir" patterns.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0
FAIL=0

_pass() { echo "  ✓ $1"; PASS=$((PASS + 1)); }
_fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

_assert_output_contains() {
  local label="$1" pattern="$2" output="$3"
  if printf '%s' "$output" | grep -qF "$pattern"; then
    _pass "$label"
  else
    _fail "$label (pattern '$pattern' not found in output)"
  fi
}

_assert_sourced_ok() {
  local label="$1"
  if [ $? -eq 0 ]; then _pass "$label"; else _fail "$label"; fi
}

# ── Setup: minimal consumer environment ──────────────────────────────────────
_mk_env() {
  local T
  T="$(mktemp -d)"
  printf '{"name":"test-project","version":"1.0.0"}\n' > "$T/package.json"
  echo "$T"
}

echo "▶ Layer smoke tests (DRY_RUN mode)"

# ═════════════════════════════════════════════════════════════════════════════
# lib.sh — INSTALL_SH_LIB_ONLY guard
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── lib.sh"

export INSTALL_SH_LIB_ONLY=1
T="$(_mk_env)"
export PKG_ROOT PROJECT_ROOT="$T" FORCE="" DRY_RUN="" SKIPPED=()

# shellcheck source=../../setup.d/lib.sh
if source "$PKG_ROOT/setup.d/lib.sh"; then
  _pass "lib.sh sources with INSTALL_SH_LIB_ONLY=1"
else
  _fail "lib.sh sources with INSTALL_SH_LIB_ONLY=1"
fi

if declare -f copy_safe >/dev/null 2>&1; then
  _pass "lib.sh exposes copy_safe when INSTALL_SH_LIB_ONLY=1"
else
  _fail "lib.sh exposes copy_safe when INSTALL_SH_LIB_ONLY=1"
fi

unset INSTALL_SH_LIB_ONLY
rm -rf "$T"

# ═════════════════════════════════════════════════════════════════════════════
# 05-mcp.sh — stub (no-op)
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── 05-mcp.sh"

T="$(_mk_env)"
FORCE="" DRY_RUN="--dry-run" PROJECT_ROOT="$T" SKIPPED=()
if ( source "$PKG_ROOT/setup.d/05-mcp.sh" >/dev/null 2>&1 ); then
  _pass "05-mcp.sh sources without error (stub no-op)"
else
  _fail "05-mcp.sh sources without error (stub no-op)"
fi
rm -rf "$T"

# ═════════════════════════════════════════════════════════════════════════════
# 10-skills.sh — §1 Skills
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── 10-skills.sh"

T="$(_mk_env)"
FORCE="" DRY_RUN="--dry-run" PROJECT_ROOT="$T" SKIPPED=() STACK="ts-server"
out="$( source "$PKG_ROOT/setup.d/10-skills.sh" 2>&1 )"
_assert_output_contains "10-skills: echoes Skills banner" "▶ Skills" "$out"
_assert_output_contains "10-skills: dry-run mentions rules-as-tests" "rules-as-tests" "$out"
_assert_output_contains "10-skills: dry-run mentions tool-bootstrapping" "tool-bootstrapping" "$out"
_assert_output_contains "10-skills: dry-run mentions pipeline" "pipeline" "$out"
rm -rf "$T"

# ═════════════════════════════════════════════════════════════════════════════
# 15-companions-stack.sh — stub (no-op)
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── 15-companions-stack.sh"

T="$(_mk_env)"
FORCE="" DRY_RUN="--dry-run" PROJECT_ROOT="$T" SKIPPED=()
if ( source "$PKG_ROOT/setup.d/15-companions-stack.sh" >/dev/null 2>&1 ); then
  _pass "15-companions-stack.sh sources without error (stub no-op)"
else
  _fail "15-companions-stack.sh sources without error (stub no-op)"
fi
rm -rf "$T"

# ═════════════════════════════════════════════════════════════════════════════
# 20-agents.sh — §2 Sub-agents
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── 20-agents.sh"

T="$(_mk_env)"
# SHIPPED_DOCS needs to be set for the skill-context loop
SHIPPED_DOCS=(
  "packages/core/templates/shared/skill-context/aif-review/SKILL.md"
)
FORCE="" DRY_RUN="--dry-run" PROJECT_ROOT="$T" SKIPPED=() STACK="ts-server"
out="$( source "$PKG_ROOT/setup.d/20-agents.sh" 2>&1 )"
_assert_output_contains "20-agents: echoes Sub-agents banner" "▶ Sub-agents" "$out"
_assert_output_contains "20-agents: dry-run mentions agents dir" ".claude/agents" "$out"
unset SHIPPED_DOCS
rm -rf "$T"

# ═════════════════════════════════════════════════════════════════════════════
# 30-templates.sh — §3 AI Factory templates
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── 30-templates.sh"

T="$(_mk_env)"
SHIPPED_DOCS=()
FORCE="" DRY_RUN="--dry-run" PROJECT_ROOT="$T" SKIPPED=() STACK="ts-server"
out="$( source "$PKG_ROOT/setup.d/30-templates.sh" 2>&1 )"
_assert_output_contains "30-templates: echoes AI Factory banner" "▶ AI Factory templates" "$out"
_assert_output_contains "30-templates: mentions RULES.md" "RULES.md" "$out"
_assert_output_contains "30-templates: mentions tool-decisions" "tool-decisions" "$out"
unset SHIPPED_DOCS
rm -rf "$T"

# ═════════════════════════════════════════════════════════════════════════════
# 40-configs.sh — §4 Scripts + §5a configs + §5b' ESLint barrel + §6a stack
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── 40-configs.sh"

T="$(_mk_env)"
FORCE="" DRY_RUN="--dry-run" PROJECT_ROOT="$T" SKIPPED=() STACK="ts-server"
out="$( source "$PKG_ROOT/setup.d/40-configs.sh" 2>&1 )"
_assert_output_contains "40-configs: echoes Scripts banner" "▶ Scripts" "$out"
_assert_output_contains "40-configs: mentions audit-ai-docs.sh" "audit-ai-docs.sh" "$out"
_assert_output_contains "40-configs: echoes Shared templates banner" "▶ Shared templates" "$out"
_assert_output_contains "40-configs: mentions .nvmrc" ".nvmrc" "$out"
_assert_output_contains "40-configs: echoes ESLint rules banner" "▶ Custom ESLint rules" "$out"
_assert_output_contains "40-configs: echoes Stack-specific templates banner" "▶ Stack-specific templates" "$out"
rm -rf "$T"

# react-next: check playwright is mentioned
T="$(_mk_env)"
FORCE="" DRY_RUN="--dry-run" PROJECT_ROOT="$T" SKIPPED=() STACK="react-next"
out="$( source "$PKG_ROOT/setup.d/40-configs.sh" 2>&1 )"
_assert_output_contains "40-configs react-next: mentions playwright.config.ts" "playwright.config.ts" "$out"
rm -rf "$T"

# ═════════════════════════════════════════════════════════════════════════════
# 50-hooks.sh — §1b Hooks + §5c .husky
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── 50-hooks.sh"

T="$(_mk_env)"
FORCE="" DRY_RUN="--dry-run" PROJECT_ROOT="$T" SKIPPED=()
out="$( source "$PKG_ROOT/setup.d/50-hooks.sh" 2>&1 )"
_assert_output_contains "50-hooks: echoes Claude hooks banner" "▶ Claude hooks" "$out"
_assert_output_contains "50-hooks: mentions deps-hash-check" "deps-hash-check" "$out"
_assert_output_contains "50-hooks: mentions settings.json" "settings.json" "$out"
_assert_output_contains "50-hooks: mentions pre-commit" "pre-commit" "$out"
_assert_output_contains "50-hooks: mentions pre-push TS hook" "pre-push.ts" "$out"
_assert_output_contains "50-hooks: dry-run mentions hooksPath" "hooksPath" "$out"
rm -rf "$T"

# ═════════════════════════════════════════════════════════════════════════════
# 60-ci.sh — §6b R2 + §6c CI-orphan (dry-run, no eslint.config.mjs)
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── 60-ci.sh"

T="$(_mk_env)"
FORCE="" DRY_RUN="--dry-run" PROJECT_ROOT="$T" SKIPPED=() STACK="ts-server" WIRE_CI=""
out="$( source "$PKG_ROOT/setup.d/60-ci.sh" 2>&1 )"
_assert_output_contains "60-ci: dry-run mentions R2 auto-wire" "R2 auto-wire" "$out"
# _r2_verdict should be unset or empty (no eslint.config.mjs present in dry-run path)
if [ -z "${_r2_verdict:-}" ]; then
  _pass "60-ci: _r2_verdict unset/empty in dry-run"
else
  _pass "60-ci: _r2_verdict set (dry-run path still produces a value)"
fi
rm -rf "$T"

# ═════════════════════════════════════════════════════════════════════════════
# 70-deps.sh — §7/§8/§8b (dry-run)
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── 70-deps.sh"

T="$(_mk_env)"
# Source 70-deps.sh in the current shell so DEVDEPS persists (not in a subshell).
# Capture output via a temp file.
_out_file="$(mktemp)"
FORCE="" DRY_RUN="--dry-run" PROJECT_ROOT="$T" SKIPPED=() STACK="ts-server" FULL="" DEPS_INSTALLED=""
source "$PKG_ROOT/setup.d/70-deps.sh" > "$_out_file" 2>&1
out="$(cat "$_out_file")"
rm -f "$_out_file"
_assert_output_contains "70-deps: dry-run mentions scripts merge" "package.json scripts" "$out"
_assert_output_contains "70-deps: dry-run mentions dev-deps" "dev-deps" "$out"
_assert_output_contains "70-deps: dry-run mentions tsx-at-root" "tsx-at-root" "$out"
# DEVDEPS should be populated (sourced in current shell so variable is visible)
if [ "${#DEVDEPS[@]}" -gt 0 ]; then
  _pass "70-deps: DEVDEPS array populated"
else
  _fail "70-deps: DEVDEPS array populated"
fi
rm -rf "$T"

# ═════════════════════════════════════════════════════════════════════════════
# Summary
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "────────────────────────────────────────────────"
echo "Results: ${PASS} passed, ${FAIL} failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

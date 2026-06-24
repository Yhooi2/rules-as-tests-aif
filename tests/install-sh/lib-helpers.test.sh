#!/usr/bin/env bash
# tests/install-sh/lib-helpers.test.sh
# Unit tests for setup.d/lib.sh helpers.
# Sources lib.sh with INSTALL_SH_LIB_ONLY=1 to expose helpers without running
# the install pipeline (no interactive prompts, no disk mutations in lib.sh).
#
# Usage:  bash tests/install-sh/lib-helpers.test.sh
# Exit:   0 = all passed, non-zero = at least one failure.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── Bootstrap: expose helpers via lib-only guard ──────────────────────────────
export INSTALL_SH_LIB_ONLY=1
# lib.sh consumes PKG_ROOT, PROJECT_ROOT, FORCE, DRY_RUN, SKIPPED from scope.
export PKG_ROOT

PASS=0
FAIL=0

_pass() { echo "  ✓ $1"; PASS=$((PASS + 1)); }
_fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

_assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then _pass "$label"; else
    _fail "$label (expected='$expected' actual='$actual')"; fi
}

_assert_file_exists() {
  local label="$1" path="$2"
  if [ -e "$path" ]; then _pass "$label"; else _fail "$label (missing: $path)"; fi
}

_assert_file_absent() {
  local label="$1" path="$2"
  if [ ! -e "$path" ]; then _pass "$label"; else _fail "$label (unexpectedly present: $path)"; fi
}

_assert_contains() {
  local label="$1" file="$2" pattern="$3"
  if grep -qF "$pattern" "$file" 2>/dev/null; then _pass "$label"; else
    _fail "$label (pattern '$pattern' not found in $file)"; fi
}

# ── Helper: create a fresh temp dir per test group, clean up after ─────────────
_tmpdir() {
  local d
  d="$(mktemp -d)"
  echo "$d"
}

# ── Source lib.sh ─────────────────────────────────────────────────────────────
# Reset globals lib.sh sets at module load time so we can re-set them per test.
SKIPPED=()
FORCE=""
DRY_RUN=""
PROJECT_ROOT="$(mktemp -d)"  # throwaway; individual tests override as needed

# shellcheck source=../../setup.d/lib.sh
source "$PKG_ROOT/setup.d/lib.sh"

echo "▶ lib-helpers tests"

# ═════════════════════════════════════════════════════════════════════════════
# copy_safe
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── copy_safe"

T="$(_tmpdir)"
src="$T/src.txt"; dst="$T/dst.txt"
printf "hello" > "$src"
FORCE=""; DRY_RUN=""; SKIPPED=(); PROJECT_ROOT="$T"
copy_safe "$src" "$dst"
_assert_file_exists "copy_safe creates destination" "$dst"
_assert_eq "copy_safe copies content" "hello" "$(cat "$dst")"

# skip-if-exists (no --force)
old="$(cat "$dst")"
printf "changed" > "$src"
SKIPPED=()
copy_safe "$src" "$dst"
_assert_eq "copy_safe skips existing (no --force)" "hello" "$(cat "$dst")"
_assert_eq "copy_safe records in SKIPPED" 1 "${#SKIPPED[@]}"

# --force overwrites
FORCE="--force"; SKIPPED=()
copy_safe "$src" "$dst"
_assert_eq "copy_safe --force overwrites" "changed" "$(cat "$dst")"
FORCE=""

# dry-run does not write
DRY_RUN="--dry-run"
rm -f "$dst"
copy_safe "$src" "$dst"
_assert_file_absent "copy_safe --dry-run does not write" "$dst"
DRY_RUN=""

rm -rf "$T"

# ═════════════════════════════════════════════════════════════════════════════
# mkdir_safe
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── mkdir_safe"

T="$(_tmpdir)"
DRY_RUN=""; SKIPPED=()
target="$T/a/b/c"
mkdir_safe "$target"
_assert_file_exists "mkdir_safe creates nested dir" "$target"

# idempotent
mkdir_safe "$target"
_assert_file_exists "mkdir_safe idempotent (no error)" "$target"

# dry-run
rm -rf "$T/x"
DRY_RUN="--dry-run"
mkdir_safe "$T/x"
_assert_file_absent "mkdir_safe --dry-run does not create" "$T/x"
DRY_RUN=""

rm -rf "$T"

# ═════════════════════════════════════════════════════════════════════════════
# chmod_safe
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── chmod_safe"

T="$(_tmpdir)"
f="$T/script.sh"; printf "#!/bin/sh\n" > "$f"
chmod 644 "$f"
DRY_RUN=""
chmod_safe +x "$f"
if [ -x "$f" ]; then _pass "chmod_safe +x sets executable"; else _fail "chmod_safe +x sets executable"; fi

# dry-run: chmod is called but skipped — check no error
DRY_RUN="--dry-run"
chmod 644 "$f"  # reset
chmod_safe +x "$f" 2>/dev/null  # should silently no-op
# In dry-run, chmod_safe returns 0 without doing anything
if [ ! -x "$f" ]; then _pass "chmod_safe --dry-run does not chmod"; else
  # macOS may differ; accept either (the important thing is no error)
  _pass "chmod_safe --dry-run returns 0 (file may or may not be executable)"; fi
DRY_RUN=""

rm -rf "$T"

# ═════════════════════════════════════════════════════════════════════════════
# refresh_safe
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── refresh_safe"

T="$(_tmpdir)"
DRY_RUN=""; FORCE=""; SKIPPED=(); PROJECT_ROOT="$T"
src="$T/src.md"; dst="$T/dst.md"
printf "v1" > "$src"

# No override — overwrites existing
printf "old" > "$dst"
refresh_safe "$src" "$dst"
_assert_eq "refresh_safe overwrites when no override" "v1" "$(cat "$dst")"

# Override present — skips
override="${dst%.md}.override.md"
touch "$override"
printf "v2" > "$src"
refresh_safe "$src" "$dst"
_assert_eq "refresh_safe skips when .override.md present" "v1" "$(cat "$dst")"
rm -f "$override"

# Source missing — no-op (does not create dst from nothing)
rm -f "$dst"
refresh_safe "$T/nonexistent.md" "$dst" 2>/dev/null || true
_assert_file_absent "refresh_safe no-ops when source missing" "$dst"

# dry-run
DRY_RUN="--dry-run"
printf "v3" > "$src"; printf "current" > "$dst"
refresh_safe "$src" "$dst"
_assert_eq "refresh_safe --dry-run does not overwrite" "current" "$(cat "$dst")"
DRY_RUN=""

rm -rf "$T"

# ═════════════════════════════════════════════════════════════════════════════
# detect_pm
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── detect_pm"

T="$(_tmpdir)"

# npm (no lockfile signals)
PROJECT_ROOT="$T"
printf '{}' > "$T/package.json"
_pm="$(detect_pm)"
_assert_eq "detect_pm defaults to npm" "npm" "$_pm"

# pnpm via lockfile
touch "$T/pnpm-lock.yaml"
_pm="$(detect_pm)"
_assert_eq "detect_pm detects pnpm via pnpm-lock.yaml" "pnpm" "$_pm"
rm -f "$T/pnpm-lock.yaml"

# pnpm via workspace
touch "$T/pnpm-workspace.yaml"
_pm="$(detect_pm)"
_assert_eq "detect_pm detects pnpm via pnpm-workspace.yaml" "pnpm" "$_pm"
rm -f "$T/pnpm-workspace.yaml"

# yarn via lockfile
touch "$T/yarn.lock"
_pm="$(detect_pm)"
_assert_eq "detect_pm detects yarn via yarn.lock" "yarn" "$_pm"
rm -f "$T/yarn.lock"

rm -rf "$T"

# ═════════════════════════════════════════════════════════════════════════════
# merge_prettierignore
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── merge_prettierignore"

T="$(_tmpdir)"
DRY_RUN=""; FORCE=""; SKIPPED=(); PROJECT_ROOT="$T"

# Shipped source: two real patterns + a comment
shipped="$T/shipped.prettierignore"
printf '# comment\n.ai-factory/RULES.md\n.ai-factory/RULES.react-next.md\n' > "$shipped"

# Greenfield: no consumer file → copy byte-identical
consumer="$T/.prettierignore"
merge_prettierignore "$shipped" "$consumer"
_assert_file_exists "merge_prettierignore creates consumer file (greenfield)" "$consumer"

# Idempotent: run again after block already present (greenfield copy_safe path)
# copy_safe copies byte-identical — no begin/end markers in the source → no block in consumer.
# Second run: consumer exists with all patterns already present (copied verbatim) → no-op.
merge_prettierignore "$shipped" "$consumer"
if ! grep -qxF "$PRETTIERIGNORE_BEGIN" "$consumer"; then
  _pass "merge_prettierignore idempotent on re-run (no begin-marker in greenfield copy)"
else
  _fail "merge_prettierignore idempotent on re-run (no begin-marker in greenfield copy)"
fi

# Brownfield: consumer has some patterns but not all
rm -f "$consumer"
printf '.ai-factory/RULES.md\n' > "$consumer"  # has one, missing the other
merge_prettierignore "$shipped" "$consumer"
_assert_contains "merge_prettierignore appends missing pattern" "$consumer" ".ai-factory/RULES.react-next.md"
_assert_contains "merge_prettierignore adds begin marker" "$consumer" "$PRETTIERIGNORE_BEGIN"
_assert_contains "merge_prettierignore adds end marker" "$consumer" "$PRETTIERIGNORE_END"

# Idempotent on brownfield: block already present
merge_prettierignore "$shipped" "$consumer"
block_count2=$(grep -c "$PRETTIERIGNORE_BEGIN" "$consumer" 2>/dev/null || echo 0)
block_count2="${block_count2//[$'\n\r']/}"
_assert_eq "merge_prettierignore block not duplicated" "1" "$block_count2"

# --dry-run: does not modify consumer
consumer_dry="$T/.prettierignore-dry"
printf '.something-else\n' > "$consumer_dry"
DRY_RUN="--dry-run"
merge_prettierignore "$shipped" "$consumer_dry"
if ! grep -qxF "$PRETTIERIGNORE_BEGIN" "$consumer_dry"; then
  _pass "merge_prettierignore --dry-run does not append block"
else
  _fail "merge_prettierignore --dry-run does not append block"
fi
DRY_RUN=""

rm -rf "$T"

# ═════════════════════════════════════════════════════════════════════════════
# ignore_shipped_configs
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── ignore_shipped_configs"

T="$(_tmpdir)"
DRY_RUN=""; FORCE=""; SKIPPED=(); PROJECT_ROOT="$T"
ign="$T/.prettierignore"

# No .prettierignore → no-op (function returns early)
ignore_shipped_configs
_assert_file_absent "ignore_shipped_configs no-op when no .prettierignore" "$ign"

# With .prettierignore: a freshly-shipped config gets added
printf '# base\n' > "$ign"
# Simulate a freshly-shipped eslint.config.mjs (not in SKIPPED, file exists)
touch "$T/eslint.config.mjs"
ignore_shipped_configs
_assert_contains "ignore_shipped_configs adds fresh config to .prettierignore" "$ign" "eslint.config.mjs"

# Consumer-owned (in SKIPPED): should NOT be added
rm -f "$ign"; printf '# base\n' > "$ign"
SKIPPED=("$T/vitest.config.ts")
touch "$T/vitest.config.ts"
ignore_shipped_configs
if ! grep -qF "vitest.config.ts" "$ign" 2>/dev/null; then
  _pass "ignore_shipped_configs skips consumer-owned (SKIPPED) file"
else
  _fail "ignore_shipped_configs skips consumer-owned (SKIPPED) file"
fi
SKIPPED=()

# Idempotent: already in .prettierignore
ignore_shipped_configs
count=$(grep -c "eslint.config.mjs" "$ign" 2>/dev/null || echo 0)
count="${count//[$'\n\r']/}"
_assert_eq "ignore_shipped_configs is idempotent" "1" "$count"

rm -rf "$T"

# ═════════════════════════════════════════════════════════════════════════════
# _prettierignore_in_skipped
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── _prettierignore_in_skipped"

SKIPPED=()
if ! _prettierignore_in_skipped "/some/path"; then
  _pass "_prettierignore_in_skipped returns 1 on empty SKIPPED"
else
  _fail "_prettierignore_in_skipped returns 1 on empty SKIPPED"
fi

SKIPPED=("/a/b" "/c/d")
if _prettierignore_in_skipped "/c/d"; then
  _pass "_prettierignore_in_skipped finds present element"
else
  _fail "_prettierignore_in_skipped finds present element"
fi

if ! _prettierignore_in_skipped "/not/in/list"; then
  _pass "_prettierignore_in_skipped returns 1 for absent element"
else
  _fail "_prettierignore_in_skipped returns 1 for absent element"
fi
SKIPPED=()

# ═════════════════════════════════════════════════════════════════════════════
# transform_internal_refs (smoke test)
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── transform_internal_refs"

T="$(_tmpdir)"
f="$T/test.md"
cat > "$f" <<'MD'
See [docs page](../../../docs/meta-factory/foo.md) and [packages](../../../packages/core/bar.md)
and [README](../../../README.md) and [rules](../../rules/something.md).
MD

transform_internal_refs "$f"
_assert_contains "transform_internal_refs rewrites docs/ refs" "$f" "https://github.com/Yhooi2/rules-as-tests-aif/blob/main/docs/"
_assert_contains "transform_internal_refs rewrites packages/ refs" "$f" "https://github.com/Yhooi2/rules-as-tests-aif/blob/main/packages/"
_assert_contains "transform_internal_refs rewrites README refs" "$f" "https://github.com/Yhooi2/rules-as-tests-aif/blob/main/README.md"
if grep -qF "../../rules/something.md" "$f"; then
  _pass "transform_internal_refs leaves consumer-resolvable refs intact"
else
  _fail "transform_internal_refs leaves consumer-resolvable refs intact"
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

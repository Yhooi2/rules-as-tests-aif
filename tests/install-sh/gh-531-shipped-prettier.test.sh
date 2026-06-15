#!/usr/bin/env bash
# gh-531-shipped-prettier.test.sh — the shipped surface must be Prettier-clean out-of-box.
#
# Deterministic core (no network): (1) the shipped .prettierignore excludes the GENERATED install
# artifacts (settings.json, the eslint-rules-local barrel) — authored sources are formatted, only
# generated ones are ignored; (2) the stryker packageManager patch is an in-place VALUE replace, not
# a JSON.stringify re-serialize (which would re-expand prettier-collapsed arrays and re-break the
# consumer). Optional end-to-end arm (only when `npx prettier` is reachable): install into a tmp
# consumer and assert `prettier --check .` is green.
set -uo pipefail
REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ✓ $1"; }
bad() { FAIL=$((FAIL+1)); echo "  ✗ $1"; }

IGN="$REPO_ROOT/packages/core/templates/shared/.prettierignore"

# ── Arm 1: generated install artifacts are ignored (so a consumer's prettier --check . skips them) ──
grep -qx '.claude/settings.json' "$IGN" \
  && ok "shipped .prettierignore excludes generated .claude/settings.json" \
  || bad "shipped .prettierignore missing .claude/settings.json (consumer prettier --check would fail on it)"
grep -qx 'eslint-rules-local/index.ts' "$IGN" \
  && ok "shipped .prettierignore excludes the generated eslint-rules-local/index.ts barrel" \
  || bad "shipped .prettierignore missing eslint-rules-local/index.ts (generated barrel would fail prettier)"
# NEG (load-bearing): authored skill docs must NOT be blanket-ignored (that would be hiding, not fixing)
grep -qE '^\.claude/skills/?\*?\*?$|^\.claude/\*\*?$' "$IGN" \
  && bad "neg: .prettierignore blanket-ignores .claude/skills — authored docs hidden, not formatted" \
  || ok "neg: authored skill docs are NOT blanket-ignored (they are formatted, not hidden)"

# ── Arm 2: stryker packageManager patch preserves formatting (in-place value replace) ──
grep -q 'replace(/("packageManager"' "$REPO_ROOT/install.sh" \
  && ok "stryker patch swaps the packageManager VALUE in place (preserves prettier formatting)" \
  || bad "stryker patch is not an in-place value replace (#531 regression risk)"
if grep -A6 'patch_stryker_package_manager' "$REPO_ROOT/install.sh" | grep -q 'JSON.stringify(cfg'; then
  bad "neg: stryker patch still uses JSON.stringify (re-expands prettier-collapsed arrays → re-breaks consumer)"
else
  ok "neg: stryker patch no longer JSON.stringify-re-serializes the whole config"
fi

# ── Arm 4 (GH #531 reopen — RC#1): prettier is pinned EXACT on BOTH sides ──
# RC#1: prettier ships formatting changes in minor/patch; a floating version makes a consumer's
# format:check non-deterministic across re-installs. Both the shipped dev-dep and the framework's
# own dogfood script must pin the SAME exact version. `prettier@[0-9.]+` extracts the pin and does
# NOT mis-match `eslint-config-prettier` (no @version on that token).
# (a) install.sh CORE_DEVDEPS pins prettier@3.8.3 EXACT.
INSTALL_PIN=$(grep -oE 'prettier@[0-9.]+' "$REPO_ROOT/install.sh" | head -1)
[ "$INSTALL_PIN" = "prettier@3.8.3" ] \
  && ok "install.sh CORE_DEVDEPS pins prettier EXACT ($INSTALL_PIN)" \
  || bad "install.sh CORE_DEVDEPS does not pin prettier@3.8.3 exact (got: '${INSTALL_PIN:-none}')"
# neg (LOAD-BEARING): a copy where the token is bare `prettier` or caret `prettier@^3` must FLIP
# the exact-pin grep to miss prettier@3.8.3.
TMP_NEG=$(mktemp)
sed 's/prettier@3\.8\.3/prettier/' "$REPO_ROOT/install.sh" > "$TMP_NEG"
NEG_PIN=$(grep -oE 'prettier@[0-9.]+' "$TMP_NEG" | head -1)
if [ "$NEG_PIN" = "prettier@3.8.3" ]; then
  bad "neg: stripping the pin still matched prettier@3.8.3 → VACUOUS"
else
  ok "neg: un-pinning install.sh (bare prettier) flips the exact-pin grep to miss (non-vacuous)"
fi
rm -f "$TMP_NEG"

# (c) format-shipped.sh uses the PINNED `npx --yes prettier@3.8.3` (positive: the pinned string is
# PRESENT — asserting mere absence of unpinned `npx --yes prettier` would be vacuous, since deleting
# the invocation entirely would satisfy absence).
FMT="$REPO_ROOT/scripts/format-shipped.sh"
[ "$(grep -cE 'npx --yes prettier@3\.8\.3' "$FMT")" -ge 2 ] \
  && ok "format-shipped.sh pins BOTH npx invocations to prettier@3.8.3" \
  || bad "format-shipped.sh does not pin both npx invocations to prettier@3.8.3"
# neg (LOAD-BEARING): a copy with the pin reverted to bare `npx --yes prettier` must FLIP the
# pinned-string grep to miss.
TMP_NEG=$(mktemp)
sed 's/npx --yes prettier@3\.8\.3/npx --yes prettier/' "$FMT" > "$TMP_NEG"
if [ "$(grep -cE 'npx --yes prettier@3\.8\.3' "$TMP_NEG")" -ge 2 ]; then
  bad "neg: un-pinning format-shipped.sh still matched the pinned string → VACUOUS"
else
  ok "neg: reverting format-shipped.sh to bare npx prettier flips the pinned-string grep to miss"
fi
rm -f "$TMP_NEG"

# ── Arm 5 (PART C drift-guard): the TWO pin sites agree on the EXACT version ──
# Project invariants 2 + 4: an executable assertion that install.sh and format-shipped.sh can never
# silently diverge. Extract X from `prettier@X` at both sites; they MUST be equal.
FMT_PIN=$(grep -oE 'prettier@[0-9.]+' "$FMT" | head -1)
if [ -n "$INSTALL_PIN" ] && [ "$INSTALL_PIN" = "$FMT_PIN" ]; then
  ok "drift-guard: install.sh and format-shipped.sh pin the SAME prettier ($INSTALL_PIN == $FMT_PIN)"
else
  bad "drift-guard: pin mismatch — install.sh='$INSTALL_PIN' vs format-shipped.sh='$FMT_PIN'"
fi
# neg (LOAD-BEARING): mutate ONE site's version → the drift-guard equality MUST flip to fail.
TMP_NEG=$(mktemp)
sed 's/npx --yes prettier@3\.8\.3/npx --yes prettier@3.8.0/' "$FMT" > "$TMP_NEG"
NEG_FMT_PIN=$(grep -oE 'prettier@[0-9.]+' "$TMP_NEG" | head -1)
if [ "$INSTALL_PIN" = "$NEG_FMT_PIN" ]; then
  bad "neg: diverging format-shipped.sh to 3.8.0 still matched install.sh → drift-guard VACUOUS"
else
  ok "neg: diverging one site's version (3.8.0) flips the drift-guard equality to fail (non-vacuous)"
fi
rm -f "$TMP_NEG"

# ── Arm 3 (optional, network): a real install must be prettier-clean end-to-end ──
# PIN the consumer-side check to prettier@3.8.3 — without the pin this arm fetches latest and would
# go flaky/false-red the moment npm publishes 3.8.4+ (files are clean under the pinned 3.8.3, the
# version the shipped surface is formatted in). Pinning faithfully models the pinned consumer.
if npx --yes prettier@3.8.3 --version >/dev/null 2>&1; then
  T=$(mktemp -d); printf '{"name":"g531","version":"0.0.0"}\n' > "$T/package.json"
  ( cd "$T" && git init -q && bash "$REPO_ROOT/install.sh" ts-server --force ) >/dev/null 2>&1
  n=$( ( cd "$T" && npx --yes prettier@3.8.3 --check . 2>&1 ) | grep -cE '^\[warn\]|^\[error\]' )
  [ "$n" -eq 0 ] \
    && ok "end-to-end: fresh ts-server consumer is Prettier-clean (prettier@3.8.3 --check . → 0 issues)" \
    || bad "end-to-end: consumer has $n prettier failures after install (#531 not fully closed)"
else
  echo "  · end-to-end arm skipped (npx prettier@3.8.3 unreachable) — deterministic arms above still hold"
fi

echo ""; echo "PASS=$PASS FAIL=$FAIL"; [ "$FAIL" -eq 0 ]

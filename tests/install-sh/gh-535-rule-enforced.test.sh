#!/usr/bin/env bash
# gh-535-rule-enforced.test.sh — the +E deep gate (check-rule-enforced.sh) must catch the false-green
# where a per-package eslint config shadows the root R2 (so `lint`/check:globs pass while R2 is inert),
# and must NOT false-fail a package that correctly re-exports the root config.
#
# NO REAL ESLINT / NO NETWORK: a FAKE eslint (injected via AIF_ESLINT_CMD) answers `--print-config
# <file>` with a resolved ruleset that INCLUDES R2 unless the file path matches $AIF_FAKE_DEAD — i.e.
# it stands in for "what eslint actually resolved for this file". The gate's job is to find a
# representative boundary file per config scope, run --print-config, and turn "R2 present?" into a
# verdict — that pipeline is what these arms exercise.
#
# PAIRED-NEGATIVES: Arm B proves the gate does NOT fire when R2 IS applied (no false-fail on a
# correct re-export-of-root) — without it Arm A's FAIL could be a gate that always fails.
set -uo pipefail
REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
GATE="$REPO_ROOT/packages/core/audit-self/check-rule-enforced.sh"
TEMPLATE="$REPO_ROOT/templates/ts-server/eslint.config.mjs"
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ✓ $1"; }
bad() { FAIL=$((FAIL+1)); echo "  ✗ $1"; }

# ── fake eslint: only handles `--print-config <file>`; emits R2 unless the path matches AIF_FAKE_DEAD ──
FAKE=$(mktemp)
cat > "$FAKE" <<'ES'
#!/bin/sh
if [ "$1" = "--print-config" ]; then
  f="$2"
  printf '{ "rules": {'
  case "$f" in
    *"${AIF_FAKE_DEAD:-__nomatch__}"*) : ;;                          # dead scope → omit R2
    *) printf '"rules-as-tests/no-unsafe-zod-parse":[2]' ;;          # wired scope → R2 present
  esac
  printf '} }\n'
fi
exit 0
ES
chmod +x "$FAKE"
export AIF_ESLINT_CMD="$FAKE"

# Build a monorepo fixture: root config (the real template, for RULE_GLOBS.boundary) + a shadowed
# package apps/api with its own config and a boundary file under routes/.
make_monorepo() { # $1=dir
  local d="$1"
  mkdir -p "$d/apps/api/src/routes"
  cp "$TEMPLATE" "$d/eslint.config.mjs"
  printf "import base from './base.mjs';\nexport default base;\n" > "$d/apps/api/eslint.config.mjs"
  printf "export const x = 1;\n" > "$d/apps/api/src/routes/probe.ts"
}

# ════ Arm A — shadowed package's config does NOT apply R2 → gate FAILS (catches the false-green) ════
A=$(mktemp -d); make_monorepo "$A"
( cd "$A" && AIF_FAKE_DEAD="apps/api" bash "$GATE" ) >/tmp/gh535a.$$ 2>&1
if [ $? -ne 0 ]; then ok "A: package with boundary files but R2 not applied → gate FAILS (exit≠0)"; else bad "A: gate passed though R2 is inert in apps/api (false-green not caught)"; fi
grep -q "apps/api" /tmp/gh535a.$$ && ok "A: failure message names the offending package (apps/api)" || bad "A: failure did not name apps/api"

# ════ Arm B (paired-negative) — same tree, R2 IS applied everywhere → gate PASSES (no false-fail) ════
B=$(mktemp -d); make_monorepo "$B"
if ( cd "$B" && bash "$GATE" ) >/tmp/gh535b.$$ 2>&1; then
  ok "B neg: R2 applied to all boundary files → gate PASSES (no false-fail on correct wiring)"
else
  bad "B neg: gate FAILED while R2 is applied everywhere ($(tr '\n' ';' </tmp/gh535b.$$))"
fi

# ════ Arm C — config present but NO boundary files → graceful skip (exit 0) ════
C=$(mktemp -d); cp "$TEMPLATE" "$C/eslint.config.mjs"; mkdir -p "$C/src/lib"; printf "export const y = 2;\n" > "$C/src/lib/util.ts"
if ( cd "$C" && bash "$GATE" ) >/tmp/gh535c.$$ 2>&1 && grep -qi "nothing for R2 to govern\|nothing to verify" /tmp/gh535c.$$; then
  ok "C: no boundary files → gate skips (exit 0), does not false-fail"
else
  bad "C: gate did not gracefully skip with no boundary files ($(tr '\n' ';' </tmp/gh535c.$$))"
fi

# ════ Arm D — eslint absent (no injected/real runner) → graceful SKIP (exit 0) ════
D=$(mktemp -d); make_monorepo "$D"
# Unset the injected runner AND blank PATH so no eslint/npx is resolvable → the SKIP arm.
if ( cd "$D" && env -u AIF_ESLINT_CMD PATH="/nonexistent" /bin/bash "$GATE" ) >/tmp/gh535d.$$ 2>&1; then
  grep -qi "eslint not available" /tmp/gh535d.$$ && ok "D: eslint absent → gate skips (exit 0) with a clear message" || ok "D: eslint absent → gate exits 0 (skip)"
else
  bad "D: gate hard-failed when eslint is absent (should skip) ($(tr '\n' ';' </tmp/gh535d.$$))"
fi

rm -f "$FAKE" /tmp/gh535a.$$ /tmp/gh535b.$$ /tmp/gh535c.$$ /tmp/gh535d.$$ 2>/dev/null
echo ""; echo "PASS=$PASS FAIL=$FAIL"; [ "$FAIL" -eq 0 ]

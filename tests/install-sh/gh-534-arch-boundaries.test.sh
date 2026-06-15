#!/usr/bin/env bash
# gh-534-arch-boundaries.test.sh — monorepo boundary rules in the shipped dependency-cruiser config
# + the R3 inertness detector (check-arch-boundaries.sh), the alarm R3 lacked (unlike R2 check:globs).
#
# SCOPE NOTE (mirrors arch-target-monorepo.test.sh): a full `depcruise` run needs the consumer
# toolchain and is out of this dependency-free harness. We assert the shipped rules + config validity
# + a behavioral REGEX arm (proves the rule reaches the #534 repro path), then exercise the detector
# directly on with/without-boundary configs.
#
# PAIRED-NEGATIVES: Arm B flips Arm A's verdict (detector FAILS a monorepo config lacking the rule);
# behavioral-neg proves the monorepo pattern stays inert on a flat path (no false-positive).
set -uo pipefail
REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
GATE="$REPO_ROOT/packages/core/audit-self/check-arch-boundaries.sh"
CFG_SRC="$REPO_ROOT/templates/ts-server/dependency-cruiser.cjs"
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ✓ $1"; }
bad() { FAIL=$((FAIL+1)); echo "  ✗ $1"; }

# ── shipped config carries the monorepo boundary rules and is valid JS ──
grep -q 'no-package-to-app' "$CFG_SRC" && ok "config: no-package-to-app (packages↛apps) rule shipped" || bad "config: no-package-to-app missing"
grep -q 'no-cross-app' "$CFG_SRC"      && ok "config: no-cross-app (apps↔apps) rule shipped"          || bad "config: no-cross-app missing"
node -e "require('$CFG_SRC')" 2>/dev/null && ok "config: .dependency-cruiser.cjs is valid JS (require succeeds)" || bad "config: .cjs failed to require"

# ── behavioral REGEX: the new rule reaches the #534 repro paths, inert on flat ──
node -e 'process.exit((new RegExp("(?:^|/)packages/").test("packages/db/src/index.ts") && new RegExp("(?:^|/)apps/").test("apps/api/src/app.ts"))?0:1)' \
  && ok "behavioral: packages/→apps/ patterns match the #534 repro paths (enforcement reaches monorepo)" \
  || bad "behavioral: patterns do not match the repro paths"
node -e 'process.exit(new RegExp("(?:^|/)packages/").test("src/domain/x.ts")?1:0)' \
  && ok "behavioral-neg: packages/ pattern does NOT match a flat src path (rule inert on flat — no false-positive)" \
  || bad "behavioral-neg: packages/ pattern matched a flat path (would false-positive on single-project)"

# ── detector Arm A: monorepo + config WITH the boundary rule → PASS ──
A=$(mktemp -d); mkdir -p "$A/apps/api/src" "$A/packages/db/src"; cp "$CFG_SRC" "$A/.dependency-cruiser.cjs"
if ( cd "$A" && bash "$GATE" ) >/tmp/g534a.$$ 2>&1; then
  ok "A: monorepo + boundary rule present → detector PASSES"
else
  bad "A: detector FAILED on a config WITH the boundary ($(tr '\n' ';' </tmp/g534a.$$))"
fi

# ── detector Arm B (paired-negative): monorepo + layered-only config (NO boundary) → FAIL ──
B=$(mktemp -d); mkdir -p "$B/apps/api/src" "$B/packages/db/src"
cat > "$B/.dependency-cruiser.cjs" <<'CJS'
module.exports = { forbidden: [
  { name: 'no-circular', severity: 'error', from: {}, to: { circular: true } },
  { name: 'domain-no-infra', severity: 'error', from: { path: '(?:^|/)src/domain' }, to: { path: '(?:^|/)src/infrastructure' } },
] };
CJS
if ( cd "$B" && bash "$GATE" ) >/tmp/g534b.$$ 2>&1; then
  bad "B neg: detector PASSED a monorepo config with NO packages↛apps rule (silent inertness not caught)"
else
  ok "B neg: monorepo + NO boundary rule → detector FAILS (the R3 inertness alarm fires)"
fi
grep -q 'unguarded' /tmp/g534b.$$ && ok "B: failure message explains the unguarded boundary" || bad "B: failure message unclear"

# ── detector Arm C: flat repo (no apps/+packages/) → graceful skip (exit 0) ──
C=$(mktemp -d); mkdir -p "$C/src"; cp "$CFG_SRC" "$C/.dependency-cruiser.cjs"
if ( cd "$C" && bash "$GATE" ) >/tmp/g534c.$$ 2>&1 && grep -qi 'not an apps/+packages/ monorepo' /tmp/g534c.$$; then
  ok "C: flat repo → detector skips (exit 0, no false-fail on single-project)"
else
  bad "C: detector did not skip on a flat repo ($(tr '\n' ';' </tmp/g534c.$$))"
fi

rm -f /tmp/g534a.$$ /tmp/g534b.$$ /tmp/g534c.$$ 2>/dev/null
echo ""; echo "PASS=$PASS FAIL=$FAIL"; [ "$FAIL" -eq 0 ]

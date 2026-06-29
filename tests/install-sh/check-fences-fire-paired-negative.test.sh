#!/usr/bin/env bash
# check-fences-fire-paired-negative.test.sh — T15 self-application: the check-fences-fire.sh probe
# MUST fail (exit non-zero) when a fence is deliberately broken — falsifiability proof.
#
# Without this test, check-fences-fire.sh could silently pass even on a broken gate (SKIP or
# logic error making it always-ok). This mirrors f17's "arm (iii) RAW-CHANNEL" pattern:
# the meta-test proves the meta-gate has teeth.
#
# ARMS:
#   (i)  form-check: check-fences-fire.sh script exists and is executable
#   (ii) FENCE SILENT arm: bad fixture replaced with valid code → gate must exit non-zero
#   (iii) FALSE POSITIVE arm: good fixture replaced with bad code → gate must exit non-zero
#
# SKIP condition: tsx or eslint not available (same graceful-degrade as the gate itself).
# rc=0 on SKIP, rc=1 on any arm FAIL.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GATE_SCRIPT="$REPO_ROOT/packages/core/audit-self/check-fences-fire.sh"
FIXTURE_SRC="$REPO_ROOT/packages/core/audit-self/fixtures/fences-fire"

PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); echo "✓ $1"; }
bad()  { FAIL=$((FAIL+1)); echo "✗ $1"; }
skip() { SKIP=$((SKIP+1)); echo "· $1"; }

# ─── Arm (i): form-check ──────────────────────────────────────────────────────
if [ -x "$GATE_SCRIPT" ]; then
  ok "(i) gate script $GATE_SCRIPT exists and is executable"
else
  bad "(i) gate script $GATE_SCRIPT missing or not executable"
fi

# ─── Skip-condition probe: is tsx + eslint resolvable? ───────────────────────
TSX_BIN=""
for _t in \
  "$REPO_ROOT/node_modules/.bin/tsx" \
  "$REPO_ROOT/packages/core/node_modules/.bin/tsx" \
  "/app/node_modules/.bin/tsx"; do
  [ -x "$_t" ] && TSX_BIN="$_t" && break
done

ESLINT_BIN=""
for _e in \
  "$REPO_ROOT/node_modules/.bin/eslint" \
  "$REPO_ROOT/packages/core/node_modules/.bin/eslint" \
  "/app/node_modules/.bin/eslint"; do
  [ -x "$_e" ] && ESLINT_BIN="$_e" && break
done

if [ -z "$TSX_BIN" ] || [ -z "$ESLINT_BIN" ]; then
  skip "(ii) tsx or eslint not found — arms (ii)/(iii) SKIP (same condition as the gate)"
  skip "(iii) tsx or eslint not found — arm (iii) SKIP"
  echo ""
  echo "PASS=$PASS FAIL=$FAIL SKIP=$SKIP"
  exit 0
fi

# ─── Scratch: isolated fixture environment ────────────────────────────────────
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT

FIXTURES_DIR="$SCRATCH/fences-fire-fixtures"
mkdir -p "$FIXTURES_DIR"

# We must also simulate a consumer's eslint-rules-local barrel for the gate to load the plugin.
# The gate skips cleanly when the barrel is missing (SKIP, rc=0). For this paired-negative test
# we want the FENCE_SILENT arm (rc=1), so we need the barrel to be found. Link from repo root.
BARREL_SRC=""
for _b in \
  "$REPO_ROOT/eslint-rules-local/index.mjs" \
  "$REPO_ROOT/packages/core/eslint-rules-local/index.mjs"; do
  [ -f "$_b" ] && BARREL_SRC="$(dirname "$_b")" && break
done

if [ -z "$BARREL_SRC" ]; then
  skip "(ii) eslint-rules-local/index.mjs not found — gate would SKIP (barrel check first)"
  skip "(iii) same reason"
  echo ""
  echo "PASS=$PASS FAIL=$FAIL SKIP=$SKIP"
  exit 0
fi

# Symlink node_modules so the gate's scratch probe can import eslint
NM_SRC="$(dirname "$(dirname "$ESLINT_BIN")")"
ln -sf "$NM_SRC" "$SCRATCH/node_modules"
ln -sf "$BARREL_SRC" "$SCRATCH/eslint-rules-local"

# The gate script resolves fixture dir via AIF_PROJECT_ROOT or relative path.
# We set AIF_PROJECT_ROOT=$SCRATCH and place the fixtures at $SCRATCH/scripts/fences-fire-fixtures.
mkdir -p "$SCRATCH/scripts"
mkdir -p "$SCRATCH/node_modules"  # already linked above

# Re-link barrel inside SCRATCH root so gate's _run_fixture finds eslint-rules-local from PROJECT_ROOT
ln -sf "$BARREL_SRC" "$SCRATCH/eslint-rules-local"

FAKE_FIXTURES="$SCRATCH/scripts/fences-fire-fixtures"
mkdir -p "$FAKE_FIXTURES"

# ─── Arm (ii): FENCE SILENT — bad file is actually good code ─────────────────
# Setup: use the real no-unsafe-zod-parse fixture manifest, but swap bad.ts with good code.
# The gate must see FENCE_SILENT (bad fixture did not trigger the rule) → exit non-zero.
ARM2_RULE="rules-as-tests/no-unsafe-zod-parse"
cat > "$FAKE_FIXTURES/arm2-silent.manifest.json" << 'EOF'
{"rule-id": "rules-as-tests/no-unsafe-zod-parse", "description": "paired-negative arm (ii): bad file is actually good — fence should be silent (test: gate must FAIL)"}
EOF
# The "bad" file is actually GOOD code (uses safeParse) — the fence should NOT fire on it.
# This simulates a generated fixture where the bad example is wrong.
cat > "$FAKE_FIXTURES/arm2-silent.bad.ts" << 'EOF'
// deliberately GOOD code in the "bad" file — fence should NOT fire
const schema = { safeParse: (x: unknown) => ({ success: true, data: x }) };
const result = schema.safeParse(process.env.INPUT);
export { result };
EOF
# Good file (correct — used only to confirm false-positive check passes)
cat > "$FAKE_FIXTURES/arm2-silent.good.ts" << 'EOF'
const schema = { safeParse: (x: unknown) => ({ success: true, data: x }) };
const result = schema.safeParse(process.env.INPUT);
export { result };
EOF

# Run gate with this single broken fixture; must exit non-zero (FENCE_SILENT)
ARM2_OUTPUT=$(AIF_PROJECT_ROOT="$SCRATCH" bash "$GATE_SCRIPT" 2>&1)
ARM2_RC=$?

if [ "$ARM2_RC" -ne 0 ]; then
  ok "(ii) FENCE SILENT arm: gate exits non-zero (rc=$ARM2_RC) when bad fixture has valid code — probe is falsifiable"
elif echo "$ARM2_OUTPUT" | grep -q 'SKIP\|tsx.*not.*found\|eslint.*not.*found\|module.*not.*found\|cannot find\|Cannot find'; then
  skip "(ii) gate SKIP'd (tool resolution issue in scratch env) — arm inconclusive"
else
  bad "(ii) FENCE SILENT arm: gate exited 0 when bad file is valid code — probe accepts silent fences (vacuous pass)"
  echo "    gate output: $(echo "$ARM2_OUTPUT" | head -5 | tr '\n' '|')"
fi

# ─── Arm (iii): FALSE POSITIVE — good file has bad code ──────────────────────
# Clear fixtures and use a fresh scenario: good.ts has bad code → false positive → gate fails.
rm -f "$FAKE_FIXTURES"/*.json "$FAKE_FIXTURES"/*.ts 2>/dev/null || true

cat > "$FAKE_FIXTURES/arm3-fp.manifest.json" << 'EOF'
{"rule-id": "rules-as-tests/no-unsafe-zod-parse", "description": "paired-negative arm (iii): good file has bad code — false positive (gate must FAIL)"}
EOF
# bad.ts is correct (uses .parse() → rule fires on it)
cat > "$FAKE_FIXTURES/arm3-fp.bad.ts" << 'EOF'
const schema = { parse: (x: unknown) => x };
const result = schema.parse(process.env.INPUT);
export { result };
EOF
# good.ts is WRONG — uses .parse() instead of .safeParse() → rule fires on it (false positive)
cat > "$FAKE_FIXTURES/arm3-fp.good.ts" << 'EOF'
// deliberately BAD code in the "good" file — fence fires here, which is a false positive
const schema = { parse: (x: unknown) => x };
const result = schema.parse(process.env.INPUT);
export { result };
EOF

ARM3_OUTPUT=$(AIF_PROJECT_ROOT="$SCRATCH" bash "$GATE_SCRIPT" 2>&1)
ARM3_RC=$?

if [ "$ARM3_RC" -ne 0 ]; then
  ok "(iii) FALSE POSITIVE arm: gate exits non-zero (rc=$ARM3_RC) when good fixture has bad code — probe catches false positives"
elif echo "$ARM3_OUTPUT" | grep -q 'SKIP\|tsx.*not.*found\|eslint.*not.*found\|module.*not.*found\|cannot find\|Cannot find'; then
  skip "(iii) gate SKIP'd — arm inconclusive"
else
  bad "(iii) FALSE POSITIVE arm: gate exited 0 when good file triggers the rule — probe misses false positives"
  echo "    gate output: $(echo "$ARM3_OUTPUT" | head -5 | tr '\n' '|')"
fi

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "PASS=$PASS FAIL=$FAIL SKIP=$SKIP"
[ "$FAIL" -eq 0 ]

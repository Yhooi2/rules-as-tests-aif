#!/usr/bin/env bash
# FQA S3-C1 — "de-inert the shipped quality gates". Asserts install.sh lands the WIRING the
# rules need (not just the rule files): P1 tool-decisions seed, P2 all 3 skill-context, W1
# generated eslint barrel, W2 dep-cruiser config, W4 package.json scripts. Plus the P1
# PAIRED-NEGATIVE (umbrella §5): WITHOUT the seed the deps-change hook is silent (the dead
# state the audit found); WITH it, a deps change WARNs (the chain is live). The negative arm
# is what proves the fix isn't vacuous — it fails if the seed stops mattering.
set -uo pipefail
REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ✓ $1"; }
bad() { FAIL=$((FAIL+1)); echo "  ✗ $1"; }

T=$(mktemp -d)
printf '{ "name": "c1t", "version": "0.0.0", "scripts": { "test": "echo keep" } }\n' > "$T/package.json"
( cd "$T" && git init -q && bash "$REPO_ROOT/install.sh" ts-server --force ) >/dev/null 2>&1

# P1 — seed lands so deps-hash-check.sh no longer short-circuits to silent exit 0
[ -f "$T/.ai-factory/tool-decisions.md" ] && ok "P1: tool-decisions.md seeded" || bad "P1: tool-decisions.md missing"

# P2 — all 3 skill-context land (verify-list ↔ copy-list single-sourced)
n=$(find "$T/.ai-factory/skill-context" -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')
[ "$n" = "3" ] && ok "P2: 3/3 skill-context landed" || bad "P2: only $n/3 skill-context"
[ -f "$T/.ai-factory/skill-context/aif-orchestrator-discipline/SKILL.md" ] && ok "P2: aif-orchestrator-discipline present (was the dropped one)" || bad "P2: aif-orchestrator-discipline missing"

# W1 — barrel generated, valid, covers every landed rule file (eslint.config imports it)
[ -f "$T/eslint-rules-local/index.ts" ] && ok "W1: eslint barrel generated" || bad "W1: eslint barrel missing"
grep -q 'export default plugin' "$T/eslint-rules-local/index.ts" 2>/dev/null && ok "W1: barrel exports a plugin" || bad "W1: barrel malformed"
nf=$(find "$T"/eslint-rules-local -maxdepth 1 -name '*.ts' ! -name index.ts | wc -l | tr -d ' ')
ni=$(grep -c '^import ' "$T/eslint-rules-local/index.ts")
[ "$nf" = "$ni" ] && [ "$nf" -ge 3 ] && ok "W1: barrel covers all $nf rule files" || bad "W1: barrel $ni imports vs $nf rule files"

# W2 — arch config lands so arch:check has something to run against
[ -f "$T/.dependency-cruiser.cjs" ] && ok "W2: .dependency-cruiser.cjs landed" || bad "W2: .dependency-cruiser.cjs missing"

# W4 — canonical scripts merged non-destructively (existing kept, gate scripts added)
node -e 'const s=require(process.argv[1]).scripts||{}; process.exit((s.lint&&s["arch:check"]&&s.validate&&s["test:coverage"]&&s.test==="echo keep")?0:1)' "$T/package.json" \
  && ok "W4: canonical scripts merged, existing 'test' kept" || bad "W4: scripts merge wrong"

# P1 PAIRED-NEGATIVE — the load-bearing arm
HOOK="$REPO_ROOT/.claude/hooks/deps-hash-check.sh"
N=$(mktemp -d); printf '{ "name":"n","version":"0.0.0","dependencies":{"x":"1"} }\n' > "$N/package.json"
out_neg=$( cd "$N" && echo '{}' | bash "$HOOK" 2>&1 )
[ -z "$out_neg" ] && ok "P1-neg: no tool-decisions.md → hook SILENT (reproduces the dead state)" || bad "P1-neg: hook spoke without a seed: $out_neg"
out_pos=$( cd "$T" && echo '{}' | bash "$HOOK" 2>&1 )
echo "$out_pos" | grep -qi 'tool-bootstrap' && ok "P1-pos: seed + sentinel hash → WARN (chain is LIVE)" || bad "P1-pos: no WARN with seed present"

echo ""; echo "PASS=$PASS FAIL=$FAIL"; [ "$FAIL" -eq 0 ]

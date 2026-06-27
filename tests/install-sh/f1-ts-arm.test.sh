#!/usr/bin/env bash
# cih-s1 F1 — "ship the dispatcher's TS arm". The shipped dispatcher
# (packages/core/templates/shared/husky-pre-push.sh) execs
# `$REPO_ROOT/packages/core/hooks/pre-push.ts` when Node≥20 + that file is present,
# else falls to the bash fallback. Before this fix install.sh shipped only the
# fallback, so the TS arm was unreachable in every consumer install. This test runs
# the REAL install pipeline and asserts pre-push.ts + its bounded static import
# closure land under packages/core/hooks/ with the relative layout the dispatcher
# resolves. PAIRED-NEGATIVE: the fallback must still land (we ADD the TS arm, we
# don't replace it) AND the dynamically-import()ed guard-liveness.ts must NOT ship
# (vendoring it pulls eslint + the eslint-rules barrel and trips the consumer's
# prettier/dependency-cruiser gates) — that negative arm proves the closure is
# bounded, not "ship everything". The static closure itself is derived from the
# shipped pre-push.ts by the drift-guard below, so it can't silently go stale (#735).
set -uo pipefail
REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ✓ $1"; }
bad() { FAIL=$((FAIL+1)); echo "  ✗ $1"; }

T=$(mktemp -d)
printf '{ "name": "f1t", "version": "0.0.0" }\n' > "$T/package.json"
( cd "$T" && git init -q && bash "$REPO_ROOT/install.sh" ts-server --force ) >/dev/null 2>&1

H="$T/packages/core/hooks"

# TS-core entrypoint the dispatcher execs
[ -f "$H/pre-push.ts" ] && ok "pre-push.ts shipped (dispatcher TS arm reachable)" || bad "pre-push.ts missing"

# Bounded static import closure (re-derived to fixpoint)
[ -f "$H/utils/run-check.ts" ]  && ok "utils/run-check.ts shipped"  || bad "utils/run-check.ts missing"
[ -f "$H/utils/git.ts" ]        && ok "utils/git.ts shipped"        || bad "utils/git.ts missing"
[ -f "$H/checks/prior-art.ts" ] && ok "checks/prior-art.ts shipped" || bad "checks/prior-art.ts missing"
[ -f "$H/checks/s17.ts" ]       && ok "checks/s17.ts shipped"       || bad "checks/s17.ts missing"
# #735: pre-push.ts:32 STATICALLY imports this — omitting it crashes the hook at load
# (ERR_MODULE_NOT_FOUND) on every push, before any check runs.
[ -f "$H/checks/unpinned-tool-install.ts" ] && ok "checks/unpinned-tool-install.ts shipped (static import — #735)" \
  || bad "checks/unpinned-tool-install.ts missing — pre-push.ts statically imports it → ERR_MODULE_NOT_FOUND on every push (#735)"

# Drift guard (#735's class): derive the static closure from the SHIPPED pre-push.ts instead of
# hand-listing it — every `./checks/*.ts` / `./utils/*.ts` it statically imports must be on disk.
# A literal copy-list in 50-hooks.sh cannot track the import graph by eye (that drift IS #735).
_miss=0
while IFS= read -r _rel; do
  [ -f "$H/$_rel" ] || { bad "static import '$_rel' (pre-push.ts) NOT shipped — hook crashes at load"; _miss=1; }
done < <(grep -oE "from '\./(checks|utils)/[a-z0-9-]+\.ts'" "$H/pre-push.ts" | sed "s/from '\.\///; s/'\$//")
[ "$_miss" -eq 0 ] && ok "drift-guard: every static ./checks|./utils import in pre-push.ts is shipped"

# GH #532 — the hooks-scoped {"type":"module"} marker must ship so the ESM-authored pre-push.ts
# loads as ESM in the consumer (whose root package.json — here "f1t", no "type" — defaults to CJS).
# Without it tsx's require(esm) bridge dies with ERR_REQUIRE_CYCLE_MODULE on Node ≥22, before any
# check runs. Structural assertion (catchable on CI's Node 20, where the runtime crash itself isn't).
[ -f "$H/package.json" ] && grep -q '"type"[[:space:]]*:[[:space:]]*"module"' "$H/package.json" \
  && ok "GH#532: hooks/package.json ships with type:module (ESM-loads the shipped .ts hook)" \
  || bad "GH#532: hooks/package.json missing or lacks type:module — shipped pre-push.ts will load as CJS and crash on Node ≥22"

# PAIRED-NEGATIVE arm 1 — fallback still lands (TS arm is additive, not a replacement)
[ -f "$H/pre-push.fallback.sh" ] && ok "neg: bash fallback still shipped (TS arm is additive)" || bad "neg: fallback lost"

# PAIRED-NEGATIVE arm 2 — guard-liveness.ts is DYNAMICALLY import()ed (not part of the static
# closure), so the minimal #735 fix deliberately does NOT vendor it: shipping it would pull eslint
# + ../../eslint-rules/index.ts into the consumer and trip its prettier + dependency-cruiser gates.
# (NB: its dynamic-import catch currently die()s rather than skipping when absent — so the
# change-scoped guard-liveness gate still aborts a rule-manifest push; tracked separately.)
[ ! -f "$H/checks/guard-liveness.ts" ] && ok "neg: guard-liveness.ts NOT shipped (dynamic; vendoring it trips prettier/depcruise)" || bad "neg: guard-liveness.ts leaked — would trip consumer prettier/depcruise gates"

echo ""; echo "PASS=$PASS FAIL=$FAIL"; [ "$FAIL" -eq 0 ]

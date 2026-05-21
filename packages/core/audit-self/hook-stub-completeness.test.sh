#!/usr/bin/env bash
# hook-stub-completeness.test.sh — audit-self meta-test.
#
# Invariant: every hard-fail self-test invocation in .husky/pre-push has a
# matching stub in EVERY make_test_repo()-equivalent block under tests/.
# Without this, a new hard-fail kills the hook before reaching the test's
# actual subject, causing 5-of-8-style false-passes (Wave 8.3 regression).
#
# Wave 10 migration note: when TS-core hook infra lands, port this audit
# to packages/core/principles/11-hook-stub-completeness.test.ts.
# Bash impl is the regression-fixture spec; TS port must produce identical
# violation output on the same fixture.
# See: docs/meta-factory/research-patches/2026-05-13-memory-to-docs-codification-audit.md §10.A
#      .claude/orchestrator-prompts/wave-10-hook-architecture/kickoff.md

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
# Wave 10.1: the self-test invocations moved from the bash body of .husky/pre-push
# (now a 10-line dispatcher) into the TS orchestrator. They remain present there
# as literal `packages/core/audit-self/<name>.test.sh` string args to runCheck(),
# so the grep below still finds the full hard-fail set.
HOOK="${REPO_ROOT}/packages/core/hooks/pre-push.ts"
TESTS_DIR="${REPO_ROOT}/tests/hooks"

# Extract hard-fail invocations from the pre-push orchestrator.
# Pattern: literal `packages/core/audit-self/<name>.test.sh` runCheck args.
hard_fail_scripts=$(grep -oE 'packages/core/audit-self/[a-z0-9-]+\.test\.sh' "$HOOK" | sort -u)

if [ -z "$hard_fail_scripts" ]; then
  echo "❌ Sanity: no hard-fail invocations detected in $HOOK"
  exit 1
fi

# For each test file using make_test_repo, verify stubs exist for every
# hard-fail script. Detection: stubs are created at
# $tmp/packages/core/audit-self/<name>.test.sh via direct heredoc.
# Pattern: cat > "$tmp/packages/core/audit-self/foo.test.sh" <<'STUB'
violations=0
for test_file in "$TESTS_DIR"/*.test.sh; do
  if ! grep -q 'make_test_repo()' "$test_file"; then
    continue
  fi

  # Extract stubbed script names from the test file's heredoc creations.
  stubbed=$(grep -oE 'packages/core/audit-self/[a-z0-9-]+\.test\.sh' "$test_file" | sort -u)

  for hard_fail in $hard_fail_scripts; do
    if ! echo "$stubbed" | grep -q "^${hard_fail}$"; then
      hard_fail_basename=$(basename "$hard_fail")
      echo "❌ ${test_file}: missing stub for ${hard_fail_basename}"
      echo "   .husky/pre-push invokes ${hard_fail} as hard-fail."
      echo "   Without stub, hook will fail before reaching the test's intended section."
      violations=$((violations + 1))
    fi
  done
done

if [ "$violations" -gt 0 ]; then
  echo ""
  echo "❌ ${violations} stub-completeness violation(s) detected."
  echo "Fix: add a 4-line heredoc stub (#!/usr/bin/env bash + exit 0 + chmod +x) for each missing dep."
  exit 1
fi

echo "✅ Hook stub completeness: every hard-fail invocation in .husky/pre-push has matching stubs in all make_test_repo()-using tests."

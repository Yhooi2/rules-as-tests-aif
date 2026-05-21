#!/usr/bin/env bash
# Negative test: enforce-husky-presence gate logic catches a stubbed hook.
# Simulates the CI gate without pushing to GitHub.
#
# Usage: bash tests/hooks/test-enforce-husky-presence.sh
# Exit 0 = gate correctly rejects stub; Exit 1 = gate has false-pass (FAIL)
set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
TMP=$(mktemp -d)

cleanup() {
  # Restore originals if backup exists
  if [ -d "$TMP/.husky-orig" ]; then
    rm -rf "$REPO_ROOT/.husky"
    mv "$TMP/.husky-orig" "$REPO_ROOT/.husky"
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT

# Back up real hooks
cp -r "$REPO_ROOT/.husky" "$TMP/.husky-orig"

# Replace pre-commit with a stub (minimal, no real probes)
printf '#!/usr/bin/env bash\nexit 0\n' > "$REPO_ROOT/.husky/pre-commit"
chmod +x "$REPO_ROOT/.husky/pre-commit"

# Replicate the enforce-husky-presence CI gate logic
GATE_PASS=0
for hook in "$REPO_ROOT/.husky/pre-commit" "$REPO_ROOT/.husky/pre-push"; do
  if [ ! -f "$hook" ]; then
    echo "GATE would FAIL: missing $hook"
    GATE_PASS=1
    continue
  fi
  if [ ! -x "$hook" ]; then
    echo "GATE would FAIL: $hook not executable"
    GATE_PASS=1
    continue
  fi
  # Kept in sync with .github/workflows/audit-self.yml#enforce-husky-presence.
  # Wave 10.1: a pre-push hook delegating to the TS orchestrator counts as non-trivial.
  if ! grep -qE '\b(actionlint|zizmor|bash -n|json\.load|yaml\.safe_load)\b|packages/core/hooks/pre-push\.ts' "$hook"; then
    echo "GATE would FAIL: $hook lacks expected probes (looks empty/stub)"
    GATE_PASS=1
  fi
done

if [ "$GATE_PASS" -eq 1 ]; then
  echo "PASS: negative test verified — gate correctly rejects stubbed pre-commit hook"
  exit 0
else
  echo "FAIL: gate did NOT catch the stubbed hook — enforce-husky-presence has a false-pass"
  exit 1
fi

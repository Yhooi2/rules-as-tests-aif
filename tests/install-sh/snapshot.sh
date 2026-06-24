#!/usr/bin/env bash
# tests/install-sh/snapshot.sh — Snapshot test harness for install.sh modular refactor.
#
# Usage:
#   SNAPSHOT_MODE=capture  bash tests/install-sh/snapshot.sh [stack]
#   SNAPSHOT_MODE=compare  bash tests/install-sh/snapshot.sh [stack]
#
# SNAPSHOT_MODE=capture : run install.sh, record the installed-tree fingerprint under
#   tests/install-sh/baselines/<stack>/{greenfield,brownfield}.fingerprint
# SNAPSHOT_MODE=compare : run install.sh, compute the fingerprint, diff against the
#   committed baseline. Exit 1 if any difference is detected.
#
# Byte-identical guarantee (O5): the fingerprint covers the *installed filesystem tree*,
# not stdout. Reordering independent copy_safe calls changes console transcript order
# but does NOT change the tree → the snapshot remains green.
#
# compute_fingerprint <dir> : sorted list of all regular files (excluding .git/ and
# node_modules/) with their sha256 checksums, relative to <dir>.
#
# All 4 stacks are tested; each stack has a greenfield (fresh empty dir + package.json)
# and a brownfield (install once, then reinstall to test idempotence) scenario.

set -euo pipefail

PKG_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BASELINES_DIR="$PKG_ROOT/tests/install-sh/baselines"
SNAPSHOT_MODE="${SNAPSHOT_MODE:-compare}"

# ─── helpers ────────────────────────────────────────────────────────────────

compute_fingerprint() {
  local dir="$1"
  # Find all regular files, exclude .git/ and node_modules/, sort deterministically,
  # compute sha256 for each. Output: "<hash>  <relative-path>" per line.
  # sha256sum on Linux, shasum -a 256 on macOS.
  local sha_cmd
  if command -v sha256sum >/dev/null 2>&1; then
    sha_cmd="sha256sum"
  else
    sha_cmd="shasum -a 256"
  fi

  find "$dir" \
    -not -path '*/.git/*' \
    -not -path '*/node_modules/*' \
    -not -name '.git' \
    -type f \
    | sort \
    | while IFS= read -r f; do
        rel="${f#"$dir/"}"
        $sha_cmd "$f" | awk -v r="$rel" '{print $1 "  " r}'
      done
}

make_project_dir() {
  # Create a minimal consumer project directory with a package.json
  local tmpdir
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/package.json" << 'EOF'
{
  "name": "test-consumer",
  "version": "0.1.0",
  "scripts": {}
}
EOF
  printf '%s' "$tmpdir"
}

run_install() {
  local stack="$1"
  local project_dir="$2"
  # Run install.sh non-interactively (pass stack directly, no TTY needed)
  # We cannot actually run install.sh end-to-end in CI without node/npm tools,
  # so we run in --dry-run=false but skip the dev-dep install step (non-interactive
  # without --full means default-No for the dep install prompt). That is correct:
  # we want the FILE COPY side effects, not the npm install.
  # In this environment node IS available, so the scripts-merge and barrel-gen run.
  # Settings.json registration via jq: jq may or may not be present; that's fine
  # (the install handles absence gracefully).
  bash "$PKG_ROOT/install.sh" "$stack" 2>/dev/null || true
}

run_capture() {
  local stack="$1"
  echo "▶ Capturing baseline for stack: $stack"

  # ── Greenfield ───────────────────────────────────────────────────────────
  local gf_dir
  gf_dir="$(make_project_dir)"
  echo "  [greenfield] install dir: $gf_dir"
  ( cd "$gf_dir" && run_install "$stack" "$gf_dir" )
  compute_fingerprint "$gf_dir" > "$BASELINES_DIR/$stack/greenfield.fingerprint"
  rm -rf "$gf_dir"
  echo "  ✓ greenfield baseline written: $BASELINES_DIR/$stack/greenfield.fingerprint"

  # ── Brownfield ───────────────────────────────────────────────────────────
  local bf_dir
  bf_dir="$(make_project_dir)"
  echo "  [brownfield] first install (seed)…"
  ( cd "$bf_dir" && run_install "$stack" "$bf_dir" )
  echo "  [brownfield] second install (idempotence check)…"
  ( cd "$bf_dir" && run_install "$stack" "$bf_dir" )
  compute_fingerprint "$bf_dir" > "$BASELINES_DIR/$stack/brownfield.fingerprint"
  rm -rf "$bf_dir"
  echo "  ✓ brownfield baseline written: $BASELINES_DIR/$stack/brownfield.fingerprint"
}

run_compare() {
  local stack="$1"
  local exit_code=0
  echo "▶ Comparing snapshot for stack: $stack"

  # ── Greenfield ───────────────────────────────────────────────────────────
  local gf_baseline="$BASELINES_DIR/$stack/greenfield.fingerprint"
  if [ ! -f "$gf_baseline" ]; then
    echo "  ❌ MISSING baseline: $gf_baseline"
    echo "     Run SNAPSHOT_MODE=capture to create it."
    return 1
  fi
  local gf_dir
  gf_dir="$(make_project_dir)"
  ( cd "$gf_dir" && run_install "$stack" "$gf_dir" )
  local gf_actual
  gf_actual="$(compute_fingerprint "$gf_dir")"
  rm -rf "$gf_dir"
  if ! diff <(cat "$gf_baseline") <(echo "$gf_actual") >/dev/null 2>&1; then
    echo "  ❌ DIFF detected (greenfield, $stack):"
    diff <(cat "$gf_baseline") <(echo "$gf_actual") || true
    exit_code=1
  else
    echo "  ✓ greenfield: no diff"
  fi

  # ── Brownfield ───────────────────────────────────────────────────────────
  local bf_baseline="$BASELINES_DIR/$stack/brownfield.fingerprint"
  if [ ! -f "$bf_baseline" ]; then
    echo "  ❌ MISSING baseline: $bf_baseline"
    echo "     Run SNAPSHOT_MODE=capture to create it."
    return 1
  fi
  local bf_dir
  bf_dir="$(make_project_dir)"
  ( cd "$bf_dir" && run_install "$stack" "$bf_dir" )
  ( cd "$bf_dir" && run_install "$stack" "$bf_dir" )
  local bf_actual
  bf_actual="$(compute_fingerprint "$bf_dir")"
  rm -rf "$bf_dir"
  if ! diff <(cat "$bf_baseline") <(echo "$bf_actual") >/dev/null 2>&1; then
    echo "  ❌ DIFF detected (brownfield, $stack):"
    diff <(cat "$bf_baseline") <(echo "$bf_actual") || true
    exit_code=1
  else
    echo "  ✓ brownfield: no diff"
  fi

  return $exit_code
}

# ─── main ────────────────────────────────────────────────────────────────────

STACKS_ALL=(ts-server react-next react-spa react-native)

if [ $# -ge 1 ]; then
  STACKS=("$1")
else
  STACKS=("${STACKS_ALL[@]}")
fi

overall=0
for stack in "${STACKS[@]}"; do
  if ! [[ " ts-server react-next react-spa react-native " == *" $stack "* ]]; then
    echo "❌ Unknown stack: $stack" >&2
    exit 1
  fi
  mkdir -p "$BASELINES_DIR/$stack"
  if [ "$SNAPSHOT_MODE" = "capture" ]; then
    run_capture "$stack"
  elif [ "$SNAPSHOT_MODE" = "compare" ]; then
    run_compare "$stack" || overall=1
  else
    echo "❌ Unknown SNAPSHOT_MODE: $SNAPSHOT_MODE (use capture or compare)" >&2
    exit 1
  fi
done

if [ "$SNAPSHOT_MODE" = "compare" ]; then
  if [ "$overall" -eq 0 ]; then
    echo ""
    echo "✅ Snapshot comparison passed — installed tree is byte-identical."
  else
    echo ""
    echo "❌ Snapshot comparison FAILED — installed tree differs from baseline."
    exit 1
  fi
fi

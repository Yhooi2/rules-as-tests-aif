#!/usr/bin/env bash
# setup.d/40-configs.sh — §4 Scripts (816-856) + §5a configs (858-890) + §5b' ESLint rules (938-992)
#                          + §6a configs-only (994-1005 ts-server branch + 1009-1017 react-next branch,
#                          NOT the workflow copies at 1006-1008/1018-1020)
# Source: install.sh §4 lines 816-856, §5a lines 858-890, §5b' lines 938-992, §6a configs lines 994-1021
# Globals consumed: FORCE, DRY_RUN, SKIPPED, PKG_ROOT, PROJECT_ROOT, STACK
# shellcheck source=./lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Lib-only guard: sourced for tests, expose helpers without running layer actions.
if [ "${INSTALL_SH_LIB_ONLY:-}" = "1" ]; then
  return 0 2>/dev/null || true
fi

# ─── 4. Scripts ─────────────────────────────────────────
echo "▶ Scripts → scripts/"
mkdir_safe "$PROJECT_ROOT/scripts"
copy_safe "$PKG_ROOT/packages/core/audit-self/audit-ai-docs.sh" "$PROJECT_ROOT/scripts/audit-ai-docs.sh"
chmod_safe +x "$PROJECT_ROOT/scripts/audit-ai-docs.sh" 2>/dev/null || true
# R4 probe (ts-morph) invoked by audit-ai-docs.sh via `npx tsx scripts/audit-r4.ts`.
copy_safe "$PKG_ROOT/packages/core/probes/audit-r4.ts" "$PROJECT_ROOT/scripts/audit-r4.ts"
# cih-s3 F3 "+V": glob-liveness gate — fails if a custom rule matches zero source files
# (silent-inertness alarm). Dependency-free bash; run pre-PR once the layout settles.
copy_safe "$PKG_ROOT/packages/core/audit-self/check-rule-globs.sh" "$PROJECT_ROOT/scripts/check-rule-globs.sh"
chmod_safe +x "$PROJECT_ROOT/scripts/check-rule-globs.sh" 2>/dev/null || true
# GH #535 "+E": deep R2-binding gate. check:globs only proves a rule's globs MATCH files; on a
# monorepo with per-package eslint configs that re-export a base NOT wiring R2, the rule stays
# silently inert while validate/lint pass. This gate resolves the actually-applied config per
# boundary file via `eslint --print-config` and FAILS when R2 is absent — catching that false-green
# without false-failing a correct re-export-of-root. Skips cleanly when eslint isn't installed yet.
copy_safe "$PKG_ROOT/packages/core/audit-self/check-rule-enforced.sh" "$PROJECT_ROOT/scripts/check-rule-enforced.sh"
chmod_safe +x "$PROJECT_ROOT/scripts/check-rule-enforced.sh" 2>/dev/null || true
# GH #547 Point 2: R2 boundary probe (C1) + the shared N/A-marker reader (C4). detect-r2-boundary.sh
# classifies the repo (boundary-present | no-boundary-confident | ambiguous) by READING it; the
# installer (§6b-bis below) and BOTH inertness gates consume it. r2-na-marker.sh is sourced by
# check-rule-globs.sh + check-rule-enforced.sh so they never diverge on honoring a recorded R2 N/A.
copy_safe "$PKG_ROOT/packages/core/audit-self/detect-r2-boundary.sh" "$PROJECT_ROOT/scripts/detect-r2-boundary.sh"
chmod_safe +x "$PROJECT_ROOT/scripts/detect-r2-boundary.sh" 2>/dev/null || true
copy_safe "$PKG_ROOT/packages/core/audit-self/r2-na-marker.sh" "$PROJECT_ROOT/scripts/r2-na-marker.sh"
chmod_safe +x "$PROJECT_ROOT/scripts/r2-na-marker.sh" 2>/dev/null || true
# GH #534: R3 (arch) inertness alarm — the dependency-cruiser analog of check:globs. The shipped
# arch config carries layout-agnostic monorepo boundary rules (packages↛apps / apps↔apps), but
# dependency-cruiser has no built-in "rule matched nothing" report, so on a monorepo whose arch
# config lacks those rules, arch:check passes green while the boundary is unguarded — silently.
# This gate FAILS on an apps/+packages/ monorepo when no packages↛apps rule is present.
copy_safe "$PKG_ROOT/packages/core/audit-self/check-arch-boundaries.sh" "$PROJECT_ROOT/scripts/check-arch-boundaries.sh"
chmod_safe +x "$PROJECT_ROOT/scripts/check-arch-boundaries.sh" 2>/dev/null || true
# cih-s3 F14: lint-staged binary-resolution gate — fails if a .lintstagedrc command's binary
# can't resolve from the cwd lint-staged would use (the ENOENT-before-commit alarm on monorepos).
copy_safe "$PKG_ROOT/packages/core/audit-self/check-lintstaged-resolves.sh" "$PROJECT_ROOT/scripts/check-lintstaged-resolves.sh"
chmod_safe +x "$PROJECT_ROOT/scripts/check-lintstaged-resolves.sh" 2>/dev/null || true
if [ "$STACK" = "react-next" ]; then
  copy_safe "$PKG_ROOT/packages/preset-next-15-canonical/audit-self/audit-ai-docs.react-next.sh" "$PROJECT_ROOT/scripts/audit-ai-docs.react-next.sh"
  chmod_safe +x "$PROJECT_ROOT/scripts/audit-ai-docs.react-next.sh" 2>/dev/null || true
fi

# ─── 5. Shared templates ────────────────────────────────
echo "▶ Shared templates → project root"
copy_safe "$PKG_ROOT/packages/core/templates/shared/.nvmrc" "$PROJECT_ROOT/.nvmrc"
copy_safe "$PKG_ROOT/packages/core/templates/shared/.lintstagedrc.json" "$PROJECT_ROOT/.lintstagedrc.json"
# cih-s3 F14 (M3): in a workspace, a single root .lintstagedrc runs `eslint` from git-root; in
# a pnpm/isolated-node_modules monorepo the per-package eslint binary isn't at root → ENOENT
# blocks the commit. Drop a per-package .lintstagedrc.json stub in each EXISTING package dir so
# lint-staged runs with cwd=that package and resolves the local binary. PM-agnostic (no
# `pnpm exec`). Best-effort — packages added later need the same stub; scripts/check-lintstaged-
# resolves.sh is the alarm that catches an unstubbed package before its first blocked commit.
if [ "$DRY_RUN" != "--dry-run" ] && { [ -f "$PROJECT_ROOT/pnpm-workspace.yaml" ] || grep -q '"workspaces"' "$PROJECT_ROOT/package.json" 2>/dev/null; }; then
  _ndrop=0
  while IFS= read -r _pkgjson; do
    _pkgdir=$(dirname "$_pkgjson")
    [ "$_pkgdir" = "$PROJECT_ROOT" ] && continue
    if [ ! -f "$_pkgdir/.lintstagedrc.json" ]; then
      cp "$PROJECT_ROOT/.lintstagedrc.json" "$_pkgdir/.lintstagedrc.json" && _ndrop=$((_ndrop + 1))
    fi
  done < <(find "$PROJECT_ROOT" -name node_modules -prune -o -name .git -prune -o -name package.json -print 2>/dev/null)
  echo "  ✓ workspace detected → dropped $_ndrop per-package .lintstagedrc.json stub(s) (F14 lint-staged cwd fix)"
fi
# cih-s3 F15: keep prettier off the generated RULES.md table region (rendered SSOT, not
# format-stable) so a `*.md → prettier --write` lint-staged step can't reflow it.
# GH #531 (reopen): merge (not skip-if-exists) so a BROWNFIELD consumer with its own
# .prettierignore still gets the AIF exclusions — otherwise the generated RULES.md re-breaks
# `prettier --check .`. Greenfield path stays byte-identical (delegates to copy_safe).
merge_prettierignore "$PKG_ROOT/packages/core/templates/shared/.prettierignore" "$PROJECT_ROOT/.prettierignore"
# GH #531: ship the Prettier config so the consumer's `format:check` (prettier --check .) uses the
# same style the shipped artefacts are formatted in (singleQuote — the framework's existing TS/JS
# style). Without it, prettier defaults (double-quote) would flag every shipped .ts/.mjs/.cjs.
# copy_safe (skip-if-exists) never clobbers a consumer's own prettier config.
copy_safe "$PKG_ROOT/.prettierrc.json" "$PROJECT_ROOT/.prettierrc.json"
copy_safe "$PKG_ROOT/packages/core/templates/shared/tsconfig.json" "$PROJECT_ROOT/tsconfig.json"

# ─── 5b'. Custom ESLint rules plugin (used by eslint.config.mjs) ───
echo "▶ Custom ESLint rules → eslint-rules-local/"
mkdir_safe "$PROJECT_ROOT/eslint-rules-local"
# Generic rules (core): no-direct-time-randomness, no-unsafe-zod-parse, require-otel-span
for f in "$PKG_ROOT"/packages/core/eslint-rules/*.ts; do
  case "$f" in
    *.test.ts) continue ;;
    */index.ts) continue ;;
  esac
  copy_safe "$f" "$PROJECT_ROOT/eslint-rules-local/$(basename "$f")"
done
if [ "$STACK" = "react-next" ]; then
  # Stack-specific rules (preset): no-server-imports-in-client, require-form-safe-parse, require-use-server-directive
  for f in "$PKG_ROOT"/packages/preset-next-15-canonical/eslint-rules/*.ts; do
    case "$f" in
      *.test.ts) continue ;;
      */index.ts) continue ;;
    esac
    copy_safe "$f" "$PROJECT_ROOT/eslint-rules-local/$(basename "$f")"
  done
fi

# Generate the barrel that eslint.config.mjs imports (`./eslint-rules-local/index.ts`).
# FQA S1-A W1: install copied the rule FILES but the copy loop skips `*/index.ts`, so the
# barrel never landed → eslint hit a missing-module error on config load → ALL custom rules
# (and all linting) died. Generated from whatever rule files landed above, so it always matches
# the shipped set (ts-server: 3 core; react-next: 3 core + 3 preset) with zero template-drift.
# Convention (holds for all 6 rules): file `foo-bar.ts` exports `fooBar`; rule key = `foo-bar`.
if [ -n "$DRY_RUN" ]; then
  echo "  [dry-run] would generate: eslint-rules-local/index.ts (barrel over copied rule files)"
else
  _barrel="$PROJECT_ROOT/eslint-rules-local/index.ts"
  {
    echo "// AUTO-GENERATED by install.sh — re-exports the sibling rule files as one ESLint"
    echo "// plugin. Regenerated each install to match the shipped rule set; do not hand-edit."
    for _rf in "$PROJECT_ROOT"/eslint-rules-local/*.ts; do
      _b=$(basename "$_rf" .ts); [ "$_b" = "index" ] && continue
      _camel=$(echo "$_b" | awk -F- '{o=$1; for(i=2;i<=NF;i++) o=o toupper(substr($i,1,1)) substr($i,2); print o}')
      echo "import { $_camel } from './$_b.ts';"
    done
    echo "const plugin = {"
    echo "  meta: { name: '@rules-as-tests/local-eslint-rules', version: '0.1.0' },"
    echo "  rules: {"
    for _rf in "$PROJECT_ROOT"/eslint-rules-local/*.ts; do
      _b=$(basename "$_rf" .ts); [ "$_b" = "index" ] && continue
      _camel=$(echo "$_b" | awk -F- '{o=$1; for(i=2;i<=NF;i++) o=o toupper(substr($i,1,1)) substr($i,2); print o}')
      echo "    '$_b': $_camel,"
    done
    echo "  },"
    echo "};"
    echo "export default plugin;"
    echo "export const rules = plugin.rules;"
  } > "$_barrel"
  echo "  ✓ generated eslint-rules-local/index.ts ($(grep -c '^import ' "$_barrel") rules)"
fi

# ─── 6a. Stack-specific config templates (NOT workflow copies — those go to 60-ci.sh) ─
echo "▶ Stack-specific templates ($STACK) → project root"
if [ "$STACK" = "ts-server" ]; then
  copy_safe "$PKG_ROOT/templates/ts-server/eslint.config.mjs" "$PROJECT_ROOT/eslint.config.mjs"
  copy_safe "$PKG_ROOT/templates/ts-server/vitest.config.ts" "$PROJECT_ROOT/vitest.config.ts"
  # Ship the arch config directly (FQA S1-A W2: deferring to legacy setup.sh left arch:check
  # with no config on the ./setup path — the template exists, just copy it).
  copy_safe "$PKG_ROOT/templates/ts-server/dependency-cruiser.cjs" "$PROJECT_ROOT/.dependency-cruiser.cjs"
  copy_safe "$PKG_ROOT/templates/ts-server/stryker.config.json" "$PROJECT_ROOT/stryker.config.json"
  patch_stryker_package_manager
elif [ "$STACK" = "react-next" ]; then
  copy_safe "$PKG_ROOT/packages/preset-next-15-canonical/templates/eslint.config.react.mjs" "$PROJECT_ROOT/eslint.config.mjs"
  copy_safe "$PKG_ROOT/packages/preset-next-15-canonical/templates/vitest.config.ts" "$PROJECT_ROOT/vitest.config.ts"
  copy_safe "$PKG_ROOT/packages/preset-next-15-canonical/templates/playwright.config.ts" "$PROJECT_ROOT/playwright.config.ts"
  # Ship the arch config (FQA S1-A W2). The ts-server base (no-circular/no-orphans) is
  # stack-agnostic; a react-tailored layering config is a follow-up (residual R-1).
  copy_safe "$PKG_ROOT/templates/ts-server/dependency-cruiser.cjs" "$PROJECT_ROOT/.dependency-cruiser.cjs"
  copy_safe "$PKG_ROOT/templates/ts-server/stryker.config.json" "$PROJECT_ROOT/stryker.config.json"
  patch_stryker_package_manager
fi

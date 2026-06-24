#!/usr/bin/env bash
# setup.d/30-templates.sh — §3a AI Factory base templates + §3b tool-decisions.md +
#   §3d stack ARCH/RULES + aif-handoff integration note.
# S0 rows:
#   §3a AI Factory templates → L802-822 (original install.sh)
#   §3b tool-decisions.md seed → L824-830
#   §3d react-next/spa/native ARCH → L848-858
#   aif-handoff integration note → L861-864
#
# Note: §3c skill-context loop goes to 20-agents.sh (MIXED split per S0 table).
# Note: §5b AGENTS.md and shared templates (nvmrc/lintstagedrc/etc.) go to 40-configs.sh.
# Note: §5c .husky goes to 50-hooks.sh.
#
# Variables consumed from dispatcher scope:
#   PKG_ROOT, PROJECT_ROOT, FORCE, DRY_RUN, STACK, SKIPPED (array), SHIPPED_DOCS (array)

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# ─── 3. AI Factory templates ────────────────────────────
echo "▶ AI Factory templates → .ai-factory/"
mkdir_safe "$PROJECT_ROOT/.ai-factory/rules"
# Consumer backlog home for /pipeline (kickoffs + plan + scratch). Agnostic namespace so the
# backlog is portable across harnesses (.claude/ is Claude-Code-specific). Empty until the
# consumer writes their first kickoff; /pipeline treats empty as "nothing queued", not an error.
mkdir_safe "$PROJECT_ROOT/.ai-factory/orchestrator-prompts"
copy_safe "$PKG_ROOT/packages/core/templates/shared/DESCRIPTION.template.md" "$PROJECT_ROOT/.ai-factory/DESCRIPTION.template.md"
copy_safe "$PKG_ROOT/packages/core/templates/shared/ARCHITECTURE.ts-server.md" "$PROJECT_ROOT/.ai-factory/ARCHITECTURE.ts-server.md"
# Base RULES.md is the stack's primary rule doc. ts-server/react-next share the manifest-rendered
# multi-stack preset-next RULES.md (Stack column carries per-stack applicability); react-spa and
# react-native each ship their own standalone preset-tailored RULES.md (no Stack column). The
# `else` keeps the ts-server/react-next output byte-identical to before these branches existed.
if [ "$STACK" = "react-spa" ]; then
  copy_safe "$PKG_ROOT/packages/preset-react-spa/RULES.md" "$PROJECT_ROOT/.ai-factory/RULES.md"
elif [ "$STACK" = "react-native" ]; then
  copy_safe "$PKG_ROOT/packages/preset-react-native/RULES.md" "$PROJECT_ROOT/.ai-factory/RULES.md"
else
  copy_safe "$PKG_ROOT/packages/preset-next-15-canonical/RULES.md" "$PROJECT_ROOT/.ai-factory/RULES.md"
fi
copy_safe "$PKG_ROOT/packages/core/templates/shared/integration-rules.md" "$PROJECT_ROOT/.ai-factory/rules/integration-rules.md"

# Seed tool-decisions.md so the deps-change re-evaluation hook actually fires (FQA S1-B P1:
# deps-hash-check.sh short-circuits to silent exit 0 when this file is absent — on the ./setup
# path nothing ever created it, so the whole automation was dead). The template carries the
# `deps-hash: <pending>` sentinel (DN-1 = Option B): the hook WARNs every session until the
# consumer runs /tool-bootstrapping once, which stamps the real hash. file-deploy only (kind
# identical to the seeds above) — no npm/package.json dependency at install time.
copy_safe "$PKG_ROOT/skills/tool-bootstrapping/templates/tool-decisions.md.template" "$PROJECT_ROOT/.ai-factory/tool-decisions.md"

# ── aif-handoff integration note ─────────────────────────
# Per Stage 2 v3 §4.6 — single informational note, no prompt needed;
# our Phase 3 skill-context files ARE the client-side aif-handoff integration.
echo "  ✓ aif-handoff integration: skill-context files installed at .ai-factory/skill-context/ (auto)"

# ─── §3d. Stack-specific ARCH/RULES ─────────────────────
if [ "$STACK" = "react-next" ]; then
  copy_safe "$PKG_ROOT/packages/preset-next-15-canonical/templates/ARCHITECTURE.react-next.md" "$PROJECT_ROOT/.ai-factory/ARCHITECTURE.react-next.md"
  copy_safe "$PKG_ROOT/packages/preset-next-15-canonical/RULES.react-next.md" "$PROJECT_ROOT/.ai-factory/RULES.react-next.md"
fi
if [ "$STACK" = "react-spa" ]; then
  copy_safe "$PKG_ROOT/packages/preset-react-spa/templates/ARCHITECTURE.react-spa.md" "$PROJECT_ROOT/.ai-factory/ARCHITECTURE.react-spa.md"
  copy_safe "$PKG_ROOT/packages/preset-react-spa/RULES.react-spa.md" "$PROJECT_ROOT/.ai-factory/RULES.react-spa.md"
fi
if [ "$STACK" = "react-native" ]; then
  copy_safe "$PKG_ROOT/packages/preset-react-native/templates/ARCHITECTURE.react-native.md" "$PROJECT_ROOT/.ai-factory/ARCHITECTURE.react-native.md"
  copy_safe "$PKG_ROOT/packages/preset-react-native/RULES.react-native.md" "$PROJECT_ROOT/.ai-factory/RULES.react-native.md"
fi

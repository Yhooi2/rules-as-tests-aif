#!/usr/bin/env bash
# setup.d/20-agents.sh — §2 Sub-agents + §3c skill-context overrides layer.
# S0 rows:
#   §2 Sub-agents → L747-800 (original install.sh)
#   §3c skill-context loop → L839-846 (MIXED split from §3, goes here per S0 table)
#
# Variables consumed from dispatcher scope:
#   PKG_ROOT, PROJECT_ROOT, FORCE, DRY_RUN, SKIPPED (array), SHIPPED_DOCS (array)

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# ─── 2. Sub-agents ──────────────────────────────────────
echo "▶ Sub-agents → .claude/agents/"
# C-1 agent-collision resolution (2026-05-20, research-patches/2026-05-20-agent-collision-resolution.md):
#   - best-practices-sidecar — KEEP-AIF: removed from our payload; AIF's rules-sidecar
#     (reads .ai-factory/RULES.md) + edit-time ESLint + pre-push are the real enforcers.
#   - docs-auditor — RENAMED to living-docs-auditor (de-collides with AIF's same-named agent).
#   - review-sidecar — still collides with AIF's. copy_safe DEFAULT (no --force) intentionally
#     SKIPS it when AIF's is present (AIF keeps its slot). Do NOT --force-overwrite it: that
#     would strip AIF frontmatter the implement-coordinator + aif-handoff pipeline depend on.
#     Instead our anti-tautology content is delivered into AIF's pipeline via the native
#     .ai-factory/skill-context/aif-review/SKILL.md override (copied in §3 below). The live
#     CC-dispatch probe (former DECISION-NEEDED #2) is RESOLVED: a background maxTurns:6
#     sidecar reads + applies skill-context (3/3 read, 2/2 apply) — SSOT #50, ADOPT.
#     agents/review-sidecar.md remains the portable SSOT (@dual-pair anchor: review-sidecar).
mkdir_safe "$PROJECT_ROOT/.claude/agents"
for f in "$PKG_ROOT"/agents/*.md; do
  case "$(basename "$f")" in
    manual-rule-liveness-prober.md) continue ;;  # authoring-only tool (#552)
    shipped-agent-liveness-prober.md) continue ;;  # authoring-only tool (M2 probe, #552 sibling)
  esac
  copy_safe "$f" "$PROJECT_ROOT/.claude/agents/$(basename "$f")"
done

# ─── §3c. skill-context overrides (MIXED from §3 — goes here, not 30-templates) ─
# AIF-native "extend a vendored sub-agent" mechanism (C-1, SSOT #50).
# AIF's own background sidecars MANDATORY-read .ai-factory/skill-context/<skill>/SKILL.md
# (verified live: a background maxTurns:6 sidecar reads + applies these). We ride that wiring
# instead of shipping colliding agents: aif-review gets our anti-tautology test-review content;
# aif-rules-check gets the R10-naming + test-existence residue of the removed best-practices-sidecar.
# Derive the skill-context copy set from SHIPPED_DOCS (single source — FQA P2 fix). Every
# skill-context entry that is header-verified above is copied here; the two lists cannot drift.
for _doc in "${SHIPPED_DOCS[@]}"; do
  case "$_doc" in
    packages/core/templates/shared/skill-context/*/SKILL.md)
      _sc="${_doc#packages/core/templates/shared/skill-context/}"; _sc="${_sc%/SKILL.md}"
      mkdir_safe "$PROJECT_ROOT/.ai-factory/skill-context/$_sc"
      copy_safe "$PKG_ROOT/$_doc" "$PROJECT_ROOT/.ai-factory/skill-context/$_sc/SKILL.md" ;;
  esac
done

# Build-first, reuse-default — operating philosophy

> **Class:** A — companion principle test shipped at [packages/core/principles/11-build-first-reuse-default.test.ts](../../packages/core/principles/11-build-first-reuse-default.test.ts) (#75, 2026-05-17). Design sketch retained at [11-build-first-reuse-default.design.md](../../packages/core/principles/11-build-first-reuse-default.design.md).
> **Authoritative for:** project-wide macro-level scope discipline; relationship to upstream tools, frameworks, and ecosystems; default verdict for new capability proposals.
> **NOT authoritative for:** per-commit build-vs-reuse — that lives in [CLAUDE.md «Build-vs-reuse invariant (Phase 8.8)»](../../CLAUDE.md). This rule is the macro-level complement to per-commit invariant.

> **Origin:** 2026-05-13 maintainer dialogue surfaced the operating principle. Codified per goal-clarity-dialogue §4.3 v2 verdict (2026-05-16) following the prose-rule-now / executable-test-later split discipline.

## §1 The principle (7-verdict table)

Every capability proposed resolves into ONE verdict:

| Verdict | When |
|---|---|
| **ADOPT** | Upstream solves identical problem-class; runtime coupling OK |
| **ADOPT VOCABULARY** | Convergent design; vocab alignment; no runtime coupling |
| **ADAPT** | Pattern useful; problem-class mismatch needs modification |
| **REFERENCE** | Our scope is rule/discipline; upstream is runtime precedent |
| **KEEP NARROW** | Our scope narrower than upstream's |
| **BUILD** | No upstream / fundamental misfit — confirmed via §3 mechanism |
| **REJECT** | Upstream explicitly unsuitable — document why |

**Default = ADOPT or REFERENCE. BUILD only after §3 mechanism confirms no production-grade upstream.**

**Cost gate:** cheap = text/skill/config/citation (no new dep, no ≥50-80 LOC module) → ADOPT now when it beats current practice; expensive = adds dep/module/infra → requires cited concrete friction instance, else DEFER.

**Own-stack-first (criterion zero):** before reaching for a companion, check whether Claude Code ships the capability natively.

Anti-patterns: `#parallel-evolution-creep`, `#own-stack-blind-spot`, `#adoption-shame`, `#integration-overhead-overestimate`, `#pattern-matching-on-name`, `#vendor-lock-by-convenience`.

Full rule (§1.1 satellite doctrine, §2-§8): `.claude/rules/build-first-reuse-default.md` (read on demand).

## §8 See also

- [packages/core/principles/11-build-first-reuse-default.design.md](../../packages/core/principles/11-build-first-reuse-default.design.md) — design sketch for the companion executable test (markdown design doc, not TypeScript)
- [docs/meta-factory/prior-art-evaluations.md](../../docs/meta-factory/prior-art-evaluations.md) — SSOT register
- [CLAUDE.md «Build-vs-reuse invariant (Phase 8.8)»](../../CLAUDE.md) — per-commit gate (predecessor at the micro level)
- [docs/meta-factory/research-patches/2026-05-16-goal-clarity-dialogue.md](../../docs/meta-factory/research-patches/2026-05-16-goal-clarity-dialogue.md) — origin research-patch
- [docs/meta-factory/research-patches/2026-05-16-1a-drafts-substantive-review.md](../../docs/meta-factory/research-patches/2026-05-16-1a-drafts-substantive-review.md) — pre-ship review that established slot-11 cascade + BFR rule final wording

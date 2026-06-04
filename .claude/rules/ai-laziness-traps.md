# AI laziness traps — discipline rule

> **Class:** A — companion principle test shipped at [packages/core/principles/12-ai-laziness-traps.test.ts](../../packages/core/principles/12-ai-laziness-traps.test.ts) (#74, 2026-05-17).
> **Authoritative for:** ai-laziness-traps discipline rule — §1 problem this solves, §2 canonical trap catalogue, §3 kickoff-author obligations (cite + extend, no blanket reference), §4 anti-patterns, §5 promotion / retirement triggers.
> **NOT authoritative for:** project goal — see [README.md#why-this-exists](../../README.md#why-this-exists). Companion to research-discipline rule — see [phase-research-coverage.md](phase-research-coverage.md).

> **Origin:** 2026-05-12. Wave 9 kickoff (`§13.31`) §6 enumerated 11 «AI laziness traps» specific to that R-phase. During Phase 10 (`§13.32`) scoping the maintainer surfaced that the trap catalogue is **structurally project-wide** — any R-phase, audit, or open-ended investigation by an AI session faces the same failure modes (sampling shallow, declaring victory at floor depth, pattern-matching the prompt instead of reasoning against it). Drift-waiting-to-happen if each kickoff re-invents its own list. Hoisted to project rule with self-defending mechanism: kickoffs must cite + extend, not blanket-reference.

## §2 Key traps (5 highest-priority; full catalogue on demand)

**T3 — Plausible-looking finding without verification**
Counter: every finding needs (a) command + output, (b) file:line + actual content, or (c) explicit `INCONCLUSIVE`. No prose-only findings.

**T7 — Following the prompt literally instead of reasoning adversarially**
Counter: when reaching adversarial counter-prompt sections, write the actual counter-prompt and run it. If it surfaces nothing, that is suspicious — rephrase and run again.

**T10 — Reporting completeness based on what you LOOKED at, not what EXISTS**
Counter: enumerate population BEFORE sampling. Without enumeration, sampling claims are meaningless.

**T15 — Self-application skipped**
Counter: project invariant #2 (recursive self-application green). Every audit must include §self-application.

**T20 — Inline-verdict-without-evidence**
Counter: before any verdict/recommendation in dialogue, run ≥1 evidence-bearing tool call in the same turn and quote its output. See `recommendation-laziness-discipline.md`.

## §3 Kickoff-author obligations

A kickoff MUST: (1) cite this rule explicitly (`See [.claude/rules/ai-laziness-traps.md §2]`), (2) enumerate active **T\d+** T-numbers, (3) add ≥1 domain-specific trap. Blanket reference (without T-number enumeration) = T7 violation.

Full catalogue (T1-T20) + §4-§5: `.claude/rules/ai-laziness-traps.md` (read on demand). Also loaded via `check-kickoff-traps.sh` PostToolUse when editing kickoff files.

## See also

- [.claude/orchestrator-prompts/wave-9-discipline-theatre-audit/kickoff.md §6](../orchestrator-prompts/wave-9-discipline-theatre-audit/kickoff.md) — origin instance; the in-flight kickoff inlines T1-T11. Future kickoffs reference this rule instead.
- [phase-research-coverage.md](phase-research-coverage.md) — companion rule on research-discipline scope (overlapping concerns: R-phase output requirements, search-coverage 6-item checklist).
- [doc-authority-hierarchy.md](doc-authority-hierarchy.md) — parallel discipline rule pattern (authority + scope statements per doc).
- [open-questions.md §13.31](../../docs/meta-factory/open-questions.md) — Wave 9 umbrella driving §2 catalogue origin.
- [open-questions.md §13.32](../../docs/meta-factory/open-questions.md) — Phase 10 umbrella; classification discipline `OWN-BUILD` / `ADAPTED` / `ADOPTED-MECHANISM` / `ADOPTED-VOCABULARY` / `REJECTED` interacts with T11 (don't sweep what's externally validated) + T13 (don't trust ADOPTED without confirming upstream evidence).

# Retros

> **Authoritative for:** folder convention for phase retrospectives. Each file documents one phase (or phase sub-step) retrospective using the format established in [EXECUTION-PLAN.md §5 «Стандартный retrospective gate»](../EXECUTION-PLAN.md). Individual retro files inherit this folder authority — they are scope-bound by phase ID and do **not** need their own Authoritative-for headers. **Closed historical artifacts post-merge** — substantive content is not retroactively rewritten (header-only edits, typo fixes, link repairs permitted).
> **NOT authoritative for:** project goal — see [README.md#why-this-exists](../../../README.md#why-this-exists). Phase scope and acceptance criteria — see [EXECUTION-PLAN.md §6](../EXECUTION-PLAN.md). Coverage-gap patches (different surface, post-retro discoveries) — see [research-patches/](../research-patches/).

## File naming

`phase-<N>[<.sub>][-<topic>].md` — e.g. `phase-7.md`, `phase-7.5.md`, `phase-8.8.1-coverage-discipline.md`. Pre-Phase-1 review docs use date suffix: `EXECUTION-PLAN-review-2026-05-07.md`.

## Required sections (per [EXECUTION-PLAN.md §5](../EXECUTION-PLAN.md))

- **Verification block** — executable commands with expected output, CI status, `git log --oneline phase-start..phase-end`
- **Self-reflection block** — assumptions checked / refuted / discovered; postponed-tasks rationale
- **Evaluation block** — self-application score (0-10), time-vs-plan ratio, new risks, verdict (GO / REVISE / STOP)
- **RCA section** (when triggered) — 5-point root cause analysis when time-vs-plan >2× or stop-rule fires

## Closed-after-merge convention

Once a retro is committed and the corresponding PR merged, the retro is **closed historical artifact**. Future-session edits to a closed retro are restricted to:

- Authority-header updates (per `.claude/rules/doc-authority-hierarchy.md`)
- Typo / formatting fixes
- Link repairs (e.g. when referenced files are renamed)

Substantive content updates require either a new retro (for a different phase or revisit), a `research-patches/` entry (for post-merge coverage gaps), or an explicit «retro reopened» commit with rationale.

## Index of retros

See `git log --oneline -- docs/meta-factory/retros/` for the chronological order. Selected entries:

- [phase-0-5.md](phase-0-5.md) — Phase 0.5 docs alignment
- [phase-1-{a,b,c,d}.md](.) — Phase 1 sub-steps
- [phase-1.md](phase-1.md) → [phase-2.md](phase-2.md) → [phase-3.md](phase-3.md) → [phase-4.md](phase-4.md) → [phase-5.md](phase-5.md) → [phase-6.md](phase-6.md) → [phase-7.md](phase-7.md), [phase-7.5.md](phase-7.5.md), [phase-8.md](phase-8.md), [phase-8.8.md](phase-8.8.md), [phase-8.8.1-coverage-discipline.md](phase-8.8.1-coverage-discipline.md), [phase-9-entry.md](phase-9-entry.md) — phase progression
- [EXECUTION-PLAN-review-2026-05-07.md](EXECUTION-PLAN-review-2026-05-07.md), [EXECUTION-PLAN-review-2026-05-07-followup.md](EXECUTION-PLAN-review-2026-05-07-followup.md) — pre-Phase-1 plan reviews
- [REVIEWER-VERDICT-2026-05-07.md](REVIEWER-VERDICT-2026-05-07.md) — reviewer-mode verdict on the same plan

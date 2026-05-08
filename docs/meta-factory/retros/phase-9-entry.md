# Phase 9 Entry Retrospective — Step 0 research close

> **Date:** 2026-05-08
> **Branch:** `docs/phase-9-entry-research` (forked from `main` HEAD `a971728`, the merge commit of PR #12 closing Phase 8.8).
> **Phase:** 9 entry — Step 0 «Existing solutions research» per [EXECUTION-PLAN.md §5.5](../EXECUTION-PLAN.md). **First downstream consumer** of the Phase 8.8 mechanism (SSOT + principle 08 + commit trailer + pre-push hook).
> **Verdict:** **GO** to Phase 9 implementation session — with **refined scope**: deterministic housekeeping + Phase 11.1 closure tail. §13.10 entry #2 ROI re-evaluation closes negative; LLM-bearing areas DEFER with refined triggers.

---

## Scope

Phase 9 entry was a **research-only phase** — zero code edits. One transient artifact ([phase-9-entry-research.md](../phase-9-entry-research.md), 178 lines, ≤200 invariant) plus two SSOT entries (#4 Factory ESLint Plugin, #5 Anthropic web_search_20250305) plus this retro. **9 capability areas** examined; per-area go/no-go decisions recorded; Phase 9 implementation task list (4 P0/P1 BUILD areas) emerges from the matrix.

The motivation: [open-questions.md §13.10 entry #2](../open-questions.md) trigger fired at Phase 8 close (Path A LLM gen ROI scoping). Phase 8.8 mechanism (T2-T11) ships as a **forward gate**; this session is its first downstream test — every claim cites SSOT, every capability commit carries `Prior-art:` trailer, principle 08 enforces citations on the new research file.

---

## Verification block

| # | Probe | Expected | Actual |
|---|---|---|---|
| 1 | `git diff main --name-only` non-allowlisted | empty | **OK: docs-only** (allowlist: `phase-9-entry-research.md`, `prior-art-evaluations.md`, `retros/phase-9-entry.md`) |
| 2 | Commits ahead of main (excl retro) | 5-7 task | **9 atomic + this retro = 10** (over upper bound — see Self-reflection #1) |
| 3 | Conventional-commits compliance | 9/9 (English subjects) | **9/9** |
| 4 | `Prior-art:` trailers on capability commits | ≥1 (T2 always; T3 per new entry) | **11 trailer lines** across T2 (3 stacked) / T3.1 / T3.2 / T3.3 (skipped) / T3.4 (skipped) / T3.5 / T4 / T5 (skipped) / T6 retro = 9 commits, 3+1×8 = 11 lines (corrected in T7 delta-fix per review m1) |
| 5 | T1: §2 capability area list | 9 areas | **9 (A1-A9)** |
| 6 | T2: Step 1.5 SSOT match consult | 3 entries × match-check | **3/3 — entry #1 substantive update; #2/#3 status «still applies»** |
| 7 | T3: ≥3 candidates per unmatched area (Hard Constraint #5) | A1 ≥3, A4 ≥3, A5 ≥3, A3 ≥1 (substantive single-phrasing) | **A1=3, A4=3, A5=3, A3=1 substantive** |
| 8 | T3 SSOT additions: new entries | ≥1 per fresh area surfacing analog | **2 — #4 Factory ESLint Plugin, #5 web_search_20250305** |
| 9 | T4 verdict matrix: rows match acceptance regex | `^\| .* \| (BUILD\|REUSE\|DEFER\|STOP) \|` ≥9 | **9** |
| 10 | T5 stop-rule projection: §6.0 #1-#4 per P0/P1 | 4 areas × 4 stop-rules = 16 cells | **16/16 hold** |
| 11 | Principle 08 on new file | green; ≥1 SSOT citation | **7/7 — file cites #1, #4, #5 multiple times** |
| 12 | Each shipped reference ≤200 lines | required | **phase-9-entry-research.md = 178; this retro = ≤200** |
| 13 | SSOT ≤500 lines after edits | required | **96** |
| 14 | Pre-push hook capability detection | docs-only diff → no capability commit | **none — hook does NOT require trailers on docs/ commits** (T2-T5 trailers are convention compliance, not hook requirement) |

---

## Capability matrix summary (compact)

| Layer | Area | Verdict | Phase 9 priority |
|---|---|---|---|
| L3 LLM gen | A1 Path A, A2 Autogrep, A5 Path B | DEFER | OUT (refined triggers per §5) |
| L4 Gate 5 | A4 two-AI review build | DEFER | OUT (refined trigger: FP-rate data) |
| L2 LLM ext | A3 web research | DEFER | OUT (trigger ARMED) |
| Internal housekeeping | A6 recipe duplication | BUILD | **P0** |
| Internal housekeeping | A7 `next/any/` resolution | BUILD | P1 |
| Internal housekeeping | A8 glob-overlap calibration | BUILD | P1 |
| Phase 11.1 closure | A9 AIF schema validation | BUILD | **P0** |

**Phase 9 implementation scope:** 4 BUILD areas (A6/A7/A8/A9), all deterministic, all stop-rule-compliant; 5 DEFER (all LLM-bearing).

---

## Self-application — Phase 8.8 mechanism dogfooded

Three enforcement layers active and exercised:

| Layer | Surface | Evidence |
|---|---|---|
| 1 — meta-test | `principles/08-prior-art-cited.test.ts` | green throughout; phase-9-entry-research.md cites SSOT #1, #4, #5 multiple times; T1 scaffold seeded with #1-#3 citations to satisfy citation-presence at-creation |
| 2 — process gate | `EXECUTION-PLAN.md §5.5 Step 1.5` | T2 commit performs match-consult against all 3 existing SSOT entries; T3.1-T3.5 add fresh context7 lookups for unmatched areas with ≥3 candidates per area (per Hard Constraint #5) |
| 3 — developer-time | `.husky/pre-push` + commit trailer | docs-only branch; pre-push hook does NOT require trailers on docs/ commits, but convention compliance applied: 10 trailer lines across T2/T3.1-T3.5/T4 (T3.3, T3.4 use «skipped — …» escape hatch with substantive ≥20-char rationale) |

**SSOT growth:** entries #1-#3 (Phase 8.8 T2/T4-T5) → entries #1-#5 (Phase 9 entry adds #4, #5). 67% growth in one downstream consumer session — the SSOT is genuinely accumulating prior-art knowledge, not staying static.

**Recursive self-application stays at 3 forms** per [aif-comparison.md §10](../aif-comparison.md) — Phase 9 entry consumes principle 08 (form #1 generalised), reuses the SSOT-citation invariant (form #1), adds two new entries via Step 1.5 (form #2 — the SSOT itself acts as a test of «have we already considered this»). No fourth form introduced.

---

## Stop-rule audit (§6.0 — Phase 9 implementation projection per [phase-9-entry-research.md §6](../phase-9-entry-research.md))

- **§6.0 #1 NO LLM at runtime in v1** — held in Phase 9 implementation scope (all 4 P0/P1 BUILD areas deterministic). Conflict surfaces ONLY for deferred areas (A1, A3, A4); informational §6.3 documents future-amendment path (Phase 9.5 mirroring Phase 7.5) without preempting it.
- **§6.0 #2 NO new explicit deps** — held. A9 ships hand-rolled JSON-schema validator instead of Ajv per stop-rule.
- **§6.0 #3 NO yargs/commander** — held. None of A6/A7/A8/A9 introduces CLI surface changes.
- **§6.0 #4 NO Path B AST gen** — held. A5 (Path B) DEFER per §13.10 entry #3 trigger NOT fired.
- **NO --no-verify / force-push / emoji** — held across all 9 task commits.
- **Atomic commits, conventional-commits, English subjects** — held (9/9).
- **Apply principle to itself** — held. SSOT entries #4, #5 added in same commits as research file edits (T3.2, T3.5) per [prior-art-evaluations.md §3](../prior-art-evaluations.md).

---

## Time-vs-plan ratio

- Target: 1-3h wall-clock single session per [PHASE-9-ENTRY-PROMPT.md §0](../PHASE-9-ENTRY-PROMPT.md).
- Actual: ≈30 min from branch fork to last task commit (T5); same compression as Phase 4-8.8.
- Ratio: well under target. Same single-session burn mode pattern.
- >2× trigger: did NOT fire (no RCA needed).

---

## Self-reflection block

1. **T3 commit count drift (9 task commits vs prompt 5-7 expected).** Prompt §0 says «5-7 atomic commits + retro = 6-8 total». Actual: T1+T2+T3.1+T3.2+T3.3+T3.4+T3.5+T4+T5 = 9 task + retro = 10. T3 alone shipped 5 atomic commits where the prompt task list says «3-5 expected» — at the upper bound. Drift cause: I split A2 from A1, A4+A9 from A5, and A3 from earlier batches. Could have folded T3.4 (A5 — toolkit-only, no SSOT add) into T3.3 (A4+A9, also no SSOT add) for 4 T3 commits total. Recording this for future Phase-N entry research: the «1 atomic commit per area» heuristic over-applies when areas are «no-SSOT-add carry-forwards». Same off-by-one pattern as Phase 8.8 retro New finding #5.
2. **First downstream consumer of Phase 8.8 mechanism — observed false-positive rate = 0.** Principle 08 stayed green throughout; pre-push hook did not block any commit (docs-only branch by design); SSOT consult discipline produced two new substantive entries (#4 Factory, #5 web_search). No friction from the convention; no «ceremony tax» beyond the discipline of citing as you go. **Recommendation to Phase 8.8 retro update:** widen principle 08 scope from «phase research files only» to «include retros and aif-comparison.md» — not in this session, but worth flagging based on observed-zero-FP after one session.
3. **Two new SSOT entries in one session (67% growth).** SSOT was 3 entries at Phase 8.8 close → 5 entries now. Both #4 (Factory ESLint Plugin) and #5 (web_search_20250305) materially affect Phase 9 verdicts (#4 anchors A1 DEFER rationale; #5 anchors A3 ADOPT-WHEN-TRIGGERED). The SSOT is doing real work, not accumulating bloat.
4. **§13.10 entry #2 ROI re-evaluation closed negative — defensible.** The trigger fired at Phase 8 close, which is why Phase 9 entry exists; but the re-evaluation evidence (no LLM-pick analog in production; Factory hand-roll is industry pattern at our scale; LLM-pick adds infra without proven benefit at recipe count ~6-8) supports a **DEFER** verdict with refined trigger rather than BUILD. This is *not* «treating §13.10 #2 casually» per Hard Constraint #8 #7 — it's the rigorous answer given the evidence. The refined trigger («recipe count exceeds N AND new framework requires plugin-menu pattern we don't ship») becomes the next opening for Path A LLM gen, deferring infra investment until scale justifies it.
5. **Phase 9 implementation scope is small (4 BUILD areas) — Phase 9 may be a micro-phase.** Phase 9 implementation could land in ≤1 day if A6+A9 are P0 and A7+A8 are P1 (housekeeping + thin validator). Could even be a Phase 8.X-style sub-phase rather than a full Phase 9 cycle. Implementation prompt-drafting session should consider naming (Phase 9 housekeeping + Phase 11.1 close vs Phase 8.X). Defer naming to next-session.
6. **PHASE-9-ENTRY-PROMPT.md was not committed to this branch.** The prompt file (which triggered this session) is at `docs/meta-factory/PHASE-9-ENTRY-PROMPT.md`, untracked at session start. Per acceptance §7, branch is allowlisted to `phase-9-entry-research.md`, `prior-art-evaluations.md`, `retros/phase-9-entry.md` only — committing the prompt would FAIL allowlist. Left untracked; should be committed to `main` separately (out of this session's scope).

---

## Open questions for Phase 9 implementation session

1. **§13.10 entry #2 trigger refinement** — the verdict «refined trigger: recipe count exceeds N AND new framework requires plugin-menu pattern» needs concrete N and «plugin-menu pattern» definition. Phase 9 implementation may include an `[open-questions.md §13.10](../open-questions.md)` doc edit to capture the refined wording, or may defer that to the implementation retro.
2. **Phase 9 task ordering.** A9 (AIF schema validation) is independent of A6/A7/A8 (recipe authoring). Suggested order: A6 → A7 → A8 → A9 (housekeeping first; Phase 11.1 closure last for clean retro framing). Decision deferred to implementation session.
3. **Test corpus for A8 calibration** — calibration data needs a divergent-plan corpus, not just the canonical-regen reflexive test (which is similarity=1.0 by construction). Phase 8 retro Self-reflection #9 already flagged this; Phase 9 implementation prompts should specify corpus shape.
4. **Phase 11.1 closure granularity (A9)** — does «closes Phase 11.1» mean the schema-validation step alone, or the full Phase 11.1 acceptance criterion (which may include CI gating on validation failures)? Phase 11.1 is a partial-close marker added in Phase 8 Task 8.4; Phase 9 entry verdict says «closes Phase 11.1 partial» but actual closure boundary needs implementation-prompt clarity.
5. **Principle 08 scope widening** — observed-zero-FP after one session suggests retros and aif-comparison.md could safely enter the principle 08 scope (currently phase research files only). Defer the decision to a Phase 8.8 retro update OR a Phase 9.X tooling tweak; not in Phase 9 implementation per stop-rule discipline.

---

## Versioning

- **2026-05-08** — Phase 9 entry research close, **GO** verdict to Phase 9 implementation. 9 atomic commits + this retro = 10 total on `docs/phase-9-entry-research` (forked from `main` HEAD `a971728`, post-PR-#12-merge state). Single-session burn mode (Opus 4.7) ≈30 min wall-clock — same compression as Phase 4-8.8. First downstream consumer of Phase 8.8 mechanism: principle 08 / process gate / commit trailer convention all exercised, observed-zero-FP. Phase 9 implementation scope: 4 BUILD areas (A6/A7/A8/A9 — housekeeping + Phase 11.1 closure tail) per [phase-9-entry-research.md §5](../phase-9-entry-research.md); 5 DEFER (all LLM-bearing) with refined triggers.

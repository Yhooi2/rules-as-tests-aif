<!-- scope:dn4-verify-before-claim-codification -->
# DN-4 — verify-before-claim family codification (§1.11) self-review

> **Scope:** §1.7 self-review patch for the discipline-bearing change that adds [`phase-research-coverage.md` §1.11](../../../.claude/rules/phase-research-coverage.md) (the "verify against source-of-truth before claim/ship" family) + the `#claim-from-memory-not-source` anti-pattern, codifying DN-4 memory-codification gaps #16/#17/#22/#28. Inherits folder authority from [research-patches/README.md](README.md); NOT authoritative for project goal — see [README.md#why-this-exists](../../../README.md#why-this-exists).
>
> **Origin:** DN-4 autonomous codification pass, 2026-05-22 (`/orchestrator`). Four `feedback_*` memory entries — `check_decided_status_before_recommending` (#16), `check_inflight_prs_before_building` (#17), `orchestrator_verify_state_before_claim` (#22), `verify_diff_direction_before_live_claim` (#28) — were stage-0 (memory-only) per the [memory-coverage audit §4](2026-05-22-memory-coverage-audit.md). They share one shape: *verify against the authoritative source (git/GitHub/decided-docs) before asserting state or taking a ship-step.* This patch records the §1.7 self-review the change is obliged to ship (the third arm of §1.7's self-reflexive trigger).

## §1 What changed

- New subsection **§1.11** in `phase-research-coverage.md` — folded the 4 conventions into the existing always-on rule rather than 4 new `.claude/rules/*.md` files.
- New §4 anti-pattern `#claim-from-memory-not-source`.
- DN-4 tracker rows #16/#17/#22/#28 → `CODIFIED → §1.11`.

## §2 Channel-selection rationale (why fold, not new files)

Per [rule-enforcement-channel-selection.md §1-§3](../../../.claude/rules/rule-enforcement-channel-selection.md): these are **judgment** rules (no mechanical gate decides "did you verify before claiming") → **injection**, not gate. Their relevance is at *claim/ship moments*, which is **not path-scoped** → a `<!-- globs: -->`-scoped injector (the §4 ADAPT hook) does not fit. The reliable channel is the **already-always-on** delivery (the rule auto-loads + the H1-class verify discipline is in the session-bootstrap digest). Adding 4 new always-on rule files would be `#always-on-bloat` (each pays per-session tokens). Folding into the existing §1.7-anchored rule reuses the channel at zero new standing cost. **Reversibility:** if the family later proves it needs stronger/narrower delivery, it graduates to its own rule (documented promotion), per the channel-selection §6 pattern.

## §3 §1.7 self-review (T7 walk)

### §1.7 Forward-check applied

The change complies with all currently-active layers:

- **no-paid-LLM-in-CI** ([rule](../../../.claude/rules/no-paid-llm-in-ci.md)): §1.11 adds zero LLM invocations — pure prose discipline. ✔
- **doc-authority** ([rule](../../../.claude/rules/doc-authority-hierarchy.md)): edits an existing rule that already carries Class + Authoritative-for header; no new canonical doc lacking a header. The new research patch inherits folder authority per [doc-authority §5](../../../.claude/rules/doc-authority-hierarchy.md). ✔
- **build-first-reuse / channel-selection**: §2 above documents the fold-vs-new-file verdict against `#always-on-bloat`. ✔
- **memory-codification §3** ([rule](../../../.claude/rules/memory-codification.md)): the change *is* the codify-then-pointer step for 4 stage-0 entries; repo home is now §1.11, tracker reflects CODIFIED. Memory pointer-reduction is delegated to the [memory-codification-auditor](../../../agents/memory-codification-auditor.md) pass (file:line evidence: `phase-research-coverage.md:73` §1.11). ✔
- **capability-commit gate**: no new dependency, no ≥50/80-LOC file under `packages/` → not a capability commit; no `Prior-art:` trailer required. ✔

### §1.7 Backward-check applied

Complete sweep of artefacts under the new rule's scope:

- §1.11 **extends** §1.7's provisional-verdict principle from recommendations to any claim/ship-step; it does not contradict §1.7-§1.10. No "H1" label was invented — the change cites §1.7's actual provisional-verdict wording (the earlier draft's stray "§1.7 H1" was removed; H1 is the distinct §13.39 recommendation-gate). Evidence: `phase-research-coverage.md:75`.
- The 4 codified conventions are **not** already enforced elsewhere — verified each was stage-0 in [memory-coverage-audit §4](2026-05-22-memory-coverage-audit.md), no prior `.claude/rules` or principle test covers them.
- `#claim-from-memory-not-source` sits in the §4 focus-tunnel anti-pattern family alongside `#recommendation-skips-own-discipline`; no duplicate anti-pattern name (`grep '#claim-from-memory'` = 1 hit). Evidence: tracker rows flip exactly #16/#17/#22/#28; #18-#21/#23-#30 untouched.

### Would it have caught the motivating gap?

Yes. Run against the origin incidents: §1.11 point 1 (re-verify HEAD before each ship-step) catches the 2026-05-16 stale-HEAD incident; point 4 (per-file content-marker probe) catches the PR #106 inverted-diff near-miss; point 3 (plain `gh pr list --state open` scan) catches the #80-dup-of-#79 incident; point 2 (grep decided-docs before recommending) catches the 2026-05-21 re-litigation. The rule fires on exactly the corpus that motivated it. ✔

## §4 Residuals

- DN-4 gaps #18-#21, #23-#30 remain PENDING — dispositioned in the [tracker](../../meta-factory/memory-codification-gap-tracker.md) for incremental on-touch codification (per its own design); not batch-codified here to avoid `#codify-everything` over-application and discipline-theatre.
- Memory pointer-reduction for the 4 codified entries is left to the auditor agent (the shipped compensating mechanism), not done destructively in this pass.

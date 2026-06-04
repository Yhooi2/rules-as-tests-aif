<!-- scope:remove-claim-detector -->
# Remove the end-of-turn factual-claim detector — net-negative sentry, dropped by evidence

> **Type:** I-phase (removal of a measured-net-negative mechanism). Single Opus Mode-A session. Maintainer decision 2026-06-01: «не нужен раз не работает».
> **Date:** 2026-06-01.
> **Authoritative for:** the rationale + evidence for removing the factual-claim scan from [`.claude/hooks/end-of-turn-reminder.sh`](../../../.claude/hooks/end-of-turn-reminder.sh); the surfaces touched; what survives.
> **NOT authoritative for:** project goal — see [README.md#why-this-exists](../../../README.md#why-this-exists). The original measurement — [`2026-05-21-instruction-compliance-empirical.md`](2026-05-21-instruction-compliance-empirical.md) (the pilot that produced the recall/precision numbers). The recap mechanism that survives — [`2026-05-21-end-of-turn-hook-redesign.md`](2026-05-21-end-of-turn-hook-redesign.md).

---

## §0 TL;DR

The end-of-turn hook's **factual-claim scan** (numeric counts / `file:line` citations / negative-existence phrases → injects an item-specific «re-verify before you finish» nudge) is **removed**. It was measured net-negative: **recall ≈ 0.43** (misses the majority of natural claim phrasings) and **precision ≈ 0.20–0.25** (cry-wolf — ~75 % of fires are false, on numbers/paths in planning prose, quoted prompts, markdown links). A sentry that misses most real claims and cries wolf on most of what it catches is itself the `#discipline-theatre` the project hunts.

The **recap** (Branch A/C) and **question/fork-check** (Branch B) survive untouched. The always-on **H1 reminder** in `inject-session-bootstrap.sh` remains the cheap salience layer.

## §1 Evidence (not re-measured — cited from the pilot)

All numbers from [`2026-05-21-instruction-compliance-empirical.md`](2026-05-21-instruction-compliance-empirical.md), scored over 266 real sessions / 1537 claim-turns:

- **§6.3 — recall ≈ 0.43** on natural numeric phrasings. Recall sweep on 14 phrasings: FIRE on 6, MISS on 8 («6 discipline rules», «11 distinct principles», «across 266 sessions», «all 4 agents» …). The regex fired only when the count-noun was adjacent; a later widening to «≤2 intervening tokens» helped recall marginally but **worsened** precision.
- **§6.2 — precision ≈ 0.20–0.25** on the target class. Manual classification of 25 ungrounded flags: genuine target-class report-claims were ~4–6 of 25 (~20–25 %). The rest were planning/meta/quoted/link noise → cry-wolf, which **erodes** compliance over time.
- **§6.1 — baseline groundedness already ≈ 0.74–0.81** with *no* mechanism → little headroom for the nudge to recover even at perfect recall.
- **§6.3 — compliance, when delivered, can be positive** (probe1: 6→8 correction). So the value is not zero — but `effective coverage ≈ recall × (1 − precision-loss) × compliance`, and recall ≈ 0.43 caps the product low.
- **H0 (grounded-rate equal w/ & w/o mechanism) was NOT rejected** and **cannot** be (eval-unaware treatment arm ≈ N0). The pilot established the *detector* findings, not a *works/doesn't-work* verdict on compliance.

**Precise framing:** «doesn't work» → «unproven + cry-wolf». Removal is a *cost > benefit* call (the cry-wolf precision cost is real and recurring; the benefit is unproven and recall-capped), not a «it's bugged» call.

## §2 Precedent

The recommendation-laziness I-phase already made the same call for the sibling stop-hook scan: [`narrow-b-benchmark.md §1.5`](2026-05-25-narrow-b-benchmark.md) measured **FP = 84.2 % (Wilson 95 % CI [62 %, 95 %])** and **dropped narrow-B** (Option D = A+C only, #210), keeping only the always-on H1 reminder + the T20 trap. Same class (post-hoc verdict/claim grep), same outcome (drop on FP evidence, keep the cheap always-on layer). See [`recommendation-laziness-discipline.md §4 (B)`](../../../.claude/rules/recommendation-laziness-discipline.md).

## §3 Surfaces touched

| Surface | Change |
|---|---|
| [`.claude/hooks/end-of-turn-reminder.sh`](../../../.claude/hooks/end-of-turn-reminder.sh) | Removed the claim-scan block + `has_claims`/`claim_count`/`claim_hits` refs in the idle-suppress guard, trigger condition, glance-line, Branch D, and append block. Trigger is now `long_text \|\| asked`; branches A/B/C only. Removal comment + this-patch pointer left in place. |
| `tests/hooks/eot-claim-scan.test.sh` | **Deleted** (185 LOC, entirely claim-scan). |
| [`.github/workflows/audit-self.yml`](../../../.github/workflows/audit-self.yml) | Removed the `eot-claim-scan.test.sh` CI step. |
| [`packages/core/hooks/end-of-turn-reminder.test.ts`](../../../packages/core/hooks/end-of-turn-reminder.test.ts) | Removed the Branch-D test + the code-fence precision-guard test; added a paired-negative «short claim-bearing turn now stays silent» case. 13/13 green. |
| `tests/eval/claim-groundedness-scorer.py` | **Kept** (historical eval artefact, not CI-wired). Its «same surface as the hook» property is now moot; noted here, not deleted (reversible; preserves the measurement reproducibility). |
| `docs/meta-factory/project-history-book*.md` | Epilogue: the «искатель утверждений» debt is now **closed by removal**, not «unfixed». |

## §4 What survives (scope guard)

- The **recap** discipline (Branch A whole-turn / Branch C whole-session) — the hook's primary purpose.
- The **question/fork-check** (Branch B) + recommendation-first nudge.
- The **already-recapped guard**, **idle-suppress guard**, **stop-hook-active guard**, **AskUserQuestion** path.
- The always-on **H1 reminder** in `inject-session-bootstrap.sh` (the cheap, always-on claim-salience layer that this scan was supposedly upgrading).

A short factual-report turn with no question now **stays silent** (previously fired Branch D) — the intended consequence: that nudge was the cry-wolf.

## §5 §1.7 self-reflexive

- **Forward-check:** complies with [`no-paid-llm-in-ci.md`](../../../.claude/rules/no-paid-llm-in-ci.md) (removal only, no LLM added), [`build-first-reuse-default.md`](../../../.claude/rules/build-first-reuse-default.md) (drops a homegrown net-negative mechanism — REUSE the always-on H1 reminder instead), [`doc-authority-hierarchy.md`](../../../.claude/rules/doc-authority-hierarchy.md) (this patch carries the `scope:` annotation + Authoritative-for header). T16 problem-class match: the removed scan and narrow-B (#210) share the *post-hoc claim/verdict grep* class → the FP-driven drop transfers.
- **Backward-check:** scope-reducing change. The pilot patch ([`2026-05-21-instruction-compliance-empirical.md`](2026-05-21-instruction-compliance-empirical.md)) is the source of the numbers and is **not** rewritten — it stays the historical measurement; this patch is the *action* taken on its finding. The hook's redesign patch ([`2026-05-21-end-of-turn-hook-redesign.md`](2026-05-21-end-of-turn-hook-redesign.md)) described the recap mechanism that survives; only the claim-scan addition is reverted. No other artefact silently superseded.

## §6 Recursive-self-application note

This removal is the project's thesis applied to its own tooling: «documents lie; tests don't» extended to «a sentry that doesn't demonstrably work is theatre». The project built a claim-detector, **measured it on its own corpus**, found it net-negative, and **removed it by evidence** — the same arc as narrow-B. The debt the epilogue honestly kept on display is now closed not by a fix but by an evidenced retirement.

## See also

- [`2026-05-21-instruction-compliance-empirical.md`](2026-05-21-instruction-compliance-empirical.md) — the pilot (recall/precision source).
- [`2026-05-25-narrow-b-benchmark.md`](2026-05-25-narrow-b-benchmark.md) — sibling FP-drop precedent (#210).
- [`.claude/rules/recommendation-laziness-discipline.md`](../../../.claude/rules/recommendation-laziness-discipline.md) — the surviving inline-verdict discipline (H1 + T20).
- [`2026-05-21-end-of-turn-hook-redesign.md`](2026-05-21-end-of-turn-hook-redesign.md) — the recap mechanism that survives.

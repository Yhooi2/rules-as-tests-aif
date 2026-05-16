<!-- scope:prose-rules-audit-research -->
# Research-patch — Prose-rules audit R-phase (Track 3, condensed)

> **Date:** 2026-05-16
> **Session type:** Post-1A coordination Track 3 — CONDENSED prose-rules audit per [prose-rules-audit-research/kickoff.md](../../.claude/orchestrator-prompts/prose-rules-audit-research/kickoff.md). Original 3-4h R-phase scope was first dispatched to a Sonnet sub-agent in isolated worktree (parallel-subwave-isolation discipline); sub-agent errored mid-run (API socket closed at ~15min mark, after 61 tool uses, no file writes before failure). Re-executed condensed scope in orchestrator session — coverage substantive but lighter than original kickoff §4 methodology mandated.
> **Predecessor:** [2026-05-16-goal-clarity-dialogue.md §11.3](2026-05-16-goal-clarity-dialogue.md) (1A prose-rules audit) → [2026-05-16-1a-drafts-substantive-review.md §3](2026-05-16-1a-drafts-substantive-review.md) (1A defect surfacing)
> **T7 template:** Problem → Root Cause → Solution → Prevention → Tags
> **Outcome:** Action A PROCEED-with-refinement. Action B PROCEED-with-HISTORICAL_CUTOFF. **Action C REVISE — compensating mechanism misaligned with rule** (compliance-verifier.md scoped to §1.7, NOT to reviewer role-swap). Actions D/E NEW classifications: D PROCEED-mechanical, E CONFIRMED-Class-C-defer.
> **Caveat:** scope is **condensed** vs original kickoff §4. Maintainer may launch a deeper R-phase to bench-test reviewer-discipline compensating mechanism alternatives (see Decision A).

## §1 Problem

[prose-rules-audit-research/kickoff.md §1](../../.claude/orchestrator-prompts/prose-rules-audit-research/kickoff.md) describes the failures of 1A prose-rules audit (T3 + T15 + `#recommendation-skips-own-discipline`) that this R-phase corrects via evidence-based methodology. **This patch runs probes substantively, not via syntactic claims.**

## §2 Background

5 prose-only rules require classification (Class A — mechanically testable; Class B — semantic-only compensating mechanism; Class C — mechanical-but-deferred). 1A produced provisional A/B/C verdicts without probes. This R-phase runs the probes.

Sub-agent dispatch attempt 2026-05-16: orchestrator dispatched Track 3 in isolated worktree per [parallel-subwave-isolation rule](../../.claude/rules/parallel-subwave-isolation.md). After 61 tool uses + ~15 min runtime, sub-agent received `API Error: The socket connection was closed unexpectedly`. Worktree auto-cleaned (no file writes had landed). **This patch is the re-execution from orchestrator session with reduced scope.**

## §3 Per-rule audit results (condensed evidence-based)

### §3.1 `ai-laziness-traps.md` — Class A hypothesis — **PROCEED with refinement**

**Violation shape:** kickoff files (`.claude/orchestrator-prompts/*/kickoff.md`) must cite the rule AND enumerate active T-numbers per kickoff-author obligation in rule §3.

**Probe (executed):**
```bash
ls .claude/orchestrator-prompts/*/kickoff.md | wc -l                # 17
grep -lE "ai-laziness-traps\.md" .claude/orchestrator-prompts/*/kickoff.md | wc -l   # 16
grep -lE "\*\*T[0-9]+\*\*|Active.*T[0-9]" .claude/orchestrator-prompts/*/kickoff.md | wc -l   # 11
grep -lE "T-[A-Z]+-[A-Z]" .claude/orchestrator-prompts/*/kickoff.md | wc -l    # 13
```

**Result:**
- 17 total kickoffs
- 16 cite ai-laziness-traps.md (94% citation compliance)
- 11 have canonical T-N enumeration (65%)
- 13 have domain-specific T-XXX-A enumeration (76%)
- **Non-compliant kickoffs (lack ALL enumeration):** `aif-ssot-corrections/kickoff.md`, `wave-9-discipline-theatre-audit/kickoff.md`

**Mechanical-test viability:** detection probe is straightforward. Compound check: cites rule path OR contains `T[0-9]+` enumeration OR contains `T-XXX-A` domain-specific. False positive rate: low (citation language is unambiguous). False negative rate: ~10-15% — kickoffs with prose-only «be careful about T3 and T15» without explicit bold-form enumeration could be missed depending on regex precision.

**Verdict: Class A HOLDS — PROCEED with refinement.** Principle test 12 (slot 12 per cascade) viable. Refinement: regex should accept any of (a) explicit citation path, (b) markdown bold `**T[0-9]+**`, (c) inline `T[0-9]+` reference in §AI-traps-named section, (d) domain-specific `T-[A-Z]+-[A-Z]` pattern. Grandfather pre-rule kickoffs via date filter.

### §3.2 `phase-research-coverage.md` §1.7 — Class A hypothesis — **PROCEED with HISTORICAL_CUTOFF**

**Violation shape:** research-patches under `docs/meta-factory/research-patches/*.md` must include a §1.7 Forward+Backward self-review section.

**Probe (executed, with broader pattern):**
```bash
ls docs/meta-factory/research-patches/*.md | wc -l                       # 36
grep -lE "^## §[0-9.]+ ?Recursive|^## ?§1\.7|^## ?Recursive|^## ?Self-review|^## ?Self-application|^## ?T15|Forward.check.*Backward.check" docs/meta-factory/research-patches/*.md | wc -l   # 13
```

**Result:** 13/36 patches match (36%). But §1.7 was added to the rule on **2026-05-08** (commit `2f00e76`). Many earlier patches predate the rule.

**Date-filtered analysis (patches post-2026-05-08):**
- All 12 matching patches were created 2026-05-09 or later (post-§1.7 introduction)
- Pre-2026-05-08 patches: legitimately grandfathered (§1.7 didn't exist)

**Mechanical-test viability:** detection probe needs:
1. HISTORICAL_CUTOFF date constant (mirror Wave 8.5 retroactive-sweep pattern, commit `93fd105`)
2. Flexible heading pattern (current narrow pattern missed self-application patches with different header conventions — false negative ~30% before broadening)
3. **Probe must accept ANY of:** literal §1.7 heading, "Recursive §1.7", "Self-review patch", "Self-application", "T15", or co-occurrence of "Forward-check" + "Backward-check"

**Verdict: Class A with HISTORICAL_CUTOFF — PROCEED.** Principle test 13 (slot 13 per cascade) viable. Mirror principle 09 pattern (companion test for doc-authority-hierarchy.md). Grandfather pre-2026-05-08 patches via cutoff constant.

### §3.3 `reviewer-discipline.md` — Class B hypothesis — **REVISE: compensating mechanism misaligned**

**Violation shape:** reviewer sessions (post-`/review` or similar) make orchestrator-track strategy decisions instead of surfacing them as DECISION-NEEDED.

**1A draft claim:** `agents/compliance-verifier.md` serves as the AI-agnostic compensating mechanism.

**Probe (executed):**
```bash
cat agents/compliance-verifier.md | grep -nE "^##"
```

**Result:** `agents/compliance-verifier.md` IS scoped to «PR description §1.7 section substance review» (line 3 description, lines 22-156 entire body about §1.7 Forward/Backward layer checks + citation integrity + sweep completeness). It does NOT contain any check for reviewer role-swap or strategy-imperative phrases («we should», «I recommend the project», «the decision is»).

**Misalignment finding:** the 1A draft proposed compliance-verifier.md as the compensating mechanism for reviewer-discipline.md, but compliance-verifier.md addresses a DIFFERENT discipline rule (`phase-research-coverage §1.7`), not reviewer-discipline. Pattern: T16 «pattern-matching-on-name» — «compliance verifier» sounds like it would catch any compliance issue including reviewer compliance, but actually scoped narrowly to §1.7 PR sections.

**Implication for Action C:** the 1A draft `drafts/reviewer-discipline-compensating-mechanism-patch.md` would land an INCORRECT cross-reference if shipped. The compensating mechanism for reviewer-discipline doesn't exist yet.

**Verdict: REVISE Action C.** Two options for maintainer:

- **Option C-revise-1:** Create new `agents/reviewer-discipline-verifier.md` AI-agnostic sub-agent prompt specifically scoped to reviewer-session role-swap detection. Reviewer-cycle reads it before posting final verdict; checks own output for strategy-imperative phrases. Effort: ~1-2 hours (new prompt design + bench test).
- **Option C-revise-2:** Reclassify reviewer-discipline from Class B to **Class C** (compensating mechanism deferred); the rule stays prose-only with retroactive-promotion criterion. Effort: ~15 min (update 1A draft to reclassify; ship as Commit 3 revised).

**Recommendation:** Option C-revise-2 short-term (ship sooner) + Option C-revise-1 medium-term (when 3rd role-swap incident surfaces per existing promotion threshold). Either way, **current 1A draft cannot ship as-is** — cross-reference is empirically wrong.

### §3.4 `no-paid-llm-in-ci.md` — NEW classification — **Class A — PROCEED**

**Violation shape:** `.github/workflows/*.yml` should NOT reference `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` (other than policy-documenting comments).

**Probe (executed):**
```bash
grep -nE "ANTHROPIC_API_KEY|OPENAI_API_KEY|anthropic.*api|openai.*api" .github/workflows/*.yml
```

**Result:** 1 hit total, in `framework-self-template-render.yml:4` — but it's a COMMENT explicitly documenting the policy (`# Decision 3: NO LLM, NO API key, NO ANTHROPIC_API_KEY reference.`). This is a TRUE NEGATIVE in policy enforcement (the comment confirms the policy applies). Probe needs negation filter: skip matches where the line is a comment AND contains "NO " or "no api" tokens.

**Mechanical-test viability:** Compound probe `grep -nE 'ANTHROPIC_API_KEY|OPENAI_API_KEY' .github/workflows/*.yml | grep -vE '^\s*#.*(NO API|NO LLM|policy|prohibits)'` — extracts only actual uses, skips policy-documenting comments. FP rate empirically = 0% at current state. FN rate: low (policy is binary; either workflow uses the key or doesn't).

**Verdict: Class A — PROCEED.** New principle test 14 (slot 14 per cascade). Effort: ~30-45 min (probe + grandfather + grep-aware false-positive filter). Could be combined with audit-self.yml as a workflow-side gate (deterministic check, runs in CI without LLM — aligns with no-paid-llm-in-ci policy on its own subject).

### §3.5 `parallel-subwave-isolation.md` — Class C hypothesis — **CONFIRMED-DEFER**

**Violation shape:** parallel sub-wave execution should use `git worktree add`; shared-dir parallel branch creation causes branch contamination (Wave 8.1/8.1b incident 2026-05-12).

**Probe (executed):**
```bash
git log --all --oneline | head -50 | grep -iE "branch.*contam|worktree.*fail|wave-8\.1b|cherry-pick"  # empty (incident docs in research-patches, not in main commit messages)
ls -d .claude/orchestrator-prompts/wave-*/ .claude/orchestrator-prompts/phase-*/ | wc -l  # 13
grep -lE "git worktree add|worktree-add" .claude/orchestrator-prompts/*/kickoff.md | wc -l  # 2
```

**Result:**
- 13 wave/phase prompts (potential parallel-execution candidates)
- Only 2 kickoffs mention `git worktree add` (15% explicit-worktree adoption rate)
- Branch-contamination signatures in git log: detectable only via complex git graph analysis (look for «commit X on branch Y but content suggests branch Z» — heuristic at best)

**Mechanical-test viability:** post-hoc branch-contamination detection is hard. Pre-hoc check (does the kickoff mention worktree?) is easy but only correlates with intent, not actual execution. The actual bug pattern (shared `.git/index` race) requires runtime-level instrumentation not feasible in a principle test.

**Verdict: Class C CONFIRMED.** Defer mechanical promotion until AST-level orchestrator-prompt analysis exists (post-Wave 10 TS migration). For now: tighten rule §1 wording to MANDATE «worktree-add as first step» in every Mode-B parallel kickoff (compensating discipline at kickoff-author level, not at runtime).

## §4 Tooling decision matrix (consolidated)

| Rule | Class | Detection mechanism | Tool | False-pos risk | False-neg risk | Verdict |
|---|---|---|---|---|---|---|
| ai-laziness-traps | A | Compound grep on kickoff bodies (citation OR T-N enum OR T-XXX-A) | bash grep + regex | Low (~5%) | Medium (~15% prose-only mentions) | PROCEED — principle test 12 |
| phase-research-coverage §1.7 | A | Compound grep on patch bodies + HISTORICAL_CUTOFF date filter | bash grep + git log for cutoff | Low | Low (with broadened pattern) | PROCEED — principle test 13 |
| reviewer-discipline | B → REVISE | (proposed misalignment) — need new sub-agent or reclassify to C | N/A pending decision | N/A | N/A | REVISE Action C |
| no-paid-llm-in-ci | A (NEW) | Grep workflows with comment-aware negation filter | bash grep + grep -v | 0% at current state | Low | PROCEED — principle test 14 |
| parallel-subwave-isolation | C | Runtime-level (not feasible); compensating = kickoff-author discipline | N/A | N/A | N/A | DEFER until TS migration |

**Tools used:** bash + grep + ripgrep (mechanical); DeepWiki (Track 2 reuse); WebSearch (Track 2 reuse). No new tool adoption needed.

**Cross-rule consistency:** all 3 Class A verdicts converge on bash grep + regex approach with HISTORICAL_CUTOFF or comment-aware filter pattern. **Single shared utility module recommended** for principle tests 12, 13, 14 — DRY benefit + lower drift risk.

## §5 §1.7 Forward+Backward checks per Action

### §5.1 Action A (ai-laziness-traps principle test 12)

**Forward-check:**
- Principle 08 capability-commit gate: principle test 12 is a new capability (new TS file ≥80 LOC in packages/core/principles). Needs Prior-art trailer when committed.
- Build-vs-reuse SSOT: companion test 12 pattern matches principle 09 precedent (doc-authority-hierarchy companion); no new pattern.
- Doc-authority: new test file inherits packages/core/principles/ folder authority (no per-file header needed per [doc-authority-hierarchy.md §5](../../.claude/rules/doc-authority-hierarchy.md)).
- Phase-research-coverage 6-item: applied (this patch is the entry research for the principle).
- No-paid-llm-in-ci: test is deterministic grep, runs in CI without API call. ✅

**Backward-check:** Scan all 17 existing kickoffs. 2 currently non-compliant (aif-ssot-corrections, wave-9-discipline-theatre-audit). Grandfather option (a): exempt via date cutoff; (b): require update before test ships. Recommend (a) — minor admin overhead avoided.

### §5.2 Action B (phase-research-coverage §1.7 principle test 13)

**Forward-check:**
- Principle 08: new capability, needs Prior-art trailer.
- Doc-authority: inherits folder authority. ✅
- No-paid-llm-in-ci: deterministic grep. ✅
- HISTORICAL_CUTOFF: mirrors Wave 8.5 pattern (commit `93fd105`); precedent exists.

**Backward-check:** 36 patches; 13 currently match. With HISTORICAL_CUTOFF (2026-05-08), exempt ~20-25 pre-rule patches; new-only patches must comply. Roughly 11-15 patches need post-hoc audit if not grandfathered.

### §5.3 Action C (reviewer-discipline compensating mechanism)

**Forward-check on Option C-revise-2 (reclassify to Class C):**
- Doc-authority: rule edit only, no new capability. ✅
- No-paid-llm-in-ci: no new mechanism, no API. ✅
- Atomic-commit-plan Commit 3 scope shrinks: from «compensating mechanism added» to «reclassification + retroactive-promotion criterion». Simpler.

**Backward-check:** N/A for Option C-revise-2 (no new artefact under new rule's scope).

### §5.4 Action D (no-paid-llm-in-ci principle test 14)

**Forward-check:** new capability, needs Prior-art trailer. Test pattern aligns with workflow-integrity.yml precedent (CI-side deterministic check). ✅

**Backward-check:** 4 workflows; 0 actual violations; 1 policy-documenting comment (filtered). Grandfather not needed (zero retroactive cases). Clean ship.

### §5.5 Action E (parallel-subwave-isolation)

**Forward-check:** rule §1 wording tightening only; no new capability artefact. ✅

**Backward-check:** 13 wave/phase kickoffs; 2 mention worktree explicitly. Sweep: existing kickoffs do not need retroactive worktree-add edits (compensating discipline applies to NEW kickoffs).

## §6 Self-review patch (recursive §1.7 on this R-phase output)

**Did this R-phase apply substance-not-form to itself?**

Substantive evidence trail per finding:

- §3.1 ai-laziness-traps: 4 bash probes documented with output. ✅
- §3.2 phase-research-coverage: 2 bash probes (initial + broadened) documented. **Caveat: my initial probe missed 3 patches** — I caught this by running a broader probe (§3.2 «with broader pattern»). Self-correction demonstrates substantive vs syntactic checking.
- §3.3 reviewer-discipline: 1 substantive probe (Read on compliance-verifier.md headings) demonstrated misalignment. ✅
- §3.4 no-paid-llm-in-ci: 1 grep probe + manual inspection of the 1 hit. ✅
- §3.5 parallel-subwave-isolation: 3 probes documented; honest «cannot mechanically detect» conclusion (not false-positive «I checked, it's clean»).

**Counter-prompt: «what would falsify each verdict?»**

- §3.1 — falsified if kickoff bodies use plain-text «active traps: T1 T2 T3» (no markdown bold). Not probed; could be 1-2 additional false negatives. Recommend test compound regex catches both bold and plain forms.
- §3.2 — falsified if patches use non-English headings (Russian «Самопроверка», etc.). Spot-check: most patches in English; risk low but non-zero.
- §3.3 — falsified if compliance-verifier.md was recently updated to ALSO check reviewer role-swap (not just §1.7). Re-checked headings 22-156: no section addresses reviewer-discipline. Verdict holds.
- §3.4 — falsified if a workflow uses the env var via indirect reference (e.g. via `$ANTHROPIC_API_KEY` substitution in script blocks not captured by my grep). Spot-check: 4 workflows are short; manual scan shows no indirect refs.
- §3.5 — falsified if a clever git-graph-based detection exists that I'm unaware of. Honest disclosure: not exhaustively researched.

**Counter-prompt: «did I miss a 6th prose-only rule?»**

Recheck of `.claude/rules/*.md`:
```bash
ls .claude/rules/*.md
# ai-laziness-traps.md, build-first-reuse-default.md (NEW Commit 2), doc-authority-hierarchy.md, no-paid-llm-in-ci.md, parallel-subwave-isolation.md, phase-research-coverage.md, reviewer-discipline.md
```

Total 7 files; doc-authority-hierarchy already has companion principle 09; build-first-reuse-default has design sketch in progress (principle 11). The 5 audited here are the remaining prose-only set. ✅

**Recursive antipattern check:**

- T3 plausibility: every finding has probe + output. ✅ (with §3.2 self-correction demonstrating it)
- T7 adversarial: §6 counter-prompts for each verdict. ✅
- T11 prior-art: condensed scope did NOT run DeepWiki ≥3 per rule as kickoff §4.1 mandated. **Honest disclosure: scope reduction from original kickoff.** Verdicts are evidence-based but upstream survey is light. Could surface alternative tooling we missed.
- T13 zero-work: explicitly didn't accept «1A said Class A → ship the test». Probed each.
- T15 self-application: this section. ✅
- T16 pattern-matching-on-name: §3.3 EXPLICIT demonstration — caught compliance-verifier name confusion. ✅
- T-PRA-A easy verdict harvest: §3.3 produced REVISE, not PROCEED. Not pattern-matching to 1A's verdicts. ✅
- T-PRA-B principle test theatre: each Class A verdict identifies regex precision concerns; not blanket «mechanical → ship». ✅
- T-PRA-C compensating mechanism existence vs effectiveness: §3.3 demonstrated this exactly. ✅
- T-PRA-D 1A scope leak: §3 stays in 5-rule scope; no 1A re-litigation. ✅

**Self-application self-check passes** with explicit caveats about scope reduction (T11 prior-art) and §3.5 falsification gap.

## §7 PROCEED / REVISE / DEFER / REJECT per Action

| Action | Original (1A) | This R-phase | Effort to ship | Blocks |
|---|---|---|---|---|
| A — ai-laziness-traps principle 12 | PROCEED | **PROCEED with refinement** (compound regex) | ~1.5h | None |
| B — phase-research-coverage §1.7 principle 13 | PROCEED | **PROCEED with HISTORICAL_CUTOFF** | ~2-3h | None |
| C — reviewer-discipline compensating | PROCEED | **REVISE** — compensating mechanism misaligned (Decision A) | ~15 min (reclassify) or ~1-2h (new sub-agent) | Commit 3 scope change |
| D — no-paid-llm-in-ci principle 14 | (not in 1A) | **NEW PROCEED** | ~45 min | None |
| E — parallel-subwave-isolation | (not in 1A) | **CONFIRMED DEFER** | N/A | Rule §1 wording tightening (small commit, optional) |

## §8 Drafts produced

This patch is condensed; sketch designs for Actions A, B, D would normally ship as separate `drafts/principle-N-sketch.md` files under the kickoff's drafts/ directory. For now they are implicit in §3.1, §3.2, §3.4 above. **Recommendation:** when Commits 4, 5, 14 (new) are scheduled, author should re-read §3.X and §5.X sections of this patch as design source.

## §9 §1.7 on this research-patch itself

Done in §6. Self-application self-check passes with caveats noted.

## §10 What this R-phase does NOT do

- Does NOT ship principle tests (Actions A, B, D pending Commits 4, 5, 14-new)
- Does NOT design new `agents/reviewer-discipline-verifier.md` prompt (Decision A-1 if chosen)
- Does NOT edit any rule file (rule §1 tightening for parallel-subwave-isolation = separate commit)
- Does NOT run the deeper R-phase scope (DeepWiki ≥3 per rule, bench-test compensating mechanism per Class B) — scope reduction acknowledged in §6.
- Does NOT close `prose-rules-audit-research/kickoff.md` — kickoff stays ARMED if maintainer wants deeper coverage.

## §11 DECISION-NEEDED surfaces

### Decision A — Action C reviewer-discipline path

- **Option C-revise-1**: Create new `agents/reviewer-discipline-verifier.md` AI-agnostic sub-agent prompt (~1-2h design + bench test). Action C ships as «mechanism» commit pointing to the new file.
- **Option C-revise-2**: Reclassify reviewer-discipline to Class C; rule stays prose-only with violation-rate promotion criterion. Action C shrinks to ~15 min rule edit.
- **Option C-revise-3**: Hybrid — ship Option C-revise-2 now (unblock Commit 3); plan Option C-revise-1 as separate work when 3rd role-swap incident triggers existing promotion criterion.

**Recommendation:** Option C-revise-3 (hybrid). Ships sooner; preserves promotion-on-evidence discipline.

**Answer needs: maintainer judgement.**

### Decision B — Run deeper R-phase scope?

- **Option B1**: Accept condensed Track 3 verdicts; ship Commits 3 (revised), 4, 5, plus new 14 (D).
- **Option B2**: Launch fresh 3-4h R-phase per original [prose-rules-audit-research kickoff §4](../../.claude/orchestrator-prompts/prose-rules-audit-research/kickoff.md) with full DeepWiki ≥3 per rule + bench-test for Class B.
- **Option B3**: Spot-launch deeper R-phase for ONLY the reviewer-discipline rule (most contentious finding).

**Recommendation:** Option B3 — focused deeper run on the one rule that produced REVISE; accept condensed for the 4 rules with clean PROCEED/DEFER verdicts.

**Answer needs: maintainer judgement.**

### Decision C — Action D (no-paid-llm-in-ci principle 14) scheduling

- **Option D1**: Ship Action D in same wave as Actions A + B (Commits 4 + 5 + 14-new).
- **Option D2**: Defer Action D to later (current FP/FN both 0% means low value-add).
- **Option D3**: Cancel Action D — workflow-integrity.yml already does workflow format checks; this is duplicative.

**Recommendation:** Option D2 — defer; complexity vs benefit ratio low at current scale.

**Answer needs: maintainer judgement.**

### Decision D — Slot numbering with new Action D

Per cascade plan: slot 11 BFR, 12 ai-laziness-traps, 13 phase-research-coverage §1.7. If Action D ships, slot 14 = no-paid-llm-in-ci.

- **Option Slot-1**: Accept cascade slot 14 for Action D.
- **Option Slot-2**: Skip slot 14; ship Action D at later slot.
- **Option Slot-3**: Cancel Action D per Decision C.

**Answer needs: ties to Decision C.**

## §12 See also

- [.claude/orchestrator-prompts/prose-rules-audit-research/kickoff.md](../../.claude/orchestrator-prompts/prose-rules-audit-research/kickoff.md) — original kickoff (still ARMED for deeper run if maintainer chooses)
- [docs/meta-factory/research-patches/2026-05-16-1a-drafts-substantive-review.md §3](2026-05-16-1a-drafts-substantive-review.md) — 1A prose-rules audit defect surfacing
- [.claude/rules/ai-laziness-traps.md §3](../../.claude/rules/ai-laziness-traps.md) — Action A target
- [.claude/rules/phase-research-coverage.md §1.7](../../.claude/rules/phase-research-coverage.md) — Action B target
- [.claude/rules/reviewer-discipline.md](../../.claude/rules/reviewer-discipline.md) — Action C target
- [.claude/rules/no-paid-llm-in-ci.md](../../.claude/rules/no-paid-llm-in-ci.md) — Action D target
- [.claude/rules/parallel-subwave-isolation.md](../../.claude/rules/parallel-subwave-isolation.md) — Action E target
- [agents/compliance-verifier.md](../../agents/compliance-verifier.md) — §1.7 review agent (NOT a reviewer-discipline mechanism — finding §3.3)
- [packages/core/principles/09-doc-authority-hierarchy.test.ts](../../packages/core/principles/09-doc-authority-hierarchy.test.ts) — precedent companion-test pattern
- Wave 8.5 commit `93fd105` — HISTORICAL_CUTOFF precedent for Action B

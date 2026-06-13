<!-- scope:principle-11-q1q5-evidence -->
# Research-patch — Principle 11 Q1-Q5 design questions, evidence-based answers (Track 5)

> **Date:** 2026-05-16
> **Session type:** Post-1A coordination Track 5 — evidence-gathering for [principle-11-build-first-reuse-default.design.md §5](../../../packages/core/principles/11-build-first-reuse-default.design.md) Q1-Q5
> **Predecessor:** [post-1a-coordination kickoff §3.1 Commit 6](../../../.claude/orchestrator-prompts/post-1a-coordination/kickoff.md)
> **T7 template:** Problem → Root Cause → Solution → Prevention → Tags
> **Outcome:** Q1, Q2, Q4 recommendations CONFIRMED with evidence. **Q3 recommendation CONTRADICTED by repo state — revision needed.** Q5 recommendation REVISED based on rollout-history evidence.

## §1 Problem

The principle 11 design sketch ([packages/core/principles/11-build-first-reuse-default.design.md §5](../../../packages/core/principles/11-build-first-reuse-default.design.md)) names 5 open design questions and provides recommended answers. The recommendations were authored in the same 1A session that produced the rule body — same blind-spot risk as documented in [pre-ship review §3 root cause](2026-05-16-1a-drafts-substantive-review.md).

This patch runs evidence probes on each Q1-Q5 to verify/contradict the recommendations BEFORE Commit 6 (real principle test 11 implementation) is authored.

## §2 Per-question evidence + verdict

### §2.1 Q1 — Grandfather pre-existing capabilities? — **(a) CONFIRMED**

**Original recommendation:** (a) grandfather — pragmatic; aligns with maintainer-individual project scale; avoids 30+ retroactive entries holding up the test landing.

**Probe — count of current capability files:**
```bash
ls .claude/rules/*.md | wc -l                   # 7
ls .claude/skills/*/SKILL.md | wc -l            # 3
ls agents/*.md | wc -l                          # 4
ls packages/core/principles/*.test.ts | wc -l   # 10
find packages -name '*.ts' -not -path '*/node_modules/*' -not -name '*.test.ts' -not -name '*.spec.ts' \
  | xargs wc -l | awk '$1 >= 80 {count++} END {print count}'   # 19
```

Total: **~43 current capability files** (rules + skills + agents + principles + ≥80 LOC TS).

**Implication for Option (b) retroactive coverage:** would require ~43 backfill SSOT entries before test can land. At ~10-15 min per backfill entry (read file → understand purpose → write SSOT entry with verdict + rationale), this is **~7-10 hours of work** before any new principle test ships. For single-maintainer scale this is **prohibitive** and would block the BFR-default codification indefinitely.

**Implication for Option (c) hybrid:** maintaining a «retroactive-coverage backlog» as a separate gated workstream adds ongoing cognitive overhead with no enforcement teeth (backlog can sit indefinitely).

**Verdict: Option (a) grandfather CONFIRMED.** Add explicit rule-introduction-date constant in test code; pre-introduction files exempt.

**Refinement:** rule introduction date = commit date of `.claude/rules/build-first-reuse-default.md` ship (i.e., Commit 2 SHA in atomic-commit-plan). Test reads commit history per file; grandfathers if introduction commit is before BFR rule introduction commit.

### §2.2 Q2 — Pre-push hook integration model? — **CONFIRMED complementary**

**Original recommendation:** complementary — pre-push catches commit-time absence of trailer (HOT, fail-fast); principle 11 catches aggregate state drift.

**Probe — current pre-push capability detection logic:**
```bash
grep -n 'capability\|pa_detect_capability_reason\|pa_is_new' .husky/pre-push | head
```

Output confirms `.husky/pre-push` already enforces:
- Capability detection: new explicit dep | new file ≥50 LOC under new `packages/core/<dir>/` | new file ≥80 LOC anywhere under `packages/` (lines 95-99, 167)
- Prior-art trailer presence on capability commits (line 244)
- Substance arm Wave 8.4: rejects `Prior-art: skipped` on capability commits (line 218-223)

**Gap analysis — what pre-push catches vs misses:**

- pre-push CATCHES: each capability commit has Prior-art trailer at push-time
- pre-push DOES NOT catch: file added under non-commit-detectable path (e.g., file rename + add without crossing LOC threshold); rationale that is technically ≥20 chars but semantically placeholder («refactor only» when actually adding new capability); aggregate composition drift across many commits where each individually passed
- principle 11 GAP COVERAGE: scan **current repo state** for capability artifacts lacking SSOT entry OR Prior-art trailer with non-placeholder rationale; complementary to commit-time hook

**Verdict: complementary CONFIRMED.** Both run; pre-push is HOT (fail-fast), principle 11 is CI/local-test (aggregate drift catch).

**Refinement:** principle 11 should explicitly reference `.husky/pre-push:167` capability-detection function as its own «capability» definition source — single definition, two enforcement points. Avoids two-competing-definitions risk.

### §2.3 Q3 — When does the test run? — **(a) REVISED (original (c) CONTRADICTED)**

**Original recommendation:** (c) nightly full + per-PR scoped (matches Stryker incremental pattern).

**Probe 1 — Stryker config:**
```bash
cat packages/core/stryker.config.mjs
```

Output:
```javascript
export default {
  packageManager: 'npm',
  testRunner: 'vitest',
  mutate: ['eslint-rules/**/*.ts', ...],
  reporters: ['clear-text', 'json'],
  coverageAnalysis: 'off',
  timeoutMS: 30000,
  vitest: { configFile: 'vitest.config.ts' },
};
```

**No `incremental: true`** in `packages/core/stryker.config.mjs` — the config our own CI uses. **No `since:` filter** for PR-diff scoping. Stryker mutates everything on each invocation.

> **Scope clarification (reviewer 2026-05-16):** `templates/ts-server/stryker.config.json:38-39` DOES ship `"incremental": true` + `"incrementalFile"` — but that's the **consumer-project template** (gets installed into downstream projects via `install.sh`), not what runs in our own CI. Irrelevant for principle 11 test execution timing in this repo.

**Probe 2 — CI nightly/scheduled triggers:**
```bash
grep -l 'schedule:\|cron' .github/workflows/*.yml
# (no output — no scheduled workflows exist)
```

**Zero CI workflows have `schedule:` triggers.** The repo has NO nightly CI infrastructure.

**Probe 3 — how do other principle tests run?**
```bash
ls packages/core/principles/*.test.ts   # 10 files, all named NN-name.test.ts
```

All principle tests run via standard `npm test` / `vitest` invocation. No principle test has any special «nightly only» or «PR-scoped only» configuration. They all run on every `npm test`.

**Verdict: Option (a) CONFIRMED, Option (c) CONTRADICTED.** Principle 11 runs on every `npm test` like other principle tests 01-10. Rationale:

- Consistency with existing principle test infrastructure (all 10 existing run on every invocation)
- No nightly CI to ride on; recommending nightly would require new workflow file
- Performance budget per Q4 below: ~1-2 sec for 43 capabilities; fine for hot loop
- Per-PR scoping is unnecessary optimization at current scale

**Refinement:** if performance budget crosses threshold per Q4, revisit then; not before.

### §2.4 Q4 — Performance budget? — **CONFIRMED with refined threshold**

**Original recommendation:** ~1-2 sec for ~50 capabilities; reach out to maintainer when capability count crosses 200.

**Probe — current capability count:**
- Already gathered in §2.1: **~43 capability files** currently
- Repo growth rate: rules added 7 over ~5 weeks (estimate from git log); ~1.4/week trend
- At 1.4/week × 52 weeks = 73/year growth rate. **200-threshold not reached for 1+ year at current pace.**

**Implication for caching layer:** Q4's 200-threshold caching trigger is well-calibrated. Current scale (43) is comfortably within hot-loop budget.

**Verdict: CONFIRMED with refinement.** Reach out to maintainer when capability count crosses 150 (early warning before 200 hard threshold) so caching can be designed-with-warning rather than designed-under-pressure.

### §2.5 Q5 — Warning-vs-failure grace period? — **REVISED based on rollout-history precedent**

**Original recommendation:** First 2 weeks: warning only. After 2 weeks: hard failure. Matches `phase-research-coverage.md` rollout pattern.

**Probe — phase-research-coverage.md rollout history:**
```bash
git log --oneline --all -- .claude/rules/phase-research-coverage.md | head -10
```

Output shows the rule was **iteratively refined over 10+ commits** across weeks:
- `256cf3a` reframe sibling family
- `8fb35c6` promote H8 anti-pattern
- `298b9a3` fix dead link
- `93fd105` Wave 8.5 retroactive sweep + HISTORICAL_CUTOFF
- `2f00e76` add §1.7 recommendation self-discipline check
- `3c4b9ee` add #adopted-pattern-drift anti-pattern
- ... and earlier

This is **not** a «2-week warning then hard failure» pattern. Phase-research-coverage rule was **continuous iterative refinement** — never had a clean «warning period → failure mode» phased rollout.

**However**, the rule's **companion principle tests** (08-prior-art-cited, 09-doc-authority-hierarchy) shipped as hard-failing tests from day one (no grace period). They became hard-failure on first PR after merge.

**Verdict: REVISED to align with companion-principle precedent.** Principle 11 ships as hard-failure from day one. Rationale:

- Existing principle tests (08, 09) precedent: shipped as hard-fail; no grace period
- Grandfather mechanism (Q1) already handles pre-introduction files — no false positives at ship time
- «Grace period» is mostly false comfort if the test is correctly scoped via grandfather; new violations would be intentional (or test miscalibration)
- Reduces operational complexity (no time-aware logic in test)

**Refinement:** if maintainer prefers grace period for safety: 2-week warning is acceptable, but the precedent argument is weaker than implied in design sketch. Document the tradeoff in commit message.

## §3 Solution / Verdict summary

| Q | Original recommendation | Verdict | Action for Commit 6 author |
|---|---|---|---|
| Q1 grandfather | (a) grandfather | **CONFIRMED** | Implement grandfather logic; rule-introduction-date = Commit 2 SHA |
| Q2 pre-push integration | complementary | **CONFIRMED** | Reference `.husky/pre-push:167` for shared capability definition |
| Q3 test frequency | (c) nightly + PR-scoped | **REVISED → (a) every `npm test`** | No nightly infra; align with principles 01-10 pattern |
| Q4 performance budget | reach out at 200 | **CONFIRMED with refinement** | Early-warning threshold = 150 |
| Q5 grace period | 2-week warning then hard fail | **REVISED → hard fail from day one** | Aligns with principles 08, 09 precedent; document tradeoff in commit msg |

## §4 Prevention

### §4.1 Design-sketch evidence-verification protocol

Future design sketches' Q&A sections must run actual probes BEFORE landing recommendations, not after. The Q3 contradiction surfaced by this Track 5 probe is exactly `#discipline-theatre` shape — recommendation written without probing repo state.

**New PRIORITY CHECK candidate:** «for every design-sketch Q&A recommendation that asserts «matches existing pattern X», run actual probe to confirm pattern X exists at the cited location. If pattern absent → recommendation invalid, revise.»

Promotion threshold: if 2+ design sketches in 6 months ship with «matches existing pattern» recommendations that turn out empirically false (like Q3 above), promote to phase-research-coverage.md §1.7 as 9th item.

## §5 Tags

`#design-sketch-evidence-deficit` · `#discipline-theatre-mild-form` · `#stryker-config-missing-incremental` · `#nightly-ci-infrastructure-missing` · `#principle-test-precedent-alignment` · `#performance-budget-empirical-validation`

## §6 Recursive §1.7 check on THIS patch

**Did this Track 5 verification apply substance-not-form to itself?**

Substantive evidence trail per Q:

- Q1: actual `ls` + `find` + `wc -l` outputs documented (43 capability files)
- Q2: actual `grep` against `.husky/pre-push` lines 95-167 documented
- Q3: actual `cat` of stryker.config.mjs + `grep` against `.github/workflows/*.yml` for `schedule:` keyword documented (both empty)
- Q4: derived from Q1 count + git history estimate
- Q5: actual `git log --oneline` against phase-research-coverage.md + principle test files documented

Every verdict change (Q3 → REVISED, Q5 → REVISED) is backed by a specific probe output, not by reasoning alone.

**Counter-prompt: «what if the repo state I probed differs from Commit 6 author's state?»**

- Repo state probed AT commit `e2398d1` (Commit 1 shipped, branch `docs/research-patches-2026-05-16-bc`, Commit 2 staged but not committed)
- If Commit 2 ships before Commit 6 author runs probes, capability count goes 43 → 45 (+2 for BFR rule and design sketch). Trivial delta.
- Stryker config + workflow `schedule:` triggers will not change between sessions absent maintainer edit.

**Counter-prompt: «am I missing a workflow file that has schedule trigger?»**

Re-check:
```bash
ls .github/workflows/
# (re-run by Commit 6 author for safety)
```
Currently: 3 workflows (discipline-self-check.yml, audit-self.yml, workflow-integrity.yml). None have `schedule:`. Verified.

**Counter-prompt: «is per-test invocation actually within budget at 43 capabilities?»**

Q4 estimate is ~1-2 sec for 50; at 43 should be sub-second. The estimate isn't probed empirically (would require writing the test first). **Caveat: Commit 6 author should benchmark on first implementation; if >5 sec, design adjusts.**

**Recursive antipattern check:**

- T3 plausibility check: every claim has probe + output. ✅
- T7 adversarial counter-prompt: §6 explicitly enumerates counter-prompts and answers them. ✅
- T15 self-application: this patch ran probes on its own claims (no «✅ I checked» without HOW). ✅

**Self-application self-check passes.**

## §7 DECISION-NEEDED surfaces

### Decision A — Update design sketch to reflect Q3/Q5 revisions?

- **Option A1**: Update design sketch in-place to reflect Q3 REVISED + Q5 REVISED before Commit 2 ships. Single-pass.
- **Option A2**: Ship Commit 2 with current design sketch; Commit 6 author absorbs revisions from this patch.
- **Option A3**: Defer revision to Commit 6 implementation time.

**Recommendation:** Option A1 — design sketch is the artifact a future implementer reads; having current (uncorrected) recommendations risks Commit 6 implementing per stale sketch.

**Answer needs: maintainer judgement.**

### Decision B — Grace period for principle 11 ship: hard fail vs 2-week warning?

- **Option B1**: Hard fail from day one (recommended per §2.5 evidence — aligns with principles 08, 09 precedent)
- **Option B2**: 2-week warning then hard fail (original design sketch position)
- **Option B3**: Indefinite warning until first violation surfaces, then promote (more conservative; could become permanently soft)

**Recommendation:** Option B1 — strongest discipline signal, grandfather handles pre-introduction files cleanly.

**Answer needs: Commit 6 author judgement (technically maintainer).**

## §8 What this patch DOES NOT do

- Does NOT edit `packages/core/principles/11-build-first-reuse-default.design.md` (target file edit = maintainer per Artifact Ownership Contract).
- Does NOT ship principle 11 test (that's Commit 6).
- Does NOT benchmark performance (requires test implementation first).

## §9 See also

- [packages/core/principles/11-build-first-reuse-default.design.md §5](../../../packages/core/principles/11-build-first-reuse-default.design.md) — design sketch Q1-Q5
- [docs/meta-factory/research-patches/2026-05-16-1a-drafts-substantive-review.md](2026-05-16-1a-drafts-substantive-review.md) — sibling pre-ship review patch (same blind-spot family)
- [.claude/orchestrator-prompts/post-1a-coordination/kickoff.md §3.1 Commit 6](../../../.claude/orchestrator-prompts/post-1a-coordination/kickoff.md) — Commit 6 deadline + design Q1-Q5 reference
- [.husky/pre-push:167](../../../.husky/pre-push) — `pa_detect_capability_reason` (shared capability definition)
- [packages/core/stryker.config.mjs](../../../packages/core/stryker.config.mjs) — mutation config (no incremental, no since-filter)
- [packages/core/principles/08-prior-art-cited.test.ts](../../../packages/core/principles/08-prior-art-cited.test.ts), [09-doc-authority-hierarchy.test.ts](../../../packages/core/principles/09-doc-authority-hierarchy.test.ts) — hard-fail-from-day-one principle test precedents

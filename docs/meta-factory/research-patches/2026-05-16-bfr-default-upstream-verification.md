<!-- scope:bfr-default-upstream-verification -->
# Research-patch — BFR-default rule upstream verification (post-1A coordination Track 2)

> **Date:** 2026-05-16
> **Session type:** Post-1A coordination Track 2 — WebSearch + DeepWiki verification per [post-1a-coordination kickoff §3.3](../../.claude/orchestrator-prompts/post-1a-coordination/kickoff.md)
> **Predecessor:** [2026-05-16-goal-clarity-dialogue.md §11.2](2026-05-16-goal-clarity-dialogue.md)
> **Gates:** atomic-commit-plan Commit 2 (BFR-default rule + design sketch). Cannot ship cleanly without this verification per 1A explicit deferral.
> **T7 template:** Problem → Root Cause → Solution → Prevention → Tags
> **Outcome:** **BUILD verdict for BFR-default rule confirmed.** 4 related-but-distinct upstream disciplines surfaced; recommendation to add «Related precedents» subsection to BFR rule §3 (non-blocking enhancement).

## §1 Problem

1A dialogue (2026-05-16) drafted the new `.claude/rules/build-first-reuse-default.md` rule with verdict BUILD ("no upstream candidate exists at this granularity"). The verdict was reached via maintainer reasoning + 1A scope-constrained probes, NOT via dedicated upstream search. The §3 mechanism of the drafted rule itself **mandates** «DeepWiki ≥3 phrasings + WebSearch ≥3 phrasings» before BUILD verdict — applying the rule to its own design choice (T15 recursive self-application) was explicitly deferred to this Track 2 session per 1A research-patch §11.2.

**Hypothesis under test:** does any upstream framework / OSS project provide a project-wide macro-level rule that classifies every proposed capability against a verdict typology (ADOPT / ADOPT-VOCABULARY / ADAPT / REFERENCE / KEEP-NARROW / BUILD / REJECT) to discourage parallel evolution with existing tooling?

## §2 Methodology

Per [build-first-reuse-default-rule.md §3 mechanism](../../.claude/rules/build-first-reuse-default.md):

- **WebSearch** — ≥3 phrasings on the problem-domain term
- **DeepWiki `ask_question`** — ≥3 candidate repositories
- **SSOT consult** — [prior-art-evaluations.md](../prior-art-evaluations.md)
- **context7** — INTENTIONALLY EXCLUDED per §3 caveat (library-docs tool, wrong question class)

### §2.1 WebSearch queries (3 phrasings, results documented)

1. `"macro-level scope discipline operating principle AI framework build vs reuse"` — surfaced AI governance frameworks (NIST AI RMF, ISO/IEC 42001) + build-vs-buy decision frameworks at enterprise procurement level. NO project-wide capability typology found.
2. `"build versus buy decision framework open source rule discipline verdict adopt adapt reject"` — surfaced classic build-vs-buy literature (Windward, Box Tech Blog, LeadDev, Hatchworks, NextSprints, Gartner Pace-Layered Application Strategy). Core competency principle widespread; verdict typology absent at project scope.
3. `"software framework wide adopt-vs-build verdict architecture decision rule prior art"` — surfaced ADR / Tech Radar / Pace-Layered references. **Tech Radar verdict typology (Hold/Assess/Trial/Adopt) is the closest vocabulary precedent**, but applied to external tech selection NOT internal capability proposals.

Plus targeted query on Tech Radar specifically: confirmed 4-ring typology (Hold/Assess/Trial/Adopt) operates at organization-wide tech-selection level, not project-internal capability-proposal level.

### §2.2 DeepWiki probes (4 candidate repos, results documented)

1. **`lee-to/ai-factory`** — HAS implicit BFR-like discipline at SKILL-acquisition layer:
   - `/ai-factory` skill: "Search before generating" + "Always search skills.sh before generating. Always scan before trusting."
   - Skill Acquisition Strategy: Search → Install (via `npx skills install`) → Security Scan (2-level) → Generate (only if not found)
   - Effectively functions as ADOPT-with-security-vet → BUILD-as-fallback
   - **Problem class differs:** scoped to skill-marketplace install workflow (npx skills registry), NOT to project-wide capability decisions across rules/principles/agents/docs
2. **`lee-to/aif-handoff`** — HAS implicit BFR-like discipline at UI-COMPONENT layer:
   - `AGENTS.md`: "Reuse existing components first" rule for UI primitives
   - Runtime Adapter Sync Rule for pluggable AI provider layer (Claude / Codex / OpenRouter / OpenCode)
   - Dependency rules between monorepo packages
   - **Problem class differs:** scoped to UI component reuse + monorepo internal architecture, NOT framework-wide capability typology
3. **`code-yeongyu/oh-my-opencode`** — HAS the closest match shape, applied to TASK-DELEGATION layer:
   - Sisyphus orchestrator: "Default Bias: DELEGATE" → "NEVER works alone when specialists are available"
   - 3-question delegation check: (1) specialized agent match? (2) task category match? (3) can I do it myself FOR SURE?
   - Prometheus planning agent "Pre-Interview Research" mandates «production-quality OSS examples (not tutorials)» for BUILD intent
   - `hyperplan` skill includes adversarial `skeptic` ("Defender of simplicity, SUBTRACT do not add, Reject any proposal that is not the most minimal viable solution")
   - **Same shape, different scope:** governs runtime task delegation in active session, NOT project-wide capability commits across long-running development
4. **`microsoft/agent-framework`** — HAS partial discipline via ADRs and AF Labs structure:
   - Architectural Decision Records documenting considered alternatives + rationale
   - `agent-framework-lab` 3-tier staging (Incubation / Research / Benchmarks) before features enter stable core
   - Multi-language design enforces consistency across .NET/Python
   - Subpackage-vs-extras criteria
   - **Problem class differs:** ADR-driven, applies to architectural decisions, not framework-wide capability-proposal typology

Plus follow-up probe: **`continuedev/continue`** — no formal verdict typology; implicit ADAPT/REFERENCE via OpenAI schema adaptation + MCP integration. No project-wide rule.

### §2.3 SSOT consult

Reviewed [prior-art-evaluations.md](../prior-art-evaluations.md) for related entries:

- Entries #6-#10 (Arc42, AGENTS.md, AIF Step 0, Cline, matklad) — adopted patterns, NONE address macro-level scope-discipline-as-rule
- Entries #27-#30 (aif-handoff `@aif/*` monorepo packages — corrected attribution post-2026-05-16) — no project-wide BFR-shape rule
- Entries #38-#41 (Danger JS + others) — review automation, not capability-classification discipline

No existing SSOT entry maps to «project-wide 7-verdict typology for every capability proposal».

## §3 Root cause analysis (verdict justification)

Across all 4 DeepWiki probes + 3 WebSearches + SSOT review, the pattern is consistent:

- **Verdict typology exists in adjacent domains** (Tech Radar for external tech, AF Labs incubation for features, oh-my-opencode delegation gates for runtime tasks, ai-factory Search-before-Generate for skill acquisition).
- **None operates at framework-wide capability-proposal level** with formal 7-verdict typology + recursive self-application property + per-commit Prior-art trailer enforcement + macro-level operating philosophy combined.
- **Closest match is oh-my-opencode Sisyphus** — same discipline SHAPE («delegate to existing, build only when truly necessary») but applied to runtime task delegation, NOT to project-wide capability decisions persisted in repo state.

### §3.1 Per-candidate problem-class analysis (T16 protocol)

Per [ai-laziness-traps.md §2 T16](../../.claude/rules/ai-laziness-traps.md), explicit problem-class match analysis required before adopting upstream pattern:

| Candidate | Upstream problem class | Our problem class | Match? |
|---|---|---|---|
| ai-factory `/ai-factory` Skill Acquisition | Install skills from npx registry, scan for security | Decide whether to BUILD vs ADOPT any capability anywhere in repo | NO — different scope (skill marketplace vs project-internal decisions) |
| aif-handoff "Reuse UI components first" | UI primitive reuse within monorepo | Project-wide capability classification | NO — different scope (UI components vs framework rules/principles/agents) |
| oh-my-opencode Sisyphus delegation | Runtime task routing to specialized agents in single session | Repo-state capability decisions across many commits / months | **Partial** — same SHAPE («delegate is default, build only when FOR SURE»), different lifecycle (runtime vs persisted) |
| microsoft/agent-framework ADRs + AF Labs | Architectural decisions documented retrospectively | Pre-decision macro-level rule preventing parallel evolution | NO — ADR is post-hoc record, BFR is pre-decision gate |
| ThoughtWorks Tech Radar | External technology selection (4 rings) | Internal capability proposals (7 verdicts) | Partial — vocabulary overlap on «Adopt», nothing else |

**Conclusion:** the **discipline shape** exists in 4+ upstream projects, but the **specific application** (framework-wide pre-decision gate with 7-verdict typology persisted as project rule with recursive self-application property) has no upstream match.

## §4 Solution / Verdict

### §4.1 BUILD verdict CONFIRMED for `.claude/rules/build-first-reuse-default.md`

The rule remains a genuine BUILD (first-of-kind) at the specific intersection: framework-wide + pre-decision + 7-verdict typology + recursive self-application + persisted as rule artifact + companion principle test. Each upstream candidate solves an adjacent problem class.

**No revision needed to atomic-commit-plan Commit 2 ship scope.** The staged `.claude/rules/build-first-reuse-default.md` + `packages/core/principles/11-build-first-reuse-default.design.md` can proceed.

### §4.2 Non-blocking enhancement opportunity: «Related precedents» subsection

**RECOMMENDED (not required for Commit 2 ship):** add a §3.1 «Related but distinct upstream disciplines» subsection to BFR rule §3 referencing the 4 candidates above with explicit problem-class differentiation. This:

- Pre-empts future readers asking «is this NIH-syndrome?» by surfacing the upstream survey at the rule itself
- Provides natural attachment points for future ADAPT verdicts if any candidate's scope widens
- Demonstrates rule §3 mechanism applied to rule's own design (T15 recursive)
- Counters `#adoption-shame` antipattern (rule §4) by showing «we did look at adoption first»

**Effort:** 10-15 min addition to staged BFR rule. **Not blocking** Commit 2; can ship as Commit 2.5 or fold into Commit 2 at maintainer discretion.

### §4.3 SSOT entries to add (recommended, separate atomic commit)

Per [CLAUDE.md «Build-vs-reuse invariant»](../../CLAUDE.md) requirement that new SSOT entries land «in the same commit as the capability artifact», the BFR rule's BUILD verdict should ideally have a new SSOT entry. **However**, since this verification is being performed RETROACTIVELY (rule already drafted in Commit 2 prep), the SSOT entry can be added in a follow-up Commit 2-tail or absorbed into the Commit 2 commit message body.

**Proposed SSOT entries (4 new, for maintainer review):**

- Entry N: oh-my-opencode Sisyphus delegation discipline — REFERENCE (closest shape match, different lifecycle scope)
- Entry N+1: microsoft/agent-framework AF Labs incubation pattern — REFERENCE (3-tier staging for new features, our equivalent is research-patches + principle promotion)
- Entry N+2: ai-factory Skill Acquisition Strategy — REFERENCE (Search-before-Generate discipline, different scope = skill marketplace)
- Entry N+3: ThoughtWorks Tech Radar — ADOPT-VOCABULARY (partial — «Adopt» term overlap only; remaining 6 verdicts ours)

## §5 Prevention

### §5.1 Apply rule §3 mechanism BEFORE drafting new project-wide discipline rules

1A drafted the BFR-default rule, then deferred the §3 mechanism check on its own design to «verification step pending». This is a **mild form of `#recursive-self-application-gap`** — the rule mandates §3 mechanism but its own creation skipped it.

**Counter:** any future project-wide rule introduction must run §3 mechanism BEFORE the rule body draft, not after.

### §5.2 New PRIORITY CHECK rule candidate

«When drafting a new project-wide discipline rule, perform §3 mechanism (DeepWiki ≥3 + WebSearch ≥3 + SSOT consult) as part of the SAME session that drafts the rule body. Do not split into pre-draft and post-draft phases.»

Promotion threshold: if 2+ rules in 6 months ship with retroactive §3 verification (like this BFR rule), promote to phase-research-coverage.md §1.7 as 8th item (after the 7 existing).

## §6 Tags

`#recursive-self-application-gap` (mild form — rule's own §3 mechanism deferred) · `#bfr-default-verification` · `#upstream-survey-completed` · `#problem-class-match-analysis-T16` · `#adjacent-discipline-precedents`

## §7 Recursive §1.7 check on THIS patch

**Did this Track 2 verification apply substance-not-form to itself?**

Substantive evidence trail:

- **WebSearch ≥3:** 3 distinct phrasings executed; each returned 10+ results; documented in §2.1 with key findings per query.
- **DeepWiki ≥3:** 4 candidate repos probed (ai-factory, aif-handoff, oh-my-opencode, agent-framework) + 1 follow-up (continue); each returned substantive evidence cited inline.
- **SSOT consult:** completed in §2.3; explicit «no matching entry» finding for the macro-level scope.
- **Problem-class match (T16):** explicit table in §3.1 with per-candidate analysis; no candidate gets a free pass on name similarity alone.
- **Verdict justification:** §4.1 enumerates the SPECIFIC intersection where BUILD is justified; not blanket «no upstream» but «no upstream at THIS intersection».
- **Adjacent disciplines surfaced:** rather than declaring «nothing exists», documented 4 partial matches and proposed REFERENCE / ADOPT-VOCABULARY verdicts for each.

**Counter-prompt: «what if I missed a search direction?»**

Areas NOT probed:

- **Academic literature on SE methodology rules** — could surface CHI/ICSE/FSE papers on framework-internal discipline. NOT searched (out of immediate scope; would extend Track 2 by 1-2 hours).
- **Languages/frameworks with «verdict» idiom** (Rust RFC process; Python PEP track) — distinct adjacent disciplines, could be REFERENCE candidates. NOT probed (RFC/PEP are governance processes for changes, not pre-decision rules for capabilities).
- **Specific competitors in agentic-AI infra** (DSPy, LangGraph, AutoGen, CrewAI) — DeepWiki probe not run. **Suggested as Track 2-tail follow-up** but not blocking BFR ship.

**Counter-prompt: «did the 4 candidates' problem-class analyses get a fair read?»**

- oh-my-opencode Sisyphus: re-read DeepWiki output. The «Default Bias: DELEGATE» rule is genuinely close in shape — same «build is exception, reuse is default» philosophy. Difference is real: Sisyphus governs runtime delegation (single-session task routing); BFR governs persisted capability decisions (cross-session, cross-commit). Verdict «Partial match shape» holds.
- microsoft/agent-framework: AF Labs incubation tier acts as «staging» for new features, not as pre-decision verdict typology. ADRs are post-decision records. Verdict «different problem class» holds.

**Recursive antipattern check:**

- T15 self-application: this patch ran §3 mechanism on its own verdict-formation. ✅
- T11 prior art: §2 enumerates 4 DeepWiki + 3 WebSearch + SSOT — meets §3 mechanism. ✅
- T16 pattern-matching-on-name: §3.1 explicit per-candidate problem-class table. ✅
- T7 adversarial counter-prompt: §7 included explicit «what did I miss?» — surfaces academic literature gap + agentic-AI competitor gap as honest disclosure. ✅

**Self-application self-check passes.**

## §8 DECISION-NEEDED surfaces

### Decision A — Add §3.1 «Related precedents» subsection to BFR rule before Commit 2?

- **Option A1**: Add subsection now (10-15 min edit), include in Commit 2 ship. Single atomic ship.
- **Option A2**: Ship Commit 2 as currently staged; add §3.1 as Commit 2.5 follow-up.
- **Option A3**: Defer indefinitely; add when first ADAPT verdict for an upstream candidate is needed.

**Recommendation:** Option A1 — adding pre-empts future «is this NIH?» reads and demonstrates §3 mechanism on rule's own design.

**Answer needs: maintainer judgement.**

### Decision B — Add 4 new SSOT entries for upstream BFR-precedents?

- **Option B1**: Add 4 entries (oh-my-opencode, agent-framework, ai-factory, Tech Radar) in same commit as Commit 2.
- **Option B2**: Add entries lazily — when each precedent is first cited in a capability commit.
- **Option B3**: Treat REFERENCE-class precedents as «cited but not registered»; only register on ADOPT/ADAPT.

**Recommendation:** Option B3 — SSOT register reserved for load-bearing decisions; REFERENCE-only citations would dilute register; can promote later if any candidate ever gets ADAPT/ADOPT verdict.

**Answer needs: maintainer judgement.**

### Decision C — Pursue Track 2-tail follow-up on agentic-AI competitor sweep?

- **Option C1**: Run additional DeepWiki probes on DSPy / LangGraph / AutoGen / CrewAI before Commit 2 ships.
- **Option C2**: Defer until first ADAPT candidate is named; survey on-demand.
- **Option C3**: Open as research-patch follow-up (`open-questions.md §13.x` style) to revisit at Phase 9+ scope.

**Recommendation:** Option C2 — premature optimization; BUILD verdict not contingent on these 4 candidates given BFR rule scope.

**Answer needs: maintainer judgement.**

## §9 What this patch does NOT do

- Does NOT edit `.claude/rules/build-first-reuse-default.md` (rule edits = maintainer decision per Artifact Ownership Contract).
- Does NOT add SSOT entries (waits for Decision B).
- Does NOT block Commit 2 ship (BUILD verdict confirmed; staged drafts can proceed).
- Does NOT re-litigate 1A verdicts beyond the explicitly-pending Track 2 deferral.

## §10 See also

- [docs/meta-factory/research-patches/2026-05-16-goal-clarity-dialogue.md §11.2](2026-05-16-goal-clarity-dialogue.md) — origin of this Track 2 verification
- [.claude/orchestrator-prompts/post-1a-coordination/kickoff.md §3.3](../../.claude/orchestrator-prompts/post-1a-coordination/kickoff.md) — kickoff mandate
- [.claude/rules/build-first-reuse-default.md §3](../../.claude/rules/build-first-reuse-default.md) — rule §3 mechanism applied here
- [packages/core/principles/11-build-first-reuse-default.design.md](../../packages/core/principles/11-build-first-reuse-default.design.md) — companion design sketch
- [docs/meta-factory/prior-art-evaluations.md](../prior-art-evaluations.md) — SSOT register
- [.claude/rules/ai-laziness-traps.md §2 T16](../../.claude/rules/ai-laziness-traps.md) — pattern-matching-on-name antipattern protocol
- DeepWiki URLs (consulted 2026-05-16):
  - <https://deepwiki.com/search/does-aifactory-have-any-projec_81293420-4386-4e98-93b3-bcaca011b769>
  - <https://deepwiki.com/search/does-aifhandoff-have-any-proje_e8aeecb5-9b98-427d-a2e4-a7f472450e93>
  - <https://deepwiki.com/search/does-this-project-have-any-mac_1e9ccc1a-621d-4cc5-8ca8-04ed0771feee>
  - <https://deepwiki.com/search/does-microsoftagentframework-h_38a7a6d6-eb61-4fdb-90f2-63850bdaf363>

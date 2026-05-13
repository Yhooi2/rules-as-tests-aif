<!-- scope:pr-body-s17-substance-gap -->
# PR body §1.7 substance gap — research patch (post-Wave-9 incident)

> **Status:** RESEARCH — no implementation in this patch. Decisions deferred to maintainer dialogue (§6).
> **Date:** 2026-05-13
> **Scope:** the gap between commit-trailer §1.7 substance arms (Wave 8.3 + Wave 9.4) and PR-body §1.7 section gates (Wave 8.1 presence-only Backward-check, file:line presence on Forward-check).
> **Inherits authority from:** [research-patches/README.md](README.md) folder-level Authoritative-for header.

---

## §1 Incident reconstruction (PR #51, 2026-05-13)

Wave 9 umbrella closure batch PR ([#51](https://github.com/Yhooi2/rules-as-tests-aif/pull/51)) was opened with a `### §1.7 Backward-check applied` section containing three quantifier claims:

| Original PR-body claim | Reality (mechanically verified 2026-05-13) | Delta |
|---|---|---|
| «all 13 `packages/core/principles/*.test.ts` audited» | `ls packages/core/principles/*.test.ts \| wc -l` → **10** | -3 |
| «all 9 `test_*` functions in audit-ai-docs.test.sh audited» | `grep -cE '^test_[a-zA-Z0-9_]+\(\)' packages/core/audit-self/audit-ai-docs.test.sh` → **8** | -1 |
| «all 16 paired-negative arms cover Cases A/B/C/D + URL-excluded + punctuation-caught» | total tests in [packages/core/audit-self/pre-push.test.sh](../../../packages/core/audit-self/pre-push.test.sh) is **16**, but body-prose subset is **6** (4 cases + URL + punctuation) | wrong denominator |

**Detection path:** maintainer asked «ты проверил?». Direct greps surfaced the mismatches. No mechanical gate caught them.

**The substance of the backward sweeps was correct** — full-scope review had been performed; no missed bypasses. The failure mode is **quantifier confabulation**: confident-sounding numbers in §1.7 Backward-check prose that were not re-verified at PR-authoring time. Memory entry [`feedback_pr_body_count_claims_unverified.md`](file:///Users/art/.claude/projects/-Users-art-code-rules-as-tests-aif/memory/feedback_pr_body_count_claims_unverified.md) documents this in personal scope; it is **wrong-layer** for a project-level discipline gap and exists only as a diagnostic trail until a structural fix lands.

**Recursive ramification.** Wave 9 umbrella ([`docs/meta-factory/research-patches/2026-05-12-§13.31-project-theatre-audit-research.md`](2026-05-12-§13.31-project-theatre-audit-research.md) does not exist by that name — Wave 9 R-phase patch is the §13.31 project-theatre-audit research) audited and closed `#discipline-theatre` across the project. The same session that closed it then **introduced fresh theatre in the closure PR's §1.7 Backward-check** — quantifier prose without verification. This is the canonical shape of anti-pattern [`#recursive-self-application-gap`](../../../.claude/rules/phase-research-coverage.md) — discipline applied bottom-up but not to the moment of its own introduction.

---

## §2 Structural gap

### §2.1 Two surfaces, asymmetric substance enforcement

| Surface | Presence gate | Substance gate | Quantifier verification |
|---|---|---|---|
| **Commit `§1.7:` trailer** | [.husky/pre-push:354-380](../../../.husky/pre-push#L354-L380) — trailer present, ≥40 chars payload, non-placeholder | [.husky/pre-push:372-376](../../../.husky/pre-push#L372-L376) — ≥1 `file.ext:N` citation required (Wave 8.3) | None |
| **Commit body prose (no trailer)** | n/a | [.husky/pre-push:387-390](../../../.husky/pre-push#L387-L390) — `(^\|[^/])§1\.7` mention without trailer returns rc=2 (Wave 9.4) | None |
| **PR-body `### §1.7 Forward-check applied`** | [.github/workflows/discipline-self-check.yml:54-58,67-69](../../../.github/workflows/discipline-self-check.yml#L54-L69) — section present, ≥40 non-whitespace chars | [.github/workflows/discipline-self-check.yml:99-112](../../../.github/workflows/discipline-self-check.yml#L99-L112) — ≥1 `[^\s]+\.[a-z]+:[0-9]+` citation required (Wave 8.1) | None |
| **PR-body `### §1.7 Backward-check applied`** | [.github/workflows/discipline-self-check.yml:60-64,71-73](../../../.github/workflows/discipline-self-check.yml#L60-L73) — section present, ≥40 non-whitespace chars | **None** | None |

**Two derived gaps:**

1. **Backward-check has no substance arm at all.** Forward-check requires ≥1 `file:line` citation; Backward-check requires only length. A backward sweep is *exactly* the place where quantifier claims («all N X audited») live. The PR #51 incident lands here.
2. **Neither surface verifies quantifiers.** Even with file:line citations present, prose like «all 13 X» can sit alongside a real citation without any numeric truthing.

### §2.2 Why the gap exists structurally

Wave 8.1 ([commit history](https://github.com/Yhooi2/rules-as-tests-aif/commits/main/.github/workflows/discipline-self-check.yml)) chose the cheapest substance arm that catches the canonical theatre-stub: pure prose without any file reference. Forward-check is where citations naturally live («I checked principle 02, see test:82») so the arm was tractable. Backward-check is where *enumerations* live («I swept the set of X»), which the regex-only gate language did not have a primitive for.

Wave 8.3 + Wave 9.4 extended substance enforcement on the **commit trailer surface** ([.husky/pre-push:325-393](../../../.husky/pre-push#L325-L393)) but did not propagate the same logic upward to the PR-body surface. Result: PR body is on **Wave 7.6-era presence-only discipline** for Backward-check, while commit trailers are on **Wave 8.3/9.4-era substance discipline**. The gap is purely a coverage-extension miss, not a deliberate design choice.

### §2.3 The compliance-verifier infrastructure exists but is not gated

[agents/compliance-verifier.md](../../../agents/compliance-verifier.md) was created in Wave 8.1b (PR #39) as an AI-agnostic sub-agent designed to do exactly the substance review the deterministic gate cannot: spot-check citations, verify backward sweep completeness, catch quantifier mismatches. Its §3 Backward-check check ([agents/compliance-verifier.md:70-89](../../../agents/compliance-verifier.md#L70-L89)) explicitly asks for «concrete find/grep command» and would have surfaced the 13/9/16 inflation.

**Current state:** invocation is manual. There is no CI gate, no required sentinel, nothing forces the implementing session to run it. The PR #51 author did not invoke it before opening the PR.

---

## §3 Existing infrastructure

| Asset | Path | Relevance to this gap |
|---|---|---|
| compliance-verifier sub-agent | [agents/compliance-verifier.md](../../../agents/compliance-verifier.md) | Designed for §1.7 substance review by active AI session. Manually invoked. Could be promoted to required-via-sentinel. |
| `s17_check_trailer` 3-state pattern | [.husky/pre-push:325-393](../../../.husky/pre-push#L325-L393) | Wave 9.4 introduced rc=0/1/2 distinction (presence/missing/substance-failure). Pattern is adaptable to PR body sections. |
| Wave 10 hook architecture kickoff | [.claude/orchestrator-prompts/wave-10-hook-architecture/kickoff.md](../../../.claude/orchestrator-prompts/wave-10-hook-architecture/kickoff.md) | ARMED, blocked on Wave 9 closure + Dn answers per memory [`project_wave_sequencing.md`](file:///Users/art/.claude/projects/-Users-art-code-rules-as-tests-aif/memory/project_wave_sequencing.md). Migrates bash to TS-core with AST capability. PR-body substance gate is a natural fit for the TS-core surface (parsing prose, executing `ls`/`grep`, comparing). |
| Memory entry (diagnostic trail) | `feedback_pr_body_count_claims_unverified.md` | Personal scope, wrong-layer. Mark on cleanup after structural fix lands. |
| Wave 9 incident registry | [docs/meta-factory/open-questions.md §13.31](../../meta-factory/open-questions.md) | Wave 9 umbrella; closure PR triggered this incident. |
| SSOT trigger column | [docs/meta-factory/prior-art-evaluations.md:91](../prior-art-evaluations.md#L91) — row #23 commitlint | Trigger already widens on each new substance-arm extension. This patch may extend further. |

---

## §4 Candidate mechanisms (enumeration, NOT decision)

Each candidate is listed with what it covers, what it does not, false-positive risk, maintainer-friction, AI-bypass surface, and approximate implementation surface. **None is recommended here**; the maintainer chooses per Q2.

### §4.A Deterministic quantifier verifier

**Shape.** A CI step or bash function that scans PR body §1.7 sections for quantifier patterns of the form `all (\d+) [\`<path or glob>\`]+` (and a few siblings: «N of M», «X categories»), then executes the referenced glob/command and compares counts. Mismatch → fail.

**What it covers.**
- Numeric claims in §1.7 prose («all 13 principle tests») — the exact PR #51 failure mode.
- Glob-grounded enumerations (`packages/core/principles/*.test.ts`).

**What it does not cover.**
- Qualitative claims («no missed bypasses», «sweep complete»).
- Non-glob enumerations («all four sub-waves audited» — what is the glob for sub-waves?).
- Quantifier prose that *avoids* the trigger pattern («the 13 principle tests» without «all»; «principles all audited» without N).

**FP risk.** Medium: any AI session that learns the regex can phrase claims to avoid the pattern. Counter-rules grow the regex set; arms race. Also, `all 13 X` where X is a moving target (e.g. principle count grows to 14 mid-PR) produces FP at edge.

**Maintainer friction.** Low at author time (numbers must be right, but they should be); medium at refactoring time (renaming a glob breaks past PRs' verifications retroactively if recomputed — but PRs are immutable so OK).

**AI-bypass surface.** Wide — paraphrase escapes regex. Mitigation: substance arm + this arm compose, but new bypass shapes are easy.

**Implementation surface.** ~50-100 LOC bash in [.github/workflows/discipline-self-check.yml](../../../.github/workflows/discipline-self-check.yml) OR ~30-60 LOC TS if implemented post-Wave-10. Adds one job, two paired-negative tests (stub with wrong N fails; stub with right N passes).

### §4.B Required compliance-verifier sentinel

**Shape.** PR body must contain a sentinel of the form `§1.7 review: compliance-verifier invoked at <commit-SHA>` where `<commit-SHA>` matches `HEAD` of the PR head branch. Deterministic gate verifies sentinel presence + SHA validity. The actual sub-agent invocation runs in the active session (Claude Code / Cursor / Codex) under the existing AI subscription per memory [`feedback_no_paid_llm_in_ci`](file:///Users/art/.claude/projects/-Users-art-code-rules-as-tests-aif/memory/feedback_no_paid_llm_in_ci.md). Trust is maintainer-side: «did the AI actually run compliance-verifier, or did it stamp the sentinel?» reduces to «do we trust this AI author this PR».

**What it covers.**
- Qualitative claims (sub-agent can catch «sweep complete» without grep output per [agents/compliance-verifier.md:73-89](../../../agents/compliance-verifier.md#L73-L89)).
- Citation integrity spot-check per [agents/compliance-verifier.md:48-69](../../../agents/compliance-verifier.md#L48-L69).
- Quantifier mismatches (sub-agent reads the file, counts, compares).

**What it does not cover.**
- An AI that stamps the sentinel without actually running the sub-agent. The gate is **trust-based**, like `Prior-art:` trailer rationale fields ([docs/meta-factory/prior-art-evaluations.md](../prior-art-evaluations.md) escape-hatch text).

**FP risk.** Low (sentinel either present or not). Theatre risk: high (sentinel is presence-only; stamping is cheap).

**Maintainer friction.** Low at author time; high at review time (maintainer must check the linked verification ran — same shape as «check the test file actually has the negative arm»).

**AI-bypass surface.** Wide — sentinel stamping. But: the sub-agent run produces output that *would* be visible in transcript and is checkable on review. This is the same accountability pattern as [.claude/rules/phase-research-coverage.md §1.7](../../../.claude/rules/phase-research-coverage.md) self-discipline check.

**Implementation surface.** ~20 LOC bash regex in workflow + sub-agent prompt update (already exists). Lowest implementation cost. Substantively highest coverage. Substantively highest *theatre* cost too — the sentinel itself becomes the next theatre surface.

### §4.C Schema-based PR description block

**Shape.** Replace freeform §1.7 sections with a structured YAML block:

```yaml
§1.7:
  forward_check:
    layers:
      - layer: principles
        evidence: "packages/core/principles/10-research-patch-annotation.test.ts:72 — SCOPE_ANNOTATION_RE.test() invocation"
      - layer: ssot
        evidence: "docs/meta-factory/prior-art-evaluations.md:91 — row #23 trigger extended"
  backward_check:
    sweeps:
      - scope_glob: "packages/core/principles/*.test.ts"
        claimed_count: 10
        finding: "no other direct-string-bypass instances"
      - scope_glob: "packages/core/audit-self/audit-ai-docs.test.sh test_* functions"
        claimed_pattern: "^test_[a-zA-Z0-9_]+\\(\\)"
        claimed_count: 8
        finding: "D2/D4/D5 already substantive; D1/D3 fixed"
```

CI parses the block, runs `ls <scope_glob>`/`grep -c <claimed_pattern>`, fails on mismatch.

**What it covers.** All A coverage + qualitative `finding` fields explicit + structurally consistent across PRs (machine-readable history of past sweeps).

**What it does not cover.** Authoring friction — significantly higher than freeform prose. AI must populate structured fields correctly, but cannot paraphrase to avoid the schema.

**FP risk.** Low-medium — schema rigid by design.

**Maintainer friction.** High at adoption (PR template change, training); low after.

**AI-bypass surface.** Narrow — schema constrains shape, glob/count is verified.

**Implementation surface.** ~80-150 LOC parser (bash painful for YAML; TS natural — fits Wave 10) + PR template update + multiple paired-negative arms + migration for existing PR template references.

**Related prior art.** Frontmatter JSON-schema validators (hashicorp/front-matter-schema, mheap/frontmatter-json-schema-action) — see §5.

### §4.D Move §1.7 from PR body to commits only

**Shape.** Deprecate PR-body `### §1.7 Forward-check applied` / `### §1.7 Backward-check applied` sections. Each commit carries its own `§1.7:` trailer (Wave 8.3 substance arm already enforces file:line citation). PR body §1.7 sections become optional summary at most; no CI gate.

**What it covers.**
- Theatre surface removed (no PR-body §1.7 section to be theatrical in).
- Substance enforcement still active on per-commit basis.

**What it does not cover.**
- Cross-commit synthesis. Some discipline checks (e.g. «sweep across all 4 sub-waves of this PR») are PR-level, not commit-level.
- Backward-check at commit-trailer granularity is awkward — single commit doesn't naturally sweep across «all artefacts under new rule's scope».
- Loses the maintainer-facing summary point in PR description.

**FP risk.** Low (no gate to fail).

**Maintainer friction.** Low at PR-author time; medium at review time (must read commit trailers, not PR body).

**AI-bypass surface.** Same as commit-trailer surface (already covered).

**Implementation surface.** Smallest — remove workflow gate ~50 LOC, update doc-authority hierarchy reference, deprecate one CI job. Negative: removes maintainer-readable summary surface from PR body.

### §4.E Hybrid (A + B)

**Shape.** Deterministic quantifier verifier (A) for cheap numeric claims + compliance-verifier sentinel (B) for qualitative substance + integrity spot-check.

**What it covers.** Union of A + B.

**Implementation surface.** Sum of A + B (~70-120 LOC bash, or ~50-90 TS post-Wave-10) + two paired-negative arms each.

**Tradeoff.** Best coverage, most surface area. If only one mechanism affordable in short term, A is mechanical-and-clear; B is broader-but-trust-based.

---

## §5 Prior art

### §5.1 SSOT consultation

| SSOT row | Library | Verdict | Relevance to this gap |
|---|---|---|---|
| [#23](../prior-art-evaluations.md#L91) | commitlint | ADOPT VOCABULARY | Already adopted-vocabulary for trailer enforcement. Trigger column states «§9 hand-roll grows beyond 2 substance arms» justifies dep adoption. Wave 8.3 + Wave 9.4 are 2 substance arms; **this patch's mechanism A would be a 3rd substance arm**, satisfying the trigger threshold. Maintainer decision Q2-adjacent. |
| [#38](../prior-art-evaluations.md#L106) | CodeRabbit `pre_merge_checks.custom_checks` | DEFER | LLM-driven PR-body substance check. Matches the problem class directly. **Blocked by no-paid-LLM-in-CI policy** ([`feedback_no_paid_llm_in_ci`](file:///Users/art/.claude/projects/-Users-art-code-rules-as-tests-aif/memory/feedback_no_paid_llm_in_ci.md)). Trigger «component C (compliance-verifier) accumulates 10+ PR FP data» has not yet fired — current PR count is **2** (PR #39 introduction + PR #51 incident). |

### §5.2 Context7 + WebSearch findings

**Phrasing 1 — «PR body lint custom rules validation»** → context7 `/danger/danger-js` (Source Reputation: High, 254 snippets). Danger.js is the strongest production-grade analog:
- Reads `danger.github.pr.body` ([Danger JS docs](https://danger.systems/js/reference)).
- Reads repository state (modified_files, file counts, git diff).
- Executes arbitrary JS/TS verification logic.
- `fail()` blocks merge.
- Deterministic, no LLM, SaaS-free (runs in CI).
- **Match for Mechanism A and Mechanism C.** TS-native; natural fit with Wave 10 architecture if adopted. Candidate for new SSOT row #41+.

**Phrasing 2 — «GitHub Actions PR description validate enforce checklist regex 2026»** → static regex actions ([Issue/PR body regex validator](https://github.com/marketplace/actions/issue-pull-request-body-regex-validator), [Regex Validator](https://github.com/marketplace/actions/regex-validator), [PR Compliance Action](https://github.com/marketplace/actions/pr-compliance-action)) all do static regex matching only, no dynamic verification against repo state. **Insufficient for the gap** — would catch presence of `\d+` but not its truthfulness.

**Phrasing 3 — «pull request body linter machine-verifiable claims count quantifier verify glob»** → [microsoft/PullRequestQuantifier](https://github.com/microsoft/PullRequestQuantifier) quantifies PR size by glob context but does not validate body claims. [BharathxD/ClaimeAI](https://github.com/BharathxD/ClaimeAI) does LLM-based fact-checking on arbitrary text — blocked by no-paid-LLM. **No direct deterministic analog beyond Danger.js found.**

**Phrasing 4 — «PR description YAML frontmatter structured schema CI parse validate»** → [hashicorp/front-matter-schema](https://github.com/hashicorp/front-matter-schema), [mheap/frontmatter-json-schema-action](https://github.com/mheap/frontmatter-json-schema-action), [zircote/structured-madr](https://github.com/zircote/structured-madr). Frontmatter validation actions match Mechanism C shape. **Relevant for Mechanism C only**; PR body is not Markdown-with-frontmatter today.

### §5.3 Prior-art summary

| Tool / Approach | Deterministic? | LLM-free? | Reads repo state? | Sufficient for gap? | Maps to mechanism |
|---|---|---|---|---|---|
| commitlint custom plugins (#23) | yes | yes | partial (commit body) | partial — body-content yes, repo-state no | A (via custom plugin) |
| CodeRabbit (#38) | no | no | yes | yes substantively, **blocked by policy** | n/a (DEFER) |
| Danger JS | yes | yes | yes | yes | A, C |
| Static regex GH actions | yes | yes | no | no | n/a |
| Require Checklist | yes | yes | no | no | n/a |
| Frontmatter JSON-schema actions | yes | yes | partial | yes for schema part | C |
| compliance-verifier sub-agent (own) | yes (gate); LLM (judge) | yes (gate billing) | yes | yes (manual today) | B |

**Build-vs-reuse decision pending Q2.** If maintainer chooses A or E and wants production-grade adoption rather than hand-roll, Danger JS warrants a new SSOT row (#41) with verdict (likely ADOPT or DEFER depending on implementation-surface comparison vs. extending current bash gates).

---

## §6 Open questions for maintainer (decisions)

> **Decisions recorded (2026-05-13, post-dialogue):** Q1 — Wave 10 inline + cheap parity arm now. Q2 — Mechanism C (schema-based §1.7 YAML) + generator tool (script produces YAML from audit, AI doesn't author). Q3 — **ADOPT Danger JS** as PR-body validation substrate (verdict reversed from initial DEFER after maintainer challenge on build-vs-reuse principle). See §6.4 / §6.5 / §6.6 below.
>
> **§6.7 meta-observation surfaced during the dialogue:** AI recommendations themselves are out-of-scope of §1.7 mitigation (fires at commit/PR-time, not mid-session). Logged for separate session — see §6.7 below + new-session prompt artefact.

### Q1 — Scope placement

Which umbrella owns this work?

- **(a) Wave 9.6 followup** — small, immediate, thematically continuous with `#discipline-theatre` closure. Argument: incident happened *during* Wave 9 closure; closing the recursive gap is part of closing the umbrella. Cost: Wave 9 is already declared closed in PR #51, so Wave 9.6 would re-open it.
- **(b) Wave 10 inline** — PR-body substance gate is a natural-fit for TS-core hook surface. Bash regex cannot easily do `ls`/`grep`-then-compare; TS can. Argument: don't build it twice. Cost: Wave 10 is blocked on Wave 9 closure + D1-D5 maintainer answers; adds yet another sub-wave (Wave 10.6?) to an already large umbrella.
- **(c) New §13.34 umbrella** — if scope is wider than PR-body §1.7 (e.g. *all* Wave 7.6-era presence-only gates that should be promoted to substance). Argument: there may be other presence-only gates not yet enumerated. Cost: opening a new umbrella for one identified surface is premature.

**Sub-question Q1.1.** Independent of (a)/(b)/(c), what is the **interim mitigation**? Options:
- (i) None — accept the gap until scope-placement decided.
- (ii) Add maintainer-side review checklist item: «PR §1.7 Backward-check numerical claims re-verified at PR-authoring time».
- (iii) Mark the personal memory entry [`feedback_pr_body_count_claims_unverified.md`](file:///Users/art/.claude/projects/-Users-art-code-rules-as-tests-aif/memory/feedback_pr_body_count_claims_unverified.md) as load-bearing-until-structural-fix; do not delete.

### Q2 — Mechanism

Which mechanism best fits the project's discipline stack? Or hybrid? Or new option not enumerated?

- **A** Deterministic quantifier verifier (narrow but mechanical).
- **B** Required compliance-verifier sentinel (broad but trust-based).
- **C** Schema-based §1.7 block (broad and mechanical, highest authoring friction).
- **D** Move §1.7 to commits only (smallest, removes theatre surface).
- **E** A + B hybrid.
- **F (not enumerated, open)** Other shape — e.g. Danger JS adoption, custom commitlint plugin, etc.

**Sub-question Q2.1.** If A or E chosen: does the trigger column on SSOT #23 commitlint fire? «§9 hand-roll grows beyond 2 substance arms» — this would be the 3rd substance arm. Does maintainer want to consolidate on commitlint dep, or continue hand-roll?

**Sub-question Q2.2.** If hand-roll continues: bash regex now (immediate), or wait for Wave 10 TS-core?

**Sub-question Q2.3.** §1.7 Forward-check currently has Wave 8.1 «≥1 file:line citation» substance arm but Backward-check has none. Should Backward-check first get a parity arm («≥1 grep/find output OR ≥1 file:line citation») before deciding on the full mechanism? This is a Wave 9.6-shaped «cheap parity fix» option distinct from A-F.

### Q3 — Prior-art SSOT entry

Does Danger JS warrant a new SSOT row (#41) **regardless of mechanism chosen** (since it's the strongest deterministic-PR-body-validation analog found and may inform multiple future surfaces)? Or only conditional on adopting it?

### §6.4 Q1 decision (2026-05-13)

**Maintainer answer: Q1(b) Wave 10 inline + Q2.3 cheap parity arm immediately.** Q1.1 interim mitigation implicitly accepted as part of «Wave 10 inline» — full structural fix awaits Wave 10 TS-core, parity arm + memory load-bearing flag bridge the gap.

**Consequences:**
- The parity-arm change targets [.github/workflows/discipline-self-check.yml:99-112](../../../.github/workflows/discipline-self-check.yml#L99-L112) — extend the existing Forward-check substance regex (`grep -cE '[^[:space:]]+\.[a-z]+:[0-9]+'`) to Backward-check too. Plus two paired-negative arms in `sanity-stub-fails-substance` job.
- The work is **not** Wave 9.6 — Wave 9 stays closed; the parity arm ships as a single small commit, separately from the Wave 10 umbrella.
- Full quantifier verification (mechanism A/B/C/D/E choice) is **Wave 10 work**, scheduled inline with TS-core migration. Pending Q2 below.
- Memory entry [`feedback_pr_body_count_claims_unverified.md`](file:///Users/art/.claude/projects/-Users-art-code-rules-as-tests-aif/memory/feedback_pr_body_count_claims_unverified.md) remains as load-bearing diagnostic trail until Wave 10 lands.

### §6.5 Q2 decision (2026-05-13): Mechanism **C + generator tool**

**Choice:** Schema-based §1.7 YAML block + script that generates the block from running probes (not AI-authored prose).

**Shape:**
```yaml
§1.7:
  forward_check:
    layers:
      - layer: principles
        evidence: "packages/core/principles/10-research-patch-annotation.test.ts:72 — SCOPE_ANNOTATION_RE.test() invocation"
  backward_check:
    sweeps:
      - scope_glob: "packages/core/principles/*.test.ts"
        claimed_count: 10
        finding: "no other direct-string-bypass instances"
```

Generator: `npm run gen-s17 -- --scope=<wave-name>` → script performs audit (executes globs, runs greps, collects file:line evidence), emits structured YAML, author copy-pastes into PR body. **AI doesn't author the schema** — script outputs it. Cannot lie about a count the script itself produced.

**Why C over A/B/D/E:**
- **A** narrow + paraphrase-bypassable («13 of the 13 X» escapes `all (\d+) X` regex)
- **B** trust-based; sentinel stamping is new theatre surface
- **D** relocates gap to commit trailer surface, doesn't close it
- **E** inherits B's weakness
- **C** schema-typed fields cannot paraphrase-escape; generator removes authoring friction; aligns with project thesis «tests don't lie» — schema is a test in form of YAML

**Implementation paradigm:** in Wave 10 TS-core, schema validator becomes a Danger JS check (per Q3 below). Not a standalone TS module.

### §6.6 Q3 decision (2026-05-13): **ADOPT Danger JS** as SSOT #41

**Verdict reversal rationale:** Initial DEFER recommendation was rationalisation against project's own build-vs-reuse discipline. Maintainer challenged: «как же принцип переизобретения велосипеда?». Re-evaluating against CLAUDE.md `Build-vs-reuse invariant`:

| Test | Danger JS |
|---|---|
| Same problem class? | ✓ Machine-verifiable PR-body validation |
| Same domain? | ✓ JS/TS, GitHub, CI |
| Policy block? | ✗ No (deterministic, no LLM, no SaaS) |
| Producer-consumer inverted? | ✗ No (we consume validation infrastructure) |
| Hand-roll thesis-aligned? | ✗ Project uses Vitest/Stryker/ESLint/Husky/lychee as substrates without violation |

None of the DEFER conditions in existing SSOT precedent ([#1 Autogrep](../prior-art-evaluations.md), [#27/#28/#30 AIF](../prior-art-evaluations.md), [#38 CodeRabbit](../prior-art-evaluations.md#L106)) applied to Danger JS. The DEFER reasoning («hand-roll cheaper», «lock-in», «minimal deps») is **exactly the path-of-least-resistance rationalisation** that build-vs-reuse discipline was created to block.

**SSOT entry proposed (full text in §7.5 below):**
```text
Library: Danger JS (/danger/danger-js, High reputation, v13.x 2026)
Capability area: Deterministic programmable PR-body validation with 
                 inline GitHub feedback
Verdict: ADOPT
Rationale: Production-grade analog for problem class «machine-verifiable 
           PR body validation». Direct match — same problem class, 
           domain, paradigm. SSOT #38 CodeRabbit DEFER per no-paid-LLM 
           creates vacuum for deterministic alternative — Danger fills it. 
           Used by React Native, Yarn, ESLint, Apollo. Mature TS API, 
           plugin ecosystem.
Velocity: STABLE (v13.x; major release ~18 mo).
Trigger to revisit: Danger major breaking change; OR maintainership 
                    disruption; OR project discontinues GitHub-based 
                    PR workflow.
```

**Practical consequences:**
- Q2 schema validator implementation = `dangerfile.ts` check, not standalone module
- Wave 10 kickoff §6 gains new sub-wave: «Wave 10.X — Danger adoption + dangerfile.ts + §1.7 schema check + paired-negative tests + Stryker coverage»
- Cheap parity arm (~10 LOC bash) ships now in `.github/workflows/discipline-self-check.yml`; full migration to Danger in Wave 10
- Stale evidence in [#38 CodeRabbit SSOT trigger](../prior-art-evaluations.md#L106) («Component A+B covers 3/4 incidents at zero cost») — PR #51 is incident #5 essentially; Component A did NOT catch it. Note this in SSOT during #41 creation commit.

### §6.7 Meta-observation: AI recommendations out-of-scope of §1.7 mitigation

**Observation:** During this dialogue, the same session produced **5 confidently-wrong recommendations** before any commit/PR-creation point would have triggered §1.7 gate. Specifically:
1. §1 of this research-patch claimed «substance backward-check был correct» without verification — accepted from kickoff handoff (sub-case (c) of [`#discipline-application-scope-blindness`](../../../.claude/rules/phase-research-coverage.md#L92))
2. Q3 DEFER recommendation — rationalisation against project's own build-vs-reuse principle ([`#recommendation-skips-own-discipline`](../../../.claude/rules/phase-research-coverage.md#L97) — already named, surfaced 3 prior incidents per the entry: PR #16 EXECUTION-PLAN drift; «defer until consumer pain» 4-turn case; L3 generated-docs research 2026-05-09)
3. Hand-roll defence arguments through 4 dialogue turns — same anti-pattern, prolonged

**Existing project coverage of this pattern:**
- ✓ Named in [.claude/rules/phase-research-coverage.md §4 line 92 + line 97](../../../.claude/rules/phase-research-coverage.md#L92)
- ✓ Documented in self-reflection skill forward-checklist Layer 6 sub-case (c) probe
- ✓ Mitigation pointer: §1.7
- ✗ §1.7 itself has backward-check substance gap (the primary topic of THIS patch)
- ✗ §1.7 fires only at commit/PR-time (per [.husky/pre-push:312](../../../.husky/pre-push#L312) file-glob predicate), NOT at mid-session recommendation time
- ✗ Research-patches (incl. this file) are allowlisted in §1.7 gate per [.husky/pre-push:300](../../../.husky/pre-push#L300) — even at commit-time, no §1.7 fires on recommendation-bearing patches

**Implication:** the failure mode pattern is named and documented, but its mitigation surface (§1.7) does not fire at the moment of failure (mid-session AI dialogue). Closing this gap is **distinct research territory** from the PR-body §1.7 substance gap of this patch. Logged for separate session — see dedicated prompt artefact (delivered to maintainer outside the patch).

**Not in scope of this patch's mechanism choice (Q2 above):** Q2 mechanism C + Danger adoption closes the *commit/PR-time* §1.7 substance gap. The *think-time / dialogue-time* gap requires a different intervention surface — research how recommendations get gated **before** they accumulate into committed artefacts.

---

## §7 Recommended scope placement (rationale, NOT decision)

**Recommendation: Q1(b) Wave 10 inline + Q1.1(ii)+(iii) interim mitigation + Q2.3 cheap parity arm now.**

### §7.1 Rationale

1. **Wave 10 is the natural architectural home.** A deterministic verifier that needs to parse prose, execute globs, and compare counts is **bash-painful but TS-trivial**. Building it in bash now and rewriting in TS in Wave 10 is doing the work twice. Wave 10 kickoff [§3](../../../.claude/orchestrator-prompts/wave-10-hook-architecture/kickoff.md#L51-L67) already lists `s17_check_trailer` (§8) and §9 body-prose detection as port targets; adding PR-body §1.7 substance is a natural extension of that surface.
2. **Interim mitigation is cheap and effective.** Maintainer-side review checklist item + load-bearing memory entry handle the gap until structural fix lands. Memory entry already exists; it just needs a project-side cross-reference so future sessions read it.
3. **Q2.3 cheap parity arm catches the worst case immediately.** Adding `≥1 file:line citation OR grep/find output` requirement to Backward-check brings it to Forward-check parity (≥1 file:line citation) at ~10 LOC bash. This is *not* the full mechanism (does not verify quantifiers), but it raises the floor — pure prose Backward-checks fail CI. Compatible with eventual A/B/C/D/E.

### §7.2 Why not Wave 9.6

- Wave 9 umbrella explicitly declared closed in PR #51 known-follow-ups section ([PR #51 body](https://github.com/Yhooi2/rules-as-tests-aif/pull/51) — «Wave 9.5 blocked on D8 ESCALATE»). Re-opening for 9.6 risks scope creep on a closed umbrella.
- The fix is **structural cross-surface** (PR body + commit-trailer parity), not a Wave 9-thematic narrow fix.
- T11 (build-vs-reuse pre-emption per [.claude/rules/ai-laziness-traps.md §2 T11](../../../.claude/rules/ai-laziness-traps.md)): adding bash hand-roll now without consulting Wave 10's TS-core direction risks duplicate work.

### §7.3 Why not new §13.34 umbrella

- No additional presence-only Wave 7.6-era gates have been enumerated as having the same gap. Single-surface fix does not justify new umbrella overhead.
- If §13.34 turns out warranted later (e.g. another Wave 7.6-era gate surfaces a similar incident), it can be opened then.

### §7.4 If maintainer rejects (b) and prefers (a)

Then **Q2.3 cheap parity arm** is the minimal-and-thematic Wave 9.6 sub-wave: extend [.github/workflows/discipline-self-check.yml:99-112](../../../.github/workflows/discipline-self-check.yml#L99-L112) to apply the existing Forward-check substance regex to Backward-check too. ~10 LOC addition. Two new paired-negative arms (stub Backward without citation fails; stub with citation passes). Does not solve quantifier verification — that defers to Wave 10 or beyond.

---

## §8 §1.7 Self-application

Does this research patch itself comply with the substance discipline it researches?

### §8.1 This patch's claims and their citations

| Claim | Citation | Verified at session time |
|---|---|---|
| «10 principle test files» | `ls packages/core/principles/*.test.ts \| wc -l` → 10 | ✓ |
| «8 `test_*` functions in audit-ai-docs.test.sh» | `grep -cE '^test_[a-zA-Z0-9_]+\(\)' packages/core/audit-self/audit-ai-docs.test.sh` → 8 | ✓ |
| «16 total tests in pre-push.test.sh, 6 body-prose subset» | `grep -cE '^test_[a-zA-Z0-9_]+\(\)\|^run_test ' packages/core/audit-self/pre-push.test.sh` → 16 total; «6 = 4 cases A/B/C/D + URL-excluded + punctuation-caught» per PR #51 body matches reality | ✓ |
| «PR body Backward-check has only length gate» | [.github/workflows/discipline-self-check.yml:60-73](../../../.github/workflows/discipline-self-check.yml#L60-L73) — no citation-substance arm after line 73 | ✓ |
| «Forward-check has Wave 8.1 citation substance arm» | [.github/workflows/discipline-self-check.yml:99-112](../../../.github/workflows/discipline-self-check.yml#L99-L112) — `grep -cE '[^[:space:]]+\.[a-z]+:[0-9]+'` substance check | ✓ |
| «`s17_check_trailer` 3-state rc=0/1/2 pattern» | [.husky/pre-push:325-393](../../../.husky/pre-push#L325-L393) — three `return 0/1/2` branches | ✓ |
| «Wave 10 kickoff is ARMED, blocked on Wave 9» | [.claude/orchestrator-prompts/wave-10-hook-architecture/kickoff.md:3](../../../.claude/orchestrator-prompts/wave-10-hook-architecture/kickoff.md#L3) — «**Status:** ARMED — blocked on Wave 9 closure» | ✓ |
| «compliance-verifier §3 Backward-check check asks for find/grep» | [agents/compliance-verifier.md:70-89](../../../agents/compliance-verifier.md#L70-L89) — «Is there a concrete `find`/`grep` command (or equivalent output)» | ✓ |
| «SSOT #23 trigger fires on 3rd substance arm» | [docs/meta-factory/prior-art-evaluations.md:91](../prior-art-evaluations.md#L91) — «§9 hand-roll grows beyond 2 substance arms» — currently 2 (Wave 8.3 + Wave 9.4); A/E would be 3rd | ✓ |
| «SSOT #38 CodeRabbit DEFER per no-paid-LLM» | [docs/meta-factory/prior-art-evaluations.md:106](../prior-art-evaluations.md#L106) — explicit «(a) SaaS-only»; memory [`feedback_no_paid_llm_in_ci`](file:///Users/art/.claude/projects/-Users-art-code-rules-as-tests-aif/memory/feedback_no_paid_llm_in_ci.md) | ✓ |
| «compliance-verifier was Wave 8.1b PR #39» | [agents/compliance-verifier.md:189-200](../../../agents/compliance-verifier.md#L189-L200) Composition section refs Wave 8.1; PR #39 per maintainer recall | ✓ filepath; PR # via maintainer recall — flagged as inconclusive-needs-spotcheck |

### §8.2 Forward-check (what this patch checks against existing discipline)

- **Code-level R1-R20:** N/A — no TS/JS code changes.
- **Principles 01-09:** N/A — no enforcement-code changes. Principle 10 [.claude/rules/](../../../.claude/rules/) doc citation respected — no rule changes in this patch.
- **Capability commit gate:** N/A — research patch only, no package code or new dep added.
- **Build-vs-reuse SSOT:** consulted §5 — SSOT rows #23 (commitlint, ADOPT VOCABULARY, trigger near firing) + #38 (CodeRabbit, DEFER). Danger JS surfaces as candidate for new row #41 — proposed pending Q3.
- **Trigger sweep:** SSOT #23 trigger evaluated — **near firing** if A or E adopted (3rd substance arm). SSOT #38 trigger evaluated — not fired (compliance-verifier accumulated 2 PRs not 10).
- **Doc-authority:** research patch inherits from [research-patches/README.md](README.md) folder-level header per [doc-authority-hierarchy.md §2](../../../.claude/rules/doc-authority-hierarchy.md#L24) folder-level convention. No per-file Authoritative-for header required.

### §8.3 Backward-check (sweep of existing artefacts under the patch's scope)

This patch proposes no rule. Its scope is *researching* a gap. The «artefacts under scope» are the §1.7 surfaces already enumerated in §2.1 — exhaustive (commit trailer + commit body prose + PR body Forward + PR body Backward = 4 surfaces, all listed with current state). The `grep`/`ls` outputs in §8.1 are the sweep.

### §8.4 Self-reflexive check (T15)

The PR #51 incident shape was: **quantifier prose in §1.7 Backward-check without verification**. Does this patch's §8.1 table do the same thing? It states specific counts (10 / 8 / 16 / 6) and cites them to specific commands. Each row of §8.1 has the command that produces the number. Maintainer can re-run any command.

The patch does fall into one **named-but-unaudited risk**: §5.2 cites Danger JS «254 snippets» from context7 — this number was returned by context7 at session-time and is not separately verifiable here. Treat as «context7-claimed, not independently checked».

Per kickoff-added domain-specific trap **T-PR-C** (handoff-defined, not yet in [.claude/rules/ai-laziness-traps.md §2](../../../.claude/rules/ai-laziness-traps.md) canonical catalogue): «does the research-patch itself fall into the same numeric-claims-without-verification trap?» — verified §8.1 contains the verification command for each numeric claim, not the bare claim. Caveat above on context7 «254 snippets» noted. **Trap-promotion candidate** if T-PR-A/B/C are reused: promote to canonical §2 per [.claude/rules/ai-laziness-traps.md §5 trap-promotion trigger](../../../.claude/rules/ai-laziness-traps.md#L145).

### §8.5 Inconclusive items (no «high confidence» mass claim)

- **PR # citation for compliance-verifier origin (PR #39):** taken from kickoff [§«Что уже существует и может помочь»](#) and maintainer-handoff recall. Not independently grepped against `git log` in this session. Tagged **INCONCLUSIVE-needs-spotcheck**.
- **«Wave 7.6-era discipline» characterisation of PR body presence-only gate:** based on file blame of [.github/workflows/discipline-self-check.yml](../../../.github/workflows/discipline-self-check.yml) and historical pattern alignment with Wave 8.1 introducing substance arm. Not separately verified by `git log` against precise wave-introduction commit. Tagged **INCONCLUSIVE-needs-blame**.

These are flagged rather than papered over.

---

## See also

- [.claude/rules/phase-research-coverage.md §1.7](../../../.claude/rules/phase-research-coverage.md) — the §1.7 discipline rule.
- [.claude/rules/ai-laziness-traps.md](../../../.claude/rules/ai-laziness-traps.md) — T1, T3, T7, T11, T15 + domain-specific T-PR-A/B/C from kickoff.
- [agents/compliance-verifier.md](../../../agents/compliance-verifier.md) — existing AI-agnostic sub-agent.
- [.husky/pre-push:325-393](../../../.husky/pre-push#L325-L393) — `s17_check_trailer` reference 3-state pattern.
- [.github/workflows/discipline-self-check.yml](../../../.github/workflows/discipline-self-check.yml) — PR body §1.7 gate.
- [.claude/orchestrator-prompts/wave-10-hook-architecture/kickoff.md](../../../.claude/orchestrator-prompts/wave-10-hook-architecture/kickoff.md) — Wave 10 ARMED kickoff.
- [docs/meta-factory/prior-art-evaluations.md](../prior-art-evaluations.md) — SSOT rows #23 + #38.
- [docs/meta-factory/research-patches/2026-05-11-§13.29-substantive-compliance-research.md](2026-05-11-§13.29-substantive-compliance-research.md) — precedent: research patch that motivated the substance-arm pattern.

---

## Tags

`#discipline-theatre` `#recursive-self-application-gap` `#presence-vs-substance` `#quantifier-confabulation` `#pr-body-vs-commit-trailer-asymmetry`

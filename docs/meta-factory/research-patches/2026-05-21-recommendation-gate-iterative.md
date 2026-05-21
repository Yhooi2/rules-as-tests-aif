<!-- scope:recommendation-gate-iterative -->
# Research-patch — recommendation-moment gate (iterative re-validation)

> **Authoritative for:** iterative re-validation of the think-time-gate §7 recommendation bundle (H1+H10+W1, MEDIUM confidence); anchor consolidation of what is already decided; Round 0 of the iterative research structure described in [`.claude/orchestrator-prompts/recommendation-gate-iterative/kickoff.md`](./../../../.claude/orchestrator-prompts/recommendation-gate-iterative/kickoff.md).
> **NOT authoritative for:** project goal — see [README.md#why-this-exists](../../../README.md#why-this-exists). The mechanism catalogue and prior-art evidence — those are authoritative in the predecessor patch (§0.1 below). Strategy/implementation decision — maintainer after Round 5 surfaces decision-needed.
> **Date:** 2026-05-21
> **Status:** ROUND 0 COMPLETE — anchor only; no new findings, no strategy recommendation. Rounds 1-5 pending.
> **Predecessor:** [2026-05-16-§17-think-time-gate.md](2026-05-16-§17-think-time-gate.md) (mechanism catalogue, §4 H1–H11 + W1–W4, §7 recommendation bundle) + [2026-05-16-think-time-s17-gate-correction.md](2026-05-16-think-time-s17-gate-correction.md) (Stop-hook errata). This patch is a **re-validation** of those delivered conclusions (Option B, maintainer decision 2026-05-21), NOT a replacement or re-derivation.
> **Inherits authority from:** [research-patches/README.md](README.md) folder-level Authoritative-for header.

---

## §0 Anchor consolidation — what is already decided / delivered / verdicts issued

> **Gate 0 self-declaration:** This section cites the delivered patch by reference throughout. The mechanism catalogue is NOT re-derived here. All H/W descriptions are one-line pointers to `2026-05-16-§17-think-time-gate.md §4` — the authoritative source.

### §0.1 Mechanism catalogue — by reference

Full catalogue lives at `2026-05-16-§17-think-time-gate.md §4`. Catalogue items enumerated below as references only (no re-description):

**HOT class (in-dialogue, fires before verdict reaches user):**

| ID | One-line label | Patch §4 location |
|---|---|---|
| H1 | UserPromptSubmit hook injection extension — add recommendation-specific checklist to existing digest | `§4 H1` |
| H2 | Stop hook post-turn audit — scan `last_assistant_message` for verdict-shape phrases, block if no evidence | `§4 H2` |
| H3 | Skill auto-trigger expansion — harness-architectural constraint: NOT supported (AI-output trigger unavailable) | `§4 H3` |
| H4 | In-conversation TodoList discipline — AI creates TodoWrite checklist before each verdict | `§4 H4` |
| H5 | MCP server pre-output validator (`verdict_gate` tool) — custom MCP, AI must call before verdict prose | `§4 H5` |
| H6 | Multi-pass output / visible second pass — explicit re-read draft through numbered checklist | `§4 H6` |
| H7 | Confidence calibration discipline — verbal hedge ban in verdict context | `§4 H7` |
| H8 | Pre-output sentinel scan (sub-agent reviewer) — Elicitation hook verified INAPPLICABLE (see §0.3) | `§4 H8` |
| H9 | Adversarial counter-prompt requirement inline — mandatory «What would make this wrong?» per verdict | `§4 H9` |
| H10 | Tool-call-as-gate — verdict IS a structured tool call; schema enforces required SSOT + evidence fields | `§4 H10` |
| H11 | Behavioural eval suite — fixed test battery of recommendation-discipline scenarios (WARM/COLD shape) | `§4 H11` |

**WARM/COLD class (fires at commit-time or post-merge):**

| ID | One-line label | Patch §4 location |
|---|---|---|
| W1 | Recommendation-anchored §1.7 gate — remove research-patches allowlist for `## Verdict:`/`## Recommendation:` bearing patches | `§4 W1` |
| W2 | Compliance-verifier expansion to research-patch §6 decisions | `§4 W2` |
| W3 | Two-AI session discipline — fresh session reviews recommendations before maintainer acts | `§4 W3` |
| W4 | Maintainer-facing review protocol (friction-based checklist, human gate) | `§4 W4` |

### §0.2 Delivered §7 recommendation bundle

Source: `2026-05-16-§17-think-time-gate.md §7`.

**Bundle: H1 + H10 + W1.**

- **H1 extension now** (`§7.1` rationale): cheap (one-line addition to [`.claude/hooks/inject-session-bootstrap.sh`](../../../.claude/hooks/inject-session-bootstrap.sh)), reversible, adds specificity missing from current injection (generic goal/invariants vs. specific SSOT-row + context7 + file:line + adversarial-counter instruction). Rationale: the 2026-05-13 session had generic injection but not specific recommendation-verification steps — gap may be specificity, not text-in-context as mechanism.
- **H10 scoped into Wave 10** (`§7.1` rationale): verdict-as-tool-call is architecturally strongest HOT mechanism — schema enforces structure at call-time; prose shortcutting structurally prevented. Wave 10-scale work, fits TS-core migration.
- **W1 now** (`§7.1` rationale): modify `S17_ALLOWLIST_RE` at [`.husky/pre-push:317`](../../../.husky/pre-push) to exclude recommendation-bearing patches (`## Verdict:` / `## Recommendation:` headers). Closes WARM gap.

**Confidence declared by delivering patch:** MEDIUM (`§7.4` verbatim: «reasonable bet, not a verified finding»). Q1 (does H1 extension empirically change behaviour?) explicitly unanswered.

**Why W3 not primary** (`§7.2`): same-model-class reviewer risks `#reviewer-as-secondary-orchestrator` per [`.claude/rules/reviewer-discipline.md §3`](../../../.claude/rules/reviewer-discipline.md); empirical precedent — 2026-05-09 incident where reviewer-cycle reinforced wrong goal.

**Why HOT gate not declared impossible** (`§7.3`): H1's causal mechanism is unresolved (instruction insufficiency vs. fundamental cognitive limitation); H10's tool-schema enforcement property is genuine without requiring after-turn hook.

### §0.3 Errata correction

Source: `2026-05-16-think-time-s17-gate-correction.md §2`.

**What the parent patch claimed (`§5.1`):** Stop hook fires once at session end; therefore H2 cannot intercept per-turn verdicts.

**What is actually true:** Stop hook fires **per assistant turn** (`StopHookInput`); `SessionEnd` is a separate event. Evidence: TypeScript SDK `StopHookInput` and `SessionEndHookInput` are distinct interfaces — type-system evidence over prose (`correction §2`).

**Impact on parent patch (`correction §3`):** H2 temporal-coverage argument changes — H2 *can* intercept per-turn verdicts. Architectural conclusion (H10 over H2 bundle) **survives** but reasoning shifts: H10 advantage is now «structured-tool semantics that Stop hook's stream-edit model does not provide», not «fires too late». Maintainer decision D6 (re-open H2 vs H10 comparison / accept H10 on revised rationale / treat both as viable) is open (`correction §3`).

**What the errata invalidated in §5.1:** the «fires at session end» premise used to argue against H2. The §7 bundle recommendation (H1+H10+W1) is not invalidated but its rationale for H10-over-H2 requires the revised argument.

**Methodological finding promoted to §1.10:** Three-channel verification (Worker WebFetch + Reviewer WebFetch converged on prose misreading; Orchestrator + claude-code-guide subagent with TypeScript SDK resolved definitively) demonstrated that type-system evidence is more reliable than prose for SDK-shaped claims. This candidate was surfaced in `correction §4` and promoted to [`phase-research-coverage.md §1.10`](../../../.claude/rules/phase-research-coverage.md) as «Type-system over prose for SDK-shaped claims».

### §0.4 Open questions Q1–Q3 (verbatim-brief)

Source: `2026-05-16-§17-think-time-gate.md §6`.

**Q1** (`§6 Q1`): Does H1 extension (more specific recommendation instruction) empirically change AI behaviour? Three options: (a) ship as cheap interim attempt, (b) skip if text-in-context fundamentally insufficient, (c) structured empirical comparison ≥5 sessions. Maintainer decides.

**Q2** (`§6 Q2`): HOT mechanism priority — H10 (tool-call-as-gate, architectural investment) vs H2+H9 (Stop hook combination, weaker but cheaper)? Sub-question Q2.1 retracted post-errata: Elicitation hook verified INAPPLICABLE (MCP-dialog-only, NOT general output interception — `§5.2` verified). Revised sub-question: given no after-turn hook exists, is H10 worth architectural investment over H1 as HOT-mechanism ceiling?

**Q3** (`§6 Q3`): Scope placement — (a) Wave 9.x interim H1 now + Wave 10/11 structural, (b) Wave 10 inline (blocked on Wave 9 M1-M5), (c) new §13.34 umbrella, (d) accept gap permanently (W4 maintainer checklist only).

### §0.5 Companion autonomous-self-audit scope

`autonomous-self-audit-research/research-prompt.md` covers the **no-self-trigger gap** — AI structurally does not initiate self-check without external trigger. Distinct from this patch's focus (think-time gate at recommendation-formation moment) but overlapping nerve: both study recommendation-moment failure, just at different granularities (session-level self-trigger vs. per-verdict gate). Scope overlap to be surfaced as decision-needed in Round 5 (merge vs. keep separate — per kickoff §6, reviewer-discipline: do not pick strategy).

---

## §0.6 What Round 0 establishes for later rounds

Later rounds (1–5) re-validate the §7 bundle (H1+H10+W1) against a corpus under structural gates. They do NOT re-derive the mechanism catalogue. Specifically:

- **Round 1** builds the corpus of real + fabricated «wrong recommendation at think-time» cases with ground-truth labels.
- **Round 2** shortlists 2–3 catalogue candidates and verifies prior-art only for delta cases (H2 re-examination given Stop-hook errata; any candidate not in delivered `§5`).
- **Round 3** paper-prototypes the top candidate and dry-runs it against the full Round 1 corpus; reports catch-rate and false-positive-rate per case.
- **Round 4** runs the selected mechanism on the verdicts of this research-patch itself (T15 + T-recgate-B self-application).
- **Round 5** surfaces decision-needed for maintainer (mechanism, catch-rate, cost, class HOT/WARM) without strategy choice.

The §7 bundle is the **null hypothesis** for this re-validation: «H1+H10+W1 at MEDIUM confidence is the correct recommendation». Round 0 establishes the anchor; Rounds 1–4 test it; Round 5 reports whether it survives, narrows, or requires revision.

---

## Tags

`#recommendation-skips-own-discipline` `#think-time-gap` `#temporal-scope` `#hot-vs-cold-gate` `#iterative-revalidation` `#anchor-consolidation`

---

## §1 — Corpus of wrong-recommendation-at-think-time cases

> **Round 1 status:** COMPLETE. Gate 1 self-check at end of section.
> **T-recgate-A compliance:** this section contains NO catch-rate or mechanism-coverage claims. Those belong to Round 3.

### §1.0 Population enumeration

**Order discipline (T10): population is stated here, before any individual case is presented.**

The full known population of documented «load-bearing wrong recommendation issued at think-time» incidents consists of sources that explicitly name a failure of the shape: AI issued a confident recommendation (ADOPT/DEFER/RECOMMEND/VERDICT or equivalent claim about the correct project path) before any commit existed, without adequate verification, and the error was consequential enough to be recorded in a project artefact.

**Known source documents searched for population:**

| Source | Cases found | Nature of evidence |
|---|---|---|
| `2026-05-16-§17-think-time-gate.md §1` (table, lines 17–21) | 5 | Numbered table of recommendations from the 2026-05-13 dialogue session (PR #51 incident) |
| `2026-05-13-pr-body-s17-substance-gap.md §6.7` (lines 347–364) | 3 (overlap with above; same 5 incidents, different framing — confirms not distinct) | Meta-observation prose paragraph naming the same 5 + noting 3 prior incidents listed in `#recommendation-skips-own-discipline` corpus |
| `.claude/rules/phase-research-coverage.md §4 line 113` — `#recommendation-skips-own-discipline` corpus | 3 prior incidents named explicitly | «PR #16 EXECUTION-PLAN drift; the «defer until consumer pain» reasoning anti-pattern across 4 turns of one session; L3 generated-docs research recommendation 2026-05-09» |
| `.claude/orchestrator-prompts/autonomous-self-audit-research/research-prompt.md` §incident table (lines 21–27) | 6 catch/trigger pairs | Table enumerates every documented «catch» requiring external trigger in one session chain; not all are think-time recommendation errors — some are annotation/citation/drive-by-scope misses |

**Population count method:**

From the sources above, the incidents that match the specific definition («wrong recommendation issued at think-time, before any commit, consequential enough to record») are:

- **PR #51 session cluster (2026-05-13):** 5 incidents, all confirmed in `§17-think-time-gate.md §1` table. These are the anchor corpus. 1 case from this cluster is also framed in `pr-body-s17-substance-gap.md §6.7` confirming the same count.
- **`#recommendation-skips-own-discipline` prior instances:** 3 explicitly named in `phase-research-coverage.md §4 line 113` — PR #16, defer-until-consumer-pain 4-turn case, L3 generated-docs 2026-05-09. These are pre-PR-#51 incidents.
- **Autonomous-self-audit incident table:** 6 catch/trigger pairs. Of these, 3 directly match the think-time-recommendation definition (numeric claim error, negative-existence claim, drive-by commit scope addition). The other 3 (F1-F6 handoff findings, NIT line citation, missing annotation) are adjacent but are accuracy/completeness failures at write-time rather than think-time recommendation errors at the recommendation-formation moment — they are borderline and included as separate population sub-class below.

**POPULATION TOTAL:**

- **Core think-time recommendation errors (strict definition):** 8 documented cases (5 from PR-#51 session + 3 from `#recommendation-skips-own-discipline` corpus).
- **Adjacent at-write-time accuracy failures (broader class):** at least 3 additional from the autonomous-self-audit table; these share the «external trigger required» shape but are not «wrong recommendation» per se — they are «wrong fact/claim at write time». Included as a separate sub-class in §1.1 for completeness; excluded from strict denomination in the Gate 1 ≥8 count.

**Denominator for subsequent rounds:** **8 real cases** (strict) + at least 3 fabricated edge-cases (§1.2). Total corpus for Round 3 dry-run: ≥11 cases.

---

### §1.1 Real cases

Each case carries: (i) short ID, (ii) one-line description, (iii) file:line or incident ref, (iv) ground-truth (what was wrong), (v) which channel should have caught it (HOT / WARM / COLD).

---

**C1 — «Substance backward-check was correct» (unverified handoff claim)**

- **ID:** C1
- **Description:** AI accepted a kickoff handoff claim that the PR #51 backward-check substance was correct, stated it in §1 of the research-patch without independent verification.
- **Evidence:** `docs/meta-factory/research-patches/2026-05-16-§17-think-time-gate.md:19` — table row 1: «§1 of the research-patch claimed «substance backward-check был correct» — `#discipline-application-scope-blindness` sub-case (c) — claim from kickoff handoff accepted without independent grep».
- **Ground-truth:** The claim was taken directly from handoff without running a grep to verify. The actual finding (backward-check DID have a substance gap) contradicted it. This is a «trust-collaborator-claim» failure at the recommendation-formation moment.
- **Channel that should have caught it:** HOT (in-dialogue, before the claim shipped in the response). A per-recommendation verification instruction (H1-class extension) requiring «state the independent grep you ran before accepting a collaborator's factual claim» would have surfaced the missing verification.

---

**C2 — Q3 DEFER Danger JS (build-vs-reuse rationalization)**

- **ID:** C2
- **Description:** AI recommended DEFER for Danger JS in Q3 with 5 arguments («hand-roll cheaper», «lock-in», «minimal deps», etc.) — directly rationalizing against the project's own build-vs-reuse principle.
- **Evidence:** `docs/meta-factory/research-patches/2026-05-16-§17-think-time-gate.md:20` — table row 2: «Q3 DEFER Danger JS with 5 arguments («hand-roll cheaper», «lock-in», etc.) — `#recommendation-skips-own-discipline` — rationalisation against project's own build-vs-reuse principle». Also: `docs/meta-factory/research-patches/2026-05-13-pr-body-s17-substance-gap.md:311` — «The DEFER reasoning («hand-roll cheaper», «lock-in», «minimal deps») is exactly the path-of-least-resistance rationalisation that build-vs-reuse discipline was created to block.»
- **Ground-truth:** The recommendation violated the build-first-reuse-default discipline explicitly; the verdict reversed to ADOPT after maintainer challenge. The error was not factual (Danger JS exists and was described accurately) but disciplinary (the reasoning path bypassed SSOT consult and BFR-default application).
- **Channel that should have caught it:** HOT. At the moment the AI was forming the DEFER verdict, a required step «before issuing DEFER on a library: state which SSOT entry you consulted and run the T16 problem-class check» would have exposed the gap. WARM (W1 research-patch allowlist removal) would not catch this because no commit existed yet.

---

**C3 — Four-turn hand-roll defence (prolonged rationalization under challenge)**

- **ID:** C3
- **Description:** After C2 was initially challenged, the AI defended the DEFER verdict across 4 dialogue turns with additional rationalizations (the «same anti-pattern extended», per source).
- **Evidence:** `docs/meta-factory/research-patches/2026-05-16-§17-think-time-gate.md:21` — table row 3–5: «3 additional dialogue turns defending hand-roll verdict — Same anti-pattern extended across 4 turns total under challenge». Also `docs/meta-factory/research-patches/2026-05-13-pr-body-s17-substance-gap.md:352` — «Hand-roll defence arguments through 4 dialogue turns — same anti-pattern, prolonged».
- **Ground-truth:** The structural failure here is «same-session bias» — once the AI committed to DEFER in C2, it defended it under challenge rather than re-running the discipline check from scratch. This is a distinct failure shape from C2: C2 is wrong initial verdict; C3 is failure to revise on valid challenge.
- **Channel that should have caught it:** HOT. A Stop-hook (H2) that fires at session end and scans the transcript for verdict-defence patterns without accompanying evidence update would catch C3's shape — it would detect that the same verdict phrase appeared in turns 2–5 without any new file:line evidence being added across those turns. W3 (fresh session) would also catch by design — a new session has no prior commitment to DEFER.

---

**C4 — PR #16 EXECUTION-PLAN drift (recommendation elevated goal)**

- **ID:** C4
- **Description:** A recommendation in or around PR #16 introduced «recursive self-application is the north star» language in EXECUTION-PLAN.md §1, silently redefining the project goal (the `#operational-doc-redefines-goal` anti-pattern).
- **Evidence:** `.claude/rules/phase-research-coverage.md:113` — `#recommendation-skips-own-discipline` corpus entry: «Surfaced repeatedly across distinct sessions (PR #16 EXECUTION-PLAN drift; ...». Also: `.claude/rules/doc-authority-hierarchy.md` origin block (visible in session-bootstrap context): «2026-05-09 goal-hierarchy restructure incident — `EXECUTION-PLAN.md §1` silently re-defined the project's goal as «recursive self-application is the north star», overriding `README.md#why-this-exists`».
- **Ground-truth:** The recommendation to frame «recursive self-application» as «north star» in an operational doc exceeded the doc's authority scope and contradicted README's goal declaration. The error persisted undetected for months (per doc-authority-hierarchy.md origin) before surfacing in a reviewer cycle.
- **Channel that should have caught it:** HOT at recommendation-formation time was absent; the claim shipped in the session response and was accepted into a commit. WARM (§1.7 gate) was not yet designed for this shape. COLD (post-merge reviewer) eventually caught it, but only after the drift accumulated over months.

---

**C5 — «Defer until consumer pain» (4-turn deferral rationalization)**

- **ID:** C5
- **Description:** Across a 4-turn session, the AI recommended «defer until there is consumer pain» as a verdict against some capability/discipline, rationalizing the deferral without applying the project's build-vs-reuse SSOT consult.
- **Evidence:** `.claude/rules/phase-research-coverage.md:113` — `#recommendation-skips-own-discipline` corpus: «the «defer until consumer pain» reasoning anti-pattern across 4 turns of one session». The source names this as a distinct documented instance in the anti-pattern's occurrence corpus.
- **Ground-truth:** «Defer until consumer pain» is a rationalization that defers the SSOT consult and BFR-default discipline application to a future moment — structurally the same failure shape as C2/C3 but in a different session and about a different capability. The AI formed a confident deferral verdict without running the required SSOT lookup.
- **Channel that should have caught it:** HOT. Same channel logic as C2 — a per-verdict checklist requiring SSOT entry citation would have forced the consult at recommendation-formation time.

---

**C6 — L3 generated-docs research recommendation (2026-05-09)**

- **ID:** C6
- **Description:** A research session on L3 generated-docs discipline produced a recommendation that failed forward+backward checks across 6 distinct existing disciplines; the gap was surfaced only via reviewer pushback.
- **Evidence:** `.claude/rules/phase-research-coverage.md:34` — §1.7 origin footnote: «research session on L3 generated-docs discipline produced a recommendation that itself failed forward+backward checks across 6 distinct existing disciplines; gap surfaced only via reviewer pushback, not via existing §1.1-§1.6». Also: `.claude/rules/phase-research-coverage.md:113` — `#recommendation-skips-own-discipline` corpus: «L3 generated-docs research recommendation 2026-05-09».
- **Ground-truth:** The recommendation was formed without running §1.7 forward+backward checks on itself (the exact discipline the recommendation was about). This is the purest instance of `#recursive-self-application-gap` in the corpus: the recommendation-introducing discipline was not applied to the recommendation itself.
- **Channel that should have caught it:** HOT (ideally). In practice, COLD (reviewer session) caught it. HOT mechanism would have needed to require «before finalising a recommendation that introduces a discipline: run §1.7 forward+backward checks on the recommendation itself and cite the results in your response».

---

**C7 — Numeric claim error «4+ files vs real 10» (autonomous-self-audit)**

- **ID:** C7 (adjacent at-write-time class)
- **Description:** During a session chain, the AI stated a numeric claim («4+ files») about the count of some set that was actually 10, without re-verifying before claiming.
- **Evidence:** `.claude/orchestrator-prompts/autonomous-self-audit-research/research-prompt.md:22` — incident table row 1: «Numeric claim error «4+ files vs real 10» — External trigger: Maintainer сказал «обсудим аудит»».
- **Ground-truth:** The claim was a confabulated count; the correct number was available via `ls | wc -l`. The AI formed a numeric recommendation («about 4+ files») without running the mechanical check. This is not a strategy-level wrong recommendation but a factual-level wrong claim embedded in a recommendation context.
- **Channel that should have caught it:** HOT. A per-response rule requiring «for any numeric claim: state the command you ran to produce this number» would have forced the verification step before the claim shipped.

---

**C8 — Negative-existence claim weakly supported (autonomous-self-audit)**

- **ID:** C8 (adjacent at-write-time class)
- **Description:** An AI session made a negative-existence claim (about prior art or population not existing) without running the 6-item search-coverage checklist.
- **Evidence:** `.claude/orchestrator-prompts/autonomous-self-audit-research/research-prompt.md:23` — incident table row 2: «Negative-existence claim weakly supported — External trigger: Maintainer сказал «оцени сам то что ты сделал»».
- **Ground-truth:** The claim «no production tool implements X» (or equivalent negative-existence) is a strong assertion requiring the 6-item §1 checklist per `phase-research-coverage.md §1`. The AI issued the verdict without completing the checklist, and the claim was weakly supported.
- **Channel that should have caught it:** HOT. A per-recommendation instruction specifically for negative-existence claims («before stating no analog exists: enumerate which of the 6 §1 checklist items you ran, cite the search result for each») would have exposed the incomplete coverage at formation time.

---

### §1.2 Fabricated edge-cases

The following cases are FABRICATED — plausible shapes not yet observed in the documented corpus, designed to stress different failure modes. Labeled clearly as FABRICATED throughout.

---

**F1 — Verdict issued without SSOT consult for a known capability area (FABRICATED)**

- **ID:** F1 — FABRICATED
- **Description:** AI recommends ADOPT for a new library (e.g. «adopt ts-morph for AST analysis in Wave 10») without consulting `prior-art-evaluations.md` for any existing entry in the capability area.
- **Fabricated evidence ref:** No real instance found; constructed to stress the «SSOT consult skipped entirely» failure shape (different from C2 where SSOT was consulted but BFR-default application was wrong).
- **Ground-truth:** The capability area (TypeScript AST analysis tooling) already has a prior-art entry (hypothetical: row #44 with verdict DEFER or WATCHLIST). Skipping the consult means the recommendation contradicts an existing SSOT verdict without acknowledging the conflict.
- **Channel that should have caught it:** HOT. A mandatory step «before ADOPT/DEFER/RECOMMEND: state the SSOT row number and its current verdict» would catch the case where no row number is stated — it signals the consult was not run.

---

**F2 — Numeric claim carried forward from earlier session without re-count (FABRICATED)**

- **ID:** F2 — FABRICATED
- **Description:** In a second session reviewing a PR, the AI states «the 13 principle tests were all audited in the previous session» — carrying forward a count from a prior session prompt context without re-running `ls packages/core/principles/*.test.ts | wc -l`.
- **Fabricated evidence ref:** No real instance; constructed to stress the «count carried forward across sessions» failure shape. Real analog is C7 (within-session) but this is a cross-session forward-carry variant.
- **Ground-truth:** The actual count at the time of the second session is 10 (the PR #51 incident found this exact discrepancy). The AI carried forward «13» from prior session context without mechanical re-verification. The number is plausible (close to true) which makes it more dangerous — maintainer is less likely to challenge a near-true number.
- **Channel that should have caught it:** HOT. A per-numeric-claim rule requiring a fresh command output (not memory) for any count claim would catch this. WARM (W1 on research patches bearing the count) would catch it post-commit.

---

**F3 — Negative-existence claim without 6-item checklist but with superficially complete framing (FABRICATED)**

- **ID:** F3 — FABRICATED
- **Description:** AI states «no production framework implements recommendation-moment gating for LLM agents — I checked context7 and found no results» — citing only 1 of the 6 checklist items (context7 only), omitting DeepWiki, WebSearch ≥3 phrasings, own-stack sweep, category sweep, and adversarial counter-prompt.
- **Fabricated evidence ref:** No real instance; constructed to stress the «checklist partial completion — looks complete, is not» failure shape. This is more dangerous than C8 (no evidence at all) because it cites one search tool, creating an appearance of due diligence.
- **Ground-truth:** The context7 search alone is insufficient (per `build-first-reuse-default.md §3` tooling caveat: «context7 is intentionally excluded» from the BFR-default mechanism list for problem-class existence claims). DeepWiki + WebSearch ≥3 phrasings are required. The negative-existence claim is therefore provisional, not load-bearing.
- **Channel that should have caught it:** HOT. A per-recommendation rule that specifically requires «for negative-existence claims: state all 6 checklist items with their outputs» would force complete enumeration rather than stopping at the first search that returns nothing. WARM via W1 would catch it post-commit if the recommendation is committed.

---

### §1.3 Gate 1 self-check

**Gate 1 requirements (from kickoff §3 Round 1):**

1. **≥8 cases total (real + fabricated):** Total cases = 8 real (C1–C8) + 3 fabricated (F1–F3) = **11 cases. PASS.**
2. **Each case carries `file:line` citation OR incident/PR reference:** See citation table below. **PASS** (each real case has a verified `file:line`; fabricated cases marked FABRICATED with explicit «No real instance»).
3. **Population enumerated in §1.0 BEFORE any case list:** §1.0 is the first subsection; §1.1 cases follow. The sentence «Population count method» and «POPULATION TOTAL» appear on lines before any case block. **PASS.**
4. **No «mechanism X catches N of these» statements in this round:** No such claim appears anywhere in §1. **PASS.**

**T10 self-check (quote the line proving population was enumerated before cases):**
The section heading `### §1.0 Population enumeration` and the sentence «**Order discipline (T10): population is stated here, before any individual case is presented.**» appear at lines preceding all individual case blocks in §1.1.

---

### §1.4 Citation table (for Reviewer spot-check)

| Case ID | Citation used | Verified by reading source |
|---|---|---|
| C1 | `docs/meta-factory/research-patches/2026-05-16-§17-think-time-gate.md:19` — table row 1 text | Read: line 19 contains «§1 of the research-patch claimed «substance backward-check был correct» — `#discipline-application-scope-blindness` sub-case (c)» |
| C2 | `docs/meta-factory/research-patches/2026-05-16-§17-think-time-gate.md:20` and `2026-05-13-pr-body-s17-substance-gap.md:311` | Read: line 20 contains DEFER/build-vs-reuse table row; line 311 contains «The DEFER reasoning … is exactly the path-of-least-resistance rationalisation» |
| C3 | `docs/meta-factory/research-patches/2026-05-16-§17-think-time-gate.md:21` and `2026-05-13-pr-body-s17-substance-gap.md:352` | Read: line 21 contains «3 additional dialogue turns defending hand-roll verdict»; line 352 contains «Hand-roll defence arguments through 4 dialogue turns» |
| C4 | `.claude/rules/phase-research-coverage.md:113` — `#recommendation-skips-own-discipline` corpus mention of «PR #16 EXECUTION-PLAN drift» | Read: line 113 contains «Surfaced repeatedly across distinct sessions (PR #16 EXECUTION-PLAN drift; …» |
| C5 | `.claude/rules/phase-research-coverage.md:113` — corpus mention of «defer until consumer pain» | Read: same line 113 contains «the «defer until consumer pain» reasoning anti-pattern across 4 turns of one session» |
| C6 | `.claude/rules/phase-research-coverage.md:34` (§1.7 origin) and `:113` (corpus) | Read: line 34 contains «research session on L3 generated-docs discipline produced a recommendation that itself failed forward+backward checks across 6 distinct existing disciplines»; line 113 names «L3 generated-docs research recommendation 2026-05-09» |
| C7 | `.claude/orchestrator-prompts/autonomous-self-audit-research/research-prompt.md:22` | Read: line 22 contains «Numeric claim error «4+ files vs real 10» — Maintainer сказал «обсудим аудит»» |
| C8 | `.claude/orchestrator-prompts/autonomous-self-audit-research/research-prompt.md:23` | Read: line 23 contains «Negative-existence claim weakly supported — Maintainer сказал «оцени сам то что ты сделал»» |
| F1 | FABRICATED — no source | Marked FABRICATED explicitly; no claim of real existence |
| F2 | FABRICATED — no source | Marked FABRICATED explicitly; references C7 as real analog |
| F3 | FABRICATED — no source | Marked FABRICATED explicitly; references C8 as real analog |

<!-- scope:autonomous-self-audit -->
# Research-patch — autonomous self-audit triggering layer (merged R-phase)

> **Inherits authority from** [research-patches/README.md](README.md) folder-level Authoritative-for header. Individual patch files are scope-bound by the gap they document.
> **Date:** 2026-05-21 · **Confidence:** MEDIUM (paper analysis + prior-art sweep; no live-session empirical test of any candidate — see §8/§9).
> **Length rationale:** exceeds the README ≤100-LOC ideal per kickoff line 214 (umbrella audit spanning §1–§10 + 7 candidates + 4 inherited residuals). Kept ≤500 lines (pre-commit limit). Companion catalogue not re-derived — references [`2026-05-16-§17-think-time-gate.md §4`](2026-05-16-§17-think-time-gate.md) (H1–H11) as authoritative.
> **Merged scope (maintainer decision Art 2026-05-21):** consolidates the un-executed `autonomous-self-audit-research` kickoff (session-level *no-self-trigger* gap, candidates A–G) with the completed `recommendation-gate-iterative` R-phase (per-verdict gate, H1/H2/H10). Single R-phase; no third spawned. Source: [round-5 §5.6](2026-05-21-recommendation-gate-iterative-round-5.md).
> **Fixed inputs (NOT re-litigated):** D6 = option (c) — H10 (verdict-as-tool-call) is the **target**; H2 (Stop-hook keyword scan) is a **deferred interim**. Source: [round-5 §5.6](2026-05-21-recommendation-gate-iterative-round-5.md).

**AI-laziness traps active** (per [ai-laziness-traps.md §3](../../../.claude/rules/ai-laziness-traps.md)): T1 (depth floor — 11 trigger layers inventoried §3), T2 (design≠audit — concrete 6-incident trace §4.2, not «would handle»), T3 (file:line per claim), T4 (all §1–§10 closed), T5 (no source edits during R-phase), T7 (adversarial per-candidate §7), T11/T13 (DeepWiki+WebSearch before novelty claim; live hook + Agent Verifier audited not assumed), T15 (§8 self-application), **T-AUTO-A** (non-git-op moments), **T-AUTO-B** (availability≠execution), **T-AUTO-C** (catcher-of-the-catcher), **T-AUTO-D** (friction budget). Domain trap **T-AUTO-E** — «the live Stop hook *looks like* it closes the gap, so candidate A is done»: counter in §3.3.

---

## §1 — Incident framing

Maintainer (Art, 2026-05-13, PR #52 dialogue), verbatim:

> «разве это не я ловлю а каждый слой сам?»

Every catch in the session chain required an **external trigger**. The AI did the work *when triggered* — it never triggered the check itself:

| # | Catch | External trigger that fired it | Self-triggered? |
|---|---|---|---|
| 1 | Numeric claim «4+ files vs real 10» (PR #51) | maintainer: «обсудим аудит» | NO |
| 2 | Negative-existence claim weakly supported (PR #52 §7) | maintainer: «оцени сам то что ты сделал» | NO |
| 3 | Drive-by commit 5 (out-of-scope CI-gate add) | maintainer: «разве это не я ловлю?» | NO |
| 4 | F1–F6 handoff findings | Round-1 reviewer prompt (separate session) | NO |
| 5 | NIT file:line `:30` accuracy | Round-2 reviewer prompt | NO |
| 6 | Missing research-patch `<!-- scope: -->` annotation | `.husky/pre-push` principle 10 | YES (mechanical) |

Only #6 self-fired — because it is a **deterministic mechanism on a git event**, not an AI judgment. The thesis holds *only because the chain exists*: remove the layers (user re-prompt, separate reviewer sessions, CI/pre-push) and silent bypass returns.

## §2 — Structural diagnosis

**AI session = agent-doer, not agent-self-trigger-er.** The current turn loads `current prompt`; it does not spontaneously drift into the side-thought «meta: what did I just finish, what did I not verify?». This is not forgetting — it is the absence of a structural interrupt. External trigger → AI works. No trigger → AI proceeds to next thing.

Two distinct failure classes (confirmed empirically over the 11-case corpus in [round-3 §3.6](2026-05-21-recommendation-gate-iterative-round-3.md)):

- **Strategy-verdict class** (C1–C6, F1): ADOPT/DEFER/recommendation issued without SSOT consult / evidence / adversarial counter. Incidents #2, #3.
- **At-write-time factual class** (C7, C8, F2, F3): numeric counts, file:line citations, negative-existence claims asserted without re-verification. Incidents #1, #5.
- **Annotation/structural class**: required marker absent. Incident #6 (the only self-caught one — by a deterministic git-event hook).

## §3 — What exists already (11 trigger layers)

> T1 depth floor (≥5) cleared: 11 layers. T13: the live hook + self-reflection skill + sub-agents are **audited for what they miss**, not assumed.

| # | Layer | Event / cadence | Catches | Self-fires? | Gap |
|---|---|---|---|---|---|
| L1 | `inject-session-bootstrap.sh` ([settings.json](../../../.claude/settings.json) UserPromptSubmit) | turn-start | injects Goal+Invariants digest | YES (auto) | generic; no named per-verdict checklist (the H1 specificity gap, [round-3 §3.5](2026-05-21-recommendation-gate-iterative-round-3.md)) |
| L2 | `deps-hash-check.sh` (UserPromptSubmit) | turn-start | dep drift | YES | unrelated surface |
| L3 | `check-doc-authority.sh` (PostToolUse) | per edit | doc-authority header presence (principle 09) | YES (auto) | header *presence*, not substance; scoped to doc-authority only |
| L4 | **`end-of-turn-reminder.sh` (Stop)** | per turn-end | recap + drift-verdict + recommendation-first **prompt** | YES (auto) | **§3.3 — instruction-only; fires only on long_text\|question; verifies nothing** |
| L5 | `.husky/pre-push` | git push | capability `Prior-art:` trailer, §1.7 trailer, principle-10 annotation | YES (mechanical) | git-event only; silent on PR-body/research-patch *prose* before push |
| L6 | CI `discipline-self-check.yml` | PR | §1.7 Forward/Backward sections + substance arm (≥1 file:line) | YES (CI) | last-resort gate; section *presence* + 1 citation, not full substance |
| L7 | principle tests 01–10 (vitest) | test run | executable invariants | needs `vitest` invocation | not at write-time |
| L8 | `self-reflection` skill ([SKILL.md](../../../.claude/skills/self-reflection/SKILL.md)) | keyword auto-trigger | §1.7 forward/backward on discipline edits | claims auto; **§3.4** | availability ≠ execution (T-AUTO-B) |
| L9 | `agents/compliance-verifier.md`, `review-sidecar.md` | manual sub-agent read | §1.7 substance / anti-tautology | NO (manual dispatch) | requires active session to invoke |
| L10 | `ai-laziness-traps.md`, `phase-research-coverage.md` | prose rules | T-catalogue, 6-item search checklist | NO (read-time) | prose; relies on AI loading + applying |
| L11 | Reviewer sessions (Round-1/2) | manual dispatch | independent falsification | NO (manual) | extra context cost; external |

**Missing layer:** an *automatic in-session trigger that performs (not just prompts) discipline-substance verification before the AI declares «done».** L4 is the closest auto-fire, but see §3.3.

### §3.3 — Precisely what the live Stop hook does / does NOT catch (T13 + domain-trap T-AUTO-E)

[`end-of-turn-reminder.sh`](../../../.claude/hooks/end-of-turn-reminder.sh) (audited line-by-line):

**Does:** fires on `Stop` ([settings.json:Stop](../../../.claude/settings.json)); skips if `stop_hook_active` (anti-loop, line 8); extracts session-goal anchor (lines 21–25); reads last assistant message; triggers ONLY if `text_length > 500` AND markdown-structured (lines 49–53) **OR** the turn ends in a question / AskUserQuestion (lines 56–66); injects a recap+drift-verdict+recommendation-first instruction via `decision:block`+`reason` (lines 141–145 — `reason` reaches the model, verified; `systemMessage` is UI-only).

**Does NOT catch (the gap):**
1. **It is candidate A/E as a *prompt*, not a *verifier*.** It asks the AI to name «одну вещь, в которой меньше всего уверен» (line 92) — the AI *chooses* which one and can pick a safe one. It never re-greps a numeric claim, re-reads a cited `file:line`, or runs the §1.7 6-item checklist. Same voluntary-compliance ceiling as H1 ([round-3 §3.5](2026-05-21-recommendation-gate-iterative-round-3.md)).
2. **Firing condition misses short turns.** A turn under 500 chars with no trailing question does not fire (lines 76–78). Incident #1 («4+ files») in a terse «готово, поправил 4 файла» turn → **NO FIRE**.
3. **No verdict/SSOT/citation/adversarial predicate.** It does not scan for ADOPT/DEFER or evidence markers (that is H2). It cannot catch incidents #2 (negative-existence) or #3 (drive-by scope) structurally — only nudge.
4. **Fires at turn-end, not at the write moment.** A fabricated `file:line` is already written by the time L4 fires; the nudge does not force a re-read.

**T-AUTO-E resolved:** L4 is a *partial* candidate-A/E instantiation (auto-fire + recap prompt). It does **not** close the gap — it closes the «AI never pauses to reflect» sub-problem but not the «AI does not *verify* its claims» sub-problem. Candidate A is **not done**; the open work is *verification*, not *reflection*.

### §3.4 — self-reflection skill: availability ≠ execution (T-AUTO-B)

[SKILL.md](../../../.claude/skills/self-reflection/SKILL.md) auto-triggers on keywords (`правило`/`principle`/`discipline`…). But Claude Code skill auto-trigger matches `description`/`when_to_use` and *surfaces* the skill — it does not *force* the AI to run the forward/backward checks. The skill's own §«How this skill itself complies» is prose the AI may or may not act on. This is the exact gap: the rule is *available in context*, the AI *declares done without applying it*. Incidents #2 and (had a rule-edit been involved) the §1.7 class are not structurally prevented.

## §4 — Candidate mechanisms (A–G) mapped to the H1–H11 catalogue + live artefacts

> Mapping: A=H1/H2 + live L4; B=H3 + self-reflection skill; C=H8 + `agents/*`; D=H5/H10; E=H4/H6/H9 + L4's recap; F=excluded; G=combinations. Catalogue authoritative: [`2026-05-16-§17-think-time-gate.md §4`](2026-05-16-§17-think-time-gate.md).

### §4.1 — Per-candidate verdict

| Cand. | Mechanism | Event | Forces execution? | Build-vs-reuse | Recursive-applicability (T-AUTO-C) | Friction (T-AUTO-D) |
|---|---|---|---|---|---|---|
| **A** | CC hook (UserPromptSubmit=H1 / Stop=H2 / PostToolUse) | turn-start / turn-end / per-edit | H1 no (instruction); H2 **yes** (block on predicate); PostToolUse yes (mechanical) | ADOPT (SSOT #20 hooks); L4 already ships partial | hook config is itself unguarded — who checks the hook fired? mitigated: hook is deterministic, testable by principle test | H1/PostToolUse ~0; H2 retry-loop cost (4× for C3, [round-3 §3.2](2026-05-21-recommendation-gate-iterative-round-3.md)) |
| **B** | skill auto-trigger | keyword | **NO** (availability≠execution §3.4) | reuse (skill exists) | skill can't verify it ran | ~0 but ineffective alone |
| **C** | mandatory sub-agent invocation (`compliance-verifier`) | at «done» | only if invocation forced | reuse (`agents/*` exist); **Agent Verifier precedent §5** | **turtles**: what forces the invoke + verifies the sub-agent ran honestly? | HIGH (context + dispatch per «done») |
| **D** | structured output schema (H10 verdict-as-tool-call / H5 MCP validator) | verdict-formation | **YES** (schema blocks pre-prose) | **BUILD** (no prod analog §5) | MCP server unguarded by itself; **fabrication-bypass** (§5.2 residual #3) | LOW per-turn; HIGH build |
| **E** | pre-completion checklist (H6 re-read / H9 adversarial / L4 recap) | turn-end | only if hook-gated (else voluntary) | reuse (L4 ships); ADAPT | checklist completion is self-reported unless mechanical | MEDIUM (re-grep/re-read per «done») |
| **F** | external paid-LLM reviewer | — | — | **REJECTED** ([no-paid-llm-in-ci.md](../../../.claude/rules/no-paid-llm-in-ci.md)) | — | — |
| **G** | hybrid (A-PostToolUse mechanical + E re-verify + D verdict-gate + L4 recap) | layered | mixed | mixed | layered defence — each catches a different class | additive |

### §4.2 — Concrete 6-incident trace (T2: «would it have caught THIS incident, self-triggered?»)

| Incident | A: live L4 (Stop) | A: H2 (Stop predicate) | A: PostToolUse | D: H10 verdict-gate | E: forced re-verify checklist |
|---|---|---|---|---|---|
| #1 numeric «4+ files» | NO if short turn (§3.3.2); else nudge-only | NO (no verdict keyword, [round-3 §3.3 C7](2026-05-21-recommendation-gate-iterative-round-3.md)) | only if claim is in an edited file + checker greps counts | NO (not a verdict; [round-3 C7 NO-FIRE](2026-05-21-recommendation-gate-iterative-round-3.md)) | **YES** — «re-run the count command, quote output» |
| #2 negative-existence weak | nudge-only | FIRE-partial if verdict-typed (C8) | NO | **FIRE-partial** if verdict carries it (C8) | **YES** — «enumerate the 6-item checklist» |
| #3 drive-by scope add | nudge (drift-verdict line 90) | NO | NO (commit-scope, not edit-content) | NO (C4-class framing, [round-3](2026-05-21-recommendation-gate-iterative-round-3.md)) | partial — «is this in agreed scope?» if checklist asks |
| #4 handoff F1–F6 | nudge-only | NO | NO | NO | partial — «independently verify accepted claims» (C1-class, hard) |
| #5 file:line `:30` | nudge-only | NO | NO | **YES** — «re-open each cited file:line, confirm content» |
| #6 missing annotation | NO (turn-end, not edit) | NO | **YES** — PostToolUse on Write checks first-line regex | NO | **YES** — checklist item |

**Result (matches [round-3 §3.6](2026-05-21-recommendation-gate-iterative-round-3.md) R4):** **no single mechanism covers all six.** The factual class (#1,#5) needs **E** (forced re-verify); the structural class (#6) needs **A-PostToolUse** (mechanical); the verdict class (#2,#3) needs **D/H2**; the social class (#4 accept-handoff) is the hardest — no mechanism fires deterministically (it is the C1 «trust collaborator» cognitive shortcut, [round-3 §3.5 C1](2026-05-21-recommendation-gate-iterative-round-3.md)).

## §5 — Prior art (DeepWiki + WebSearch ≥3 phrasings each; context7 NOT used for existence — per [build-first-reuse-default.md §3](../../../.claude/rules/build-first-reuse-default.md))

**Negative-existence claim under test:** *«No production framework auto-forces discipline-substance self-audit (SSOT / file:line / negative-existence / adversarial) before an AI agent completes a turn, within the operator's own subscription (no paid LLM).»*

6-item search-coverage checklist:

1. **context7** — correctly **excluded** for existence (library-API docs only); appropriate only for the CC hooks *API surface* (SSOT #20).
2. **DeepWiki ≥3:** `anthropics/claude-code` → **no built-in self-audit/verification mechanism**; `{continue:false,stopReason}` documented, `reason`-on-block path used by L4 is undocumented-in-changelog (project verified empirically). `modelcontextprotocol/servers` → **no verification-gate server**; closest = Sequential-Thinking (structured reasoning) + Everything-server elicitation — building blocks, not a gate. `aurite-ai/agent-verifier` → **not DeepWiki-indexed** → **resolved by cloning the repo and reading source directly** (WebFetch of blog vs GitHub README *disagreed*; arbitrated by repo source — §5.1).
3. **WebSearch ≥3:** surfaced **Agent Verifier** (open-source CC skill; §5.1), **AgentSpec** (ICSE'26 — runtime enforcement, intercepts decision pipeline, enforcement via termination/self-reflection — academic, action-level not discipline-substance), **SAVER / «Verify Before You Commit»** (arxiv 2604.08401 — verification over belief-states before commitment), **SmartSnap** (proactive in-situ self-verification), **Reflexion** (self-reflection as next-episode context — L4's pattern), **Tool Receipts** (arxiv 2603.10060, «Tool Receipts, Not Zero-Knowledge Proofs», NabaOS — HMAC-signed per-tool-call receipts the LLM cannot forge; title + claim verified from arxiv abstract, not snippet — §5.2).
4. **SSOT consult:** #20 hooks ADOPT; #9 Cline Memory-Bank ADOPT VOCABULARY; #49 Karpathy skills DEFER (Goal-Driven verification is the *prose* layer, not a tool — `#pattern-matching-on-name`); #50 AIF skill-context ADOPT; #38 CodeRabbit DEFER (SaaS/paid).
5. **Internal precedent:** L4 (auto Stop, instruction-only), self-reflection skill (manual keyword), `agents/*` (manual sub-agents).
6. **Adversarial:** «what would make 'no auto-forcing prod analog' wrong?» → if Agent Verifier or AgentSpec shipped a *customizable, auto-firing, discipline-substance* check. **Neither does** (§5.1).

### §5.1 — Agent Verifier (`github.com/aurite-ai/agent-verifier`) — closest analog, T16 problem-class check

> **Source-grounded** (repo cloned + read 2026-05-21 — blog and README disagreed; arbitrated by source). Three corrections to a first-pass reading are folded in below (T13 in action — the «adopted-tool» was *not* zero-work to characterise).

| Dimension | Agent Verifier (source-confirmed) | Our problem-class | Match? |
|---|---|---|---|
| Delivery | CC **skill executed by the AI session** — explicitly «runs as an AI agent skill rather than a deterministic parser» ([README:576]); two tiers `[P]` mechanical + `[H]` heuristic; no external API, «code never leaves your machine» ([README:609]) | AI-agnostic skill/sub-agent on own subscription | **STRONG** — matches the project's own sub-agent pattern + no-paid-LLM scope |
| Trigger | **manual** (`verify agent`) — no auto-fire, no Stop-hook, no block | we need **auto-fire before «done»** | **NONE** — Agent Verifier *has our exact gap* (needs an external trigger) |
| Object verified | the project's **source code** (`config.py:12` etc. — retry limits, secrets, tool-registry, `any` types) | the AI's **own output claims** (counts, file:line citations, negative-existence) in prose/PR-body/research-patch | **NONE** — different object: artifact-code vs claims-about-work |
| Extensibility | **YES — via Kahuna MCP** ([getting-started:48]): `.kahuna/context-guide.md` custom project/org rules «automatically loaded during verification» | project-specific discipline checks | **PARTIAL** — extensible, but to *code* checks; would still not see prose claims |

**T16 verdict (corrected):** the skill-execution + Kahuna-extensible-rules pattern is a **REFERENCE / ADAPT** precedent, stronger than a first reading credited — it validates candidate **C** (AI-agnostic verifier skill with injectable project rules; direct parallel to AIF skill-context SSOT #50). But two axes do **not** transfer: (1) **trigger** stays manual — the auto-fire-before-done is unsolved upstream; (2) **object** is committed code, not the AI's reasoning output. The BUILD/ADAPT residue is therefore sharpened: *auto-fire a session-executed verifier at the AI's own claims*. Name «verifier» matched; problem-class matched on delivery, missed on trigger + object.

### §5.2 — Build-vs-reuse verdicts (per candidate)

- **A (hooks):** **ADOPT** — SSOT #20; L4/L1/L3 already ship the substrate.
- **B (skill):** reuse, but **insufficient alone** (§3.4).
- **C (sub-agent):** **REFERENCE / ADAPT** — Agent Verifier (session-executed skill) + Kahuna MCP (`.kahuna/context-guide.md` injectable project rules) is a production precedent for «verifier skill with project-specific rules», parallel to AIF skill-context (SSOT #50); `agents/*` reuse. The ADAPT delta: auto-fire it (Stop hook) + point it at the AI's *claims* not source code. Trigger-forcing unsolved upstream.
- **D (H10 verdict-as-tool-call):** **BUILD** — DeepWiki MCP sweep + WebSearch confirm no production verdict-gate server. Matches [round-5 R2c BUILD](2026-05-21-recommendation-gate-iterative-round-5.md).
- **E (checklist re-verify):** **ADAPT** — L4 recap + H6/H9; the *forcing* (hook-gate the Stop event on checklist completion) is the delta.
- **F:** **REJECTED** (policy).

## §6 — Constraint matrix (candidate × project constraint)

| Cand. | no-paid-LLM | recursive-self-application | AI-agnostic | build-vs-reuse | search-coverage | Verdict |
|---|---|---|---|---|---|---|
| A | ✅ deterministic | ✅ principle-test-able | ⚠️ CC-hook (portable fallback = `agents/*` per [dual-implementation-discipline.md](../../../.claude/rules/dual-implementation-discipline.md)) | ✅ ADOPT #20 | ✅ | **viable** |
| B | ✅ | ✅ | ✅ skill content portable | ✅ reuse | ✅ | viable-but-weak |
| C | ✅ (deterministic sub-agent) | ✅ | ✅ markdown prompt (AI-agnostic by design) | ✅ REFERENCE | ✅ | viable, turtles-risk |
| D (H10) | ✅ (schema validation, no LLM) | ✅ | ⚠️ MCP = CC/MCP-host only; portable fallback weaker | ✅ BUILD justified | ✅ | **target (D6=c)** |
| E | ✅ | ✅ | ✅ | ✅ ADAPT | ✅ | viable interim |
| F | ❌ **violates** | — | ❌ | — | — | **REJECTED** |

No candidate except F violates a hard constraint. The live binding constraint is **AI-agnostic delivery** (D's MCP surface is CC/MCP-host-bound — needs a portable fallback per dual-implementation-discipline) and **forcing execution** (B/C/E are voluntary unless hook-gated).

## §7 — Adversarial counter-prompts

- **T7 «mechanism X looks correct» → what does it NOT catch?** Per §4.2: every single mechanism misses ≥2 of the 6 incidents. The honest headline is *combination*, not any single winner.
- **T-AUTO-A «hooks fire on git ops» →** false for this project: L1/L3/L4 fire on UserPromptSubmit/PostToolUse/Stop — *non-git* moments. But **research-patch prose** (this very file) is written across many edits; only PostToolUse-on-Write (mechanical first-line checks) and Stop (recap) fire — neither verifies prose *substance*. The substance gap is real and un-hooked.
- **T-AUTO-B «skill auto-trigger catches» →** §3.4: skill *surfaces*, never *forces*. The 2026-05-13 session had the bootstrap digest in context (L1) and still issued the weak negative-existence claim. Availability was present; execution was not.
- **T-AUTO-C «catcher of the catcher» →** D (H10) is a tool whose call the AI can fill with fabricated `evidence[]` (§5.2 residual #3). A: a hook can silently fail / be disabled — mitigated only because hooks are deterministic and **principle-testable** (recursive: a principle test asserts the hook fires). The turtle stops at *deterministic + testable*, not at *another LLM*.
- **T-AUTO-D friction →** H1/PostToolUse ≈ 0; L4 ≈ one recap/turn; E ≈ re-grep/re-read per «done» (seconds); H2 ≈ retry-loop (4× for C3); C ≈ full sub-agent dispatch (highest). Friction must be justified by the class it uniquely covers.
- **Per-candidate concrete:** see §4.2 table — each cell is FIRE/NO/partial against a documented incident, not «would handle».

## §8 — §1.7 self-application (T15 — run the 6 inventory items against THIS patch)

This patch is itself an AI artefact making counts, citations, and a negative-existence claim. Running its own subject against it:

1. **Numeric claims:** «11 trigger layers» — enumerated L1–L11 in §3 (not asserted, listed). «6 incidents» — enumerated §1 table. «4 residuals» — §9. ✅ each backed by an enumeration, not a memory carry-forward (counter to incident #1).
2. **file:line citations:** every cited artefact carries a path; line-anchored where line-specific (`end-of-turn-reminder.sh` lines 8/21–25/49–66/90/141–145 — re-read during §3.3, not paraphrased; `.husky/pre-push:317`; `10-research-patch-annotation.test.ts:23` regex). ✅ (counter to incident #5).
3. **Negative-existence claim:** §5 — ran the full 6-item checklist (DeepWiki ≥2 repos, WebSearch ≥3, SSOT, internal precedent, adversarial). ✅ (counter to incident #2). **Residual — now resolved:** `aurite-ai/agent-verifier` was not DeepWiki-indexed and WebFetch of the blog vs the GitHub README **disagreed** (blog: «blocking»/«reads transcript»; README: «manual»/«reads source»). Rather than trust either summary, I **cloned the repo and read source** (§5.1) — which corrected *three* of my own first-pass claims: it is an AI-skill-executed verifier (not a «deterministic parser, no LLM»), it reads source code (not transcript), and it **is** extensible (Kahuna MCP — I had wrongly written «no custom-rule API»). This is T13 confirmed live: the «adopted tool» was not zero-work to characterise; paraphrase from a blog would have shipped three errors.
4. **Drive-by scope:** this patch edits **only** its own file under `research-patches/` — no source/rule/settings edits (T5; counter to incident #3). Candidates are *enumerated for decision*, none adopted.
5. **Annotation:** first line `<!-- scope:autonomous-self-audit -->` — matches `10-research-patch-annotation.test.ts:23` regex `/^<!-- scope:[a-zA-Z0-9.§-]+ -->$/`. ✅ (counter to incident #6).
6. **Adversarial on the patch's own recommendation (§10):** «What would make §10's *combination* recommendation wrong: if a live test shows the at-write-time factual class (#1,#5) is in practice already covered by L4's recap nudge often enough that the added E-checklist friction isn't worth it — Q1 is empirically unanswered (§9 Q-C).»

**Recursive finding (honest):** this patch *did* run all six against itself and surfaced one real residual (item 3 source-discrepancy) — i.e. the methodology caught a gap in its own evidence base. That is the intended behaviour and a small confirmation that a forced 6-item pass has value. It does **not** prove the AI would have self-run it absent this kickoff's explicit instruction — which is precisely the gap (§9 Q-A).

## §9 — Resolution of the 4 inherited Round-4 residuals

> Per [round-5 §5.6](2026-05-21-recommendation-gate-iterative-round-5.md): carried into this session as open inputs under fixed D6=(c).

**Residual 1 — adversarial-falsification sentences for R2a/R2b/R2c.** Resolved: the three sentences (verbatim [round-4 §4.4](2026-05-21-recommendation-gate-iterative-round-4.md)) are folded into §5.2 verdicts here and remain in round-4 §4.4 as the discovery record. **Recommendation (not decision):** accept the fold; do **not** retroactively amend the committed main §2 (append-only patch discipline — round-5 §5.2.4 option «accept gap as-documented»). → still maintainer's call (§10 Q-B).

**Residual 2 — does shortlist/meta-decision count as a «recommendation» the H10 schema gates?** **Finding:** scoping H10 to gate intermediate research-synthesis selections would (a) inflate `verdict_type` enum, (b) re-introduce the H2 67%-FP meta-discourse problem at schema level (a research patch *discussing* candidates is not *issuing* verdicts — [round-4 §4.1](2026-05-21-recommendation-gate-iterative-round-4.md)). **Recommendation:** scope H10 to **final** ADOPT/DEFER/BUILD/REJECT/RECOMMEND/RULE_CHANGE verdicts only; shortlist/synthesis prose is exempt. This is the «simpler H10» path (round-5 §5.2.2). → maintainer confirms at build time.

**Residual 3 — H10 fabrication-bypass (schema enforces structure, not truthfulness).** **This is the load-bearing finding.** Prior art gives the answer: **Tool Receipts** (arxiv 2603.10060) and self-verification asymmetry (verification cheaper than generation) → the fix for fabricated `evidence[]` is a **deterministic secondary pass that re-executes the citation**: a PostToolUse/post-`issue_verdict` hook greps each `citation` (`file:line`) and confirms `citation_content` actually appears there. This is candidate **A-PostToolUse + D composed** — H10 enforces *structure*, an A-hook enforces *truthfulness of the citation*. The project already noted this ([round-3 §3.0 H10 note](2026-05-21-recommendation-gate-iterative-round-3.md): «a secondary verification pass (H2-class grep on cited file:line) would be needed»). **Recommendation:** H10 MUST ship with a paired deterministic citation-checker (no LLM), else its 0% FP is bought with an open fabrication hole. → §10 Q-A (this changes H10 from «one tool» to «tool + checker pair»).

**Residual 4 — «no single mechanism covers both failure classes» → combinations.** Confirmed independently here (§4.2 trace): no single mechanism catches all 6 incidents. Minimal covering combination from the trace: **{A-PostToolUse (structural #6 + citation-truthfulness for #5/residual-3) + E forced re-verify checklist (factual #1,#5) + D/H10 (verdict class #2,#3)}**. The social-trust class (#4) remains uncovered by any deterministic mechanism (out-of-scope per kickoff Q4 — needs human/reviewer). L4 (Stop recap) is the cheap always-on backstop, not a class-coverer.

## §10 — Recommended next-action + decision-needed (reviewer-discipline: options, no pick)

> Per [reviewer-discipline.md §1–§2](../../../.claude/rules/reviewer-discipline.md): each names options + consequences + «→ maintainer decides». This file issues **no** strategy pick and **no** PR/codify.

**Recommended trajectory (a recommendation, not a decision — maintainer owns it):** sequence **research-shaped, then build**, per kickoff §0.5 lines 30–32. H10 (D6=c target) ships **on top of Wave-10 TS-core** as a **pair**: `issue_verdict` schema gate **+** a deterministic citation-truthfulness checker (residual 3). Ship the cheap interim now only if earlier coverage is needed: **E (forced re-verify checklist hook-gated on Stop)** is the lowest-build, highest-coverage interim for the factual class (#1,#5) and reuses L4's existing Stop infrastructure — strictly more than H2's keyword scan for the factual class, without H2's 67% meta-discourse FP.

**DECISION-NEEDED items:**

- **Q-A — which to prototype first (under Wave-10), and as what shape?** Option (i): H10-pair (verdict-gate + citation-checker) only, accept no factual-class coverage until then. Option (ii): ship E-checklist Stop-gate now as factual-class interim, H10-pair later. Option (iii): full combination {A-PostToolUse + E + H10-pair} as one Wave-10 umbrella. → **maintainer / `/orchestrator` decides.** Consequence: (i) narrowest, fastest to the target; (ii) earliest factual coverage, two workstreams; (iii) widest, largest umbrella.
- **Q-B — residual-1 retroactive amendment of main §2?** Option «accept gap as-documented» (recommended, append-only) vs «amend §2». → maintainer decides.
- **Q-C — acceptable friction?** E-checklist adds seconds (re-grep/re-read) per «done»; H2 adds retry-loops. Is the factual-class coverage worth per-turn friction, or is L4's nudge «good enough» until a live incident recurs? Q1 (does any of this change live behaviour vs voluntary compliance) is **empirically unanswered** — paper analysis cannot resolve it. → maintainer decides whether to fund a live A/B.
- **Q-D — catcher-of-the-catcher degradation?** For D: pair with deterministic citation-checker (residual 3). For A-hooks: add a **principle test** asserting each discipline hook fires on a known-bad fixture (recursive self-application — the hook that catches drift is itself caught by a test if it silently breaks). → maintainer decides whether the principle-test backstop is in-scope for the build.

**Out of scope (per kickoff Q5):** no mechanism implemented; no rule codified; no settings.json/hook/principle edits; no PR; no Sonnet dispatch. Social-trust class (#4) and architectural-judgment errors remain human/reviewer concerns by design.

## §10.5 — Maintainer decisions (recorded 2026-05-21)

> Per [reviewer-discipline.md §2 step 3](../../../.claude/rules/reviewer-discipline.md): the §10 surface is options-only; this section records the **maintainer's** (Art) explicit answers — the legitimate closure of a decision-needed surface. **Still no implementation** in this session (kickoff Q5 unchanged); these decisions shape the follow-up build session.

| Item | Maintainer decision | Note |
|---|---|---|
| **Q-A — prototype-first shape** | **Accepted Option (ii):** ship **E-checklist Stop-gate** as the factual-class interim now; **H10-pair** (verdict-gate + citation-checker) later on Wave-10 TS-core. | «Иди по рекомендации» (2026-05-21). Reuses L4's existing Stop infra; earliest coverage of the most-frequent class (#1,#5); strictly > H2 on factual class without H2's 67% meta-discourse FP. |
| **Q-B — retro-amend main §2** | **Accepted recommendation:** accept gap as-documented (append-only); do **not** rewrite committed §2. | — |
| **Q-D — catcher-of-the-catcher** | **Accepted recommendation:** H10 ships paired with a deterministic citation-checker (residual 3); discipline hooks get a principle test asserting fire-on-known-bad-fixture. | Recursive self-application: the hook that catches drift is itself caught by a test if it silently breaks. |
| **Q-C — friction / live A/B** | **Inferred from «иди по рекомендации» — flagged for explicit confirmation:** proceed with the interim E-checklist; defer a funded live A/B until a factual-class incident recurs (L4 nudge is the standing backstop until then). | This one I *inferred*; the others were direct. If you want a live A/B funded up front, say so. |

## §11 — Design-readiness for the accepted path (Option ii) — «how best to do it» (paper sketch, NOT implementation)

> Per maintainer «заресёрч как лучше сделать». Design sketch only — no `settings.json`/hook/principle edits in this session (kickoff Q5). Consistent with how the recommendation-gate rounds shipped paper prototypes (H1 text / H2 bash / H10 schema) inside research patches.

**Framing (ADAPT of §5.1 Agent Verifier):** «session-executed verifier skill with injectable rules» (Agent Verifier + Kahuna) — but **auto-fired** via the Stop event and pointed at the **AI's own claims**, not source code. That single sentence is the whole design: it borrows the validated half (skill-executed checks, no paid API) and supplies the two missing axes (auto-trigger + claims-object).

### §11.1 — Interim now: E-checklist Stop-gate (extends live L4)

- **Vehicle:** extend `end-of-turn-reminder.sh` (already fires on Stop, reads transcript, blocks via `reason`). No new hook surface → lowest build, no new principle-09/dual-channel obligation beyond the existing file.
- **Mechanical salience upgrade (the delta over L4's generic nudge):** before composing the `reason`, deterministically scan `last_assistant_message` for the factual-class shapes and **enumerate the specific hits back to the AI** (Agent Verifier's `[P]` tier idea — name the exact finding, don't say «be careful»):
  - numeric-count claims near file/dir nouns (`[0-9]+\+? *(files?|tests?|cases?|entries|rules?)`),
  - `file:line` citations (`[\w./-]+\.\w+:[0-9]+`),
  - negative-existence shapes (`no (production|existing) .* (exists|found|analog)`).
- **Injected instruction (forced re-verify, per enumerated hit):** «For EACH item below, re-run the count command and quote output / re-open the file:line and quote the line / state which of the 6 search-coverage items you ran — before you finish: [enumerated hits].» Voluntary-compliance ceiling remains (T-AUTO-B) — but salience is now item-specific at the exact moment, strictly more than the generic «least-confident thing» nudge.
- **Recursive backstop (Q-D):** a principle test feeds a known-bad fixture transcript (a turn asserting «4+ files» with no re-verify) and asserts the scan enumerates it. If the hook silently breaks, the test fails.
- **Honest limit:** this is salience-raising, not structural forcing. It targets the factual class (#1,#5) and the negative-existence class (#2); it does NOT force (the AI can still ignore). Q1 (does it change live behaviour) stays empirically open until observed — which is exactly why it ships as cheap interim, not as the target.

### §11.2 — Target later (Wave-10 TS-core): H10-pair

- **Part A — `issue_verdict(...)` schema gate** (BUILD; [round-3 §3.0 H10 schema](2026-05-21-recommendation-gate-iterative-round-3.md)): scoped to **final** verdicts only (residual-2 resolution — shortlist/synthesis exempt). Enforces `ssot_id` / `evidence[]` / `adversarial_falsification` / `external_search_summary` *before* verdict prose exists. 0% FP ([round-3 §3.7](2026-05-21-recommendation-gate-iterative-round-3.md)).
- **Part B — deterministic citation-checker** (residual-3 / Tool-Receipts pattern, arxiv 2603.10060): a post-`issue_verdict` deterministic pass greps each `evidence[].citation` (`file:line`) and confirms `citation_content` actually appears there. No LLM. **This pairing is non-optional** — without it, H10's 0% FP is bought with an open fabrication hole (schema enforces structure, not truthfulness).
- **Sequencing:** Part A+B sit on Wave-10's TS-core hook foundation as their own atomic capability commit (build-vs-reuse gate + `Prior-art:` trailer). NOT folded into the Wave-10 migration umbrella (atomic-umbrella discipline) — they are a new capability on top of it.

## Tags

`#no-self-trigger` `#availability-not-execution` `#pattern-matching-on-name` `#fabrication-bypass` `#no-single-mechanism` `#catcher-of-the-catcher` `#recursive-self-application-gap`

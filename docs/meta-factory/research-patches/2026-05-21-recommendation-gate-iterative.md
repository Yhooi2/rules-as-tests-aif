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

<!-- scope:no-human-verification-self-verify-thesis -->
# DN-4 #21 — "human verifies nothing; AI self-verifies everything" (recursive-thesis convention)

> **Scope:** proposal-of-record codifying DN-4 gap #21 (`no_human_verification_ai_self_verifies`) — the maintainer-stance convention and its failure mode. Names the principle, connects it to the operational instances already in the repo, and **surfaces** (does not decide) whether to widen [§13.34](../open-questions.md) or elevate it to a CLAUDE.md/README invariant. Inherits folder authority from [research-patches/README.md](README.md); **NOT authoritative for** project goal (see [README.md#why-this-exists](../../../README.md#why-this-exists)) nor for the README/CLAUDE invariant set (maintainer-owned per [CLAUDE.md `Artifact Ownership Contract`](../../../CLAUDE.md)).
>
> **Origin:** maintainer dialogue 2026-05-21 (memory `feedback_no_human_verification_ai_self_verifies`): «0% reliance on human checking; AI self-verifies + re-verifies + re-tests, including its own merges and epics; the human only DECIDES where there is no clear unambiguous best; AI reports in plain language — what / why / checked / gaps». Flagged stage-0 in the [memory-coverage audit §4](2026-05-22-memory-coverage-audit.md). Codified here per the maintainer's explicit instruction «codify via research-patch, don't autopilot» — this gap is **not** a quick rule-fold (the other 10 DN-4 gaps were); it is the project thesis applied one layer up, and touches invariant-owned surfaces.

## §1 The convention

| Axis | Stance |
|---|---|
| **Human verification of AI output** | **None.** The maintainer is not a backstop that re-checks the AI's diffs, counts, or claims. 0% reliance. |
| **AI verification of its own output** | **Total.** The AI self-verifies, re-verifies, and re-tests every claim, merge, and epic-integration — at write time, before declaring done, without an external trigger. |
| **Human role** | **Decision, not verification.** The human is consulted only where there is no clear unambiguous best on the merits (a genuine strategy fork — cf. [reviewer-discipline.md §2](../../../.claude/rules/reviewer-discipline.md)). |
| **AI report** | **Plain language:** what was done / why / what was checked (with evidence) / what gaps remain. Not a green-checkmark theatre. |

## §2 Why it is "one layer up" from the project thesis

The project thesis ([README.md#why-this-exists](../../../README.md#why-this-exists)): *AI agents can't silently bypass undocumented conventions — every rule is an executable artifact that fails at the earliest reachable channel, so a human need not manually police compliance.* The verification of **user-code conventions** is automated.

#21 is that thesis applied to the **human↔AI verification boundary itself**: the human does not manually police the **AI's own work** either — the AI's output is self-verified through the same executable-artifact discipline (tests, hooks, cold-review, file:line evidence). It is recursive: the verification-automation the project builds for user code is turned on the agent's own output. This is the same framing [§13.34](../open-questions.md) reaches («the recursive form of the project thesis itself … extended one layer up»; [open-questions.md:405](../open-questions.md)).

## §3 The load-bearing failure mode — mutual-deferral deadlock

The reason #21 must be **explicit** and not assumed:

> **AI assumes the human will catch it at review/merge. The human assumes the AI self-verified. Neither does → unverified work ships.**

§13.34's diagnosis is «AI session = agent-doer, not agent-self-trigger-er; every catch required an external trigger» ([open-questions.md:403-405](../open-questions.md)). #21 **removes the implicit human safety-net** that diagnosis silently leaned on. Once the human is declared *not* a backstop, the absence of an autonomous self-trigger (§13.34's open problem) is no longer a latent inefficiency — it is an active hole through which unverified work reaches `main`. **#21 is the premise that makes §13.34 load-bearing rather than nice-to-have.**

## §4 Operational instances already in the repo (this is not un-enforced)

#21 is "hard to mechanize as a single gate" because it is the **union** of every write-time verification channel plus a stance. Those channels exist:

- **Verify-before-claim** — [phase-research-coverage.md §1.11](../../../.claude/rules/phase-research-coverage.md) (line 73): verify state/claims against git/GitHub/source-of-truth before asserting or shipping (the write-time self-verification §13.34 wants).
- **Own cold-QA before handoff** — [ai-laziness-traps.md T19](../../../.claude/rules/ai-laziness-traps.md) (line 140): run your own adversarial cold-review before handoff; CI ≠ design review; «merge is the maintainer's, QA is yours».
- **Lead with a reasoned pick** — [phase-research-coverage.md §1.12](../../../.claude/rules/phase-research-coverage.md) (line 86): the human decides only genuine forks; everything else the AI resolves and reports.
- **Existing gates** — principle tests, the §1.7 PR-body substance gate ([discipline-self-check.yml](../../../.github/workflows/discipline-self-check.yml)), pre-push hooks. These mechanically self-verify a slice.

#21 names the **meta-principle** these instances serve, and the deadlock they collectively guard against.

## §5 Proposal — surfaced, not decided (maintainer call)

This patch is the codification the tracker asked for (DN-4 #21 → research-patch). The remaining choice **touches invariant-owned surfaces** and is therefore a maintainer decision per [CLAUDE.md `Artifact Ownership Contract`](../../../CLAUDE.md) — **DECISION-NEEDED:**

- **Option A — widen [§13.34](../open-questions.md)**: add the «human is not a verification backstop» premise + the mutual-deferral-deadlock failure mode to §13.34's problem statement, so the autonomous-self-audit research is scoped against the real (no-human-backstop) threat model. Consequence: keeps it as research-tracked; no new always-on cost. *(open-questions.md is near its 500-line cap — may need an archive-first.)*
- **Option B — elevate to a CLAUDE.md/README invariant**: state the stance as a project invariant («the human verifies nothing; the AI self-verifies everything»). Consequence: strongest signal, but README §Why-this-exists / CLAUDE invariants are maintainer-owned — a deliberate invariant edit, not an operational side-effect.
- **Option C — leave as this proposal-of-record** + the §4 operational instances; promote on a documented mutual-deferral-deadlock incident. Consequence: matches violation-rate promotion discipline; lowest ceremony.

Reviewer/agent **cannot pick** between these (project-strategy + invariant ownership) — surfaced per [reviewer-discipline.md §2](../../../.claude/rules/reviewer-discipline.md).

## §6 §1.7 self-review (T7 walk) — T15 self-application is CENTRAL here

This patch is *about* self-verification, so T15 («self-application skipped») is the load-bearing trap: a patch on «AI self-verifies» that did not itself self-verify would be self-refuting.

### §1.7 Forward-check applied
Complies with active disciplines: no-paid-LLM (prose, zero LLM calls — [no-paid-llm-in-ci.md](../../../.claude/rules/no-paid-llm-in-ci.md)); doc-authority (this patch inherits folder authority, and **defers** invariant edits to the maintainer per `CLAUDE.md` Artifact Ownership Contract — it does not touch [README.md#why-this-exists](../../../README.md) or CLAUDE invariants itself); channel-selection (no new always-on rule file — it is a research-patch, the correct channel for a thesis-level proposal-of-record, per [rule-enforcement-channel-selection.md §3](../../../.claude/rules/rule-enforcement-channel-selection.md)); memory-codification §3 (the codify step for stage-0 entry #21, with the memory pointer-reduction left to the auditor agent). Evidence of operational backing: [phase-research-coverage.md:73](../../../.claude/rules/phase-research-coverage.md) (§1.11) and [ai-laziness-traps.md:140](../../../.claude/rules/ai-laziness-traps.md) (T19). Not a capability commit → escape-hatch trailer.

### §1.7 Backward-check applied
Touches/relates to existing artefacts without contradiction: it **extends** [open-questions.md:401](../open-questions.md) §13.34 (supplies the no-human-backstop premise §13.34 left implicit at [open-questions.md:405](../open-questions.md)) rather than duplicating it; it names the meta-principle behind the already-merged [phase-research-coverage.md:73](../../../.claude/rules/phase-research-coverage.md) §1.11 and [ai-laziness-traps.md:140](../../../.claude/rules/ai-laziness-traps.md) T19 (DN-4 rounds 1-2) rather than re-codifying them; it does not edit the maintainer-owned [CLAUDE.md](../../../CLAUDE.md) invariant set (Option B surfaced, not taken). The DN-4 tracker row #21 in [memory-codification-gap-tracker.md:27](../memory-codification-gap-tracker.md) flips to CODIFIED → this patch.

### Did this patch self-apply (T15)?
Yes — and it is the proof-of-concept for #21. This session's DN-4 work (PRs #159/#161/#162) was self-verified by the AI before handoff, not by the human: each rule-bearing PR ran its own 1× Opus cold-review (T19), each state-claim was re-verified against `origin/staging` (§1.11 caught two behind-branch reverse-diffs), and the human was asked only the one genuine fork («batch-all vs incremental»). #21 was therefore *practised before it was codified* — the recursive self-application invariant ([ai-laziness-traps.md T15](../../../.claude/rules/ai-laziness-traps.md)) holds. **Sharper proof:** this very patch's own T19 cold-review caught a BLOCKER — 7 broken `../meta-factory/…` relative links (the patch is already inside `docs/meta-factory/`, so `..` overshot) — fixed before handoff. The AI self-verification (not the human) caught the miss; that is #21 working on #21's own artefact.

## §7 See also
- [open-questions.md §13.34](../open-questions.md) — autonomous self-audit triggering layer (the mechanism-research this stance scopes).
- [memory-codification-gap-tracker.md](../memory-codification-gap-tracker.md) — DN-4 tracker (row #21).
- [phase-research-coverage.md §1.11/§1.12](../../../.claude/rules/phase-research-coverage.md), [ai-laziness-traps.md T19](../../../.claude/rules/ai-laziness-traps.md) — operational instances (DN-4 rounds 1-2).
- memory `project_autonomous_self_audit_triggering_evidence` — the §13.34 incident counter where mutual-deferral-deadlock instances should be logged.

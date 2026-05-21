<!-- scope:n2-adopt-from-superpowers -->
# Research-patch — N2 adopt-from-companion R-phase (vocabulary/SSOT alignment under DECISION=C)

> **Inherits authority from** [research-patches/README.md](README.md) folder-level Authoritative-for header. Scope-bound to: Wave **N2** of [2026-05-21-niche-strategy-and-growth-roadmap.md §4](2026-05-21-niche-strategy-and-growth-roadmap.md) — the per-item adopt/reference/adapt verdicts for Superpowers agent-methodology, evaluated under the maintainer's **DECISION=C** (companion = both, on separate layers). **NOT authoritative for** project goal (see [README.md#why-this-exists](../../../README.md#why-this-exists)); not authoritative for the rule-file edits or SSOT rows it *proposes* — those are maintainer-owned (`.claude/rules/*` per [CLAUDE.md Artifact Ownership Contract](../../../CLAUDE.md)) and surfaced for application, not applied here.
> **Date:** 2026-05-21 · **Author session:** Opus 4.7, N2 research. No rule edited, no SSOT row written, no dependency added. Research deliverable only.

---

## §1 — Goal + decision context

N2 (roadmap §4): stop reinventing agent-methodology — adopt/reference where Superpowers (`obra/superpowers`) is mature; codify the vocabulary mapping.

**DECISION=C is now set** (maintainer, 2026-05-21): «companion» = both on separate layers — substrate stays **dependency-free / never coupled** (axis A); process/dev-workflow layer **dogfoods** companions (axis B). N2 and N7 split accordingly:

- **N2 (this patch) = vocabulary + idea alignment.** ADOPT-VOCABULARY / ADAPT / REFERENCE only — *no Superpowers dependency, no runtime coupling*. **Substrate-pure by construction.**
- **N7 (#103) = actual dogfooding** — using Superpowers' skills *in our own dev* (the only part that introduces a real dependency, confined to the process layer per C).

This is why N2 is safe to run now regardless of layer: nothing here couples anything. The dep-bearing work is entirely N7's.

## §2 — Method + inputs (no new probes required)

The adopt verdicts rest on **already-verified** Superpowers facts — 3 DeepWiki probes in N1 ([2026-05-21-n1-niche-validation.md](2026-05-21-n1-niche-validation.md)) + the per-feature matrix in [companion-target-comparison.md §3.1/§4.2](2026-05-16-companion-target-comparison.md) + the ADAPT-candidate tracking already on main ([open-questions.md §13.35/§13.36/§13.37](../open-questions.md)). N2 makes **no new negative-existence claim**, so the [phase-research-coverage.md §1](../../../.claude/rules/phase-research-coverage.md) heavy-probe checklist is not re-triggered; the load-bearing discipline here is **T16 problem-class match per item** ([ai-laziness-traps.md §2](../../../.claude/rules/ai-laziness-traps.md)).

## §3 — Per-item verdict (T16 problem-class match)

| # | Our artifact | Superpowers analog | Their problem class | Our problem class | Match? | Verdict |
|---|---|---|---|---|---|---|
| 1 | orchestrator Mode A/B (`~/.claude/skills/orchestrator/SKILL.md`) | `subagent-driven-development` skill | coordinator delegates to fresh isolated-context subagents + two-stage review | identical lifecycle (orchestrator + workers + evidence-accept) | **YES** | **ADOPT-VOCABULARY** — rename internal «Mode A/B» to «subagent-driven-development»; more precise, reduces cross-project drift. No dep. |
| 2 | `parallel-subwave-isolation.md` (Class C) | `using-git-worktrees` skill | manage isolated workspaces per parallel subagent | git-worktree-per-parallel-session to avoid `.git/index` race | **YES** | **REFERENCE** — cite as multi-source precedent alongside aif-handoff; **drop the §4 Class-C→principle-test promotion ambition** (the mechanical-detection build is now redundant against a mature upstream). No dep. |
| 3 | `agents/*.md` AI-agnostic prompts | SP sub-agent prompt files (`implementer-prompt.md` etc.) | markdown prompt files for subagent roles | same shape | **YES (shape)** | **REFERENCE + KEEP-NARROW** — keep ours (consumer-facing, AI-agnostic); cite as parallel evolution. No dep. |
| 4 | trigger-keyword discipline in `.claude/skills/*/SKILL.md` frontmatter | «1% Rule» ([§13.35](../open-questions.md)) | mandate skill invocation on even slight applicability | when does a skill auto-activate (when_to_use field) | **PARTIAL** — their problem = under-invocation; ours = trigger precision/overlap | **ADAPT-candidate** — adopt the *idea* (bias toward invoke), not verbatim. Decision-needed §8. No dep. |
| 5 | `packages/core/principles/02-paired-negative-test.test.ts` | TDD-for-Skills «NO SKILL WITHOUT A FAILING TEST» ([§13.36](../open-questions.md)) | RED-GREEN-REFACTOR applied to skill authoring | paired-negative enforcement on rule artifacts | **YES (idea)** — extending OUR own principle to cover `SKILL.md` is *idea-adoption*, **not** vendor coupling → still substrate-pure | **ADAPT-candidate** — extend principle 02 scope to skill files. Decision-needed §8. No dep. |
| 6 | principle-test adversarial probes | «Pressure scenarios» ([§13.37](../open-questions.md)) | run skill against pressure/time scenarios to elicit wrong behavior | adversarial probes in principle tests | **YES (idea)** | **ADAPT-candidate** — fold pressure-scenario shape into principle adversarial probes. Decision-needed §8. No dep. |
| 7 | swarm-readiness | SP subagent dispatch (partial) | — | — | partial | **No change** — remains DEFER (per companion-comparison §3.1); see [[project-swarm-execution-approach]]. |

## §4 — C-split classification

| Layer | Items | Treatment under C |
|---|---|---|
| **Process / dev-workflow** | 1 (Mode A/B vocab), 2 (worktrees), 3 (subagent prompts) | eligible for ADOPT-VOCABULARY / REFERENCE now; **actual dogfooding = N7** |
| **Substrate (enforcement)** | 5 (paired-negative→SKILL.md), 6 (pressure→principle probes) | ADAPT *the idea* into OUR OWN principles — **never a Superpowers dep** (substrate axis = A) |
| **Cross** | 4 (1% Rule → trigger discipline) | idea-adoption into our SKILL.md frontmatter convention; no dep |

**Verification of substrate purity (the C invariant):** every item above is ADOPT-VOCABULARY / ADAPT-idea / REFERENCE. **Zero add a Superpowers dependency.** The C guard — `grep` of companion deps in `package.json` stays empty — holds trivially for all of N2. (The guard does real work only in N7.)

## §5 — Proposed codification (maintainer-owned; surfaced, not applied)

Per [Artifact Ownership Contract](../../../CLAUDE.md), `.claude/rules/*` and SSOT rows are maintainer/capability-author surfaces. N2 proposes; it does not edit them here (mirrors N1's posture).

1. **SSOT rows** (`prior-art-evaluations.md`, append-only): one ADOPT-VOCABULARY row for `obra/superpowers subagent-driven-development` (item 1); one REFERENCE row for `using-git-worktrees` (item 2, stacks alongside the existing aif-handoff worktree precedent). Draft text available on request.
2. **Rule edit** (`parallel-subwave-isolation.md`): demote §4 «promotion to principle test» — replace the mechanical-detection ambition with a REFERENCE to `using-git-worktrees` as mature upstream; rule stays Class C as *prose discipline*, not a build target. Carries its own §1.7 when authored.
3. **Vocabulary 5-item codification** (companion-target-comparison §4.2 Decision B): land the Mode-A/B → subagent-driven-development mapping in the orchestrator skill + a short vocabulary table.

## §6 — N2 / N7 boundary (reconciliation)

Flagged earlier as an overlap risk. Clean split: **N2 = say it their way + adopt their ideas into our own artifacts (no dep). N7 = actually run on their skills in our dev (dep, process-layer only).** N2 must land *before or with* N7 so the vocabulary is aligned before the tooling is swapped. N5 (give-back) sequences after N7 (you only know what's worth contributing once you've used theirs).

## §7 — §1.7 self-reflexive (per [phase-research-coverage.md §1.7](../../../.claude/rules/phase-research-coverage.md))

- **Forward-check:** complies with `build-first-reuse-default` (every item carries an explicit verdict from the 7-verdict typology + T16 match); `no-paid-llm-in-ci` (no probes; cites prior free DeepWiki evidence); `doc-authority-hierarchy` (declares scope, subordinates to README); `reviewer-discipline` (ADAPT-candidate go/no-go + rule edits surfaced as decision-needed §8, not decided); Artifact Ownership (does not touch maintainer-owned `.claude/rules/*` or SSOT — proposes only).
- **Backward-check:** introduces no rule → no existing-artefact sweep owed. Proposes SSOT rows + one rule edit; each carries its own §1.7 when authored. The proposed `parallel-subwave-isolation` demotion *removes* a promotion ambition rather than adding scope, so no new backward sweep.
- **Self-application:** N2 applies `build-first-reuse-default` to the project's *own* agent-methodology (the thing the project itself reinvented) — recursive self-application of the adopt-don't-rebuild discipline to its own scaffolding. The T16 column is the discipline's own `#pattern-matching-on-name` guard applied per row.

## §8 — Decision-needed (maintainer; per `reviewer-discipline` §2)

1. **ADAPT-candidates go/no-go** (items 4/5/6 — open-questions §13.35/36/37, currently ARMED). Each is a real new mechanism: 1%-Rule → trigger discipline; TDD-for-Skills → extend principle 02 to SKILL.md; Pressure-scenarios → principle adversarial probes. **Recommendation:** pursue **#5 first** (highest leverage — directly extends the substrate's core paired-negative discipline to an uncovered surface, no dep), defer 4/6 until a skill-authoring pain incident fires. Final call yours.
2. **Apply the §5 codification?** SSOT rows + the `parallel-subwave-isolation` demotion + vocabulary mapping. **Recommendation:** yes — it's the durable output N2 was chartered to produce; I can author the apply-PR (touching maintainer-owned files) only on your explicit go, per the ownership contract.

## §9 — Tags

`#companion-symbiosis` `#build-first-reuse-as-strategy` `#adopt-vocabulary` `#pattern-matching-on-name` `#dogfood-companions` `#substrate-purity`

## §10 — See also

- [2026-05-21-niche-strategy-and-growth-roadmap.md](2026-05-21-niche-strategy-and-growth-roadmap.md) — parent roadmap (N2 + N7 + DECISION=C context).
- [2026-05-21-n1-niche-validation.md](2026-05-21-n1-niche-validation.md) — N1; the substrate-purity-is-the-moat finding that makes C the right call.
- [2026-05-16-companion-target-comparison.md](2026-05-16-companion-target-comparison.md) — §3.1 per-feature matrix + §4.2 5-item vocabulary mapping (Decision B).
- [docs/meta-factory/open-questions.md §13.35/§13.36/§13.37](../open-questions.md) — ADAPT-candidate tracking (ARMED).
- [.claude/rules/build-first-reuse-default.md](../../../.claude/rules/build-first-reuse-default.md) — the 7-verdict typology this patch applies per row.
- [.claude/rules/parallel-subwave-isolation.md](../../../.claude/rules/parallel-subwave-isolation.md) — item 2 demotion target (maintainer-owned).

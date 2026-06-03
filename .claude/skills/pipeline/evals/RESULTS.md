# /pipeline behavioral eval — Stage 6 results

> **Authoritative for:** the recorded outcome of the Stage 6 behavioral eval run (slimmed-vs-baseline) and the disciplines it proves preserved. Companion to [`evals.json`](evals.json) (the eval definitions) + `files/` (the scenario fixtures).
> **NOT authoritative for:** project goal — see [README.md#why-this-exists](../../../../README.md#why-this-exists). The skill's behavioral contract — see [`../SKILL.md`](../SKILL.md).

## Why this exists (NS1 ≡ WS5 closure)

The `meta-orchestrator-refactor` audit (`orchestrator-prompts/meta-orchestrator-refactor/verified-audit.md` — gitignored CANON; MIN-13 / behavioral angle 9) flagged that the skill had **never been behaviorally tested** — every gate was prose (Class C) or structural (principle 12/18/19), none observed the skill *acting*. Stage 6 closes that gap and answers the binding question: **did Stage 4 slim (600→524 LOC, content pushed into references) + Stage 5 rename + i18n break any discipline?**

## Method (session-bound; zero paid LLM)

skill-creator harness, consumed by an active session on the operator's Claude Code subscription — **no API-billed calls** (per [`no-paid-llm-in-ci.md §1`](../../../rules/no-paid-llm-in-ci.md)). Not a CI gate; a reproducible local proof.

- **3 evals** ([`evals.json`](evals.json)), 16 expectations total, each backed by a fixture under `files/` that simulates the `!shell`-injected live state so executor behavior is deterministic and gradeable without real `git`/`gh`.
- **2 configurations per eval:** `slimmed` = current `.claude/skills/pipeline` (524 LOC + 11 refs); `baseline` = pre-slim `.claude/skills/meta-orchestrator` @ `02d53ee` (600 LOC + 8 refs), materialized from git history.
- **Executor** (6 subagents, Opus): read the respective skill spec + fixture, produced the skill's output as a transcript. Executors were **never shown the expectations** (no pass-bias).
- **Grader** (6 subagents, skill-creator [`grader.md`](https://github.com/anthropics/skill-creator)): graded each transcript blind against that eval's expectations, wrote `grading.json`.
- **Viewer:** `generate_review.py --static` over the workspace + `benchmark.json` ([`stage6-benchmark.json`](stage6-benchmark.json)) renders the run (evidence; raw transcripts kept under `/tmp/stage6-eval/workspace/`, not committed).

## Result — no slim-induced regression

| Eval | Discipline focus | Slimmed | Baseline |
|---|---|---|---|
| 1 — no-arg overview (V3) | plan-currency-first · drift-detect · mechanical-state-wins · overview-not-dispatch | **5/5** | 4/5 |
| 2 — named-umbrella dispatch | launch-table · meta-kickoff §5 AI-traps explicit T-numbers · real-`gh` stage-gates · anti-scope | **6/6** | 6/6 |
| 3 — DN-park (genuine fork) | DECISION-NEEDED surfaced · no strategy-pick · «выбирай сам» = non-answer · route to maintainer | 4/5 | **5/5** |
| **Aggregate (per expectation)** | | **15/16 (0.94)** | **15/16 (0.94)** |

**Identical aggregate pass rate. Every targeted discipline passed in the slimmed config.** The two per-eval deltas are eval-design artifacts, not discipline regressions (below).

### Disciplines proven preserved in the slimmed skill

- §1 **plan-currency runs first**, before any priority/overview output (eval-1 E1 ✅).
- §1 **drift detection** — the planted stale claim (`n7-foo ✅ merged PR #410` absent from `gh`) was caught (eval-1 E2 ✅), and **mechanical `gh` state was trusted over the plan claim** (eval-1 E3 ✅).
- §2 Step 5 **V3 overview** = ordered "what to do, in what order", no forced winner-pick, no dispatch (eval-1 E4/E5 ✅).
- §3 **launch-table** with Mode/Stage/Volume + B∥C parallel → Mode B worktrees (eval-2 E1/E2 ✅).
- §4 **meta-kickoff mandatory sections** — `## §5 AI-traps` with **explicit T-numbers** (not a bare pointer — the T7 trap), **stage-gates as real `gh pr list --search "is:merged … base:staging"` commands**, recursive-self-application clause, per-stage stop conditions (eval-2 E3/E4/E5 ✅).
- §8 **anti-scope** — does not write sub-wave code, does not auto-dispatch a Worker (awaits maintainer) (eval-2 E6 ✅).
- §2 Step 4.1 **DECISION-NEEDED + anti-rationalization** — genuine tie surfaced naming both umbrellas, no strategy-pick, **«выбирай сам / оба норм» treated as a non-answer** → re-surfaced with sharper framing + coin-flip, routed to maintainer (eval-3 E1/E3/E4/E5 ✅).

### The two per-eval deltas (attributed — neither is a regression)

- **Eval-1 (slimmed 5/5 vs baseline 4/5).** The baseline executor **HALTED on the drift** per `failures.md` F1 (never reached the overview → failed E4 "produces overview"); the slimmed executor surfaced the drift but continued to the V3 overview. **Content-attributed:** `failures.md` F1 (*"drift detected → Halt, do NOT proceed to §2/§3"*) is **byte-identical** in both configs (line 10), and the §1 gate wording is identical. → executor variance under Class-C prose enforcement (N=1), **not** a content change. Arguably the baseline (HALT) was the more spec-faithful read; the eval fixture conflates drift-handling with the overview path (see follow-ups).
- **Eval-3 (slimmed 4/5 vs baseline 5/5).** Both graders flagged expectation E2 ("describe each option's consequence") as ambiguous / trivially-gameable when the two candidates are *genuinely identical on every axis*. The slimmed run refused to fabricate asymmetric consequences (arguably more correct); the baseline gave "same consequence reversed" (passed E2, but the grader called it trivially-gameable). → eval-design artifact, not a discipline regression.

## Eval follow-ups (grader-raised; logged, not yet actioned)

1. **Separate the drift eval from the overview eval.** Add a clean-plan (no-drift) fixture to exercise the §2 V3 overview path without tripping the F1 HALT, so eval-1 E4/E5 test the overview unconditionally.
2. **Tighten eval-3 E2** to require kickoff-grounded asymmetric analysis, or replace it with a HALT-property assertion (no launch-table / no meta-kickoff written) + a coin-flip-offer assertion — both load-bearing behaviors currently uncovered.
3. **Add a file-on-disk existence check** for the meta-kickoff/state.md in eval-2 (currently narrated inline in the transcript).

## Caveats (honest)

- **N = 1 per configuration** (skill-creator recommends 3). The two deltas fall within single-sample variance and were each content-attributed (byte-identity) or grader-flagged as non-regressions; the "disciplines preserved" claim rests on the **per-expectation aggregate parity (15/16 = 15/16) + byte-identity attribution**, not on N=1 timing/token figures.
- **Executors are AI simulating the skill**, not the literal slash-command runtime (subagents cannot invoke `/pipeline`'s `!shell` injections; the fixtures stand in for injected state). This tests the skill's *prose+reference behavioral contract* — which is exactly the surface the slim changed.
- Pre-existing, unrelated: 5 tests under `packages/core/skills/` fail on this worktree against pristine `origin/staging` (bash `rc=127` PATH, live-`gh`-dependent plan-currency/dogfood) — independent of these additions (none reference `evals/`); surfaced as an observation, out of Stage-6 scope.

## Re-run

```bash
# materialize baseline (pre-slim) skill from git
mkdir -p /tmp/stage6-eval/baseline && git archive 02d53ee .claude/skills/meta-orchestrator | tar -x -C /tmp/stage6-eval/baseline
# then dispatch executor + grader subagents per eval (see this file's Method), or wire run_loop.py.
python3 <skill-creator>/eval-viewer/generate_review.py /tmp/stage6-eval/workspace \
  --skill-name pipeline --benchmark .claude/skills/pipeline/evals/stage6-benchmark.json
```

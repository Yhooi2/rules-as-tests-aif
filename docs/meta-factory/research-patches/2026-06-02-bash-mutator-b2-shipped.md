<!-- scope:bash-mutator-b2-shipped -->
# Bash mutator B.2 — shipped (mutation-discipline-umbrella Stage 2)

> **Class:** C — I-phase ship record + dogfood evidence; the shipped artefacts (`bash.rules`, `run-bash-mutation.sh`, its paired-negative test) are the mechanism. Closes Stage 2 **B.2** of the [mutation-discipline-umbrella](../../../.claude/orchestrator-prompts/mutation-discipline-umbrella/kickoff.md).
> **Authoritative for:** the B.2 build record — what shipped, the §2 dogfood-gate evidence (per-hook kill rates + real survivors), the recursive-bootstrap result, and the `/*`-comment regexp-engine limitation + its in-wrapper mitigation.
> **NOT authoritative for:** project goal — see [README.md#why-this-exists](../../../README.md#why-this-exists). The ADAPT verdict — see [2026-05-31-bash-mutator-prior-art-b1.md](2026-05-31-bash-mutator-prior-art-b1.md) (SSOT #91). Stage-1 audit B/C/D admissibility — see [2026-05-25-mutation-discipline-audit.md §A.4](2026-05-25-mutation-discipline-audit.md).

> **Origin:** 2026-06-02. Consumes B.1's **ADAPT `universalmutator`** verdict (#305, SSOT #91) and the B.1 §B.1.6 delivery-fork **resolved by maintainer 2026-06-01 = Option B (session-bound / local, NOT CI)**. Dispatch: [`b2-dispatch.md`](../../../.claude/orchestrator-prompts/mutation-discipline-umbrella-meta-launch/b2-dispatch.md).

---

## §1 What shipped

| Artefact | Role | LOC |
|---|---|---|
| [`packages/core/audit-self/bash.rules`](../../../packages/core/audit-self/bash.rules) | the **only** project-authored data artefact — universalmutator regexp operators for bash | 46 |
| [`packages/core/audit-self/run-bash-mutation.sh`](../../../packages/core/audit-self/run-bash-mutation.sh) | thin wrapper: sanitize → `mutate --only bash.rules --noCheck` → `analyze_mutants <hook> "<test>"` → kill-rate + survivors + ≥60% gate | 139 |
| [`packages/core/audit-self/run-bash-mutation.test.ts`](../../../packages/core/audit-self/run-bash-mutation.test.ts) | the wrapper's own paired-negative test (T15); `skipIf` no universalmutator | 129 |
| [`CONTRIBUTING.md` «Bash mutation testing»](../../../CONTRIBUTING.md) | how-to-run + `pipx install universalmutator` prereq + **no CI** note | — |

**Operators** (each a single-line `LHS ==> RHS` regexp): negate `if [[ … ]]` (single-test scope), swap `&&`/`||` (both ways), flip `exit 0`/`1`, flip `=`/`!=`/`==` inside `[[ ]]`, `set -e`→`set +e`; plus `^\s*# ==> DO_NOT_MUTATE` to skip pure-comment lines (else comment `exit 0`s are guaranteed-equivalent survivors).

**Delivery = Option B (session-bound, local, NOT CI).** Mirrors Stryker, which is a `devDep` run by hand (`npx stryker run`), not a CI job — mutation is slow, CI minutes metered, README «CI = last resort». The original kickoff §3 B.3 (CI job in `audit-self.yml`) is **DROPPED**. universalmutator is **MIT**-licensed, dev-time only, never consumer-shipped (B.1 §B.1.6 license precondition satisfied).

## §2 Dogfood gate (umbrella §5 — MANDATORY) — PASSED

The wrapper was run against the M.4 + adjacent bash hooks (each with `npx vitest run hooks/<name>.test.ts` as the kill command, ≥60% floor). It **surfaced real, undocumented weaknesses in multiple paired-negative tests** — the gate's success criterion:

| Hook | mutants | kill rate | verdict | representative surviving mutant |
|---|---|---|---|---|
| **end-of-turn-reminder** | 31 | **52%** | **FAIL** | `if [ "$asked" = "true" ] && [ "$long_text" = "false" ]` → `\|\|` — the AskUserQuestion idle-suppress logic (hook:129-131 B2 fix), uncaught |
| **validate-prompt** | 9 | **56%** | **FAIL** | `if [[ -z "$FILE_PATH" ]] \|\| [[ "$FILE_PATH" != *…* ]]` → `&&` — off-path skip condition, uncaught |
| deps-hash-check | 13 | 62% | PASS | `if ! command -v node …; then exit 0` → `exit 1` — no-node graceful-skip path, uncaught |
| check-doc-authority | 10 | 70% | PASS | `jq unavailable … exit 0` → `exit 1`; `tsx not found … exit 0` → `exit 1` — degraded paths, uncaught |
| check-kickoff-traps | 13 | 77% | PASS | `[[ -z "$ABS_PATH" ]] && exit 0` → `exit 1` |
| inject-matching-rule | 11 | 82% | PASS | glob comparator `[[ "$path" == "$pat" ]]` → `!=` |
| check-hook-marker | 10 | 100% | PASS | — (after the `/*` fix in §3) |

**Categorisation (T-MUT-B — survivor ≠ automatic gap):**
- **Real test gaps** (the test *should* kill these): `end-of-turn-reminder` `&&`↔`||` on the suppress/AskUserQuestion conditions (mutant.20/.21) + `exit 0→1` (mutant.14); `validate-prompt` off-path `||`→`&&` (mutant.2); the **degraded-path exit flips** across check-doc-authority / validate-prompt / deps-hash-check (no-jq / no-tsx / no-node skips are asserted by none of the tests).
- **Likely equivalent mutants** (no observable behaviour change for the test): the `… 2>/dev/null || true` → `… && true` flips inside `$(…)` command substitutions under `set -uo pipefail` (no `-e`) — the captured value and exit are observably unchanged. These are NOT gaps; recording them here so they are not re-investigated.

The dominant audit target (`end-of-turn-reminder.sh`, 29 branches × 159 LOC) scoring **52%** is the headline finding: its 434-line test asserts payload *shape* on trigger turns but does not exercise the boundary `&&`/`||` logic of its suppress conditions. **F3 (dogfood detects 0 bugs) does NOT fire** — the opposite happened.

## §3 The `/*`-in-comment regexp-engine limitation (found + fixed)

universalmutator's generic comment scanner ([`mutator.py` lines 188-201]) treats `/*` (C) and `{-` (Haskell) as **block-comment openers** unconditionally — language-independent. bash has neither, but a bash *glob in a comment* (`# … .claude/hooks/*.sh`) contains `/*`; with no later `*/`, the engine **skips every subsequent line** → silent under-count or **zero mutants**. `check-hook-marker.sh` (a `/*` glob on line 9, no `*/`) produced **0 mutants** until fixed — a discipline-theatre landmine (a tool that silently reports a high kill rate on un-mutated code).

This is the Trail-of-Bits regexp-engine limitation B.1 §B.1.3 flagged, surfacing on our corpus. **Mitigation (in the wrapper, automatic):** a line-count-preserving sanitised copy (`/*`→`/ *`, `{-`→`{ -`; inert spaces inside comments) is used for *generation only*; `analyze_mutants` still swaps mutants into the **real** hook path and restores it. After the fix, `check-hook-marker.sh` mutates fully (10 mutants, 100% kill). **F2 (engine cannot usefully mutate) does NOT fire** — 12/13 hooks mutate cleanly; the one suppressed case is recovered by the sanitiser.

## §4 Recursive self-application (umbrella §5/§6, T15) — PASSED

The mutator mutates **its own paired-negative test's target**: running the wrapper on `run-bash-mutation.sh` itself (kill command = `run-bash-mutation.test.ts`) generated **13 mutants, killed 13/13 = 100%**. The recursive bootstrap holds: `bash.rules` mutates the wrapper, and the wrapper's own test kills every mutant. (Safety: `analyze_mutants` transiently overwrites the target during the run and restores the untouched original on completion — verified the wrapper was byte-intact afterwards.)

## §1.7 Forward + Backward check

### §1.7 Forward-check applied

- **[build-first-reuse-default.md §1](../../../.claude/rules/build-first-reuse-default.md)** — executes the B.1 **ADAPT** verdict (SSOT #91): the universalmutator engine + `analyze_mutants` harness are ADOPTed verbatim; the only project-authored code is the `bash.rules` data file + a thin wiring wrapper. No `#parallel-evolution-creep` (no homegrown mutation engine).
- **[no-paid-llm-in-ci.md §1](../../../.claude/rules/no-paid-llm-in-ci.md)** — universalmutator is deterministic regexp; zero LLM calls; and the tool is **not in CI at all** (Option B). The wrapper invokes only `mutate`/`analyze_mutants` + the project's own vitest.
- **[dual-implementation-discipline.md §6](../../../.claude/rules/dual-implementation-discipline.md)** — the wrapper carries `# @dual-pair: mutation-discipline-bash-b2` + `# @cc-only-rationale:` (local dev tool, not a CC hook, not consumer-shipped). `bash.rules` + the test share the same anchor.
- **[phase-research-coverage.md §1.7/§1.12](../../../.claude/rules/phase-research-coverage.md)** — R-phase (B.1) preceded this I-phase; the delivery fork was surfaced to + decided by the maintainer (Option B), not picked unilaterally.

### §1.7 Backward-check applied

- **B.1 survey (#305, SSOT #91)** — consumed, not re-opened; the ADAPT verdict + ~85% T16 problem-class match stand. The B.1 §B.1.5 secondary falsifier («regexp engine cannot usefully mutate») was tested in §3 and did **not** fire.
- **Stage-1 audit (#219)** — its §A.4 «B = GO» + ≥60% floor are consumed verbatim (the wrapper's default floor). C and D remain FROZEN pending their own gates; this patch does not advance them.
- **The 9 (now 13) M.4 hook tests** — NOT rewritten (umbrella §2 forward-going discipline). They are *audit subjects*: §2 reports their kill rates as findings. Acting on the `end-of-turn-reminder` 52% / `validate-prompt` 56% gaps is a **separate follow-up**, not this PR (no drive-by per CLAUDE.md PR-strategy).
- **No `.github/workflows/*` touched** — kickoff §3 B.3 (CI job) is dropped, not added.

## §5 AI-traps discharged (per [ai-laziness-traps.md §2](../../../.claude/rules/ai-laziness-traps.md))

- **T11 / T16** — discharged in B.1 (prior-art done; problem-class verified ~85%); consumed here, not re-opened.
- **T15 (self-application)** — §4: the wrapper has its own paired-negative test, exercisable by `analyze_mutants` (100% recursive kill).
- **T19 (own QA before handoff)** — the §2 dogfood + §4 recursion were run before PR; this is design-substance QA a green CI would not provide.
- **T-MUT-A («manual ≡ automated»)** — the on-demand local run *is* the automation; the «run when you touch a hook or its test» convention (CONTRIBUTING.md) is the discipline replacing the dropped CI job, not a weaker form of it.
- **T-MUT-B («high kill = good test»)** — §2 categorises survivors into real-gap vs equivalent-mutant rather than treating every survivor as a gap or every kill as proof.
- **T3 (no prose-only findings)** — every §2/§3/§4 number is a real `analyze_mutants` run captured this session.

## §6 Follow-ups (surfaced, NOT done here — no drive-by)

1. **`end-of-turn-reminder.sh` test (52%)** + **`validate-prompt.sh` test (56%)** below the floor — strengthen to kill the `&&`/`||` suppress/skip-condition mutants. Stage 3 (tests-of-tests) territory or a dedicated fix-PR.
2. **Degraded-path coverage** (no-jq / no-tsx / no-node `exit 0→1` survivors across several hooks) — tests don't exercise the graceful-skip branches.
3. **`runtime-bridge-dispatch.sh`** has no paired-negative test (13th hook) — Stage 4 / D territory.

## See also

- [2026-05-31-bash-mutator-prior-art-b1.md](2026-05-31-bash-mutator-prior-art-b1.md) — B.1 ADAPT verdict (this patch's input); SSOT #91.
- [2026-05-25-mutation-discipline-audit.md](2026-05-25-mutation-discipline-audit.md) — Stage-1 audit; §A.4 B=GO + ≥60% floor.
- [.claude/orchestrator-prompts/mutation-discipline-umbrella/kickoff.md](../../../.claude/orchestrator-prompts/mutation-discipline-umbrella/kickoff.md) — umbrella spec (§5 dogfood gate, §F2/F3 stop conditions).
- [agroce/universalmutator](https://github.com/agroce/universalmutator) — the ADAPTed engine (MIT).

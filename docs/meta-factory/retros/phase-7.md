# Phase 7 Retrospective — Layer 4 Validator + Layer 5 Installer

> **Date:** 2026-05-08
> **Branch:** `feat/phase-7-validator-installer` (forked from `main` HEAD `b94ef56`, the merge commit of PR #5 closing Phase 5+6)
> **Phase:** 7 — Layer 4 Validator + Layer 5 Installer per [EXECUTION-PLAN.md §6 reordering](../EXECUTION-PLAN.md), refined by [phase-7-research.md](../phase-7-research.md).
> **Verdict:** **GO** to Phase 8 (acceptance Next 15 → 16 + canonical regen ≤5% trigger)

---

## Architectural pivot (continuation, durable)

Phase 4 (L1 Detector), Phase 5 (L2 Research), Phase 6 (L3 Synthesizer), and now Phase 7 (L4 Validator + L5 Installer) all ship as **deterministic-curated v1** with Planner-Executor module-surface contracts. **NO LLM at runtime in v1.** LLM extension is a strict superset for v2 trigger (Phase 8 acceptance test or first real consumer).

Phase 7 specifically defers gate 5 (two-AI review) to Phase 8 with explicit cost-scope rationale — the gate maps cleanly to AIF's `review-sidecar` (`model: opus`) sub-agent per [aif-comparison.md §4](../aif-comparison.md), so the integration path is open without forcing a v1 commitment.

---

## L4 6-gate triage (final v1 lock)

| # | Gate | v1 status | Module |
|---|---|---|---|
| 1 | Schema check | **REQUIRED** | [validator/gate-schema.ts](../../packages/core/validator/gate-schema.ts) — re-validates SynthesisPlan against synthesis-plan.schema.json + semantic check that eslint-typed rules carry `negative-test` |
| 2 | rule-tester roundtrip | **REQUIRED** | [validator/gate-rule-tester.ts](../../packages/core/validator/gate-rule-tester.ts) — minimal per-rule Linter.Config + TS-ESLint parser; built-in + plugin rules; skip manual/command/script |
| 3 | Mutation testing | **SKIP v1** | Path B only; Phase 9+ |
| 4 | Tautology check | **REQUIRED** | [validator/gate-tautology.ts](../../packages/core/validator/gate-tautology.ts) + 3-file negative-corpus (`empty.ts`, `comment-only.ts`, `unrelated.tsx`) |
| 5 | Two-AI review | **DEFER Phase 8** | Maps to AIF `review-sidecar` ([aif-comparison.md §4](../aif-comparison.md)); cost-scope unresolved |
| 6 | Cross-rule conflict | **REQUIRED** | [validator/gate-conflict.ts](../../packages/core/validator/gate-conflict.ts) — plugin rule existence + snippet completeness + duplicate check.rule tracking |

`validate(plan: SynthesisPlan) → ValidationReport` is pure; all 4 REQUIRED gates run when shape passes; downstream gates skip when gate 1 fails.

---

## L5 v1 scope (architecture.md §2.7 mapping)

| Architecture intent | v1 status | Implementation |
|---|---|---|
| Write only validated rules | **YES** | `install()` requires `ValidationReport.ok === true`; pre-validate stage returns early on failure |
| Generate RULES.md / eslint config / audit-ai-docs.sh / GHA workflow | **PARTIAL** | Delegates to existing [emit()](../../packages/core/synthesizer/emit.ts): 3 artifacts. **DEFER** audit-ai-docs.sh + GHA generation to Phase 8 — `install.sh` already handles those; L5 v1 is the additions layer |
| `rules-lock.json` | **YES** | New artifact: `{ schemaVersion, framework, version, ruleIds[], emittedAt, sourceFingerprint (sha256/16) }` |
| npm deps / husky / scripts install | **DEFER Phase 8** | install.sh territory; v1 = artifact write only |
| Re-run L4 post-install | **YES** | postValidation + disk-artifact existence check + lock ruleIds drift detection |

`install(plan, opts) → InstallReport` writes under `<consumerRoot>/.ai-factory/synthesizer-output/`; flags: `force`, `dryRun`. Returns structured failures per stage; never throws on validation outcomes.

---

## Verification block

All acceptance criteria from [phase-7-research.md §7](../phase-7-research.md) green.

| # | Probe | Expected | Actual |
|---|---|---|---|
| 1 | `make self-audit` | 24/24 + zizmor clean | **24/24, zizmor: «No findings to report. Good job!» (2 suppressed)** |
| 2 | `npm test --workspace=@rules-as-tests/core` | ≥200 tests | **220 passed (was 168 baseline; +52 from validator + installer + B2 + M2 extensions)** |
| 3 | `npm test --workspace=@rules-as-tests/preset-next-15-canonical` | 38/38 | **38/38** |
| 4 | `npm run typecheck --workspaces` | 3 clean | **3 workspaces clean** |
| 5 | All 4 L4 REQUIRED gates green on next-16 fixture | required | **schema/ruleTester/tautology/conflict all `pass`; `manual` rule G2 marked `n/a` in gate 2** |
| 6 | L4 reject scenarios | 3 fail with explicit gate+reason | **malformed plan → gate 1 fail; tautology rule → gate 4 fail; orphan plugin rule → gate 6 fail; missing negative-test → gate 1 fail; broken examples.good → gate 2 fail** |
| 7 | L5 install on tmp consumer | artifacts + lock + post-validate green | **8 install tests cover happy-path, dry-run, lock collision, force, pre-validate fail, post-validate drift, empty plan; all green** |
| 8 | 2 new CI jobs | green | **`framework-self-validate` + `framework-self-install-validated` added; depend on `principles-meta-tests` per m4 fix** |
| 9 | Snapshot stability | own + fixture × {validate, install} | **3 frozen snapshots: expected-self-validate, expected-fixture-validate, expected-self-install (deterministic shape)** |

### Self-application invariants

| Invariant | Source | Status |
|---|---|---|
| L4 (a) ValidationReport snapshot stability | [self-application.md §7 row L4](../self-application.md) | **CLOSED point-in-time.** Two-fixture coverage: own repo (rules=[], gates pass/n/a) + next-16 fixture (3 recipes, all 4 gates pass). |
| L4 (b) every existing rule passes meta-tests | [self-application.md §7 row L4](../self-application.md) | **CLOSED via M2 fix:** P1 + P2 now load `expected-fixture-synth.json` and assert each synthesized rule has executable check + non-trivial paired examples + non-tautological negative-test. |
| L5 (a) framework-self-install green | [self-application.md §7 row L5](../self-application.md) | **CLOSED.** `framework-self-install-validated` job runs synth → install → diff vs frozen shape on every push. |
| L5 (b) post-install meta-check | [architecture.md §2.7 item 5](../architecture.md) | **CLOSED.** install() re-validates plan + asserts disk artifacts + lock ruleIds match. |

---

## Created/modified files (commit hashes)

```
b963142 docs(phase-7):     Step 0 entry research — 6-gate triage + L5 v1 scope
9b4312b feat(synthesizer): negative-test field + recipe schema validation [M1+M3]
a29fc67 feat(research):    validateResearchPlan + synth CLI plug-in [B2]
f24cd44 feat(validator):   module skeleton + gate 1 (schema)
e1bf374 feat(validator):   gate 2 (rule-tester roundtrip)
8f4c97a feat(validator):   gate 4 (tautology) + negative-corpus
fbd3607 feat(synthesizer): semantic merge for eslintRuleConfig [B1]
b5f2830 feat(validator):   gate 6 (cross-rule conflict)
86f6f6b feat(validator):   public CLI + aggregator regression tests
f97a183 test(principles):  extend P1+P2 to cover synthesized rules [M2]
3a75b73 feat(installer):   L5 v1 — write artifacts + rules-lock + post-validate
1adf67d feat(validator,installer): self-app + fixture snapshots
ae8817f ci(audit-self):    framework-self-validate + framework-self-install-validated [m4]
65153a6 chore(meta-factory): convert stale stubs to re-exports from core
[this commit] docs(phase-7): retro + GO verdict + open-questions/EXECUTION-PLAN closing edits [m1]
```

**15 atomic commits.** Net surface change:
- **L4 (validator)**: 8 source files (`types`, `internal-validators`, `gate-schema`, `gate-rule-tester`, `gate-tautology`, `gate-conflict`, `validate`, `index`, `cli`) + 5 test files + 3 fixtures (negative-corpus) + 2 frozen snapshots.
- **L5 (installer)**: 4 source files (`types`, `install`, `index`, `cli`) + 2 test files + 1 frozen snapshot.
- **Synthesizer**: `negative-test` field + recipe schema + Ajv validation + B1 semantic merge helper + tests; 2 recipes updated; 1 snapshot refreshed.
- **Research**: shared Ajv factory (`internal-validators.ts`) + new `validate-plan.ts` (B2 closure) + tests; load.ts refactor preserves coupling.
- **Principles**: P1 + P2 extended for M2 closure; +3 tests, no manifest changes.
- **CI**: 2 new jobs + `needs:` dep on existing `framework-self-synth` (m4).
- **Meta-factory**: 3 stub files converted to re-exports (mirror Phase 4 detector pattern).
- **Docs**: `phase-7-research.md`, this retro, `open-questions.md` §13.7 closing edit (m1), `EXECUTION-PLAN.md` §6 status update.

---

## Reuse posture validated (per [phase-7-research.md §4](../phase-7-research.md))

| # | Reuse decision | Status | Evidence |
|---|---|---|---|
| 7.1 | Schema gate uses existing Ajv compile | **CLOSED** | `validator/internal-validators.ts` mirrors `research/internal-validators.ts`; same compile-once pattern. |
| 7.2 | Rule-tester gate uses `@typescript-eslint/rule-tester` | **CLOSED** | Linter API + TS-ESLint parser via existing transitive deps; no new explicit deps. |
| 7.3 | Recipe schema mirrors Recipe TS interface | **CLOSED via M3 fix** | `recipe.schema.json` + Ajv validation in `loadRecipe()`. Authoring note on `appliesTo` exact match (m3) captured in schema description. |
| 7.4 | Conflict detector reads existing 3 preset rules | **CLOSED** | `gate-conflict.ts` imports preset plugin; verifies plugin rule existence + snippet completeness. |
| 7.5 | Installer extends framework-self-install pattern | **CLOSED** | `framework-self-install-validated` job mirrors `framework-self-install-{ts-server,react-next}` shape (`mkdir tmp consumer`, run install). |
| 7.6 | Validator + installer mirror L1/L2/L3 module location | **CLOSED** | `packages/core/{validator,installer}/` consistent with `{detector,research,synthesizer}/`. |
| 7.7 | DRY shared `getValidateEntry()` factory | **CLOSED** | `research/internal-validators.ts` exports `validateEntry` + `validateResearchPlanShape` + `errorsText`; `load.ts` and `validate-plan.ts` both consume. Edit 3 from Art's plan-review applied. |
| 7.8 | No new explicit deps | **CLOSED** | `package.json` diff: only bin entries + scripts + exports added. ESLint, TS-ESLint parser, preset plugin — all transitive. |

---

## PR #5 post-merge audit findings — closure status

| ID | Severity | Closure |
|---|---|---|
| B1 | BLOCKER | **CLOSED** — semantic merge for eslintRuleConfig (commit `fbd3607`). Future recipe collisions throw `RuleCollisionError` naming both source recipes; `no-restricted-imports` paths[] merge by name dedup. |
| B2 | BLOCKER | **CLOSED** — `validateResearchPlan()` exported, plugged into synthesizer cli.ts (commit `a29fc67`). Spoofed allowlist URL now caught at JSON-parse time. |
| M1 | MAJOR | **CLOSED** — `negative-test` field added to types + schema + 2 eslint recipes; manual recipe correctly skipped (commit `9b4312b`). Gate 1 enforces presence at runtime for `check.type === 'eslint'`. |
| M2 | MAJOR | **CLOSED** — P1 + P2 principle tests now load `expected-fixture-synth.json` (commit `f97a183`). +3 principle tests; coverage extends to synthesized rules. |
| M3 | MAJOR | **CLOSED** — `recipe.schema.json` + Ajv validation in `loadRecipe()` (commit `9b4312b`). Typos in `appliesTo` now throw `RecipeError`. |
| m1 | MINOR | **CLOSED** — `open-questions.md` §13.7 updated (this commit): symbolic v1 closed, behavioral + embedding-based v2 open. |
| m2 | MINOR | **DEFER v2** — `fetchedAt` `format: date` constraint waits for LLM-generated entries. |
| m3 | MINOR | **CLOSED** — recipe schema description carries the `appliesTo` framework-slug authoring note. |
| m4 | MINOR | **CLOSED** — `framework-self-synth` + 2 new self-validate/install jobs declare `needs: principles-meta-tests` (commit `ae8817f`). |

All BLOCKER + MAJOR closed; m2 deferred with explicit v2 trigger.

---

## Self-reflection block

- **Combined L4+L5 in one session?** Yes, burn-mode Opus 4.7. Wall-clock ≈45 min from Phase 0 sanity to this retro. Same compression as Phase 5+6.
- **Did the schema-vs-runtime split for `negative-test` hold?** Yes. Treating `negative-test` as optional in JSON Schema and enforcing presence at runtime in gate 1 (semantic check) keeps the schema universal — manual rules legitimately don't carry one. If schema had hard-required it for all rules, Pages-Router (manual) would need a placeholder, polluting authoring.
- **Was DRY refactor for `getValidateEntry()` worth it?** Yes — small (~25 LOC) and prevents two Ajv instances + two schema parses. Same pattern duplicated for validator/internal-validators.ts (synthesis-plan schema). Both modules compile schema once at module-load.
- **Was gate 6 minimal v1 right call?** Yes for v1. Three failure modes covered (orphan plugin rule, snippet drop, duplicate check.rule). Synth-vs-preset semantic conflict (severity drift) deferred — current 3 recipes deliberately reuse preset rule at preset's intended severity.
- **Lock file fingerprinting strategy?** sha256/16 over `JSON.stringify(plan)`. Adequate for collision detection during repeated installs of same plan; not cryptographically meaningful (truncated). Phase 8 acceptance test will exercise repeated install of slightly-modified plans and clarify whether truncation suffices.
- **Module surface discipline?** Held. validator/index.ts exports `validate` + types only; gate functions internal. installer/index.ts exports `install` + types only. emit.ts still not in synthesizer/index.ts (Phase 6 retro reuse 6.4 preserved).
- **Stale stub cleanup approach?** Re-export over delete (Art's review observation #1). Mirrors detector pattern. `meta-factory` package surface stays stable for future LLM/CLI integrations; real impl lives in core.

---

## Evaluation block

| Metric | Target | Actual | Verdict |
|---|---|---|---|
| Self-application score | 8/10 | **9/10** — all 4 REQUIRED gates green; L5 self-install round-trips; 3 frozen snapshots stable. -1 for gate 5 deferred (acknowledged debt with documented mapping). | ✓ |
| Time-vs-plan ratio | ≤6h orchestrator path | **≪1h wall-clock** (single-session, Opus 4.7 burn-mode direct execution) | ✓ well under |
| Tasks 1-12 closed | required | All 12 closed with verified acceptance | ✓ |
| BLOCKER + MAJOR from PR #5 audit | required closure | All 5 closed | ✓ |
| Tests added | ≥30 | **+52** (220 vs 168 baseline) | ✓ exceeded |
| 4 REQUIRED gates green | required | All green on next-16 fixture | ✓ |
| 2 new CI jobs | required | Both added + zizmor clean | ✓ |
| Snapshot stable | required | 3 frozen snapshots round-trip | ✓ |
| Verdict | GO | **GO** to Phase 8 | ✓ |

### Stop-rule audit

- **NO LLM v1**: held — gate 5 deferred with documented `review-sidecar` mapping; no Anthropic SDK calls anywhere.
- **NO new explicit deps**: held — ESLint, TS-ESLint parser, preset plugin all transitive; only bin entries + scripts in package.json.
- **NO yargs/commander**: held — both new CLIs use `process.argv` parsing (≤60 LOC each).
- **NO recipe expansion**: held — 3 recipes still; R12/R14/R20 trigger Phase 8.
- **NO Path B AST gen**: held — Phase 9+.
- **Atomic commits**: held — 15 commits, 1 logical change each, conventional-commits + English subjects.

---

## RCA section

**Skipped.** Time-vs-plan ratio well under threshold; no snapshot fragility (refreshed in same commit as schema change); no quality regressions (typecheck stayed clean across all workspaces; one transient TS narrowing fix during gate 1 commit was caught and resolved before next commit). No scope creep beyond planned Phase 8 deferrals.

---

## Open questions for Phase 8 entry (§5.5 Step 0 trigger)

1. **Canonical regen ≤5% trigger** — what constitutes the diff metric? Identical rule IDs, identical `eslintConfigSnippet` keys, identical `applies-to` glob coverage? Acceptance test design needs this concrete.
2. **Recipe expansion R12/R14/R20** — are stack-specific preset rules promoted to recipes by mechanical lift (read existing rule, derive negative-test from existing test fixtures), or by hand re-authoring with provenance?
3. **Gate 5 (two-AI review) cost-scoping** — Phase 8 must answer: per-rule or per-plan invocation? Cached or per-commit? Advisory or blocking? Maps to AIF `review-sidecar`; integration vs reimplementation choice.
4. **L5 v1 → v2 trigger** — first real consumer ships? Or Phase 8 acceptance test? Both expand L5 scope to cover npm deps install + husky + GHA generation.
5. **`/aif-verify` integration** — Phase 11 territory but L4 + L5 now produce `aif-gate-result`-compatible JSON shape? Worth a forward-spike in Phase 8 if cost is low.

---

## Versioning

- **2026-05-08** — Phase 7 close, GO verdict for Phase 8 entry. 15 atomic commits on `feat/phase-7-validator-installer` (forked from main HEAD `b94ef56` post-PR-#5-merge). Single-session orchestrator-direct path (Opus 4.7 burn mode) maintained ≪1h wall-clock — same compression pattern as Phase 4/5/6. EXECUTION-PLAN §6 reordering note updated; Phase 8 = canonical regen + acceptance Next 15 → 16. open-questions.md §13.7 closed for symbolic v1; behavioral + embedding-based remain v2 triggers.

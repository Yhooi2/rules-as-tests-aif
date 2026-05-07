# Phase 2 Delegation Prompt — Principles as Meta-Tests

> **Назначение:** self-contained prompt для делегации Phase 2 (Agent Opus subagent **или** Sonnet manual handoff — orchestrator decision based on Art's choice).
> **Версия:** 0.1.0 — 2026-05-07
> **Embeds:** Art's review guardrails (Phase 2 alignment review, 4 substantive constraints)

---

## Identity & Context

**Repo:** `/Users/art/code/rules-as-tests-aif`
**Branch:** `chore/self-application` (HEAD `184c2be` после Phase 1 + Phase 1.D + MAJOR-1/2 fixes)
**Phase:** 2 (Principles as meta-tests, planned ~1 неделя per EXECUTION-PLAN §8)
**Goal:** извлечь принципы из source files и формализовать каждый как **исполнимый тест против `factory/rules-manifest.json`**.

## Обязательное чтение перед стартом

1. `/Users/art/code/rules-as-tests-aif/docs/meta-factory/EXECUTION-PLAN.md` — особенно §6 Phase 2 (search `Phase 2 — Principles as meta-tests`).
2. `/Users/art/code/rules-as-tests-aif/docs/meta-factory/self-application.md` §2 — canonical L2 source list (3 файла).
3. `/Users/art/code/rules-as-tests-aif/skills/rules-as-tests/SKILL.md` — entry-point.
4. `/Users/art/code/rules-as-tests-aif/skills/rules-as-tests/references/overview.md` — 5-layer principles content (это и есть «principles»).
5. `/Users/art/code/rules-as-tests-aif/skills/rules-as-tests/references/ai-traps.md` — anti-patterns (negative principles).
6. `/Users/art/code/rules-as-tests-aif/skills/rules-as-tests/references/self-testing-docs.md` — documents-lie principles, examples-as-tests.
7. `/Users/art/code/rules-as-tests-aif/factory/rules-manifest.json` (280 строк) и `factory/rules-manifest.schema.json` (63 строки) — SSOT для правил, target meta-tests.
8. `/Users/art/code/rules-as-tests-aif/scripts/render-rules.ts`, `scripts/render-rules.test.ts` — pattern для написания TS scripts с тестами.
9. `/Users/art/code/rules-as-tests-aif/scripts/package.json` — TS setup (vitest, tsx, ajv).

---

## SCOPE — Hard Guardrails (Art's review 2026-05-07)

### Guardrail 1 — Scope criterion (in/out gate)

**Принцип входит в Phase 2 scope ТОЛЬКО ЕСЛИ:**

> Можно написать `test.ts` который читает `factory/rules-manifest.json` и делает `assert` **без Phase 3+ инфраструктуры** (без npm package split, без runtime ESLint execution, без consumer filesystem, без Stryker mutations).

**Принципы которые EXPLICITLY OUT of Phase 2 scope** (defer to indicated phase, document в `principles-as-tests.md` known-limitations section):

| Принцип | Reason out | Defer to |
|---|---|---|
| "AST > grep" для validator logic | Требует runtime, не structural manifest check (можно лишь structural: `assert(rule.check.type === "eslint")` — это weaker form) | Phase 5 (validator runtime) |
| "Mutation kill rate ≥70%" | Stryker mutation testing, не manifest-readable | Phase 5 (validator) |
| "Every exported function has test" | Filesystem traversal consumer side, не manifest scope | Phase 7+ (consumer integration) |
| "rule-tester прогон" runtime | Требует npm install + ESLint runtime | Phase 5 (validator) |

### Guardrail 2 — Mutation-style verification REQUIRED for each meta-test (NOT optional)

Per Art's review:
> «Mutant-style verification — plan'овое требование "сломать правило в manifest, проверить что meta-test падает" — обязательно для каждого meta-test, не optional. Это acceptance gate против тавтологии самих meta-tests.»

**Implementation contract для каждого meta-test:**

```ts
// tests/principles/<principle-name>.test.ts
describe('Principle X: <name>', () => {
  test('all rules in manifest pass principle X', () => {
    const manifest = loadManifest();
    for (const [id, rule] of Object.entries(manifest)) {
      assertPrincipleX(rule); // throws if violation
    }
  });

  test('mutation: violating one rule causes assertion to fail (anti-tautology)', () => {
    const manifest = loadManifest();
    const mutated = mutateRuleToViolatePrincipleX(manifest);
    expect(() => assertPrincipleX(mutated.somerule)).toThrow();
  });
});
```

Without mutation-style test — meta-test возможно тавтологичен. Это HARD requirement, не optional.

### Guardrail 3 — Threshold 80% MUST be qualified в retro

Plan §6 Phase 2 verdict gate: «≥80% правил проходят meta-tests, OR оставшиеся ≤20% классифицированы с rationale».

Per Art's review:
> «`rules-manifest.json` не содержит `negative-test` поля в R1-R6 (проверено). Большинство правил fail'нут принцип "paired negative test". Threshold 80% должен быть квалифицирован в Phase 2 retro: "% правил, проходящих принципы applicable к ним при текущей manifest структуре".»

**В Phase 2 retro явно зафиксировать:**
- N rules total в manifest
- M principles в Phase 2 scope (after Guardrail 1 filter)
- Per-principle pass rate (% rules satisfying that specific principle)
- **Composite "applicable" pass rate** = % rules passing principles **applicable** to them (some principles apply only to certain rule types — e.g., paired-negative-test applies к ESLint rules, не к manual probes)
- 80% threshold applies к composite, не к each individual principle

### Guardrail 4 — REVISE/STOP trigger явный

Per plan §8 stop-rule + Art's review:
- **REVISE trigger:** ≥30% правил R1-R20 fail **any** meta-test (не "all" — fails one principle is enough). Это явный stop-rule из plan §8, должен быть **recorded в Phase 2 brief** и checked в retro.
- **STOP trigger:** Phase 2 не закрыта за 14 дней (>2x planned 1 week) → RCA section per EXECUTION-PLAN §5.

---

## Стартовый список 7 принципов (Art's mapping подтверждён)

| # | Принцип | Source file | Phase 2 status |
|---|---|---|---|
| 1 | Every rule has executable check (или explicit manual rationale) | `overview.md` Layer 2 + `ai-traps.md` §4 | ✅ IN — manifest field `check` |
| 2 | Paired negative test для каждого rule | `overview.md` Layer 4 («expected = SUT output» anti-pattern) | ✅ IN — manifest field `negative-test` (даже если currently absent в R1-R6 — это findings) |
| 3 | AST > grep | `overview.md` Layer 2 («AST scan» emphasis) | ⚠ PARTIAL — only structural check (`check.type === "eslint"` имеет AST-based default); deeper runtime check → Phase 5 |
| 4 | No tautology | `ai-traps.md` §3 («Tautological tests») | ✅ IN — mutation-style verification на самих meta-tests (Guardrail 2) |
| 5 | Manifest = SSOT (manifest ↔ RULES.md drift) | `self-testing-docs.md` (drift detection concept) + existing `render-rules.ts --check` | ✅ IN — extends existing render check |
| 6 | MUST не демотируется до should | `ai-traps.md` (rule MUST enforcement) | ✅ IN — grep manifest для wording «should», «consider», «recommended» в MUST contexts |
| 7 | Documents lie (examples bad/good исполнимы) | `self-testing-docs.md` §code-vs-docs | ⚠ PARTIAL — structural check (`examples.bad` и `examples.good` exist) ✅; actual parse/run examples → Phase 5 |

**Stretch principles** (если время остаётся, low priority — defer if not done):
- Generic vs stack-specific scoping (R-rules vs IR-rules) — manifest имеет `stack: []` field
- Rule rationale mandatory (`overview.md` Layer 1 «Rules without `because(...)` rationale → first to be deleted»)

**НЕ добавлять новые принципы** beyond это list без явного rationale в retro.

---

## Артефакты для создания

### 1. `tests/principles/<id>-<slug>.test.ts` — один файл per principle

Naming: `tests/principles/01-executable-check.test.ts`, `02-paired-negative-test.test.ts`, etc.

Each file:
- Vitest `describe` block per principle
- Test 1: «all rules pass principle» (positive)
- Test 2: «mutation: violating one rule fails assertion» (anti-tautology)
- Helper: `loadManifest()` from `factory/rules-manifest.json`
- Type-safe via Ajv (manifest schema already exists)

### 2. `docs/meta-factory/principles-as-tests.md` — catalog

Format:

```markdown
# Principles as Tests — Catalog

> Status: Phase 2 deliverable, 2026-05-07
> Phase 2 scope: principles testable against rules-manifest.json без Phase 3+ infrastructure

## Principle 1 — Every rule has executable check

**Source:** [overview.md Layer 2](...)
**Test file:** [01-executable-check.test.ts](../../tests/principles/01-executable-check.test.ts)
**Manifest field checked:** `check.type` ∈ {"eslint", "manual", ...}
**Pass criterion:** all rules have either `check.type` or explicit `manual: true` with rationale field
**Mutation test:** removes `check` field → expect assertion fail
**Currently passing:** N/M rules (computed at retro time)
**Known exceptions:** ...

## Principle 2 — Paired negative test
...

## Known limitations (Phase 2 explicit deferrals)

### Out of scope per Guardrail 1

- **AST > grep validator runtime** — Phase 5 (validator) deliverable. Phase 2 covers только structural check `rule.check.type === "eslint"`.
- **Mutation kill rate ≥70%** — Phase 5 (Stryker integration). Phase 2 covers anti-tautology of meta-tests themselves, не of underlying ESLint rules.
- ...
```

Размер: ≤500 строк (соблюдаем invariant — это shipped reference doc).

### 3. Integration

- `scripts/package.json`: add script `"test:principles": "vitest run tests/principles/"`
- `Makefile`: extend `self-audit` target
- `.husky/pre-push`: add `npm --prefix scripts run test:principles` step (≤5s budget — vitest run быстрый)
- `.github/workflows/audit-self.yml`: new job `principles-meta-tests` (similar pattern as `manifest-render-check`)

### 4. Phase 2 retro `docs/meta-factory/retros/phase-2.md`

Standard format (Verification / Self-reflection / Evaluation), плюс **mandatory sections**:

- **Threshold qualification table** (Guardrail 3): per-principle pass rate, applicable rules, composite rate
- **Mutation verification status** для каждого meta-test (Guardrail 2): mutation test exists? mutation actually fails? evidence (vitest output snippet).
- **Out-of-scope deferrals** explicit list (Guardrail 1): какие принципы deferred + Phase target.
- **REVISE/STOP trigger check** (Guardrail 4): «≥30% rules fail any meta-test? — yes/no with numbers».
- **Time-vs-plan ratio reality check:** Phase 2 = discovery-heavy, expected ratio ~0.2-0.5x (vs Phase 1's 0.01x). Actual ratio + RCA if >2x (>14 days).

---

## Verification (запускаешь после создания)

```bash
# 1. All tests pass
cd /Users/art/code/rules-as-tests-aif/scripts && npm test

# 2. Mutation tests reachable: temporarily break a rule в manifest copy → meta-test should fail
cp /Users/art/code/rules-as-tests-aif/factory/rules-manifest.json /tmp/manifest-orig.json
# ... mutation experiment per principle ...

# 3. principles-as-tests.md ≤500
wc -l /Users/art/code/rules-as-tests-aif/docs/meta-factory/principles-as-tests.md

# 4. Required principle count
grep -c "^## Principle" /Users/art/code/rules-as-tests-aif/docs/meta-factory/principles-as-tests.md
# expect: ≥7 (5 fully IN + 2 partial)

# 5. Pre-push integration
bash -n /Users/art/code/rules-as-tests-aif/.husky/pre-push

# 6. CI YAML valid
python3 -c "import yaml; yaml.safe_load(open('/Users/art/code/rules-as-tests-aif/.github/workflows/audit-self.yml'))"
actionlint /Users/art/code/rules-as-tests-aif/.github/workflows/audit-self.yml

# 7. Composite pass rate
# pseudo: read manifest, for each rule, for each applicable principle, run check
# report composite pass rate
```

---

## Hard constraints

- **NO `git commit --no-verify`** — нарушает self-application principle
- **NO `git push`** — orchestrator decides push timing
- **NO new principles outside list** without explicit rationale в retro
- **NO scope creep** Phase 2 → Phase 3 (split) infrastructure assumptions
- **NO Stryker / runtime ESLint** в Phase 2 tests (Guardrail 1)
- **Pinned SHAs** в новых YAML changes (use existing `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683`)
- **Real filenames** per MAJOR-2 fix: `skills/rules-as-tests/SKILL.md`, `skills/rules-as-tests/references/overview.md`, `skills/rules-as-tests/references/ai-traps.md` (no phantom `principles.md`)
- **Independent verification** required — каждое claim в return report должен быть verifiable через grep/test/wc, не trust-by-narration (per Phase 1.C + Phase 1.D over-claim pattern)

---

## Возврат результата

Структурированный report (под 600 слов):

1. **Created/modified artifacts** список с line counts
2. **Verification results** все 7 probes
3. **Composite pass rate table** (Guardrail 3): N rules total, per-principle pass rate, composite applicable rate
4. **Mutation verification evidence** для каждого meta-test (Guardrail 2): vitest output snippet showing mutation actually fails
5. **Out-of-scope deferrals** (Guardrail 1): какие принципы deferred + Phase target + rationale
6. **REVISE/STOP trigger check** (Guardrail 4): «≥30% rules fail? composite < 80%?» — yes/no with numbers
7. **Findings for Phase 2 retro:** что обнаружилось discovery-heavy work
8. **Commit hashes**
9. **Open questions for orchestrator:** decisions taken self с rationale (особенно при ambiguity в principle interpretation)

**Hard requirement:** if return report claims «mutation test passes» — provide vitest output snippet as evidence. If claims «N/M rules pass principle X» — provide command to verify (e.g., `npm test -- --reporter=verbose 01-executable-check`). Trust-but-verify pattern enforced.

---

## Версия

- **0.1.0** — 2026-05-07 — first version, embeds Art's Phase 2 alignment review guardrails.

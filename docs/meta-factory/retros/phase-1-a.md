# Retro: Phase 1 batch 1.A — Local enforcement

**Status:** GO
**Closed at:** 2026-05-07
**Time spent:** ~4 минуты (planned: 1 день)
**Commit:** `fea6ea7 feat(self-application): Phase 1.A local enforcement (.husky/ + CI gate)`

---

## Verification

### Mechanical

| Команда | Expected | Actual | Result |
|---|---|---|---|
| `test -x .husky/pre-commit` | exit 0 | exit 0 | ✓ |
| `test -x .husky/pre-push` | exit 0 | exit 0 | ✓ |
| `bash .husky/pre-commit` (clean HEAD, no staged) | exit 0 silent | exit 0 silent | ✓ |
| `wc -l Makefile` | exists | 14 строк | ✓ |
| `wc -l CONTRIBUTING.md` | ≤500 | 94 строки | ✓ (within 500-line invariant) |
| YAML syntax `audit-self.yml` | passes `yaml.safe_load` | passes | ✓ |
| `enforce-husky-presence` job uses real pinned SHA | not fabricated | `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683` (v4.2.2) | ✓ |

### Negative tests (run by subagent during delegation)

- Staged file with `bash -n` violation (`if [ missing_bracket`) → hook rejected with `❌ Bash syntax error in scripts/test-broken-temp.sh` ✓
- Note: `broken bash {{` is **valid** bash (subagent's first attempt) — `bash -n` doesn't catch syntactically valid but semantically broken commands. Real syntax errors are caught.

### Decision matrix coverage

| Probe | Layer | Implementation | Verdict |
|---|---|---|---|
| Bash syntax | pre-commit MUST | `bash -n` per changed `*.sh` | ✓ |
| JSON validity | pre-commit MUST | `python3 json.load` | ✓ |
| YAML validity | pre-commit MUST | `python3 yaml.safe_load` | ✓ |
| Markdown ≤500 | pre-commit MUST | `awk` | ✓ |
| actionlint | pre-push MUST | hard fail with install instructions if missing | ✓ |
| zizmor plain | pre-push MUST | hard fail with install instructions if missing | ✓ |
| Self-test pipeline | pre-push SHOULD | `audit-ai-docs.test.sh` | ✓ |
| Manifest render drift | pre-push SHOULD | `render-rules.ts --check` (flag confirmed exists) | ✓ |
| Spec validation (SHAs) | pre-commit MAY | — | deferred to Phase 1.C |
| Framework-self-install | CI MAY | — | deferred to Phase 1.B |
| Enforce husky presence | CI gate (Phase 1.A scope expansion per PROPOSAL §13.9) | new `enforce-husky-presence` job | ✓ |

---

## Self-reflection

### Совпадает ли `.husky/pre-commit` с template?

**Major divergence по дизайну.** Template (`templates/shared/husky-pre-commit.sh`, 7 строк) делегирует в `npx lint-staged`. Author-hook (56 строк) — direct probes без lint-staged. Причина: репо автора **не имеет** lint-staged config; consumer-репо (предполагается) **имеет**. Это **не bug**, а structural difference в audience.

**Но:** template для consumer'а **проще** чем нужно. Если consumer не имеет lint-staged-config, hook ничего не делает. Это **скрытый failure mode** consumer template'а — не закрывает self-application gap для consumer'а аналогично тому как author-hook закрывает для author'а.

**Action item для Phase 1 composite retro:** template `husky-pre-commit.sh` должен быть улучшен (Phase 1.B candidate?) добавлением direct probes (bash/JSON/YAML/markdown) **до** делегации lint-staged'у. Это closes consumer-side gap аналогично author-side.

### Какие probes на pre-push, не pre-commit

Cost-budget alignment correct:
- pre-commit total: ~400ms (4 probes × <100ms)
- pre-push total: ~10s (actionlint 200ms + zizmor 3s + audit-ai-docs 5s + render-rules 2s)

Соответствует Decision matrix §3 self-application.md (pre-commit <5s, pre-push ≤30s).

### `git config core.hooksPath` vs husky npm-package

**Выбран `core.hooksPath`** (native git ≥2.9). Justification:
- Репо без root `package.json` — добавление husky требовало бы npm setup overhead
- `core.hooksPath` zero runtime deps, identical mechanism
- Trade-off: contributor должен запустить `make install-hooks` манually вместо `npm install` triggering автоматически через `prepare`

**Decision корректен.** Если в будущем добавится root `package.json` (например, в Phase 3 monorepo split с workspace root) — можно мигрировать на husky без потери функциональности.

### Соблазн «сделать на потом»

- ✅ Не возникло soblazn'а pomyatь corner cases (template divergence honestly documented как finding)
- ⚠ **One judgment call:** subagent decided NOT добавлять `--soft` mode для `make self-audit` чтобы не ослаблять hard-fail policy. Я как orchestrator **подтверждаю** это решение — soft mode противоречит Decision matrix MUST/SHOULD policy.

### Unknown unknowns

- **`bash -n` syntactic limits.** `bash -n` не catch'ит valid syntax с broken semantics (например, `broken bash {{` парсится как command `broken` с argument `bash` и unbalanced braces — но braces валидны в bash). Это known limitation `bash -n`, not hook bug. Worth documenting в hook comments или test plan для будущих рефакторингов.
- **CI gate `enforce-husky-presence` использует grep на pre-existing keywords** (`actionlint|zizmor|bash -n|json\.load|yaml\.safe_load`). Если в будущем hook переписан на Node.js (без python3) — gate ложно fail'нет потому что grep не найдёт `yaml.safe_load`. **Risk** для Phase 1 composite retro: gate-trigger keyword list нужно держать synchronized с реальной hook implementation. Кандидат для §13 PROPOSAL.

---

## Evaluation

### Self-application score: 8/10

Plan §6 Phase 1.A evaluation: «Self-application score: 7/10 (применён, но без CI gate, проверяющего наличие .husky/)».

**Actual: 8/10** (выше plan'a на 1 пункт) потому что:
- ✅ CI gate `enforce-husky-presence` добавлен — закрывает «без CI gate» qualification
- ✅ Multiple probes теперь блокируют commit/push — automatic enforcement, не manual review
- ✅ Negative test verified (broken bash blocked)
- ❌ Но: bypass через `--no-verify` всё ещё possible локально (CI gate ловит post-push, не pre-bypass)
- ❌ Spec discipline (Phase 1.C) ещё не интегрирован — частичное self-application

### Time-vs-plan ratio: ~0.05x

Planned: 1 день. Actual: ~4 минуты subagent + ~5 минут verification orchestrator. Ratio ≪ 0.5x, RCA не требуется.

**Insight:** subagent с full context был efficient. Verification commands (negative test, YAML syntax check, executable bit) — automated. Это переcalibration data point: Phase 1 batch'и могут идти быстрее чем planned.

**Caveat:** не extrapolating 0.05x ratio на Phase 1.B (framework-self-install — runtime test, требует tmp-dir setup, потенциально slower).

### New risks identified

| Risk | Where to add |
|---|---|
| Consumer template `husky-pre-commit.sh` не закрывает consumer-side gap (lint-staged-only) | §13 PROPOSAL or Phase 1.B candidate |
| `enforce-husky-presence` keyword grep diverges from hook implementation | §13 PROPOSAL §13.10 candidate |
| `bash -n` не catch'ит валидный syntax с broken semantics | CONTRIBUTING.md note или skill memory |

### Verdict: GO

Все verification gates ✓. Phase 1.A acceptance criterion met:
- Author не может закоммитить нарушение (broken bash blocked локально) ✓
- CI gate enforce-husky-presence добавлен (--no-verify bypass made visible) ✓
- Decision matrix MUST + SHOULD rows covered ✓

**GO к Phase 1 batch 1.B** (framework-self-install CI job).

**Pre-Phase-1.B action items:**

1. Закоммитить этот retro перед стартом 1.B
2. (deferred) Document 3 new risks выше в PROPOSAL §13 на Phase 1 composite retro (не для каждого batch retrovsek'а, raznootnost'í budet'í в composite)

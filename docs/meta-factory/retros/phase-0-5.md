# Retro: Phase 0.5 — Documentation alignment

**Status:** GO
**Closed at:** 2026-05-07
**Time spent:** ~2 часа (planned: 1-2 дня)

> Phase 0.5 — fresh phase, introduced 2026-05-07 как closure self-application gap, между Phase 0 (legacy) и Phase 1 (umbrella `chore/self-application`). Не было в первой версии плана; добавлена в EXECUTION-PLAN v0.1.0 после 7 итераций обсуждения и закреплена в PROPOSAL §10 в этой фазе.

---

## Verification

### Mechanical gates

| Команда | Expected | Actual | Result |
|---|---|---|---|
| `wc -l docs/meta-factory/self-application.md` | ≤500 | 171 | ✓ |
| `grep -c "Self-application\|self-application" docs/meta-factory/PROPOSAL.md` | ≥3 | 10 | ✓ |
| `grep -n "^## 15\." docs/meta-factory/PROPOSAL.md` | exists | matches §15 | ✓ |
| `grep -n "0.5" docs/meta-factory/PROPOSAL.md \| head -1` | Roadmap row exists | line 518 | ✓ |
| `wc -l docs/meta-factory/PROPOSAL.md` | ≤750 (was 709 + ~30) | 731 | ✓ (within budget) |
| `wc -l docs/meta-factory/EXECUTION-PLAN.md` | grew from v0.1.0 closure of 8 findings | 691 (was 665, +26) | ✓ |

### Fresh-session test

**Probe:** subagent (general-purpose, fresh context) с промптом «Прочитай только PROPOSAL.md. Перечисли архитектурные invariants мета-фабрики».

**Subagent output (key excerpt):**
> «**Cross-cutting invariants:**
> 6. Self-application действует с момента 0 — каждый слой применяет принципы к самому себе в CI, а не только при установке у потребителя.»

**Pass criterion:** self-application фигурирует как cross-cutting invariant. **PASSED** — subagent самостоятельно категоризировал invariants на «Structural» vs «Cross-cutting» (категоризацию я не запрашивал) и поместил self-application в cross-cutting bucket. Это сильнее чем требуемый minimum.

### Diff состояний

```
git log --oneline phase-0-5-start..phase-0-5-end (после commit'а)
```
Будет: один commit `chore(self-application): close 8 findings + Phase 0.5 docs alignment`.

### Artifacts shipped

- ✅ `docs/meta-factory/self-application.md` (171 строка, 8 секций per Phase 0.5 step 1 spec)
- ✅ `docs/meta-factory/PROPOSAL.md` v0.2.0-draft: §15 short pointer (15 строк), §6 переписан (invariant с момента 0, §6.3 mandatory), §10 Phase 0.5 row + примечание
- ✅ `docs/meta-factory/EXECUTION-PLAN.md` v0.1.1: 8 findings closed
- ✅ `docs/meta-factory/retros/EXECUTION-PLAN-review-2026-05-07.md` + Resolution log + followup APPROVE
- ✅ `docs/meta-factory/retros/phase-0-5.md` (этот файл)

---

## Self-reflection

### Сравнение v0.1.0-draft → v0.2.0-draft PROPOSAL — смена приоритета или патч?

Per Phase 0.5 self-reflection bullet, diff должен быть **смена приоритета**, не патч.

**Анализ:**
- §6 был **«Acceptance test = self-test через 5 слоёв»** → стал «invariant с момента 0, не после установки». Это **смена приоритета** от «verification step at install time» к «structural property of every commit». Качественное изменение, не дополнение.
- §15 (новый) — short pointer, не дублирующий контент, а **возводящий** self-application к top-level invariant'у. До v0.1.0 self-application фигурировал только в §6.3 как «дополнительный инвариант» core. Сейчас — структурный.
- §6.3 «дополнительный» → «обязательное (mandatory)». Прямая смена нормативного класса.

Заключение: **смена приоритета**, не патч. Verdict requirement met.

### Что не получилось зафиксировать — кандидаты в §13 «Открытые вопросы»

1. **Self-application для Layer 2 (Research Agent).** В invariant table §15 PROPOSAL и self-application.md §2 acceptance criterion для L2 формулируется как «все три источника семантически синхронизированы; drift detection возвращает 0 расхождений». Но **что значит «семантически синхронизированы»**? Operationalization (как именно мерить semantic drift между principles.md, ai-traps.md, SKILL.md) — не определено. Кандидат в §13.7 PROPOSAL.
2. **Granularity decision matrix (§3 self-application.md).** Decision matrix перечисляет 9 layers (bash, YAML, JSON, markdown, actionlint, zizmor, self-test, manifest drift, spec validation). Но что делать когда добавится 10-й? Правило expansion'а matrix'а не зафиксировано. Кандидат в §13.8.
3. **Bypass через `--no-verify`.** Plan §6 Phase 1.A self-reflection упомянул это как «Risk», но **mitigation не описан**. Если автор всегда может обойти hooks — invariant decoративен. Кандидат в §13.9 + Phase 1.A scope expansion?

Эти 3 пункта **не блокируют** GO Phase 0.5, но требуют документации в §13 PROPOSAL до старта Phase 1 (либо как explicit deferred, либо как scope-expansion для Phase 1).

### Есть ли архитектурные invariants, которые я пропустил?

Fresh-session test даёт independent baseline. Subagent перечислил 10 invariants, разделил на «structural» (5) и «cross-cutting» (5). Все 10 присутствуют в PROPOSAL.md. Категория **«self-application»** на cross-cutting уровне — закрыта (§15 + §6 переписан).

**Кандидаты на пропуск (subagent НЕ упомянул):**
- **Atomicity invariant** (§5.3 PROPOSAL: atomic file writes через temp+rename) — структурное свойство installer'а, но не выделено как top-level invariant.
- **Stateful resume** — описан в §5.1 как реализационная деталь, но invariant'а («любая длительная операция должна быть resumable») не формализован.

Это **минор**, не block Phase 0.5. Кандидаты в §13 PROPOSAL для Phase 1 retro.

### Был ли соблазн что-то «сделать на потом»

- ✅ Не возникло soblazn'а добавить полный §17 контент в PROPOSAL (обработано M1 fix'ом — short pointer)
- ✅ Не возникло соблазна обойти Phase 0.5 fresh-session test (выполнен subagent'ом, результат принят независимо)
- ⚠ **Один deferred:** §13.7-9 PROPOSAL (3 кандидата выше) — добавлены в текстовый retro, но **не записаны в PROPOSAL.md §13** в этой фазе. Risk: на Phase 1 retro могу забыть. **Mitigation:** явно перечислены здесь в retro; при чтении этого retro перед Phase 1 retro вопросы вернутся в фокус.

### Unknown unknowns

- **Subagent категоризировал invariants без подсказки.** Не очевидно было что «structural vs cross-cutting» — natural reading PROPOSAL.md. Это сигнал что текст PROPOSAL стал более structurally legible после §15. Insight: добавление top-level §17/§15 имеет emergent эффект — переориентирует читателя, не только добавляет контент.
- **PROPOSAL.md вырос всего на +21 строку** (709 → 731) при содержательной qualitative смене. Это потому что §15 — pointer, а не дублирование. M1 fix имел больший эффект чем ожидал — не только избежали violation, но и сделали §15 более читабельным (короткий pointer быстрее понять, чем длинный self-contained раздел).

---

## Evaluation

### Self-application score: 4/10

Plan §6 Phase 0.5 evaluation: «Self-application score: 2/10 (документация, тут self-application проявляется только через executable verification)».

**Actual: 4/10.** Выше ожидания на 2 пункта потому что:
- ✅ Phase 0.5 itself has 3 executable verification gates (`wc -l`, `grep -c`, fresh-session test) — не «manual review»
- ✅ Fresh-session test — это **executable proof** что текст работает as documentation. Это редкий случай когда documentation phase сама по себе self-applies.
- ❌ Но: всё ещё нет automated enforcement в pre-commit/pre-push. Эти gate'ы манифестируются только в Phase 1.
- ❌ Ничто пока не блокирует автора повторно создать out-of-date план типа v0.1.0. Этот гарантия появится в Phase 1.C (spec validation).

### Time-vs-plan ratio: ~0.1x

Planned: 1-2 дня. Actual: ~2 часа (от старта Stage 1 review до завершения retro). Ratio ≪ 1, RCA не требуется (RCA mandatory только при >2x).

**Insight:** недооценил эффективность Agent tool delegation для mechanical synthesis из существующих artifacts. Phase 0.5 step 1 (171-строчный документ) занял 2.5 минуты у subagent'а, потому что reference files были relatively self-contained. Это переcalibration data point для будущих фаз — mechanical edits быстрее чем казалось.

**Caveat:** Phase 1+ scope (`.husky/`, новые workflow jobs, `Makefile`, `CONTRIBUTING.md`) включает не только mechanical synthesis, но и **runtime verification** (что hook реально срабатывает на тестовом сценарии). Runtime verification — медленнее. Не extrapolating 0.1x ratio на Phase 1.

### New risks identified

| Risk | Where to add |
|---|---|
| L2 Research Agent semantic drift detection не operationalized | §11 PROPOSAL row + §13.7 |
| Decision matrix expansion rule не определён | §13.8 |
| `--no-verify` bypass — invariant декоративен без mitigation | §11 PROPOSAL + Phase 1.A scope |

**Action item для Phase 1:** перед стартом Phase 1.A — добавить эти 3 риска в `PROPOSAL.md §11` и `§13`. Это часть Phase 1 batch 1.A scope, не extra phase.

### Verdict: GO

Все три gate'а Phase 0.5 verdict gate (per §6 EXECUTION-PLAN) пройдены:

1. ✅ `wc -l self-application.md` = 171 ≤500
2. ✅ `grep -c "Self-application" PROPOSAL.md` = 10 ≥3
3. ✅ Fresh-session test passed (cross-cutting categorization самостоятельно появилась)

**GO к Phase 1 batch 1.A** (Local enforcement: `.husky/pre-commit`, `.husky/pre-push`, `Makefile`, `CONTRIBUTING.md`).

**Pre-Phase-1 action items (закрыть до старта batch 1.A):**

1. Закоммитить все Phase 0.5 artifacts одним commit'ом в ветку `chore/self-application`
2. Добавить 3 deferred risks в PROPOSAL §11/§13 (mini-edit ≤20 строк)
3. Получить ok-to-proceed от Art'а (Phase 1 = 3-5 дней, signal point per communication protocol)

---

## Addendum 2026-05-07 (post-retro write, pre-commit)

**Action item #2 → DONE.** 3 deferred risks закрыты в этом же commit'е перед Phase 1:

- **PROPOSAL.md §11 +2 строки:** L2 semantic drift (мiitigation: Phase 6 deliverable + manual review до этого), `--no-verify` bypass (mitigation: CI gate на наличие `.husky/` директории + framework-self-install passing)
- **PROPOSAL.md §13.7** Operationalization L2 semantic drift detection (3 кандидата операционализации, decision postponed to Phase 6)
- **PROPOSAL.md §13.8** Decision matrix expansion rule (4-criteria gate для добавления 10-го layer'а, decision при первом expansion'е)
- **PROPOSAL.md §13.9** Bypass через `--no-verify` — структурное решение (CI gate hypothesis для Phase 1.A scope)

**Effect on Phase 1 scope:** §13.9 явно говорит что CI gate на `.husky/` directory existence — это **scope expansion для Phase 1.A**. Phase 1.A теперь должен включать **ещё одну job в `audit-self.yml`** — проверка что в репо автора есть non-empty hooks. Это незначительное расширение (~10 строк YAML), но фиксируется здесь чтобы не упустить.

**Action item #3 (ok-to-proceed) — Art сказал «без паузы, проверь сам».** Self-review перед Phase 1 — мой ответственность, не Art'а. Self-review будет третьим коммитом если найдутся issues; если нет — старт Phase 1 batch 1.A в этом же session'е.

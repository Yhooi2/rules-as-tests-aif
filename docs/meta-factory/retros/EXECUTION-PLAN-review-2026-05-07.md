Чт# EXECUTION-PLAN review — 2026-05-07

> **Verdict:** REVISE
> **Reviewer:** Opus 4.7 orchestrator (fresh session, sceptic mode)
> **Plan version reviewed:** v0.1.0 (2026-05-07)
> **Files read in order:** EXECUTION-PLAN.md (665 lines), PROPOSAL.md (709 lines), docs/audits/2026-05-07-self-application-gap.md (82 lines)

---

## Method

Прошёл по 6 категориям раздела 10 EXECUTION-PLAN + 6 red-team checks из ORCHESTRATOR-START-PROMPT. Verification команды из плана раздел 2 проверял через `ls`/`grep`/`git`. Vepdict на основе severity findings: BLOCKER → REJECT, любой BLOCKER или ≥3 MAJOR → REVISE, иначе APPROVE.

---

## BLOCKER findings (1)

### B1 — Plan section 2 state claim полностью устарел; ветка уже merged в main

**Claim (EXECUTION-PLAN.md:26):** «Branch: `feat/audit-fixes-2026-05` (13 коммитов ahead of origin/main, не запушен)».

**Reality (verified 2026-05-07):**

- `git rev-list --count origin/main..feat/audit-fixes-2026-05` = **0**
- `git status` → up-to-date with `origin/feat/audit-fixes-2026-05`
- `origin/main` HEAD = `35ab3f9 Merge pull request #1 from Yhooi2/feat/audit-fixes-2026-05`

PR #1 уже merged. Plan был написан до merge'а и не обновлён. Это блокер потому что весь Phase 1 plan (husky hooks, framework-self-install, spec validation) — это ровно тот scope, который self-application-gap.md описывает как proposed follow-up umbrella `chore/self-application`. Этот umbrella должен идти **отдельной веткой после merge'а PR #1**, не доработкой merge'd ветки. Если стартовать Phase 0.5 на `feat/audit-fixes-2026-05` — мы будем коммитить в уже-merged ветку, что нарушает git hygiene и создаёт divergence.

**Что нужно:**

- Обновить EXECUTION-PLAN.md раздел 2 под реальное post-merge состояние
- Создать новую ветку (predлoжение: `chore/self-application` per self-application-gap.md, либо `feat/meta-factory-phase-0-5`)
- Зафиксировать в плане какие artifacts из текущей ветки (untracked `docs/meta-factory/`, `.claude/`) переезжают в новую ветку

---

## MAJOR findings (3)

### M1 — Phase 0.5 step 2 ухудшает self-application к собственному PROPOSAL.md

**Plan §6 Phase 0.5 step 2:** «Добавить §17 Self-application as architectural invariant в PROPOSAL.md».
**Reality:** PROPOSAL.md уже **709 строк**. Plan'овый invariant: «no markdown >500 lines» (применяется к shipped framework docs, но PROPOSAL.md не помечен как transient artifact — в отличие от EXECUTION-PLAN.md, который явно self-помечен в строке 8).
**§14.1 PROPOSAL.md** уже сам предусматривает split на 9 sub-документов («architecture.md», «versioning.md», etc.).

Phase 0.5 step 2 добавит ещё одну секцию в already-violating документ. Само Phase 0.5 — про «documentation alignment». Если Phase 0.5 нарушает invariant, который Phase 0.5 же декларирует, то retrospective gate Phase 0.5 (verification: «`grep -c "Self-application" PROPOSAL.md` ≥3») всё равно пройдёт — но self-application к плану нарушено.

**Что нужно:** Phase 0.5 step 2 переформулировать. Варианты:

- §17 как **ссылка** в PROPOSAL.md (3-5 строк pointer'а на standalone `self-application.md`), без полного контента
- Запустить split PROPOSAL → architecture.md + других sub-документов **в Phase 0.5**, не откладывать на potом
- Явно пометить PROPOSAL.md как transient pre-1.0 RFC и обновить invariant до «применяется к docs/ только после релиза 1.0»

### M2 — Line numbers в плане устарели; verification команды без точечной проверки

**Plan claims:**

- §2 «`@next/eslint-plugin-next@^15.0.0` в `setup.sh:169`» — реально на строке **257** (off by 88)
- §2 «templates шипятся consumer'у через `install.sh:127`» — реально husky copy на строках **171-174** (off by 44)

Line numbers в плане не проверены через `grep -n` перед commit'ом. Это та же категория ошибки, которую план хочет ловить (фейковый SHA в batch-D.md). Self-application к плану нарушено.

**Что нужно:** перед стартом Phase 0.5 — обновить все line numbers в EXECUTION-PLAN.md через `grep -n`, либо удалить line numbers и оставить только file names + grep-pattern (чтобы не привязываться к версии).

### M3 — Зависимости Phase 2 → Phase 3 → Phase 4 over-sequential

**Plan §6:** Phase 2 (principles meta-tests) → Phase 3 (monorepo split) → Phase 4 (Stack Detector v1).
**Reality:**

- Phase 2 принципы — извлекаются из `skills/rules-as-tests/references/*.md` и формализуются как тесты против `factory/rules-manifest.json`. **Не зависит** от monorepo split.
- Phase 4 Stack Detector — `setup.sh:80-102` + `scripts/detect-applicable-rules.ts` уже работают в текущей структуре. Доработка version-aware logic возможна in-place.

Только Phase 3 (split) реально блокирует, что **финальный shape** Phase 2/4 артефактов попадёт в `packages/core/`. Но **разработка** Phase 2 и Phase 4 может идти параллельно с Phase 3.

**Что нужно:** Cumulative timeline §8 пересчитать с учётом параллелизма. Realistic estimate: Phase 2/3/4 параллельно = 2 недели вместо последовательных 4. Либо явно сказать «not parallelized for cognitive load reasons».

---

## MINOR findings (4)

### m1 — Phase 1 stop-rule «не закрыто за 7 дней → root cause analysis» не определяет RCA

§8 cumulative timeline ссылается на RCA при overrun >2x time, но процедура RCA не описана. В практике это означает либо «retrospective с расширенной self-reflection», либо «новый план целиком». Без определения — dead text.

**Fix:** добавить в §5 «Стандартный retrospective gate» формат RCA section (3-5 пунктов: failed assumption / surprise / what we learned / scope change / next probe).

### m2 — Evaluation thresholds (30%, 80%, 5%, 15%, $5) — без обоснования

Phase 2 «≥80% правил проходят meta-tests», Phase 7 «diff на canonical regen ≤5%», Phase 8 «diff с manual ≤15% И стоимость ≤$5» — числа произвольные. Acceptable для transient plan, но caveat нужен.

**Fix:** один раз сказать в §5 — «numerical thresholds are initial guesses; adjusted at first retrospective with rationale».

### m3 — Phase 1.C self-reflection вопрос смешивает разные viды references

Plan §6 Phase 1.C self-reflection: «Применима ли spec validation к references в SKILL.md (skill X → references/X.md)?». Это смешивает:

- SHA-validation для GitHub action references (`owner/repo@SHA`) — то, что валидирует gh api
- Intra-skill paths (`references/X.md`) — это relative file paths, валидируются `test -f`, не gh api

Логически разные probes. Self-reflection вопрос плохо сформулирован.

**Fix:** разделить вопрос на два separate probes в §6 Phase 1.C.

### m4 — План не явно говорит «no consumers yet»; multi-month plan только для proof-of-concept

Plan §10.5 в fresh-review checklist спрашивает это, но в самом плане ни §1, ни §10 не делают явного statement: «у пакета нет downstream consumers, поэтому 4-month plan justified только как proof-of-concept для self-validation тезиса». Это важно для priority decisions внутри фаз (если consumer'ов нет — некоторые decisions можно отложить).

**Fix:** добавить в §1 одно предложение — «As of 2026-05-07 the package has no downstream consumers; this plan is justified as a proof-of-concept for the recursive-self-validation thesis, not as user-driven roadmap».

---

## Что прошло проверку

- ✅ `.husky/` отсутствует (state claim VERIFIED)
- ✅ `templates/shared/husky-pre-commit.sh` и `husky-pre-push.sh` существуют
- ✅ `factory/rules-manifest.json` (280) + `rules-manifest.schema.json` (63) существуют
- ✅ `templates/shared/eslint-rules/` — 7 правил с paired tests существуют
- ✅ `scripts/render-rules.ts`, `scripts/detect-applicable-rules.ts` — существуют
- ✅ `tests/audit/audit-ai-docs.test.sh` — существует
- ✅ EXECUTION-PLAN.md self-flagged как transient artifact в строке 8 (acknowledged self-violation, OK)
- ✅ Self-application gap (4 layers) — точно описан, фактологически правильно
- ✅ Decision matrix Phase 1 (раздел 7) — costs реалистичные (actionlint 200ms, zizmor 3s — соответствуют наблюдаемым в PR #1 timeline из self-application-gap.md)
- ✅ Phase 0.5 fresh-session test (read PROPOSAL.md, list invariants) — методологически правильный probe (PROPOSAL.md действительно сейчас не презентует self-application как top-level invariant — Phase 0.5 правильно identifies the gap)

---

## Resolution path

Plan structurally sound. Goal correctly framed (recursive self-application). Phase decomposition reasonable. **Не REJECT**.

REVISE = needs targeted updates перед стартом Phase 0.5:

1. **B1 fix** — обновить §2 plan, создать новую ветку для self-application umbrella
2. **M1 fix** — переформулировать Phase 0.5 step 2 (либо §17 как pointer, либо split PROPOSAL в Phase 0.5)
3. **M2 fix** — обновить line numbers в §2 через `grep -n`
4. **M3 fix** — пересчитать cumulative timeline с явным указанием parallelism (или rationale почему sequential)
5. **m1-m4** — желательно одним коммитом вместе с B1/M1-3, но не блокирующее

После применения fix'ов — повторный self-review (≤15 строк, focus только на applied changes), затем APPROVE → Phase 0.5 step 1.

---

## Stop point per plan contract

Plan §10 Stage 1 contract: «Если REVISE — записать список findings, сообщить Art'у, **остановиться и ждать его решения** (не делать revisions самостоятельно)».

**Я останавливаюсь.** Решение Art'а:

- (A) применить fix'ы B1/M1/M2/M3 к плану (silent acknowledgement m1-m4) — затем self-re-review → Phase 0.5
- (B) accept findings as known issues, продолжить Phase 0.5 на текущем плане — записать в Phase 0.5 retro как known limitations
- (C) переписать план с нуля под актуальное post-merge состояние

---

## Resolution log (2026-05-07, post Art's decision)

**Art's decision:** вариант (A) расширенный — закрыть **все 8 findings** в одном commit'е, без deferred items. Rationale: M3 и m1-m4 fixes дешёвые (~25 строк суммарно), tracking-механизмы для deferred items стоили бы примерно столько же + cognitive overhead в каждой fresh session + риск пропуска. «Закрыто» лучше «отслеживается».

| Finding | Status | Resolution |
|---|---|---|
| **B1** — stale state claim, ветка merged | CLOSED | Создана новая ветка `chore/self-application` от `main` (post-merge `35ab3f9`). EXECUTION-PLAN.md §2 переписан под post-merge state с явной ссылкой на B1 finding и упоминанием PR #1. |
| **M1** — Phase 0.5 step 2 ухудшает PROPOSAL.md violation | CLOSED | EXECUTION-PLAN.md §6 Phase 0.5 step 2 переформулирован: §17 в PROPOSAL.md = **short pointer ≤15 строк** (тезис + invariant table + ссылка на standalone `self-application.md`). Полный контент НЕ дублируется в PROPOSAL. |
| **M2** — line numbers устарели | CLOSED | Все line refs обновлены через `grep -n`: `setup.sh:80-102` → `:82-97` (2 места в EXECUTION-PLAN), `install.sh:127` → `:171-174` (EXECUTION-PLAN §2), `setup.sh:169` → `:257` (PROPOSAL.md §1.1). |
| **M3** — Phase 2/3/4 over-sequential | CLOSED (вариант b) | EXECUTION-PLAN.md §6 — добавлен **Parallelism note** в начало раздела: знание о возможном параллелизме зафиксировано без commitment'а. Cumulative timeline §8 не тронут — остаётся консервативным upper bound. Решение «делать ли параллельно» — на Phase 1 retro по реальным данным. |
| **m1** — RCA не определён | CLOSED | EXECUTION-PLAN.md §5 — добавлен формат `## Root cause analysis` (5 пунктов: failed assumption / surprise / what we learned / scope change / next probe). Без всех 5 — verdict не может быть GO. |
| **m2** — thresholds произвольные | CLOSED | EXECUTION-PLAN.md §5 — добавлен Numerical thresholds caveat: все числовые пороги — initial guesses, на первом релевантном retro фиксируется rationale с записью в retro. |
| **m3** — Phase 1.C self-reflection mixes refs | CLOSED | EXECUTION-PLAN.md §6 Phase 1.C — вопрос разделён на Probe 1 (SHA validation для GitHub action refs через gh api) и Probe 2 (intra-skill paths через test -f). Логически разные probes. |
| **m4** — нет statement про no-consumers | CLOSED | EXECUTION-PLAN.md §1 — добавлен No-consumers caveat: 4-month plan justified как proof-of-concept для recursive-self-validation thesis, не user-driven roadmap. |

**Verdict transition:** REVISE → APPROVE pending self-re-review в `EXECUTION-PLAN-review-2026-05-07-followup.md`.

**Plan version bump:** v0.1.0 → **v0.1.1** (changelog в `docs/meta-factory/retros/CHANGELOG.md` будет создан при первом retrospective phase).

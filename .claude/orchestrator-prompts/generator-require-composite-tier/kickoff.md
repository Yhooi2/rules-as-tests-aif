# generator-require-composite-tier — umbrella kickoff

> **Статус:** ACTIVE — merged to staging, authorized for dispatch (maintainer overnight directive 2026-06-23). Следующая умбрелла генератора ПОСЛЕ `generator-forbid-mvp` (DONE, #696/#697).
> **For:** `/pipeline generator-require-composite-tier` → `/dispatcher generator-require-composite-tier`.
> **PR base:** `staging`. Стадия = PR; stage-gate (Phase -1 cold-review) между стадиями; авто-мёрж в staging после GO.
> **Карта:** `build-execution-map.md §10` (re-приоритизация после MVP) — планировочная папка `rules-as-tests/` (вне репо).
> **Доказательная база:** `build-plan-redteam-research.md` §A1/§A2+/§B2/§непокрытое-п.4; `RULES.md` всех пресетов; код `packages/core/eslint-rules/*`, `packages/preset-*/eslint-rules/*`, `synthesizer/recipe.schema.json`.

## §0 Что уже проверено vs что проверить ВНУТРИ исполнения

**Проверенные факты (grep по коду 2026-06-23 — можно опираться):**
- Ни одно правило репо не вызывает `parserServices`/`getTypeChecker` → **сейчас 0 type-aware правил** (даже `require-form-safe-parse` читает аннотацию `FormData` синтаксически).
- require-ярус самописный, не использует типы; `require-otel-span` = 120 LOC ручного обхода = `not(has())`.
- R10/R13/R18 в `RULES.md` помечены «manual review / no ESLint rule today»; R7 есть, но погашен (`AIF_STRICT_RUNTIME=1`).

**Гипотезы к ЭМПИРИЧЕСКОЙ проверке в S0 (НЕ принимать на веру — это и есть «проверить сначала внутри исполнения»):**
- Что R18 + `require-otel-span` требуют ast-grep, а `require-use-server`/`require-form-safe-parse`/R13 хватает esquery. ← **проверить 2-движковой матрицей на каждом правиле, как MVP S1b.**
- Что R10 (naming/path) не ложится в декларативный ярус.
- Что **G3b сейчас пуст** (нет правил, которым нужен вывод типов). ← S0 должен это подтвердить ИЛИ найти контрпример (правило, где синтаксиса недостаточно).

## §1 Goal (one line)

Расширить генератор с forbid на **require/presence-absence + композитный реляционный** ярус, движок по форме правила (esquery / ast-grep — выбор доказывается матрицей, не вкусом), закрыть незакрытые R13/R18 и мигрировать самописные require-правила в данные — **и одновременно подготовить почву под G3b**: общий engine-шов, `presence:"require"`-семантика и engine-agnostic anti-vacuity, в которые кодоген-движок (G3b) встанет как ещё один engine, плюс S0 определяет реальный scope G3b (правила, которым синтаксиса не хватает).

## §2 Stage map (stage-gated)

| Stage | Deliverable | Depends on | Acceptance (gate) |
|---|---|---|---|
| **S0 — DISCOVERY / VERIFY (R-phase, doc-output, BLOCKING)** | Аудит **ВСЕХ** правил **всех** пресетов (core, next-15, react-spa, react-native, microservices IR1-6) + `RULES.md`. Для КАЖДОГО кандидата — **2-движковая матрица** (esquery vs ast-grep, прогон на реальном/синтетическом примере): какой движок изолирует, какой over-flags. Найти **все** места, где ast-grep реально нужен (не только R18/otel-span). Отдельно пометить правила, где **синтаксиса недостаточно → нужен вывод типов = G3b-scope**. Output: research-patch `docs/meta-factory/research-patches/2026-..-engine-assignment-matrix.md`. | — (MVP DONE) | Таблица «правило → класс → движок → доказательство (вывод матрицы)» по всему корпусу; список ast-grep-нужных правил; **список G3b-триггеров (type-inference) с обоснованием почему синтаксиса мало**; вердикт по R10 (декларативно/кастом/manual). Никаких prose-only — каждая строка с прогоном (T3). Этот вердикт задаёт scope S1-S4. |
| **S1 — ast-grep раннер (adopt)** | Вкрутить ast-grep как engine (зависимость, пин версии); engine-agnostic исполнение в валидаторе; прогон на правилах, которые **S0 подтвердил** ast-grep-нужными. | S0 | ast-grep-правило компилируется из данных, гоняется через свой rule-test, проходит anti-vacuity engine-agnostic; `Prior-art:` трейлер ссылается на S0-матрицу + MVP S1b. |
| **S2 — `presence:"require"` семантика** | Расширить declarative-схему: `presence:"forbid"\|"require"` (require краснеет при ОТСУТСТВИИ); anti-vacuity адаптировать под require. **G3b-groundwork:** схема/валидатор проектируются так, чтобы кодоген-движок встал третьим engine без переделки. | S0 | declarative require-рецепт валиден; гейты ловят вакуумное require-правило (срабатывает всегда/никогда); snapshot зелёный. |
| **S3 — миграция самописных require → данные** | Мигрировать `require-otel-span`/`require-use-server-directive`/`require-form-safe-parse` в declarative-данные (engine по S0-вердикту); удалить самописные `.ts` ПОСЛЕ паритета. | S1, S2 | Байт-эквивалент поведения на существующих фикстурах; генератор — единственный писатель; самописный удалён только при зелёном паритете (T17/T18 — сохранить уникальный остаток, не слепо delete). |
| **S4 — закрыть R13 + R18** | Сгенерировать R18 + R13 (движок по S0); добавить в пресет; `RULES.md` строки «manual review» → enforced. | S0, S1, S2 | R18/R13 — сгенерированные правила с парными фикстурами, проходят anti-vacuity; RULES.md обновлён; провенанс на месте. |

**Stage-gate:** между каждой — Phase -1 adversarial cold-review (`reviewer-discipline.md §2`), GO/REVISE/STOP, 1 REVISE макс, CI-green ≠ design-review (T19). Авто-мёрж в staging после GO.

## §2.5 Подготовка к G3b (зачем эта умбрелла = on-ramp)

Эта умбрелла **не строит** G3b, но кладёт под него рельсы:
1. **Engine-шов обобщается до кодогена** — после S1/S2 добавить движок = добавить вариант в enum + раннер; кодоген (typescript-eslint codegen) встанет третьим, не ломая S3/S4.
2. **`presence:"require"` + engine-agnostic anti-vacuity** — type-aware правила G3b почти все require-класса; их валидация поедет на тех же гейтах.
3. **S0 определяет scope G3b** — список правил, где синтаксиса недостаточно (нужен вывод типов), — это и есть стартовый бэклог G3b. Если S0 найдёт 0 таких — G3b остаётся отложенным с доказательством «спроса нет».

## §3 Scope fence (hard)

**IN:** S0-S4 (аудит-матрица, ast-grep раннер, require-семантика, миграция 3 правил, R13/R18, G3b-groundwork-шов).
**OUT (observation only, не спавнить PR):**
- **Сам кодоген G3b** — не строить здесь; только определить scope (S0) и оставить шов (S2). Отдельная умбрелла по S0-бэклогу.
- **R7** — enablement-тумблер, не генерация.
- **R10 naming** — если S0 подтвердит «не декларативно» → кастом/скрипт, отдельно.
- LLM-черновик (G4), version-guard (G5), install-врезка (G6), полиглот-расширение ast-grep на non-TS/JS.

## §4 AI-laziness traps (`.claude/rules/ai-laziness-traps.md §2` — MANDATORY)

Active: **T1, T2, T3, T4, T5, T9, T11, T13, T14, T15, T16, T20**.

- **T1/T9** (sampling floor / не семплить лёгкое) — S0 аудитит **весь** корпус правил всех пресетов, не 3 удобных; floor = все заявленные R + IR.
- **T2/T3** (designing≠doing; no prose-only) — S0-матрица = реальные прогоны обоих движков, не «ast-grep наверное лучше».
- **T4** (premature close) — S0 adversarial «какое правило/класс я не проверил»; не закрывать пока весь каталог не в матрице.
- **T5** (no scope creep) — не строить G3b-кодоген (только шов+scope); не тащить R7/R10.
- **T13/T16** (ADOPTED≠zero-work; pattern-match по имени) — ast-grep adopt по S0-доказательству на КАЖДОМ правиле; «require-form-safe-parse звучит type-aware» — проверить: читает аннотацию синтаксически (T-RCT-A ниже).
- **T14/T15** (clean≠no-theatre; self-application) — каждое правило со своей paired-negative на свой engine.
- **T20** — выбор engine backed прогоном (матрица), не вкусом.
- **Domain T-RCT-A:** соблазн пометить `require-form-safe-parse` как G3b/type-aware. Counter: оно читает `tn.name==='FormData'` СИНТАКСИЧЕСКИ; S0 должен прогнать и подтвердить, что синтаксиса хватает (или честно найти случай, где нет → тогда это G3b-триггер).
- **Domain T-RCT-B:** «require = инверсия forbid» — неверно (require краснеет на отсутствии); anti-vacuity нельзя копировать слепо.
- **Domain T-RCT-C:** соблазн объявить «G3b пуст» не пройдя весь корпус. Counter: S0 обязан проверить каждое правило на достаточность синтаксиса; «0 G3b-триггеров» — вывод матрицы, не предположение.

## §5 TDD-обязанность
Failing-тест первым: S1 — ast-grep правило из данных краснит bad/молчит good (красный без раннера); S2 — require-рецепт валиден (красный без `presence:require`); S3 — мигрированное правило воспроизводит фикстуры самописного; S4 — R18 ловит `useQuery` без `.parse()`.

## §6 Capability-commit discipline
S1 = новая зависимость ast-grep → capability-commit, `Prior-art:` трейлер (ссылка на S0-матрицу + MVP S1b; consult SSOT + DeepWiki/WebSearch ≥3 phrasings). Пин версии (alpha). S2-S4 — код ≥80 LOC → трейлеры.

## §7 `done.md` (схема CLAUDE.md Umbrella closure) — при мёрже S4. Частичный прогресс → не писать, умбрелла открыта.

## §8 Staging-placement
ДРАФТ. merge kickoff в staging ДО `/pipeline` (`kickoff-staging-placement.md §1`). Зависит от `generator-forbid-mvp` DONE (#697). Не диспетчеризовать с feature-ветки (`#dispatch-before-staging`).
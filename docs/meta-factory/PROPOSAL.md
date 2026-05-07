# Meta-Factory: пакет, который генерирует rules-as-tests под конкретный стек через research

> Status: **DRAFT / RFC**
> Date: 2026-05-07
> Authors: Art + AI discussion
> Audience: будущие реализаторы, фреш-сессии Claude/Cursor, контрибьюторы

Этот документ — **проектная заявка** на следующее архитектурное направление пакета `rules-as-tests-aif`. Текущий пакет станет одним из компонентов мета-фабрики (canonical example), а новое ядро превратится в генератор, который умеет собирать аналогичные «фабрики правил» под произвольный стек.

Документ намеренно длинный — это база, из которой потом будут отдельные документы (`architecture.md`, `versioning.md`, `validator.md`, etc.). Здесь зафиксированы все обсуждённые решения, чтобы не потерять.

---

## 1. Контекст и мотивация

### 1.1 Проблема текущего состояния

Текущий пакет — **застывший снимок** best practices мая 2026 для Next 15 + TS-server. Конкретные привязки:

- Next.js **15** в `setup.sh:257` (`@next/eslint-plugin-next@^15.0.0`), при этом Next 16 уже stable с октября 2025 и 16.2 — март 2026
- ESLint 10, Vitest 4, Stryker 8.7 — конкретные версии мая 2026
- Каноническая гексагональная раскладка `src/{domain,application,infrastructure,web}/`
- R12-R20 завязаны на App Router (Server Actions, `'use client'`, `'use server'`)

Через год эта снимка устареет. Через два года — станет вредной (например, `useMemo` антипаттерн в эпоху React Compiler — а пакет будет требовать exhaustive-deps).

### 1.2 Главный тезис

> **Preset-ы устаревают, принципы — нет.** Опираться на принципы вместо preset-ов — это тот же сдвиг, что от документов к тестам, только на уровень выше.

Идея: пакет становится **спецификацией процесса**, а не списка правил.

```
[invariant core: принципы]
        +
[detected stack: Next 16.2, Fastify 5, etc.]
        +
[research: best practices через context7 / WebSearch]
        ↓
[generated rules-as-tests именно под эту версию]
        ↓
[self-validation by core principles]
        ↓
[install only validated rules]
```

Пакет ест свой собственный собачий корм на этапе генерации: его принципы (5 layers, AST > grep, paired negative tests, mutation testing, two-AI review) применяются к LLM-output как фильтр.

### 1.3 Зачем именно мета-уровень

1. **Релевантность во времени** — апгрейды стэка автоматически порождают апгрейды правил.
2. **Покрытие стэков** — Remix, Astro, Hono, SvelteKit получают свои фабрики без ручного preset.
3. **Демонстрация принципа на максимуме** — если фреймворк проповедует «every rule is a test», то и сама генерация правил должна следовать тому же принципу.
4. **Снижение долговой нагрузки** — не надо вручную поддерживать N preset-ов, отслеживать N changelog-ов, синхронизировать N конфигов.

---

## 2. Архитектурные слои

### 2.1 Шесть слоёв

```
Layer 0 — Invariant Core (никогда не генерится)
Layer 1 — Stack Detector
Layer 2 — Research Agent
Layer 3 — Rule Synthesizer
Layer 4 — Self-Validator
Layer 5 — Installer
```

Поток данных: `0 → 1 → 2 → 3 → 4 → 5`. Layer 4 имеет **обратную связь** в Layer 3 (отклонённые правила возвращаются на регенерацию или в human review).

### 2.2 Layer 0 — Invariant Core

**Что внутри.** То, что никогда не генерится и определяет «настоящий пакет»:

| Компонент | Содержание | Почему invariant |
|---|---|---|
| Принципы | 5 layers framework, AST > grep, paired negative tests, mutation testing, two-AI review | Это сам тезис; если генерировать — теряется опора |
| Meta-rules | «every rule has executable check», «no tautology», «documents lie», «MUST не демотируется до should» | Критерии валидности любого LLM-output |
| Workflow контракт | detect → research → synthesize → validate → install | Контракт между фазами |
| Schema manifest | JSON Schema для `rules-manifest.json` | Фиксирует формат, в который research должен попадать |
| Generic R-rules | TS hygiene (R1), async correctness (R5), errors (R6), naming (R10) — стэк-независимы | Одинаковы для Next 14/15/16, Fastify 4/5, Astro |
| Validator | rule-tester прогон, mutation testing, negative-test gate | Стоит на выходе, режет мусор |
| Audit-self CI | Проверка пакета своими же принципами | Без этого «принципы» — пустые слова |

**Граница invariant ↔ generated.** Каждый компонент инварианта покрыт **тестами на сам инвариант**: при любом изменении core эти тесты прогоняются и проверяют, что:
- Schema manifest не сломана
- Validator не пропускает заведомо плохие правила (positive test)
- Validator не отвергает заведомо хорошие правила (negative test)
- Generic R-rules компилируются и проходят rule-tester

См. §6.3 «Acceptance test для самого core».

### 2.3 Layer 1 — Stack Detector

**Что делает.** Парсит `package.json`, lock-файлы, конфиги, структуру каталогов. Возвращает structured `stack.json`:

```json
{
  "framework": { "name": "next", "version": "16.2.1", "router": "app" },
  "runtime": { "name": "node", "version": "20.18.0" },
  "language": { "name": "typescript", "version": "5.7.2" },
  "patterns": ["server-actions", "rsc", "form-data", "use-cache"],
  "structure": {
    "kind": "monolith-app",
    "src-layout": "app-router",
    "test-runner": "vitest"
  },
  "missing": ["opentelemetry", "playwright", "storybook"]
}
```

**Что НЕ делает.** Не принимает решений о правилах. Только наблюдение, факты, без интерпретации.

### 2.4 Layer 2 — Research Agent

**Что делает.** Для каждого detected паттерна:
1. Идёт в `context7` MCP за официальной документацией (allowlist).
2. WebSearch с allowlist (nextjs.org, react.dev, vercel.com/docs, MDN, official changelogs).
3. Извлекает best practices + anti-patterns.
4. Структурирует в `research-cache.json` под версию.

**Granularity (см. ответ на вопрос 1).** Двойная: **и** на уровне фреймворка целиком («Next 16.2 patterns»), **и** на уровне отдельных фич («Server Actions return type pattern в Next 16.2»). При генерации правил учитываются их взаимодействия — например, Turbopack default в 16 влияет на то, как Stryker должен мутировать.

**Diff-режим (см. ответ на вопрос 2).** При апгрейде версии (Next 15 → 16):
1. Берётся существующий `rules-lock.json` для Next 15.
2. Research даёт **только дельту**: что изменилось между 15 и 16 в best practices.
3. Synthesizer актуализирует правила точечно, не переписывая всё.
4. Diff показывается человеку на review.

Это решает «не переписываем заново, только актуализируем».

**Защита от prompt injection.** Жёсткий allowlist источников. WebSearch без allowlist для best practices — запрещён. Только официальные docs.

### 2.5 Layer 3 — Rule Synthesizer

**Что делает.** На основе research'а выводит:
- ESLint правила (конфигурация существующих плагинов — Path A) или сам AST-плагин (Path B, см. §3)
- Negative test cases (обязательно для каждого правила)
- Audit probes
- RULES.md fragments под стек
- ESLint flat config с правильным scoping

**Output формат.** Tentative `rules-manifest.json`:

```json
{
  "R12": {
    "title": "Server vs Client Components (Next 16)",
    "stack": ["next@>=15"],
    "applies-to": ["src/app/**/*.tsx"],
    "requires-package": "next",
    "check": {
      "type": "eslint",
      "plugin": "rules-as-tests",
      "rule": "no-server-imports-in-client",
      "config": "error"
    },
    "negative-test": {
      "input": "'use client'\\nimport fs from 'node:fs'\\nexport default function X() {}",
      "expect-violation": "no-server-imports-in-client"
    },
    "examples": {
      "bad": "...",
      "good": "..."
    },
    "research-source": "nextjs.org/docs/app/building-your-application/rendering",
    "research-version": "16.2.1",
    "research-fetched-at": "2026-05-07T10:00:00Z"
  }
}
```

### 2.6 Layer 4 — Self-Validator

**Что делает.** Прогоняет invariant-проверки против каждого сгенерированного правила:

1. **Schema check** — соответствует JSON Schema.
2. **rule-tester прогон** — для каждого правила запускается positive case (нарушение → ошибка) и negative case (валидный код → ошибки нет).
3. **Mutation на правиле** — Stryker мутирует AST-логику правила; тесты должны убить мутантов.
4. **Tautology check** — правило не должно срабатывать на пустом коде или на коде без целевой конструкции.
5. **Two-AI review** — второй агент в холодную смотрит правило и его тесты, ищет тавтологию или пропуски.
6. **Cross-rule conflict check** — новое правило не противоречит существующим (например, не запрещает паттерн, который другое правило требует).

**Отклонение.** Если хоть один gate провален — правило **не пишется на диск**. Возврат в Layer 3 для регенерации (с feedback'ом от validator) или в human review.

**Это и есть применение собственных принципов пакета к LLM-output.**

### 2.7 Layer 5 — Installer

**Что делает.**
1. Записывает только validated правила в проект.
2. Генерит `RULES.md`, `eslint.config.mjs`, `audit-ai-docs.sh`, GitHub Actions workflow из manifest.
3. Создаёт `rules-lock.json` для воспроизводимости.
4. Устанавливает npm deps, husky, скрипты.
5. После установки запускает Layer 4 ещё раз против установленного — финальная meta-проверка.

---

## 3. Path A vs Path B (генерация AST-правил)

### 3.1 Path A — безопасный (default)

**Что генерится:** конфигурация существующих плагинов + список применимых плагинов.

Research отвечает на вопрос «какие плагины и в каких настройках нужны для Next 16.2». Например:
- Включить `eslint-plugin-react-compiler` (новый для React 19+)
- Выключить часть `react-hooks/exhaustive-deps` (компилятор делает за нас)
- Скорректировать scoping `no-restricted-imports` под App Router

LLM не пишет TypeScript код, он **выбирает из меню**. Риск ошибки минимальный.

### 3.2 Path B — амбициозный (опционально)

**Что генерится:** сам AST-плагин TypeScript.

LLM получает описание паттерна → генерит `eslint-rule.ts` + `rule-tester.test.ts`. Validator прогоняет. Если все negative tests падают и positive проходят — правило допускается.

**Риск.** Сгенерированный TS-код может зависнуть на edge cases (template strings, JSX spread, conditional rendering). Validator должен покрывать их matrix-тестами.

**Когда применять.** Только когда Path A не покрывает потребность (новый паттерн, для которого нет готового плагина). С обязательным **human review checkpoint** перед commit'ом.

### 3.3 Переключение

Конфигурация в `meta-factory.config.json`:
```json
{
  "synthesis-mode": "conservative",  // только Path A
  "synthesis-mode": "creative",       // Path A + Path B с human review
  "synthesis-mode": "research-only"   // не генерить, только репортить findings
}
```

Default — `conservative`.

---

## 4. Воспроизводимость и lock-файлы

### 4.1 Проблема

Если установка дёргает интернет → каждый запуск даёт разные правила. Это анти-deterministic build, кошмар для CI и онбординга.

### 4.2 Решение — `rules-lock.json`

Аналог `package-lock.json`. Содержит:
- Зафиксированный набор сгенерированных правил с их content hash
- Метаданные research: версия стэка, источники, timestamp
- Validator metadata: что прошло, что было отклонено

**Поведение:**
- Первый запуск: research + generation + validation → `rules-lock.json` создаётся, коммитится в репо.
- Последующие запуски: read-only из lock'а. Воспроизводимо.
- Регенерация: только по явной команде `npm run rules:upgrade`, которая показывает diff и требует подтверждения.

### 4.3 TTL и автоматический regen

При апгрейде версии в `package.json` (Next 16.2 → 16.3) postinstall hook замечает смену версии и предлагает:

```
ℹ Next.js обновился: 16.2.1 → 16.3.0
ℹ Запустить research diff и предложить актуализацию правил? [Y/n]
```

Если `Y`: research-agent сравнивает changelog'и, выдаёт дельту, synthesizer актуализирует только затронутые правила, validator прогоняет, человек ревьюит diff в правилах.

### 4.4 Общий research-cache

Кеш research'а можно расшарить на уровне организации:
- `~/.rules-as-tests/cache/next/16.2.1.json`
- Отдельный CI job обновляет кеш по расписанию (раз в неделю)
- Команда переиспользует один и тот же research при установках

Это снимает проблему стоимости (десятки WebSearch на каждую установку → один централизованный pull раз в неделю).

---

## 5. Failure modes и пауза/возобновление

(Ответ на открытый вопрос 5: «устанавливается база, и на паузу, можно продолжить потом».)

### 5.1 Stateful installer

Установка — не атомарная команда, а **state machine** с persistent state в `.meta-factory-state.json`:

```json
{
  "phase": "research-completed",
  "last-completed-step": "synthesize-R12",
  "pending-steps": ["validate-R12", "synthesize-R13", "validate-R13", ...],
  "started-at": "2026-05-07T10:00:00Z",
  "stack": { ... },
  "research-cache-ref": "..."
}
```

Каждая фаза:
1. Базовая установка (Layer 0 + 1 + skeleton). **Атомарная**, быстрая.
2. Stack detection. **Атомарная**.
3. Research. **Можно прервать**, возобновится с того же места.
4. Synthesis. **По правилу за раз**, прерывание безопасно.
5. Validation. **По правилу за раз**, прерывание безопасно.
6. Final install. **Атомарная**, должна пройти целиком.

### 5.2 Команды

```
npx meta-factory install                  # начать или продолжить с last state
npx meta-factory install --resume         # явно продолжить
npx meta-factory install --restart        # начать с нуля
npx meta-factory status                   # показать где остановились
npx meta-factory status --verify          # проверить, что сделано
```

### 5.3 Защита от прерываний

- Atomic file writes (через temp + rename)
- Lock-файл `.meta-factory.lock` с PID, чтобы не запустить параллельно две установки
- При offline-режиме на фазе research: пауза + сообщение «нужен интернет, повтори когда будет»
- Каждое сгенерированное правило записывается отдельным коммитом (опционально), чтобы можно было откатить точечно

### 5.4 Failure без интернета (ответ на вопрос 4)

Минимальный режим: использовать локальный `research-cache.json`, если он есть. Если нет:
- Установить только invariant core (R1-R10)
- Сообщить: «research недоступен; установлены generic правила; запустите `meta-factory install --resume` когда появится интернет»
- Не падать, не блокировать пользователя

---

## 6. Acceptance test = self-test через 5 слоёв

(Ответ на открытый вопрос 6: «отличный пример meta-testing — установился, проверил себя 5 слоями».)

### 6.1 Идея

Self-application invariant действует **с момента 0** — самим фактом разработки фабрики, а не только при установке у потребителя. Установка — лишь **последняя точка верификации** уже-существующего invariant: фабрика прогоняет на себе все свои же 5 слоёв, доказывая корректность до того как окажется в руках потребителя.

| Слой | Что проверяется на себе |
|---|---|
| L1 Architecture | Сгенерированные правила соблюдают layer boundaries в самом сгенерированном коде |
| L2 Meta-tests | Каждое правило имеет negative test; validator уже прогнал их |
| L3 Spec by Example | Examples (bad/good) в manifest исполняемы — bad ловится правилом, good проходит |
| L4 Mutation | Stryker мутирует сгенерированные AST-правила, тесты должны убивать мутантов |
| L5 Living Docs | RULES.md сгенерирован из manifest — автоматически синхронизирован |

Если **любой** слой падает — установка считается **некорректной**, фабрика выдаёт отчёт и предлагает:
- Откатить
- Перегенерировать только провалившиеся правила
- Перейти в human review

### 6.2 Ценность

Это не отдельный test suite — это **тот же набор инвариантов**, который применяется к проекту пользователя. Фабрика **доказывает свою правомочность** на самой себе.

Как сказал пользователь: «установился сразу проверил себя что все ок всеми 5 слоями» — это и есть acceptance criterion для самой установки.

### 6.3 Acceptance test для самого core

**Обязательное требование:** автор не имеет права релизить core без работающего acceptance test'а — без него нечем доказать корректность всей последующей мета-фабрики. Согласно [self-application.md](self-application.md) §8 («6-month projection»): к Phase 7 без acceptance test'а core будет shipped с broken installer. Тезис: **«генератор воспроизводит canonical example»**.

Сценарий:
1. Берём текущий `rules-as-tests-aif` для Next 15 — это canonical example.
2. Запускаем мета-фабрику на чистом проекте Next 15.
3. Сравниваем сгенерированный output с canonical.
4. Ожидаем: эквивалентность по поведению (не по символьному совпадению).

Если генератор генерит что-то качественно отличное от canonical — это сигнал, что либо canonical устарел, либо генератор работает неправильно. В любом случае — повод разобраться.

Аналогично — **на апгрейде**:
1. Берём canonical Next 15.
2. Запускаем `meta-factory upgrade --to next@16.2`.
3. Сравниваем с тем, как мы вручную обновили бы canonical под Next 16.
4. Diff = область для improvement генератора.

Это превращает текущий пакет из «застывшего шаблона» в **золотой стандарт** для тестирования генератора.

> Полный invariant table по слоям и acceptance criteria — в [self-application.md](self-application.md) §2 и §7.

---

## 7. Граница invariant core: тесты на изменяемость

(Ответ на открытый вопрос 3: «нужна граница для неизменяемого core, на это тоже можно тесты написать».)

### 7.1 Что значит «core invariant»

Файлы и компоненты, изменение которых требует **major version bump** мета-фабрики и явного review:
- `core/principles.md`
- `core/manifest-schema.json`
- `core/validator/*.ts`
- `core/audit-self/*.sh`
- `core/generic-rules/R1.json` — R10.json (стэк-независимые)

### 7.2 Тесты на core stability

CI job `core-stability`:
1. Hash content всех `core/**` файлов → `core.lock`.
2. На каждом PR: пересчитывает hash. Если что-то изменилось в `core/` без явного флага `core-change: approved` в PR description — CI падает.
3. При изменении core: автоматический trigger полного regression test suite — на canonical examples (Next 15, TS-server) перегенерируется output, сравнивается с baseline. Любая регрессия в behavior блокирует merge.

### 7.3 Тесты на immutability принципов

Отдельный `core/principles.test.ts`:
- Парсит `core/principles.md`
- Проверяет наличие 5 layer'ов (regex)
- Проверяет наличие meta-rules (every rule has executable check, etc.)
- Если кто-то удалил пункт — тест падает

Это **жёсткий guard** против тихого размывания принципов («drift из MUST в should», см. ai-traps lesson #6).

### 7.4 Версионирование core

Semver для самой мета-фабрики:
- **Major**: меняется core (принципы, schema, validator API)
- **Minor**: добавлены новые presets, расширен research, добавлены generic rules
- **Patch**: bug fixes в generators, обновления research-cache

Major bump = breaking change для всех проектов, использующих мета-фабрику. Это редкое событие, требующее migration guide.

---

## 8. Нишевые стеки

(Ответ на открытый вопрос 4: «как минимум предупредить точно стоит».)

### 8.1 Confidence score

Research-agent для каждого паттерна оценивает confidence:
- **High**: official docs дают чёткий best practice (Next, React, TypeScript)
- **Medium**: community consensus есть, но не в official docs (Hono, Bun)
- **Low**: данных мало, паттерны нестабильны (новые/нишевые фреймворки)

### 8.2 Поведение по уровню

| Confidence | Что делает фабрика |
|---|---|
| High | Генерит правила, прогоняет validator, устанавливает |
| Medium | Генерит, **выводит warning**: «правила основаны на community sources; ревью рекомендуется» |
| Low | **Не генерит автоматически**. Сообщает: «стек поддерживается только в research-only mode; включаем generic R1-R10, остальное напиши руками» |

### 8.3 Список поддерживаемых стеков

В `core/supported-stacks.json` — реестр с confidence-уровнями:
```json
{
  "next@>=15": "high",
  "react@>=19": "high",
  "fastify@>=4": "high",
  "hono@>=4": "medium",
  "astro@>=4": "medium",
  "bun-runtime": "low"
}
```

Реестр обновляется по мере того, как стеки набирают зрелость и accumulated research.

---

## 9. Текущий пакет → canonical example

### 9.1 Новая роль

Текущий `rules-as-tests-aif` (Next 15 + TS-server) **не выкидывается**. Он получает две новые функции:

1. **Для людей** — обучающий артефакт: «вот как должна выглядеть законченная фабрика правил для Next 15. Изучи структуру, поймёшь принципы, которые core применяет ко всем стекам».
2. **Для агента** — few-shot example для генератора: «вот образец output'а; стремись к такой структуре и качеству при генерации под другие стеки».

### 9.2 Структура нового монорепо

```
rules-as-tests-aif/                     ← repo
  packages/
    core/                                ← invariant core
      principles.md
      manifest-schema.json
      validator/
      generic-rules/                     ← R1-R10
      audit-self/
    meta-factory/                        ← генератор (CLI)
      bin/meta-factory.mjs
      detector/
      research/
      synthesizer/
      installer/
    preset-next-15-canonical/            ← текущий пакет (frozen)
    preset-next-16/                      ← сгенерированный + полишинг
    preset-fastify/                      ← сгенерированный + полишинг
  examples/                              ← reference output для агента
    canonical-next-15/
    canonical-fastify-5/
  docs/
    meta-factory/                        ← этот документ и потомки
```

### 9.3 Миграционный путь

1. Извлечь invariant из текущего пакета → `packages/core/`. См. §2.2 — список того, что invariant.
2. Текущий пакет переименовать → `packages/preset-next-15-canonical/`, заморозить.
3. Создать пустой `packages/meta-factory/` со skeleton.
4. Вдохнуть жизнь в Layer 1 (Stack Detector) — простой, хорошо тестируемый.
5. Layer 2 (Research) — средняя сложность, использует MCP.
6. Layer 3 Path A (Conservative Synthesis) — конфигурация плагинов.
7. Layer 4 (Validator) — переиспользует существующие custom ESLint rules + rule-tester.
8. Layer 5 (Installer) — переиспользует существующий `setup.sh` логику с расширениями.
9. Acceptance test: `meta-factory generate --stack=next@15` → diff с `preset-next-15-canonical` → ожидаем minimal diff.
10. Когда зелёный — запустить генерацию `preset-next-16`, ручной review, commit.
11. Path B (Creative Synthesis) — позже, когда Path A стабилизируется.

---

## 10. Roadmap реализации

| Фаза | Содержание | Время | Зависимости |
|---|---|---|---|
| **0** | Закрыть Phase 1 + Phase 2 из предыдущего плана (R2 drift, manifest SSOT, depcruise --init) | 3 дня | — |
| **0.5** | Documentation alignment: создать `self-application.md` (reference), добавить §15 в этот PROPOSAL, переписать §6 (invariant с момента 0), вставить эту строку в Roadmap | 1-2 дня | 0 |
| **1** | Извлечь invariant core из текущего пакета | 2 недели | Phase 0 |
| **2** | Stack Detector (Layer 1) | 1 неделя | 1 |
| **3** | Research Agent (Layer 2) с allowlist + cache | 2 недели | 1 |
| **4** | Validator (Layer 4) с rule-tester + mutation + two-AI | 3 недели | 1 |
| **5** | Synthesizer Path A (Layer 3, conservative) | 2 недели | 3, 4 |
| **6** | Installer (Layer 5) с stateful install/resume | 1 неделя | 5 |
| **7** | Lock-файлы и diff-режим | 1 неделя | 6 |
| **8** | Acceptance test: воспроизведение canonical Next 15 | 1 неделя | 6 |
| **9** | Auto-upgrade Next 15 → 16 как E2E proof | 1 неделя | 8 |
| **10** | Synthesizer Path B (Layer 3, creative) | 4 недели | 9 |
| **11** | Документация, маркетинг, релиз 1.0 | 2 недели | 10 |

> Phase 0.5 introduced 2026-05-07 после обнаружения self-application gap (см. [docs/audits/2026-05-07-self-application-gap.md](../audits/2026-05-07-self-application-gap.md), [self-application.md](self-application.md)).

**Итого до 1.0** (без Path B): ~4 месяца full-time, в одного.
**С Path B**: ~5-6 месяцев.

С AI-помощью реалистично сжать в 1.5-2 раза.

---

## 11. Защита от рисков (сводно)

| Риск | Защита |
|---|---|
| LLM-generated context хуже human-written (InfoQ 2026) | Validator-gate с executable behavioral checks, не «правдоподобность текста» |
| Воспроизводимость | `rules-lock.json` + общий research-cache + явная команда `rules:upgrade` |
| Prompt injection через web | Allowlist источников (nextjs.org, react.dev, vercel.com, MDN) |
| Стоимость токенов | Shared research-cache на уровне организации, обновляется по расписанию |
| Decay best practices | TTL на кеш + auto-regen при апгрейде версий стэка |
| Self-bootstrapping recursion | Invariant core минимизирован, покрыт тестами на стабильность; любое изменение core = major bump + regression suite |
| Сгенерированный AST-код с багами (Path B) | Matrix tests на edge cases, mutation testing, two-AI review, human review checkpoint |
| Сломанный регекс/AST правила тихо always-PASS | Парные negative tests + mutation на самих правилах |
| Регрессия при апгрейде стэка | Canonical examples как regression baseline; diff-режим показывает изменения человеку |
| L2 Research Agent semantic drift не operationalized (см. §13.7) | Phase 6 deliverable: формальный drift-detector с измеримой метрикой; до этого — manual review при изменении принципов |
| Bypass через `--no-verify` делает invariant декоративным | Phase 1.A добавляет CI gate на наличие `.husky/` директории + non-empty hooks; локальный bypass не блокируется, но CI fail при отсутствии setup'а |

---

## 12. Связь с предыдущим планом фаз

| Старая фаза | Что становится с ней |
|---|---|
| **Phase 1** (R2 drift, expected failures, three-tier perms) | Прерequi для всего; **обязательна до старта мета-фабрики** |
| **Phase 2** (rules-manifest SSOT) | Становится **schema** для invariant core; manifest format фиксируется здесь |
| **Phase 3** (depcruise --init) | Становится частью Layer 1 (Stack Detector делегирует ему) |
| **Phase 4** (npm publishing) | Становится distribution для `packages/core`, `packages/meta-factory`, `packages/preset-*` |
| **Phase 5** (spec-driven install) | Становится Layer 5 stateful workflow (см. §5.1) |

То есть мета-фабрика **поглощает** все предыдущие фазы как свои внутренние компоненты. Старый план — это инкрементальная дорожная карта; новый план — её эндшпиль.

---

## 13. Открытые вопросы (что ещё не решено)

### 13.1 Granularity research, детально

Как именно сегментировать паттерны в research? «Server Actions» — один паттерн или семь подпаттернов (return type, FormData, revalidatePath, error handling, ...)?

Гипотеза: иерархия в `research-cache.json`:
```
next/16.2.1/
  app-router/
    server-actions/
      return-type.json
      form-data-validation.json
      revalidate-after-mutation.json
    server-components/
      data-fetching.json
      use-cache.json
  build/
    turbopack-vs-webpack.json
```

Granularity ≈ **один файл = один паттерн**, на котором можно построить **одно правило**. Это упрощает diff-режим (изменился один файл → перегенерировано одно правило).

### 13.2 Маркетинг и наименование

«AI генерит твои правила» — половина людей не доверяет. Маркетинг должен быть про **self-validating rule generator** с акцентом на validator, не на LLM.

Возможные названия:
- `meta-factory` — про генерацию фабрик
- `rules-foundry` — про литьё правил
- `aif-stack-aware` — расширение AIF
- `rules-as-tests/core` + `rules-as-tests/cli` — продолжение текущего

### 13.3 Granularity invariant core — где провести границу

R1 (no `as any`) — invariant. R8 (OTel spans) — generated. Где граница?

Гипотеза: правило — invariant если:
- Не зависит от стэка (works on any TS code)
- Защищает фундаментальное свойство языка (типобезопасность, async correctness)
- Не имеет version-specific edge cases

Generated если:
- Завязано на конкретный фреймворк
- Зависит от версии (изменения в API)
- Apply-to пути зависят от структуры проекта

Это **рабочая гипотеза**, нужно валидировать на реальных правилах.

### 13.4 Обработка legacy кодовой базы

Если мета-фабрика устанавливается в **существующий** проект с кучей legacy кода — все сгенерированные правила сразу дадут тысячи violations. Что делать?

Варианты:
- Bulk `// audit:exempt` для existing files (не рекомендуется — заглушает)
- Baseline file типа eslint-baseline (фиксирует current violations, новые ловятся)
- Postpone enforcement — правила в WARN режиме первый месяц, потом ERROR

Это UX-вопрос, не архитектурный, но важный для adoption.

### 13.5 Multi-stack monorepos

Что если в одном репо `apps/web` (Next 16) и `apps/api` (Fastify 5) и `packages/shared` (TS-only)? Три фабрики? Одна с разными scoped правилами?

Гипотеза: одна meta-factory invocation, на выходе — слой scoping в ESLint flat config, разные правила scoped к разным каталогам. Lock-файл общий, в нём отметки «правило R12 applies-to apps/web/**».

Это требует более продвинутого Layer 1 (Stack Detector), который понимает workspace structure.

### 13.6 Relationship с AIF core

AIF — это workflow framework (slash-команды, sub-agents, .ai-factory/). Meta-factory — это генератор enforcement layer. Они **ортогональны**. Но как они стыкуются?

Гипотеза: `meta-factory` генерит **в том числе** обновлённые `.ai-factory/RULES.md`, sub-agent prompts (`best-practices-sidecar.md`), AGENTS.md секции. То есть AIF получает stack-aware контент через meta-factory.

Это нужно проработать в отдельном документе `meta-factory-and-aif.md`.

### 13.7 Operationalization L2 semantic drift detection

Acceptance criterion для L2 в [self-application.md](self-application.md) §2: «Все три источника (`skills/`, `principles.md`, `ai-traps.md`) семантически синхронизированы; drift detection возвращает 0 расхождений». Но **что значит «семантически»**? Возможные операционализации:

- **Symbolic:** одинаковые term'ы (e.g. «MUST» vs «should» — диcyrepancy при demotion'е)
- **Behavioral:** rule из principles.md проверяется тестом из ai-traps.md → если изменился principle и не изменился test (или наоборот) — drift
- **Embedding-based:** semantic similarity score; threshold для drift

Решение откладывается до Phase 6. До этого — manual review при любом изменении файлов из этих трёх источников.

### 13.8 Decision matrix expansion rule

Decision matrix в [self-application.md](self-application.md) §3 фиксирует 9 layer'ов локального enforcement. Добавление 10-го (например, типизация YAML schema, ESM/CJS coherence check, dependency policy) — по какому правилу включается / исключается?

Гипотеза: 4-критерия gate перед включением в matrix:
1. Failure-cost (low/medium/high) — пропуск через локальный gate
2. Local-cost (<100ms / 100ms-1s / 1s-10s / >10s)
3. Detectability только в runtime/не имеет обратной совместимости
4. Stage в lifecycle (pre-commit / pre-push / CI-only)

Решение принять при добавлении 10-го layer'а; до этого — текущая matrix фиксирована.

### 13.9 Bypass через `--no-verify` — структурное решение

Локальный pre-commit / pre-push не блокирует автора который запускает `git commit --no-verify`. Без mitigation invariant декоративен.

Гипотеза (для Phase 1.A scope expansion):
- **CI gate на наличие `.husky/`** в root репо. Если директория пуста или hooks не executable — CI fail. Это не блокирует локальный bypass, но не позволяет push'нуть в main без setup hooks.
- **Audit-self job на наличие framework-self-install passing** — если автор закоммитил без локального запуска (любым путём, включая `--no-verify`), эту ситуацию ловит CI.

Это не silver bullet (контрибьютор всё ещё может временно отключить hooks), но превращает bypass из «invisible» в «visible breach» через CI signal.

---

## 14. Что дальше

### 14.1 Немедленные следующие шаги

1. **Закрыть Phase 0** (предыдущие Phase 1 + 2): R2 drift, expected-failures section, manifest SSOT. Без чистой базы строить мета-уровень нельзя.
2. **Прототип Stack Detector** (Layer 1) — самый дешёвый и обозримый компонент. Рабочий прототип за неделю даст уверенность в направлении.
3. **Дискуссия по §13** — закрыть открытые вопросы хотя бы на уровне рабочих гипотез.
4. **Разбить этот документ** на отдельные специализированные файлы:
   - `architecture.md` (§2-3)
   - `versioning-and-locks.md` (§4)
   - `failure-modes.md` (§5)
   - `acceptance-tests.md` (§6)
   - `core-stability.md` (§7)
   - `niche-stacks.md` (§8)
   - `migration-from-current.md` (§9)
   - `roadmap.md` (§10)
   - `risks.md` (§11)
   - `open-questions.md` (§13)

### 14.2 Что нужно обсудить с пользователем перед стартом

- Согласие на разделение монорепо (текущий пакет → `preset-next-15-canonical`)
- Согласие на naming (`meta-factory` или другое)
- Приоритеты в roadmap — где сжимать сроки, где растягивать
- Бюджет на интернет-research (стоимость токенов)
- Готовность поддерживать confidence-tier систему для нишевых стеков

### 14.3 Принцип развития документа

Этот файл — **живой**. По мере прояснения вопросов обновляется, секции вытаскиваются в отдельные документы. Каждое решение фиксируется с датой и контекстом. История — через git log.

Версия документа: `0.2.0-draft` (2026-05-07; Phase 0.5 alignment: §15 self-application invariant, §6 rewrite, §10 Phase 0.5 row, line ref :169 → :257).

---

## 15. Self-application as architectural invariant

Self-application — не отдельный шаг, а cross-cutting invariant каждого слоя мета-фабрики. Без него центральный тезис «documents lie; tests don't» фальсифицирован: фреймворк поставляет enforcement-инструменты потребителю, но не применяет их к себе. Invariant действует с момента 0 — установка лишь последняя точка верификации.

| Слой | Self-application clause |
|---|---|
| **L0 Invariant Core** | Принципы прогоняются как тесты против собственного `rules-manifest.json` в pre-commit/CI |
| **L1 Stack Detector** | Detector запускается на самом репо в CI; expected output зафиксирован snapshot-тестом |
| **L2 Research Agent** | Research прогоняется на собственных docs (`skills/`, `principles.md`) |
| **L3 Rule Synthesizer** | Synthesizer регенерирует canonical Next 15, diff ≤5% — детерминирован |
| **L4 Self-Validator** | Validator прогоняется на `rules-manifest.json` перед каждым CI run |
| **L5 Installer** | `install.sh` + `setup.sh` запускается в CI на tmp-dir; результат проходит own audits |
| **Spec discipline** | orchestrator-prompts валидируются как код (SHA-check, action existence) |

См. полный rationale, decision matrix и acceptance criteria в [self-application.md](self-application.md).

---

## Приложения

### A. Глоссарий

- **Invariant core** — ядро мета-фабрики, которое не генерится и определяет принципы.
- **Generated artifacts** — всё, что собирается под конкретный стек (правила, конфиги, RULES.md).
- **Canonical example** — эталонный preset (текущий Next 15), служит образцом и regression baseline.
- **Confidence tier** — оценка зрелости стэка (high/medium/low), определяющая поведение фабрики.
- **Path A / Path B** — режимы синтеза правил: конфигурация плагинов vs. генерация AST-кода.
- **Two-AI review** — паттерн из текущего пакета: один LLM пишет, второй ревьюит вне контекста.
- **Negative test** — тест, проверяющий, что правило ловит инжектированное нарушение (защита от always-PASS).

### B. Связанные документы

- `audits/2026-05-06.md` — фреш-сессия аудит, нашедший R2 drift и regex bugs.
- `skills/rules-as-tests/SKILL.md` — текущий skill (станет частью invariant core).
- `factory/RULES.md` — текущий список правил (станет seed для generic-rules).

### C. Внешние референсы

Учтены при разработке концепции (см. предыдущее обсуждение):
- AGENTS.md spec — agents.md
- GitHub Blog: «How to write a great agents.md» (2500 repos analysis)
- InfoQ 2026: research показавший, что LLM-generated context может ухудшать success rate
- Anthropic — Complete Guide to Building Skills for Claude
- npm-agentskills (onmax) — convention `package.json.agents.skills`
- openskills — universal SKILL.md installer
- jsonschema2md (Adobe) — generation pattern
- LN-Zap rulesync — SSOT синхронизация конфигов
- dependency-cruiser `--init` — auto-detect конфигурации
- Idempotent installers (OneUptime) — паттерны state-машин
- Spec-driven development (timdeschryver) — proposal/design/tasks

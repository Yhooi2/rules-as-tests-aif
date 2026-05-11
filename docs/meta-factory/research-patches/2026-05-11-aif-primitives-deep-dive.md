<!-- scope:aif-handoff-mandate -->
# AIF paused-semantic + implement-coordinator — deep-dive analysis

> **Scope:** follow-up analysis 2026-05-11 на два AIF primitives из aif-handoff-overlap mandate.
> **Authoritative for:** decision documents для Primitive A (paused) и Primitive B (implement-coordinator).
> **NOT authoritative for:** project goal — see README.md#why-this-exists.

---

## §A `paused:true/false` semantic (SSOT #28)

### Контекст

AIF: `handoff_sync_status({ taskId, newStatus:"review", paused:true })` — coordinator знает «стоп, ждём
human review». Наш аналог: имплицитные pause-points (P5 reviewer gate, wave kickoff → wave review → wave
close) — нет machine-readable статуса.

**Negative check (bash):**
Существующие упоминания «waiting/pending/status:» в `.claude/` и `docs/meta-factory/`:
- `.claude/orchestrator-prompts/aif-handoff-overlap-2026-05-11/primitives-deep-dive.md:48` — описание боли
- `.claude/orchestrator-prompts/wave-7-hot-checks-joint-closure/orchestrator-kickoff.md` — «CONDITIONALLY
  CLOSED», «status» как enum в таблице строк
- Нет единого места «что сейчас открыто»: нужно читать разные файлы и историю чата

**Реальная нагрузка одновременных ожиданий (Wave 5, 2026-05-11):**
- Wave 5 pending (impl GO ожидается)
- PR #31 в review (wave-5-readiness-revise)
- Всего активных: 2 — порог «10+» из SSOT #28 не достигнут, но 2-3 ожидания уже требуют разных мест проверки

### Три варианта адаптации

**Вариант A — `.claude/wave-status.md` (single truth-file)**

Pros: один grep, понятно; минимум новых артефактов.
Cons: требует ручного обновления при каждом переходе; легко рассинхронизировать с реальным состоянием;
файл в `.claude/` не gitignored → попадает в историю; разрастается при многих waves.

**Вариант B — frontmatter `status:` в kickoff файлах**

```bash
grep -r "status: waiting" .claude/orchestrator-prompts/
```

Pros: нет отдельного файла; состояние co-located с артефактом; понятный grep.
Cons: `orchestrator-prompts/` gitignored → не в git history; требует конвенции для всех будущих kickoffs;
ретрофит на существующие kickoffs нужен.

**Вариант C — расширить `<!-- scope:§N status:open -->`**

Pros: leverages уже принятый ADAPT (SSOT #29 — scope аннотации в research-patches); CI gate может
enforcement.
Cons: смешивает два разных понятия (§N = тема патча; status:open = workflow state); scope аннотация
предназначена для trigger sweeps, не для wave workflow tracking; добавляет сложность CI gate без
реальной автоматизированной пользы.

### Анализ trigger'а SSOT #28

Текущий trigger: «Wave count >10 OR Phase 11+». Аргументы за снижение:
- Боль реальная уже при Wave 5 (2 ожидания = разные места поиска)
- Trigger был установлен в 2026-05-11 без эмпирических данных
- Вариант B (frontmatter grep) — настолько низкая стоимость (no new file, no CI gate), что соотношение
  боль/стоимость положительно уже сейчас

Аргументы против снижения trigger'а:
- Вариант A и C требуют ретрофита и CI enforcement — overhead не оправдан при 2 ожиданиях
- Вариант B — достаточно лёгкий для немедленного ADAPT без снижения trigger

### Verdict §A: ADAPT (Вариант B)

**Rationale:** Frontmatter `status:` в orchestrator kickoff-файлах — минимально инвазивный способ сделать
wave state machine grep-able уже сейчас. Стоимость: добавить одну строку в шаблон kickoff; ретрофит
существующих открытых kickoffs (2-3 файла). Capability commit: НЕТ (doc-only, <80 LOC изменений в
.claude/, gitignored). Trigger SSOT #28 корректируется: снизить до «≥3 одновременных ожидания ИЛИ
автоматизация pipeline требует machine-readable state» — Вариант B покрывает ручной workflow до этого.

### Как реализовать

- **Файлы которые меняются:**
  - Существующие открытые kickoff-файлы в `.claude/orchestrator-prompts/wave-5-tool-bootstrapping/`
    (добавить `status: waiting-for-review`)
  - `.claude/orchestrator-prompts/README.md` или аналогичный шаблон — задокументировать конвенцию
- **Новые файлы:** нет (никакого отдельного wave-status.md)
- **Capability commit?** Нет — doc-only изменения в gitignored директории. Escape-hatch: `Prior-art:
  skipped — doc-only convention in gitignored .claude/orchestrator-prompts/; no new capability artifact`
- **Prior-art: trailer:** `prior-art-evaluations.md#28` (DEFER → ADAPT partial; Вариант B покрывает
  manual workflow; full state machine остаётся на SSOT #28 trigger-fire)
- **Размер работы:** small (1-2 часа; ретрофит 2-3 файлов + конвенция в шаблоне)
- **Риски:**
  - Orchestrator-prompts gitignored → конвенция не enforced CI; зависит от дисциплины
  - При добавлении новых waves — новые kickoffs должны использовать `status:` (без gate — drift возможен)
- **SSOT #28 trigger update needed:** снизить с «>10 waves» до «≥3 одновременных OR pipeline automation»
  (изменение в prior-art-evaluations.md — отдельный capability commit или orchestrator Stage 3)
- **Acceptance check:** `grep -r "status:" .claude/orchestrator-prompts/wave-5*/` показывает статус;
  `grep "status: waiting" .claude/orchestrator-prompts/**/*.md` показывает всё открытое

---

## §B `implement-coordinator` pattern

### Context7 findings (4 queries, `/lee-to/ai-factory`)

**Query 1:** `implement-coordinator dependency graph task dispatch parallel sequential`
Source: `subagents/implement-coordinator.md`, `docs/subagents.md`

Coordinator execution algorithm (псевдокод):
```text
remaining = all incomplete tasks
while remaining:
    ready = tasks in remaining whose dependencies all completed
    if len(ready) == 0: ERROR circular dependency
    if len(ready) == 1: implement directly (with quality sidecars)
    if len(ready) > 1: launch implement-worker for EACH ready task in parallel
    wait for all workers; collect results
    if any failed: stop + report
    mark completed; remaining -= completed
report final summary
```

**Query 2:** `implement-coordinator subagent worker spawning orchestration pattern`
Source: `subagents/implement-coordinator.md`, `docs/subagents.md`

- `implement-coordinator` = top-level agent (`claude --agent implement-coordinator`)
- Нельзя спавнить из обычного subagent (обычные subagents не имеют subagent-spawning capability)
- Использует `Agent` tool для workers + quality sidecars
- Tools coordinator: `Agent`, `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash`

**Query 3:** `plan-coordinator implement-coordinator interaction flow task list format`
Source: `subagents/implement-coordinator.md`

Plan parsing: coordinator парсит план, извлекает задачи (номер, описание, completion status,
optional `depends_on`, phase grouping). Tasks в одной phase без explicit deps = independent.
Tasks в более поздней phase = implicitly depend on all preceding phase tasks (unless overridden).
Dependency graph строится из этих аннотаций — нет отдельного JSON/YAML; всё inline в markdown плане.

**Query 4:** `aif coordinator batch tasks execution order dependencies worktree merge commit centrally`
Source: `subagents/implement-coordinator.md`, `docs/subagents.md`

Commit handling: workers НЕ делают commits. После каждого dependency layer → coordinator ищет
commit checkpoint в плане → если есть, делает single commit для всего layer. Финальный commit в конце.
Auto-pushing запрещён. Workers работают в worktrees; coordinator merges результаты.

### Feature inventory

| Feature | Деталь |
|---|---|
| Dependency graph format | Inline markdown аннотации в plan; `depends_on` + phase grouping |
| Worker dispatch | `implement-worker` via `Agent` tool; parallel при len(ready)>1 |
| Worker «результат» | Success/fail/warnings — coordinator ждёт tool result от Agent call |
| Coordinator узнаёт о завершении | Синхронно: `Agent` tool завершается, coordinator видит результат |
| Требует БД? | НЕТ: in-memory state only (нет external DB, нет MCP state persistence) |
| Commit handling | Centrally by coordinator; workers commit-free |
| Worktree merge | Coordinator merges; conflict = stop + report |
| Top-level requirement | MUST run as `claude --agent`; не subagent of subagent |

**Ключевое отличие от AIF Handoff:** coordinator НЕ требует external DB (в отличие от `HANDOFF_MODE=1`
с Handoff DB ownership). Coordinator — in-process state machine.

### Overlap mini-matrix

| AIF Coordinator feature | Наш Mode B batch | Наш Phase planning | Наш wave kickoff |
|---|---|---|---|
| dependency graph dispatch | GAP | OVL(ours: tables/sections) | ORT |
| worker status tracking | GAP | ORT | ORT |
| parallel safe ordering | GAP | OVL(ours: human-enforced) | ORT |

**GAP cells rationale:**
- `dependency graph dispatch / Mode B batch`: Mode B = N файл-промтов + user вручную открывает окна.
  Нет автоматического определения «какие задачи уже готовы». GAP — у AIF автоматически, у нас вручную.
- `worker status tracking / Mode B batch`: статус воркера узнаётся когда пользователь приносит REPORT.
  Нет проверки timeout / partial failure / stuck worker. GAP.
- `parallel safe ordering / Mode B batch`: orchestrator пишет батчи, пользователь запускает параллельно.
  Dependency ordering = ответственность orchestrator при написании батчей (human-enforced, error-prone).
  GAP vs. AIF автоматически проверяет circular deps.

**OVL cells rationale:**
- Phase planning: наш orchestrator строит table batches с sequential/parallel обозначениями — OVL с
  coordinator's dependency layer concept. Winner = AIF: machine-enforced. Ours: human-enforced.

### Ключевой вопрос: ADOPT pattern без AIF runtime?

AIF `implement-coordinator` требует:
1. `claude --agent` top-level session (не доступно без AIF runtime)
2. `implement-worker` агентов (AIF-specific subagent registry)

Мы — **producer для AIF** (`rules-as-tests-aif` пакет), не consumer. Запускать AIF coordinator в нашем
dev workflow = запускать наш же downstream в нашем upstream.

**Lightweight adaptation идея:** batch manifest YAML + `dispatch-batches.sh`:
```yaml
# .claude/orchestrator-prompts/batch-manifest.yml
tasks:
  - id: T1
    file: batch-A.md
    depends_on: []
  - id: T2
    file: batch-B.md
    depends_on: [T1]
  - id: T3
    file: batch-C.md
    depends_on: []  # parallel with T1
```
Скрипт читает manifest, запускает `claude --model sonnet < batch-X.md > results/T1.md` в правильном порядке.

**Оценка lightweight адаптации:**
- Про: автоматический dispatch; нет зависимости от AIF runtime; reproducible
- Контра: `claude < file > result` = non-interactive headless mode; Claude Code не поддерживает stdin
  piping без специальных флагов; результат нужно структурировать machine-readably (REPORT format)
- Контра: пользователь рядом (Mode B нормальный flow) = lightweight адаптация не нужна
- Контра: пользователь не рядом = Mode A inline Agent уже доступен без нового скрипта
- Контра: overhead разработки скрипта + manifest формата >> пользы при текущей нагрузке

**Autonomous mode use case реальный?**
Текущий ответ: нет. SKILL.md «Режим A для execution — исключение, не норма. Оправдан только: пользователя
нет рядом / autonomous mode». Ни один wave не использовал autonomous mode. Wave 5 kickoff предполагает
пользователя рядом.

### Verdict §B: DEFER

**Rationale:** `implement-coordinator` pattern решает реальную боль (auto-dispatch параллельных задач,
dependency ordering enforcement), но GAP существует только при autonomous execution — которого у нас нет.
Пока пользователь рядом: Mode B уже покрывает dispatch (human orchestrated); dependency ordering
обеспечивает orchestrator при написании батчей. Lightweight адаптация (bash скрипт + manifest) создаёт
overhead разработки без практического выигрыша при interactive mode. AIF runtime adoption невозможна
(мы producer, не consumer AIF). In-memory state машина coordinator'а — хорошая идея для Phase 11+
autonomous orchestration.

**Улучшенный trigger SSOT #28 (бывший §8 out-of-scope):**
Добавить SSOT запись: DEFER. Trigger: «orchestrator запускается в CI без пользователя (autonomous batch)
≥3 волны подряд; ИЛИ dependency ordering error (circular dep / wrong order) задокументирована в ≥2
research-patches под тегом `#mode-b-ordering-error`».

---

## §Decision summary

| Primitive | SSOT entry | Verdict | Rationale (краткий) |
|---|---|---|---|
| A `paused:true/false` | #28 | **ADAPT (Вариант B)** | Frontmatter `status:` в kickoff files; grep-able state уже при 2 ожиданиях; doc-only, no CI gate |
| B `implement-coordinator` | new entry needed | **DEFER** | GAP только в autonomous mode которого нет; Mode B достаточен; overhead adaptation > польза |

**Следующие шаги:**

1. **Primitive A — ADAPT:** orchestrator добавляет `status:` в шаблон wave kickoff + retrofits открытые
   kickoffs (wave-5-tool-bootstrapping). НЕ capability commit. Документировать конвенцию.

2. **SSOT обновления** (orchestrator Stage 3, в prior-art-evaluations.md):
   - SSOT #28: обновить trigger с «>10 waves» на «≥3 одновременных ожидания OR pipeline automation»;
     Verdict: DEFER→ADAPT(partial) для Вариант B
   - SSOT #new: добавить запись для `implement-coordinator` pattern с DEFER verdict и новым trigger

3. **Wave 5 §13.25 check:** armed trigger «Wave 5 §13.25 implementation surfaces AIF Handoff MCPs»
   из SSOT #27/#28 — при Wave 5 impl kick проверить наличие handoff MCP candidates.

---

*§1.7 forward-check: этот патч = research-only, no discipline introduced. Doc-authority header compliant.
Artifact Ownership: session that discovered analysis owns patch; prior-art-evaluations.md untouched.*

# Phase 3 Delegation Prompt — Monorepo Split

> **Назначение:** self-contained prompt для делегации Phase 3 (Agent Opus subagent **или** Sonnet manual handoff per orchestrator/Art choice).
> **Версия:** 0.1.0 — 2026-05-07
> **Embeds:** Reviewer's 6 mandatory blocks + lessons learned from Phase 1.C/1.D over-claim pattern.

---

## Identity & Context

**Repo:** `/Users/art/code/rules-as-tests-aif`
**Branch:** `chore/self-application` (HEAD `eaf3e19` после Phase 2 closure + reviewer actions 1-3 + CI 8/8 green в production).
**Phase:** 3 (Monorepo split, planned 1-2 недели per [EXECUTION-PLAN.md §6](EXECUTION-PLAN.md) lines 405-435).
**Goal:** разделить текущий repo на `packages/core/`, `packages/preset-next-15-canonical/`, `packages/meta-factory/` (skeleton) per [migration-from-current.md §9.2](migration-from-current.md). Acceptance: каждый пакет проходит Phase 2 meta-tests standalone.

## Обязательное чтение перед стартом

1. [EXECUTION-PLAN.md](EXECUTION-PLAN.md) §6 Phase 3 (lines 405-435) — full spec.
2. [migration-from-current.md](migration-from-current.md) — §9.2 целевая структура монорепо, §9.3 11-шаговый migration path.
3. [self-application.md](self-application.md) §2 invariant table — L0 Invariant Core acceptance criterion.
4. [open-questions.md](open-questions.md) §13.3 — invariant↔generated boundary (Phase 2 partial closure, Phase 3 финализирует).
5. `/Users/art/code/rules-as-tests-aif/factory/rules-manifest.json` (280 строк) — текущий SSOT правил.
6. `/Users/art/code/rules-as-tests-aif/scripts/principles/*.test.ts` — Phase 2 meta-tests которые должны работать standalone в каждом package.
7. `/Users/art/code/rules-as-tests-aif/scripts/package.json` — текущая TS setup (vitest, tsx, ajv) — модель для package.json'ов sub-packages.
8. `/Users/art/code/rules-as-tests-aif/install.sh`, `setup.sh` — должны быть обновлены под workspace structure.
9. `/Users/art/code/rules-as-tests-aif/templates/` — текущие preset templates (ts-server, react-next, shared).

---

## SCOPE — Hard Guardrails (6 mandatory blocks per reviewer)

### Block 1 — Scope criterion (in/out)

**В Phase 3 scope:**
- Создание `packages/core/` (invariant rules R1-R10 generic + manifest schema + meta-tests из Phase 2 + audit-self CI infrastructure)
- Создание `packages/preset-next-15-canonical/` (rules R12-R20 + IR1-IR6 stack-specific + 7 ESLint custom rules + Next 15 specific configs)
- Создание `packages/meta-factory/` **skeleton only** (bin/cli, detector/, research/, synthesizer/, installer/ — пустые dirs или single placeholder file each)
- Workspace root setup (npm workspaces) — `package.json` с `workspaces` field
- Обновлённый `install.sh` — должен работать на workspace structure
- Phase 2 meta-tests должны проходить standalone в каждом package (это Phase 3 verdict gate)

**OUT of Phase 3 scope:**

| Item | Reason out | Defer to |
|---|---|---|
| Phase 4 work (Stack Detector v1 logic enhancement) | New version-aware detection — separate phase | Phase 4 |
| ESLint version upgrade | Change in dependencies = scope creep | future maintenance |
| New rules в manifest | Phase 5 validator scope | Phase 5 |
| Stryker mutation runtime | Phase 5 (validator) | Phase 5 |
| Research agent implementation | Phase 6 | Phase 6 |
| Path B (creative synthesis) | Phase 9+ | Phase 9+ |
| Confidence-tier registry для нишевых стеков | Phase 8+ | Phase 8+ |

### Block 2 — Verification (real commands, not narrative)

После split — выполнить **все** verification команды из [EXECUTION-PLAN.md:412-422](EXECUTION-PLAN.md):

```bash
# 1. Workspace install
cd /Users/art/code/rules-as-tests-aif && npm install

# 2. Self-audit green из workspace root
cd /Users/art/code/rules-as-tests-aif && make self-audit

# 3. Phase 2 meta-tests green standalone в каждом package (verdict gate per Block 3)
cd /Users/art/code/rules-as-tests-aif/packages/core && npm test
cd /Users/art/code/rules-as-tests-aif/packages/preset-next-15-canonical && npm test
cd /Users/art/code/rules-as-tests-aif/packages/meta-factory && npm run typecheck

# 4. npm pack simulation (consumer install scenario)
cd /Users/art/code/rules-as-tests-aif/packages/core && npm pack
cd /tmp && rm -rf fake-consumer && mkdir fake-consumer && cd fake-consumer
npm init -y && npm install /Users/art/code/rules-as-tests-aif/packages/core/*.tgz

# 5. CI YAML still valid + actionlint clean
python3 -c "import yaml; yaml.safe_load(open('/Users/art/code/rules-as-tests-aif/.github/workflows/audit-self.yml'))"
actionlint /Users/art/code/rules-as-tests-aif/.github/workflows/audit-self.yml

# 6. Pre-commit + pre-push hooks still pass after split
bash /Users/art/code/rules-as-tests-aif/.husky/pre-commit
bash /Users/art/code/rules-as-tests-aif/.husky/pre-push
```

**Каждое claim в return report должно быть привязано к команде** — не «всё работает», а «pre-commit exit 0, output: ...».

### Block 3 — Verdict gate

**GO к Phase 4 только если выполнены ВСЕ:**

1. ✅ `packages/core && npm test` — Phase 2 meta-tests pass (24/24)
2. ✅ `packages/preset-next-15-canonical && npm test` — 7 ESLint custom rules pass + applicable subset Phase 2 meta-tests pass
3. ✅ `packages/meta-factory && npm run typecheck` — skeleton compiles (TypeScript strict)
4. ✅ `make self-audit` green из workspace root
5. ✅ Pre-commit + pre-push hooks green после split
6. ✅ npm pack simulation работает на `packages/core`

**Если хоть один не выполнен → REVISE** (не GO с deferral'ом — это hard gate per план).

### Block 4 — REVISE/STOP triggers

**STOP triggers:**
- **Circular deps между пакетами** — `packages/core/` импортирует из `packages/preset-*/` или `packages/meta-factory/`. Это нарушение §13.3 hypothesis (core не должен зависеть от generated). Per [EXECUTION-PLAN.md:427](EXECUTION-PLAN.md): «§13.3 неправильно решён, пересмотреть».
- **`packages/core/` ≥70% размера старого пакета** (counted by source file LOC, not docs/tests) — split не дал semantic separation; per [EXECUTION-PLAN.md:428](EXECUTION-PLAN.md): «split не дал ничего».

**REVISE triggers** (sub-agent fixes + retries):
- **Файлы которые сложно классифицировать** между core и preset (>3 such files) — кандидаты на hybrid категорию §13.3.
- **Phase 2 meta-tests fail standalone в каком-то package** — split нарушил dependencies meta-tests.

**Decision gates requiring Art's explicit approval BEFORE commit (not REVISE — substantive choices)** (Fix 2 per reviewer 2026-05-07):
- **Workspace tooling** (npm workspaces vs pnpm vs yarn) — long-term commitment, hard to change later. Subagent proposes choice + rationale; **PAUSE** для Art's OK перед creating root `package.json`.
- **Hard-to-classify files (>3)** — список + proposed allocation; **PAUSE** для Art's call перед commit.
- **TS-server preset fate** (ambiguity per Fix 1) — see Mapping section below.

**Time stop-rule** per [EXECUTION-PLAN.md §8](EXECUTION-PLAN.md): >2x planned 1-2 недели = >4 недели → mandatory RCA section per [EXECUTION-PLAN.md §5](EXECUTION-PLAN.md).

### Block 5 — Trust-but-verify reminder (lessons learned)

Phase 1 и Phase 1.D зафиксировали 3 instances over-claim'а subagent'ов:

1. **Phase 1.C** (commit `5b60d6e`): subagent claimed «pre-commit soft warn ✓» — реально dead code после `exit "$fail"`. Caught by reviewer Opus.
2. **Phase 1.D** (commit `d6eba6c`): subagent claimed «MAJOR-2 closed» — phantom `principles.md` всё ещё в 4 locations. Caught by orchestrator independent grep.
3. **Phase 1.D**: subagent claimed «mutation test passes» в reviewer artifacts — required vitest output snippet evidence per Phase 2 prompt.

**Implication для этого Phase 3 prompt:**

- Каждое claim в return report MUST be backed evidence (command output snippet, file content excerpt, exit code)
- НЕ «работает», а «команда X exited 0, output (last 10 lines): ...»
- НЕ «split chistый», а «`packages/core/` size = N LOC vs old pkg M LOC, ratio = N/M = X.XX, ≤0.70 ✓»
- НЕ «dependencies clean», а «`madge --circular packages/core/` exit 0, no cycles found»
- Orchestrator пере-проверит каждое claim independent grep/test/wc post-execution. If discrepancy → finding в Phase 3 retro Addendum (как Phase 1.D MAJOR-2 fix).

### Block 6 — Subagent self-verification + orchestrator post-verify

**Subagent's обязанности (verifies own commit):**

1. После создания каждого package — запустить verification commands из Block 2 на этом package
2. После создания workspace root — запустить full verification suite
3. Перед commit — read commit diff, убедиться что нет stray files (например, `node_modules/` в git)
4. Перед commit — verify все claims в commit message backed by evidence (no "works" without command output)
5. После commit — запустить pre-push hook locally, убедиться что push не блокируется

**Orchestrator пере-проверит (per pattern из commit `184c2be`):**

1. Independent `find` для всех созданных files
2. Independent run всех 6 verification commands
3. Independent grep на «principles.md» phantom (Phase 1.D lesson) и других anti-patterns
4. Independent check что Phase 2 meta-tests реально pass standalone в каждом package
5. Independent check что workspace dependency graph нет cycles
6. Если orchestrator находит расхождение между subagent's claim и actual state → Phase 3 retro Addendum + fix commit

---

## Артефакты для создания (granular)

### 0. Explicit file mapping (Fix 1+3 per reviewer 2026-05-07)

**`templates/` post-split mapping table** (every current file accounted for):

| Source path | Target | Rationale |
|---|---|---|
| `templates/shared/eslint-rules/*.{ts,test.ts}` (7 rules) | `packages/preset-next-15-canonical/eslint-rules/` ИЛИ split between core+preset based on stack-dependence | См. ambiguity note ↓ |
| `templates/shared/{husky-pre-commit.sh, husky-pre-push.sh, .lintstagedrc.json, .nvmrc, tsconfig.json, AGENTS.md.template, CLAUDE.md.template}` | `packages/core/templates/shared/` | Universal consumer-side artefacts; не связаны со stack |
| `templates/react-next/**/*` (6 files: storybook, eslint config, playwright, vitest, github-actions-ci-ui.yml, storybook-package-additions.json) | `packages/preset-next-15-canonical/templates/` | React/Next 15 specific |
| `templates/ts-server/**/*` (5 files: dependency-cruiser, stryker, github-actions-ci.yml, vitest, eslint config) | **DECISION GATE — Art approval required** (option A: stays в root `templates/ts-server/` legacy; option B: создать `packages/preset-ts-server-canonical/` parallel) | §9.2 migration plan упоминает только `preset-next-15-canonical` — ts-server preset не в Phase 3 scope per Block 1; default option A unless Art chooses B |

**eslint-rules ambiguity (subagent должен classify each file + flag findings):**
- Stack-specific (→ preset-next-15-canonical): `no-server-imports-in-client`, `require-use-server-directive`, `require-form-safe-parse` (Server Actions / 'use client' / 'use server' boundaries)
- Generic candidates (→ core): `no-direct-time-randomness` (TS hygiene), `no-unsafe-zod-parse` (Zod usage — но scoped к React forms?), `require-otel-span` (observability — universal или Next-specific?)
- **Subagent classifies each, flags any ambiguity в return report** (per Block 4 «hard-to-classify >3 files = decision gate»)

**`scripts/` post-split mapping table** (Fix 3):

| Source path | Target | Rationale |
|---|---|---|
| `scripts/principles/*.test.ts` (7 files) | `packages/core/principles/` | Phase 2 meta-tests, generic |
| `scripts/render-rules.ts` + `.test.ts` + `__snapshots__/` | `packages/core/render/` | Manifest → RULES.md rendering, generic |
| `scripts/validate-batch-spec.ts` + `.test.ts` | `packages/core/spec-validation/` | Spec discipline tooling, generic |
| `scripts/audit-ai-docs.sh` + `.react-next.sh` | `packages/core/audit-self/` (.sh) + `packages/preset-next-15-canonical/audit-self/` (.react-next.sh) | Generic + stack-specific split |
| `scripts/audit-r4.ts` | `packages/core/probes/` | R4 probe runner, generic |
| `scripts/detect-applicable-rules.ts` + `.test.ts` | `packages/core/detector-v0/` (placeholder; Phase 4 will enhance) | Phase 4 dependency, but file lives in core |
| `scripts/package.json` | **NOT moved** — workspace root `package.json` becomes superset; per-package `package.json` создаются заново | Avoids stale dependencies; explicit per-package deps |
| `scripts/package-lock.json` | **DELETED** — replaced by root `package-lock.json` | Single lockfile per workspace |
| `scripts/node_modules/` | **DELETED** | Workspaces hoist to root |

**`scripts/` directory after split:** **EMPTY → REMOVED** via `rmdir scripts/` after move. Verification: `test ! -d /Users/art/code/rules-as-tests-aif/scripts || echo "scripts still exists, FAIL"`.

**`tests/audit/audit-ai-docs.test.sh`** → `packages/core/audit-self/audit-ai-docs.test.sh` (already noted в section 2 below).

**`factory/`** → contents move to `packages/core/manifest/` and `packages/preset-next-15-canonical/rules/` (R12-R20 + IR1-IR6 stack-specific RULES). `factory/` directory **DELETED** post-move.

---

### 1. Workspace root files

- `/Users/art/code/rules-as-tests-aif/package.json` — root workspace manifest:
  ```json
  {
    "name": "rules-as-tests-aif-workspace",
    "private": true,
    "workspaces": ["packages/*"],
    "scripts": {
      "test": "npm test --workspaces --if-present",
      "typecheck": "npm run typecheck --workspaces --if-present"
    }
  }
  ```
- `/Users/art/code/rules-as-tests-aif/Makefile` — extend existing self-audit target для workspace root execution

### 2. `packages/core/`

**Содержание (move from current locations):**
- `factory/rules-manifest.json` → `packages/core/manifest/rules-manifest.json`
- `factory/rules-manifest.schema.json` → `packages/core/manifest/rules-manifest.schema.json`
- Generic R1-R10 правила (subset of `factory/RULES.md` — TS hygiene, async, errors, naming)
- `scripts/principles/*.test.ts` (Phase 2 meta-tests) → `packages/core/principles/*.test.ts`
- `scripts/render-rules.ts`, `render-rules.test.ts` → `packages/core/`
- `scripts/validate-batch-spec.ts`, `.test.ts` → `packages/core/spec-validation/`
- `tests/audit/audit-ai-docs.test.sh` → `packages/core/audit-self/audit-ai-docs.test.sh`
- `package.json` per [migration-from-current.md §9.2](migration-from-current.md): peerDeps на ESLint flat config, vitest, tsx, ajv

**Verification:** `cd packages/core && npm test` — все Phase 2 meta-tests + render-rules.test + validate-batch-spec.test pass.

### 3. `packages/preset-next-15-canonical/`

**Содержание:**
- R12-R20 + IR1-IR6 stack-specific правила (subset из `factory/RULES.md`, `factory/RULES.react-next.md`)
- `templates/shared/eslint-rules/` (7 ESLint custom rules с RuleTester paired tests) → `packages/preset-next-15-canonical/eslint-rules/`
- `templates/react-next/` configs → `packages/preset-next-15-canonical/templates/`
- Next.js 15 specific `@next/eslint-plugin-next@^15.0.0` peerDep
- `package.json` peerDeps: `@core: workspace:*`

**Verification:** `cd packages/preset-next-15-canonical && npm test` — 7 ESLint custom rules pass + applicable subset Phase 2 meta-tests pass.

### 4. `packages/meta-factory/` (skeleton)

**Содержание (placeholders only):**
- `bin/meta-factory.mjs` — single-line CLI entry placeholder
- `src/detector/index.ts` — empty export или 1-line type
- `src/research/index.ts` — empty export
- `src/synthesizer/index.ts` — empty export
- `src/installer/index.ts` — empty export
- `tsconfig.json` — strict TS config
- `package.json` — peerDeps на @core: workspace:*

**Verification:** `cd packages/meta-factory && npm run typecheck` — TS compiles без errors.

### 5. Updated `install.sh`

- Adapted под workspace structure: copy from `packages/preset-next-15-canonical/templates/` instead of root `templates/`
- Updated paths во всех `copy_safe` calls
- **Backward-compatible CLI** — `bash install.sh` continues to work как раньше для consumers (the change is internal only)

### 6. `audit-self.yml` updated jobs

- `mechanical` — обновить find paths под workspace
- `principles-meta-tests` — должен работать через `npm run test --workspaces`
- `framework-self-install-{ts-server,react-next}` — путь к install.sh не меняется, но проверять что workspace install.sh работает

### 7. Phase 3 retro `docs/meta-factory/retros/phase-3.md`

Standard format (Verification / Self-reflection / Evaluation), плюс mandatory:

- **Block 3 verdict gate check** — все 6 пунктов с evidence
- **Block 4 STOP/REVISE check** — circular deps result, packages/core size ratio, hard-to-classify files count
- **§13.3 Phase 3 closure** — финальная классификация invariant↔generated boundary; update [open-questions.md §13.3](open-questions.md) finalizing partial closure из Phase 2
- **Workspace tooling decision rationale** — почему npm workspaces (vs pnpm vs yarn) с tradeoffs
- **Migration script** или manual diff — что было перенесено куда (audit trail)

---

## Verification (full sequence — run after all artifacts created)

```bash
# 1. Workspace install (no errors, no warnings about peer deps)
cd /Users/art/code/rules-as-tests-aif && npm install 2>&1 | tail -5

# 2. Self-audit green из workspace root
make self-audit

# 3. Phase 2 meta-tests standalone в каждом package
for pkg in core preset-next-15-canonical meta-factory; do
  echo "=== $pkg ==="
  if [ "$pkg" = "meta-factory" ]; then
    cd "packages/$pkg" && npm run typecheck && cd ../..
  else
    cd "packages/$pkg" && npm test && cd ../..
  fi
done

# 4. npm pack consumer simulation
cd packages/core && npm pack
TGZ=$(ls /Users/art/code/rules-as-tests-aif/packages/core/*.tgz)
mkdir -p /tmp/fake-consumer && cd /tmp/fake-consumer
npm init -y --silent && npm install "$TGZ"
ls node_modules/  # expect: rules-as-tests-aif-core or similar

# 5. CI checks valid
python3 -c "import yaml; yaml.safe_load(open('/Users/art/code/rules-as-tests-aif/.github/workflows/audit-self.yml'))"
actionlint /Users/art/code/rules-as-tests-aif/.github/workflows/audit-self.yml
zizmor --format plain /Users/art/code/rules-as-tests-aif/.github/workflows/

# 6. Hooks pass
cd /Users/art/code/rules-as-tests-aif && bash .husky/pre-commit
cd /Users/art/code/rules-as-tests-aif && bash .husky/pre-push

# 7. Block 4 STOP triggers — explicit checks
# (a) Circular deps
npx madge --circular --warning packages/ 2>&1 | tail -3
# expect: "✔ No circular dependencies found"

# (b) packages/core size ratio
OLD_LOC=$(find scripts factory templates -type f \( -name '*.ts' -o -name '*.json' -o -name '*.md' \) -not -path '*/node_modules/*' | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
NEW_LOC=$(find packages/core -type f \( -name '*.ts' -o -name '*.json' -o -name '*.md' \) -not -path '*/node_modules/*' | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
echo "core/old ratio: $NEW_LOC / $OLD_LOC = $(echo "scale=2; $NEW_LOC / $OLD_LOC" | bc) (expect ≤0.70)"

# (c) Hard-to-classify files
# Subjective — list любые файлы которые pretendent на оба categories, > 3 = REVISE per Block 4
```

---

## Hard constraints

- **NO `git commit --no-verify`** — нарушает self-application
- **NO `git push`** — orchestrator decides push timing
- **NO scope expansion** в Phase 4-6 work (Block 1 OUT list)
- **NO dependency upgrades** (ESLint, vitest, tsx, ajv versions stay)
- **NO new rules added к manifest** — only move existing
- **NO `node_modules/` или package-lock.json в committed files** — verify через `git status` перед commit
- **Pinned SHAs** в новых YAML changes (use existing `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683`)
- **Real filenames** per MAJOR-2 fix — `skills/rules-as-tests/{SKILL.md, references/overview.md, references/ai-traps.md}` (no phantom `principles.md`)
- **Backward-compat install.sh** — consumers running `bash install.sh` should not see change in behavior
- **Independent verification** в return report: каждое claim → command output / file content / line count

---

## Возврат результата

Структурированный report (под 800 слов):

1. **Created/modified artifacts** список с line counts (sorted by package)
2. **Block 2 verification results** все 6 commands с output snippets (last 5-10 lines each)
3. **Block 3 verdict gate** — 6 checkmarks с evidence
4. **Block 4 STOP/REVISE check:**
   - Circular deps: `madge --circular` output
   - packages/core size ratio: numeric calculation с командой
   - Hard-to-classify files: explicit list (or "0 files")
   - Workspace tooling choice: «npm workspaces because...»
5. **§13.3 Phase 3 closure summary** — финальная классификация invariant↔generated с rationale (для open-questions.md update)
6. **Migration audit trail** — что было перенесено куда (file mapping table), что было создано new
7. **Findings for Phase 3 retro:** discovery в процессе (например, файлы которые могли быть в обоих, dependency surprises)
8. **Commit hashes** (sequence)
9. **Open questions for orchestrator:** decisions taken self с rationale (особенно при ambiguity — например, размещение common configs)
10. **Trust-but-verify items для orchestrator post-verify** — список claims которые orchestrator должен independent grep/test/wc

**Hard requirement:** if return report claims «N tests pass» — provide exact command + output. If claims «package builds» — provide tsc/typecheck output. If claims «no cycles» — provide madge output. If claims size ratio — provide numeric formula. **Trust-but-verify pattern enforced** post Phase 1.C/1.D.

---

## Версия

- **0.1.0** — 2026-05-07 — first version, embeds reviewer's 6 mandatory blocks + Phase 1.C/1.D over-claim lessons.
- **0.1.1** — 2026-05-07 — applied 3 reviewer pre-flight fixes: (Fix 1) explicit `templates/` mapping table including ts-server decision gate; (Fix 2) workspace tooling reclassified из REVISE trigger в Decision Gate (Block 4); (Fix 3) explicit `scripts/` post-split mapping table + `scripts/` removed post-move.

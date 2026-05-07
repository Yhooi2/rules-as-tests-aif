# Retro: Phase 1 batch 1.B — Framework-self-install CI

**Status:** GO (with documented limitation)
**Closed at:** 2026-05-07
**Time spent:** ~3 минуты subagent + ~3 минуты verification (planned: 1-2 дня)
**Commit:** `f45b2da feat(self-application): Phase 1.B framework-self-install CI (ts-server + react-next)`

---

## Verification

### Mechanical

| Команда | Expected | Actual | Result |
|---|---|---|---|
| `python3 yaml.safe_load(audit-self.yml)` | parses | parses | ✓ |
| Job count | 7 (5 from 1.A + 2 new) | 7 | ✓ |
| Job names | `framework-self-install-{ts-server,react-next}` | confirmed | ✓ |
| `on.push.branches` | includes `chore/**` | `['main', 'chore/**']` | ✓ |
| SHA pinning | only verified pre-existing SHAs | 2 distinct: `11bd7190...` (checkout v4.2.2), `49933ea5...` (setup-node v4.4.0) | ✓ |
| Permissions | `contents: read` only | confirmed both jobs | ✓ |
| No fabricated SHAs | grep + manual check | clean | ✓ |

### Runtime CI verification — DEFERRED

Per план §6 Phase 1.B verification:
```
git checkout -b test/break-install
sed -i '' 's|copy_safe.*ARCHITECTURE|# DELETED|' install.sh
git add . && git commit && git push
gh run watch                                  # должно стать red
```

**Status:** не запущено в этой phase (требует push в GitHub, который оставлен Art'у). Записано в Phase 1 composite retro как required smoke test перед closing Phase 1.

---

## Self-reflection

### Job duration estimate

Per subagent report: ~33s per job (checkout 10s + setup-node 5s + pip install pyyaml 5s + install.sh 3s + audit-ai-docs.test.sh 10s). Под 2-минутным threshold плана. **OK.**

### React-next path requires storybook init — handled?

**Decision: skipped.** subagent excluded `setup.sh` invocation полностью. Rationale:
- `setup.sh` hard-depends on `ai-factory` CLI (global binary, not in tmp consumer)
- `setup.sh` calls `npm install` (требует package-lock context, не существующий в tmp consumer)
- Smoke с `setup.sh` требует CI install ai-factory + npm setup — **scope creep** для Phase 1.B

**Closes L5 self-application clause только частично:**
- ✓ install.sh file copies — verified by `audit-ai-docs.test.sh` после копирования
- ✗ setup.sh stack detection / template selection / npm install / husky init / storybook init — **не tested** в Phase 1.B

**Action item для Phase 7** (installer release): добавить fixture-based testing с pre-installed `ai-factory` CLI и npm context для full setup.sh smoke.

### Edge cases on tmp-dir handled?

`git init --quiet` + `git config user.email/name` + `echo '{...}' > package.json` — minimum viable consumer. install.sh validates package.json existence (lines 46-54). **OK.**

React-next job также создаёт `next.config.js` для exercise auto-detection path в setup.sh — но since setup.sh не invoked, этот файл не используется. **Cosmetic, не функциональный.** Можно убрать в follow-up или оставить как future-proofing.

### Fixture-based testing vs tmp-dir

Plan §6 Phase 1.B self-reflection: «tmp-dir может скрыть real-world problems → fixture-based testing с подготовленными скелетами».

**Decision: tmp-dir сейчас, fixtures отложены.**

Rationale:
- L5 self-application acceptance criterion (`framework-self-install` green) **достижим через tmp-dir** для file-copy layer
- Fixture-based — additional reproducibility, но maintenance overhead
- «Real-world problem» которое fixtures expose'ят (wrong content) — не covered current audit probes anyway → fixtures без новых probes — cargo cult

**Reconsider** на Phase 7 если CI flakiness потребует fixtures.

### Соблазн «сделать на потом»

- ⚠ **One judgment call:** subagent decided EXCLUDE `setup.sh` smoke полностью, без fallback step. Я как orchestrator подтверждаю: правильно — partial smoke хуже чем явно documented gap. Honest "этот layer не testable в этой phase'е" лучше ложного «всё работает».

### Unknown unknowns

- **setup.sh failure modes исключены из CI coverage.** Steps 3-5 (ai-factory init, npm install, husky init, storybook init) могут регрессировать без detection до Phase 7. Risk: user installing framework discovers broken setup. Mitigation для proof-of-concept (no consumers yet) — **acceptable**. Для 1.0 release — must close в Phase 7.
- **`enforce-husky-presence` зависит от grep keywords** (Phase 1.A finding). Если в будущем pre-push hook добавит новый probe — keyword список ОК. Если убрать `actionlint` или `zizmor` — gate станет always-pass (ломанный hook не detect'ed). Кандидат для §13 PROPOSAL composite retro.

---

## Evaluation

### Self-application score: 7/10

Plan §6 Phase 1.B evaluation: «Self-application score: 8/10».

**Actual: 7/10** (на 1 пункт **ниже** plan'a) потому что:
- ✅ install.sh layer covered (file copies tested)
- ✅ Two presets covered (ts-server + react-next)
- ✅ CI runs framework's own audit on installed artifacts
- ✅ SHA discipline (no fabricated SHAs)
- ❌ **setup.sh layer не covered** — это значимое exclusion, downgrade score
- ❌ Runtime CI verification still deferred (no push'а в этой session'е)

### Time-vs-plan ratio: ~0.005x

Planned: 1-2 дня. Actual: ~6 минут total. Ratio ≪ 0.5x, RCA не требуется.

**Confirmed pattern:** mechanical synthesis в audit-self.yml через subagent эффективен; runtime verification (которая dragged бы phase) — отложена. **Caveat для Phase 1.C:** spec validation requires actual scripting (`scripts/validate-batch-spec.ts` — TS code), не только YAML. Не extrapolating ratio.

### New risks identified

| Risk | Where to add |
|---|---|
| setup.sh steps 3-5 (ai-factory/npm/husky/storybook init) не CI-tested | §11 PROPOSAL row + Phase 7 scope |
| `enforce-husky-presence` keyword grep stale at hook refactoring | §13 PROPOSAL composite retro candidate (joins existing Phase 1.A finding) |
| `next.config.js` fixture в react-next job не используется (setup.sh excluded) | follow-up cleanup, not blocker |

### Verdict: GO

L5 self-application clause partially closed — file-copy layer ✓, setup.sh layer documented exclusion. Acceptance criterion из self-application.md §7 «Job framework-self-install зелёный» достижим **after push в GitHub**. Local YAML/SHA validation ✓.

**GO к Phase 1 batch 1.C** (spec validation script).

**Pre-Phase-1.C action items:**

1. Закоммитить этот retro перед стартом 1.C
2. (deferred to composite retro) добавить 2 risks выше в §11/§13 PROPOSAL
3. (deferred to Art) push branch для runtime CI verification batch'ей 1.A + 1.B перед closing Phase 1

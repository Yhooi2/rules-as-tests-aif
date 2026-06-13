# /pipeline skill i18n Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the entire `/pipeline` skill English-canonical, with Russian delivered to the operator via a hook-style language pack selected by `AIF_HOOK_LANG`.

**Architecture:** Three string classes (per spec `docs/superpowers/specs/2026-06-03-pipeline-skill-i18n-design.md`): (1) emitted operator-facing tokens → new `.claude/skills/pipeline/lang/{en,ru}.sh` sourced by a helper and injected via `!shell`; (2) all skill prose → English in place; (3) decision-detection phrases → bilingual RU+EN inline (the one exception, mirroring the hook's bilingual detection regex). principle 18 updated in lockstep.

**Tech Stack:** Bash (lang packs, helper, parity check), Markdown (skill files), Vitest + TypeScript (principle 18 + companion tests). No paid LLM; deterministic checks only.

**Branch:** `feat/pipeline-skill-i18n` (already created, stacked on `feat/meta-orch-stage5-rename` / PR #397; the `pipeline/` directory rename is a prerequisite already present).

**Reference precedent (read before starting):** `.claude/hooks/lang/en.sh`, `.claude/hooks/lang/ru.sh`, `.claude/hooks/lang/check-parity.sh`, and spec `docs/superpowers/specs/2026-06-01-hook-lang-i18n-design.md`.

---

## File Structure

- Create `.claude/skills/pipeline/lang/en.sh` — English emitted-token pack (canonical default). Defines `AIF_PIPELINE_*` variables + `AIF_RECAP_MARKER`.
- Create `.claude/skills/pipeline/lang/ru.sh` — Russian emitted-token pack (operator). Same keys, Russian values.
- Create `.claude/skills/pipeline/lang/check-parity.sh` — key-parity check between the two skill packs (adapted from the hook copy).
- Create `.claude/skills/pipeline/helpers/emit-output-strings.sh` — sources `${AIF_HOOK_LANG:-en}` pack with EN fallback, echoes the active-language tokens as `KEY=value` lines.
- Modify `.claude/skills/pipeline/references/output-format.md` — translate prose to EN; example tables use EN headers.
- Modify `.claude/skills/pipeline/SKILL.md` — §10 injects `emit-output-strings.sh` via `!shell`; translate all prose to EN; bilingual detection phrases where present.
- Modify `.claude/skills/pipeline/references/{anti-rationalization,red-flags}.md` — prose → EN; detection phrases → bilingual RU+EN.
- Modify `.claude/skills/pipeline/references/{placeholders,plain-language-tail}.md`, `templates/meta-kickoff.template.md`, `templates/state.md.template` — translate residual Russian prose to EN.
- Create `packages/core/skills/emit-output-strings.test.ts` — companion test for the helper (fallback + key emission).
- Create `packages/core/skills/pipeline-lang-parity.test.ts` — asserts `lang/check-parity.sh` exits 0.
- Create `packages/core/skills/pipeline-english-canonical.test.ts` — the whole-skill-English invariant.
- Modify `packages/core/principles/18-meta-orchestrator-output-format.test.ts` — EN canonical substrings + `AIF_HOOK_LANG=ru` pack case.

**Token inventory (the Class-1 emitted set — the pack keys):**

| Key | EN value | RU value |
|---|---|---|
| `AIF_PIPELINE_COL_PASTE` | `Paste into a new CC tab` | `Paste в новый CC tab` |
| `AIF_PIPELINE_COL_WHEN` | `When` | `Когда` |
| `AIF_PIPELINE_COL_WAITING` | `Waiting on` | `Ждёшь` |
| `AIF_PIPELINE_COL_PARALLEL` | `Can parallel with` | `Можно параллельно с` |
| `AIF_PIPELINE_LBL_WHATDOES` | `What it does` | `Что делает` |
| `AIF_PIPELINE_LBL_WHYNOW` | `Why now` | `Почему сейчас` |
| `AIF_PIPELINE_STATUS_CURRENT` | `current` | `актуален` |
| `AIF_PIPELINE_WAVE_NOW` | `NOW` | `СЕЙЧАС` |
| `AIF_PIPELINE_ACTION_QUEUE_SUB` | `what you do next` | `что ты делаешь дальше` |
| `AIF_RECAP_MARKER` | `## 🟢 In plain words` | `## 🟢 Простыми словами` |

> Step 0 (do once before Task 1): re-run `LC_ALL=en_US.UTF-8 grep -n '[А-Яа-яЁё]' .claude/skills/pipeline/references/output-format.md` and confirm every emitted token above is present and that the table above is complete. If a new emitted token surfaces, add a pack key for it (do NOT leave it untranslated in the markdown).

---

### Task 1: Create the English + Russian lang packs

**Files:**
- Create: `.claude/skills/pipeline/lang/en.sh`
- Create: `.claude/skills/pipeline/lang/ru.sh`

- [ ] **Step 1: Write `lang/en.sh`**

```bash
#!/usr/bin/env bash
# @cc-only-rationale: NONE — this pack IS shipped (the /pipeline skill ships via install.sh:237-256). EN is the canonical default.
# @dual-pair: pipeline-lang-i18n
#
# English emitted-token pack for the /pipeline skill session report.
# Canonical default — used when AIF_HOOK_LANG is unset or names a missing pack.
# Sibling: lang/ru.sh (operator). Key parity enforced by lang/check-parity.sh.
# See docs/superpowers/specs/2026-06-03-pipeline-skill-i18n-design.md.

AIF_PIPELINE_COL_PASTE='Paste into a new CC tab'
AIF_PIPELINE_COL_WHEN='When'
AIF_PIPELINE_COL_WAITING='Waiting on'
AIF_PIPELINE_COL_PARALLEL='Can parallel with'
AIF_PIPELINE_LBL_WHATDOES='What it does'
AIF_PIPELINE_LBL_WHYNOW='Why now'
AIF_PIPELINE_STATUS_CURRENT='current'
AIF_PIPELINE_WAVE_NOW='NOW'
AIF_PIPELINE_ACTION_QUEUE_SUB='what you do next'
AIF_RECAP_MARKER='## 🟢 In plain words'
```

- [ ] **Step 2: Write `lang/ru.sh`** (same keys, Russian values; same header but "Russian … operator" + drop the `@cc-only-rationale: NONE` note's "canonical default" phrasing)

```bash
#!/usr/bin/env bash
# @cc-only-rationale: NONE — shipped with the /pipeline skill. Operator pack, selected by AIF_HOOK_LANG=ru.
# @dual-pair: pipeline-lang-i18n
#
# Russian emitted-token pack for the /pipeline skill session report.
# Sourced when AIF_HOOK_LANG=ru. Sibling: lang/en.sh (canonical default).
# See docs/superpowers/specs/2026-06-03-pipeline-skill-i18n-design.md.

AIF_PIPELINE_COL_PASTE='Paste в новый CC tab'
AIF_PIPELINE_COL_WHEN='Когда'
AIF_PIPELINE_COL_WAITING='Ждёшь'
AIF_PIPELINE_COL_PARALLEL='Можно параллельно с'
AIF_PIPELINE_LBL_WHATDOES='Что делает'
AIF_PIPELINE_LBL_WHYNOW='Почему сейчас'
AIF_PIPELINE_STATUS_CURRENT='актуален'
AIF_PIPELINE_WAVE_NOW='СЕЙЧАС'
AIF_PIPELINE_ACTION_QUEUE_SUB='что ты делаешь дальше'
AIF_RECAP_MARKER='## 🟢 Простыми словами'
```

- [ ] **Step 3: Verify both source cleanly**

Run: `bash -n .claude/skills/pipeline/lang/en.sh && bash -n .claude/skills/pipeline/lang/ru.sh && echo OK`
Expected: `OK`

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/pipeline/lang/en.sh .claude/skills/pipeline/lang/ru.sh
git commit -m "feat(pipeline-i18n): add en/ru emitted-token lang packs"
```

---

### Task 2: Create the emit-output-strings helper (TDD)

**Files:**
- Test: `packages/core/skills/emit-output-strings.test.ts`
- Create: `.claude/skills/pipeline/helpers/emit-output-strings.sh`

- [ ] **Step 1: Write the failing test**

```typescript
import { describe, it, expect } from 'vitest';
import { execFileSync } from 'node:child_process';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(HERE, '../../..');
const HELPER = resolve(REPO_ROOT, '.claude/skills/pipeline/helpers/emit-output-strings.sh');

function run(lang: string | undefined): string {
  const env = { ...process.env };
  if (lang === undefined) delete env.AIF_HOOK_LANG;
  else env.AIF_HOOK_LANG = lang;
  return execFileSync('bash', [HELPER], { env, encoding: 'utf8' });
}

describe('emit-output-strings.sh', () => {
  it('default (no AIF_HOOK_LANG) emits English tokens', () => {
    const out = run(undefined);
    expect(out).toMatch(/AIF_PIPELINE_COL_WHEN=When/);
    expect(out).toMatch(/AIF_RECAP_MARKER=## 🟢 In plain words/);
  });

  it('AIF_HOOK_LANG=ru emits Russian tokens', () => {
    const out = run('ru');
    expect(out).toMatch(/AIF_PIPELINE_COL_WHEN=Когда/);
    expect(out).toMatch(/AIF_RECAP_MARKER=## 🟢 Простыми словами/);
  });

  // paired-negative: unknown lang must FALL BACK to English, not emit empty / crash.
  it('unknown AIF_HOOK_LANG falls back to English (non-empty)', () => {
    const out = run('zz');
    expect(out).toMatch(/AIF_PIPELINE_COL_WHEN=When/);
    expect(out.trim().length).toBeGreaterThan(0);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx --prefix packages/core vitest run skills/emit-output-strings.test.ts --root packages/core`
Expected: FAIL (helper file does not exist → execFileSync throws / ENOENT)

- [ ] **Step 3: Write the helper**

```bash
#!/usr/bin/env bash
# @cc-only-rationale: NONE — shipped with the /pipeline skill (install.sh). Emits the active-language session-report tokens for SKILL.md §10 !shell injection.
# @dual-pair: pipeline-lang-i18n
#
# Sources the language pack selected by AIF_HOOK_LANG (default en; hard EN
# fallback if the requested pack file is missing), then echoes every emitted
# token as KEY=value lines for the skill to read in §10.
# See docs/superpowers/specs/2026-06-03-pipeline-skill-i18n-design.md.
set -euo pipefail

_lang_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lang" && pwd)"
_lang_file="${_lang_dir}/${AIF_HOOK_LANG:-en}.sh"
[ -f "$_lang_file" ] || _lang_file="${_lang_dir}/en.sh"
# shellcheck source=/dev/null
. "$_lang_file"

for k in AIF_PIPELINE_COL_PASTE AIF_PIPELINE_COL_WHEN AIF_PIPELINE_COL_WAITING \
         AIF_PIPELINE_COL_PARALLEL AIF_PIPELINE_LBL_WHATDOES AIF_PIPELINE_LBL_WHYNOW \
         AIF_PIPELINE_STATUS_CURRENT AIF_PIPELINE_WAVE_NOW AIF_PIPELINE_ACTION_QUEUE_SUB \
         AIF_RECAP_MARKER; do
  printf '%s=%s\n' "$k" "${!k}"
done
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx --prefix packages/core vitest run skills/emit-output-strings.test.ts --root packages/core`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/pipeline/helpers/emit-output-strings.sh packages/core/skills/emit-output-strings.test.ts
git commit -m "feat(pipeline-i18n): emit-output-strings helper sources lang pack by AIF_HOOK_LANG"
```

---

### Task 3: Create the per-skill parity check (TDD)

**Files:**
- Create: `.claude/skills/pipeline/lang/check-parity.sh`
- Test: `packages/core/skills/pipeline-lang-parity.test.ts`

- [ ] **Step 1: Write the parity check** (adapted from `.claude/hooks/lang/check-parity.sh`; keys are `AIF_PIPELINE_*` vars + `AIF_RECAP_MARKER`)

```bash
#!/usr/bin/env bash
# @cc-only-rationale: NONE — shipped with the /pipeline skill. Drift guard between en.sh and ru.sh.
# @dual-pair: pipeline-lang-i18n
#
# Asserts en.sh and ru.sh expose the SAME set of AIF_PIPELINE_* / AIF_RECAP_MARKER
# variable keys. Deterministic, no LLM. Exit 0 = parity, 1 = drift.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

keys() { grep -oE '^(AIF_PIPELINE_[A-Z_]+|AIF_RECAP_MARKER)=' "$1" | sed 's/=$//' | sort -u; }

en="$(keys "$DIR/en.sh")"; ru="$(keys "$DIR/ru.sh")"
if [ "$en" = "$ru" ]; then
  echo "OK: en.sh and ru.sh expose identical keys ($(echo "$en" | wc -l | tr -d ' ') entries)."
  exit 0
fi
echo "DRIFT: en.sh and ru.sh key sets differ." >&2
echo "--- only in en ---" >&2; comm -23 <(printf '%s\n' "$en") <(printf '%s\n' "$ru") >&2
echo "--- only in ru ---" >&2; comm -13 <(printf '%s\n' "$en") <(printf '%s\n' "$ru") >&2
exit 1
```

- [ ] **Step 2: Write the test**

```typescript
import { describe, it, expect } from 'vitest';
import { execFileSync } from 'node:child_process';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
const HERE = dirname(fileURLToPath(import.meta.url));
const SCRIPT = resolve(HERE, '../../..', '.claude/skills/pipeline/lang/check-parity.sh');

describe('pipeline lang parity', () => {
  it('en.sh and ru.sh expose identical keys', () => {
    const out = execFileSync('bash', [SCRIPT], { encoding: 'utf8' });
    expect(out).toMatch(/^OK:/);
  });
});
```

- [ ] **Step 3: Run test**

Run: `npx --prefix packages/core vitest run skills/pipeline-lang-parity.test.ts --root packages/core`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/pipeline/lang/check-parity.sh packages/core/skills/pipeline-lang-parity.test.ts
git commit -m "feat(pipeline-i18n): per-skill lang parity check"
```

---

### Task 4: Translate output-format.md to EN + wire §10 injection

**Files:**
- Modify: `.claude/skills/pipeline/references/output-format.md`
- Modify: `.claude/skills/pipeline/SKILL.md` (§10 region around line 454)

- [ ] **Step 1: Translate all prose in `output-format.md` to English.** Run `LC_ALL=en_US.UTF-8 grep -n '[А-Яа-яЁё]' .claude/skills/pipeline/references/output-format.md` and translate every line. For the example launch tables, use the **English** headers: `| # | Paste into a new CC tab | When | Waiting on | Can parallel with |`. Keep the structural substrings principle 18 needs (`## Dependency graph`, `↓`, `## Action queue`, `### Stage`). After this step the file has zero Cyrillic.

- [ ] **Step 2: Add the §10 injection note in SKILL.md.** In the §10 inline-session-report description (around line 454), add a line instructing the AI to source the active-language tokens before rendering the report:

```markdown
**Output language (i18n):** before rendering the report, run
`!bash ${CLAUDE_SKILL_DIR}/helpers/emit-output-strings.sh` and use the emitted
`AIF_PIPELINE_*` values for the launch-table column headers, the `What it does` /
`Why now` block labels, the `## Action queue` sub-caption, the wave-`NOW` marker,
the plan-currency status word, and the `AIF_RECAP_MARKER` recap heading. Default
is English; the operator's `AIF_HOOK_LANG=ru` yields Russian. The example tables
below show the English (default) tokens.
```

- [ ] **Step 3: Verify output-format.md has no Cyrillic**

Run: `LC_ALL=en_US.UTF-8 grep -c '[А-Яа-яЁё]' .claude/skills/pipeline/references/output-format.md`
Expected: `0`

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/pipeline/references/output-format.md .claude/skills/pipeline/SKILL.md
git commit -m "feat(pipeline-i18n): output-format.md → EN canonical + §10 lang injection"
```

---

### Task 5: Translate remaining skill prose; make detection phrases bilingual

**Files:**
- Modify: `.claude/skills/pipeline/SKILL.md` (residual prose lines 97, 139, 455, 490)
- Modify: `.claude/skills/pipeline/references/anti-rationalization.md`
- Modify: `.claude/skills/pipeline/references/red-flags.md`
- Modify: `.claude/skills/pipeline/references/placeholders.md`, `references/plain-language-tail.md`
- Modify: `.claude/skills/pipeline/templates/meta-kickoff.template.md`, `templates/state.md.template`

- [ ] **Step 1: Translate prose in each file to English.** For each file run `LC_ALL=en_US.UTF-8 grep -n '[А-Яа-яЁё]' <file>` and translate prose lines. The recap-block references use the English marker `## 🟢 In plain words` (canonical); SKILL.md status «План актуален» → "Plan is current".

- [ ] **Step 2: Make detection phrases bilingual (the Class-3 exception).** In `anti-rationalization.md` and `red-flags.md`, the *deferral-detection lists* keep the Russian tokens AND add the English equivalents, on the same line, e.g.:

```markdown
- Not-an-answer phrases (match in either language): «выбирай сам» / "you decide",
  «оба норм» / "both fine", «я устал» / "I'm tired", "it's technical not strategy".
```

These bilingual tokens are the ONLY Cyrillic permitted to remain in the shipped skill (enumerated in Task 7's allowlist).

- [ ] **Step 3: Verify only the allowlisted detection tokens remain**

Run: `LC_ALL=en_US.UTF-8 grep -rn '[А-Яа-яЁё]' .claude/skills/pipeline/ --exclude-dir=lang | grep -viE 'выбирай сам|оба норм|я устал'`
Expected: empty (every remaining Cyrillic line is a bilingual detection token).

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/pipeline/SKILL.md .claude/skills/pipeline/references/ .claude/skills/pipeline/templates/
git commit -m "feat(pipeline-i18n): skill prose → EN; detection phrases bilingual"
```

---

### Task 6: Update principle 18 in lockstep (TDD — change assertions first, then verify markdown)

**Files:**
- Modify: `packages/core/principles/18-meta-orchestrator-output-format.test.ts`

- [ ] **Step 1: Update `REQUIRED_SUBSTRINGS` to the EN canonical tokens.** Replace the two Russian entries:

```typescript
const REQUIRED_SUBSTRINGS = [
  '## Dependency graph',
  '↓',
  '## Action queue',
  'Paste into a new CC tab',   // was 'Paste в новый CC tab'
  'Can parallel with',          // was 'Можно параллельно с'
  '### Stage',
] as const;
```

- [ ] **Step 2: Update the two paired-negative synthetic blocks** (around lines 145–185) to use the EN headers (`| # | Paste into a new CC tab | When | Waiting on | Can parallel with |`) and assert `'Paste into a new CC tab'` is the missing token.

- [ ] **Step 3: Add an `AIF_HOOK_LANG=ru` pack-contract case** at the end of the describe block:

```typescript
import { readFileSync } from 'node:fs';
it('RU lang pack carries the Russian emitted tokens (operator contract)', () => {
  const ru = readFileSync(resolve(REPO_ROOT, '.claude/skills/pipeline/lang/ru.sh'), 'utf8');
  expect(ru).toContain('Paste в новый CC tab');
  expect(ru).toContain('Можно параллельно с');
  expect(ru).toContain('## 🟢 Простыми словами');
});
```

- [ ] **Step 4: Run principle 18**

Run: `npx --prefix packages/core vitest run principles/18-meta-orchestrator-output-format.test.ts --root packages/core`
Expected: PASS (EN substrings now present in output-format.md + SKILL.md §10 from Task 4; RU pack case passes)

- [ ] **Step 5: Commit**

```bash
git add packages/core/principles/18-meta-orchestrator-output-format.test.ts
git commit -m "test(pipeline-i18n): principle 18 → EN canonical substrings + RU-pack contract case"
```

---

### Task 7: Whole-skill-English invariant test

**Files:**
- Create: `packages/core/skills/pipeline-english-canonical.test.ts`

- [ ] **Step 1: Write the invariant test**

```typescript
import { describe, it, expect } from 'vitest';
import { execSync } from 'node:child_process';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(HERE, '../../..');

// The ONLY Cyrillic permitted in the shipped skill (excluding lang/ru.sh):
// the Class-3 bilingual deferral-detection tokens (spec §Class 3).
const ALLOWED = /выбирай сам|оба норм|я устал/;

describe('pipeline skill is English-canonical', () => {
  it("grep Cyrillic over the skill (excluding lang/ru.sh) yields only allowlisted detection tokens", () => {
    let out = '';
    try {
      out = execSync(
        `LC_ALL=en_US.UTF-8 grep -rn '[А-Яа-яЁё]' .claude/skills/pipeline/ --exclude-dir=lang`,
        { cwd: REPO_ROOT, encoding: 'utf8' },
      );
    } catch (e: any) {
      // grep exits 1 when no matches — that is the cleanest pass.
      if (e.status === 1) out = '';
      else throw e;
    }
    const offenders = out.split('\n').filter((l) => l.trim() && !ALLOWED.test(l));
    expect(offenders, `Unexpected Russian prose:\n${offenders.join('\n')}`).toHaveLength(0);
  });
});
```

> Note: `--exclude-dir=lang` excludes the `lang/` pack dir (ru.sh is legitimately Russian). Detection tokens live in `references/`, so they are still scanned and must match the allowlist.

- [ ] **Step 2: Run the test**

Run: `npx --prefix packages/core vitest run skills/pipeline-english-canonical.test.ts --root packages/core`
Expected: PASS (only bilingual detection tokens remain after Tasks 4–5)

- [ ] **Step 3: Commit**

```bash
git add packages/core/skills/pipeline-english-canonical.test.ts
git commit -m "test(pipeline-i18n): whole-skill-English invariant (allowlist = detection tokens)"
```

---

### Task 8: Full-suite verification + PR

- [ ] **Step 1: Run principle suite + skill tests + parity**

Run:
```bash
npm --prefix packages/core run test:principles
npx --prefix packages/core vitest run skills/ --root packages/core
bash .claude/skills/pipeline/lang/check-parity.sh
bash .claude/skills/pipeline/helpers/emit-output-strings.sh                 # EN smoke
AIF_HOOK_LANG=ru bash .claude/skills/pipeline/helpers/emit-output-strings.sh # RU smoke
npm run check:skill-drift
```
Expected: principles green; new skill tests green; parity OK; EN/RU smokes emit the right language; skill-drift PASS. (Pre-existing flaky failures noted in PR #397 are unrelated.)

- [ ] **Step 2: Push + open PR (base = `feat/meta-orch-stage5-rename`, the stacked parent; retarget to staging once #397 merges)**

```bash
git push -u origin feat/pipeline-skill-i18n
gh pr create --base feat/meta-orch-stage5-rename --title "feat(pipeline): skill i18n — EN canonical + AIF_HOOK_LANG=ru operator pack" --body "<§1.7 forward/backward; links spec; notes stacked on #397>"
```

> If #397 has already merged to staging by this point, base the PR on `staging` instead and rebase the branch.

---

## Self-Review

**Spec coverage:** (1) whole-skill-EN → Tasks 4,5,7. (2) emitted tokens → lang pack → Tasks 1,2,4. (3) detection bilingual → Task 5. (4) principle 18 lockstep → Task 6. (5) check-parity → Task 3. (6) whole-skill-English invariant → Task 7. All spec sections covered.

**Placeholder scan:** the PR `--body` in Task 8 Step 2 is the only `<...>` — that is a per-PR write-up, not code; acceptable. No other placeholders.

**Type/name consistency:** pack keys `AIF_PIPELINE_*` + `AIF_RECAP_MARKER` are identical across en.sh (Task 1), ru.sh (Task 1), helper loop (Task 2), parity grep (Task 3), and principle-18 RU case (Task 6). EN token values (`Paste into a new CC tab`, `Can parallel with`, `When`, `Waiting on`) match between en.sh (Task 1), output-format.md tables (Task 4), and principle-18 `REQUIRED_SUBSTRINGS` (Task 6). Detection allowlist regex `выбирай сам|оба норм|я устал` matches between Task 5 Step 3 and Task 7.

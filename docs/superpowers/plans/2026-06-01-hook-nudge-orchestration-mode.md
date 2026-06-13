# Hook-nudge orchestration-mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the two reminder hooks orchestration-mode-aware — drop the low-precision fork-regex and lower the recap threshold ONLY when an `.claude/orchestration-mode` marker is fresh; add a brainstorm nudge to the pre-question hook. Normal mode stays byte-for-byte.

**Architecture:** A marker file gated by mtime-TTL is read in `end-of-turn-reminder.sh`; two existing conditionals (`asked` regex, `long_text` threshold) become mode-aware. `ask-question-reminder.sh` gains one prose line. All changes are deterministic bash; tests inject the marker via an `ORCHESTRATION_MODE_MARKER` env override.

**Tech Stack:** bash + jq (hooks), vitest + spawnSync (tests).

**Spec:** `docs/superpowers/specs/2026-06-01-hook-nudge-orchestration-mode-design.md`

---

## File structure

- `.claude/hooks/end-of-turn-reminder.sh` — add `orch_mode` marker read; gate the `asked` decision-regex; make `long_text` threshold mode-aware.
- `.claude/hooks/ask-question-reminder.sh` — add one numbered brainstorm-cue line to the reminder heredoc.
- `packages/core/hooks/end-of-turn-reminder.test.ts` — extend `runHook` with an env param; add the in-mode / stale-marker / normal-mode-regression matrix.
- `packages/core/hooks/ask-question-reminder.test.ts` — **create**; one test asserting the brainstorm cue is present.

---

## Task 1: Marker read + Bug A gate (drop decision-regex in-mode)

**Files:**
- Modify: `.claude/hooks/end-of-turn-reminder.sh:46` (insert marker read), `:79-86` (gate the regex)
- Modify: `packages/core/hooks/end-of-turn-reminder.test.ts:100-106` (env param), add tests after `:165`

- [ ] **Step 1: Extend `runHook` to accept env (test harness)**

Replace `packages/core/hooks/end-of-turn-reminder.test.ts:100-106` with:

```ts
function runHook(
  stdin: Record<string, unknown>,
  env?: Record<string, string>,
): { status: number; stdout: string; stderr: string } {
  const r = spawnSync('bash', [HOOK], {
    input: JSON.stringify(stdin),
    encoding: 'utf8',
    env: env ? { ...process.env, ...env } : process.env,
  });
  return { status: r.status ?? -1, stdout: r.stdout ?? '', stderr: r.stderr ?? '' };
}

/** Write a fresh orchestration-mode marker file; returns its path. */
function writeMarker(): string {
  const dir = mkdtempSync(join(tmpdir(), 'm4-5-marker-'));
  tmpDirs.push(dir);
  const p = join(dir, 'orchestration-mode');
  writeFileSync(p, '');
  return p;
}
```

- [ ] **Step 2: Write the failing tests (Bug A in-mode + normal-mode regression)**

Add after line 165 (after the Branch A test) in `end-of-turn-reminder.test.ts`:

```ts
describe('orchestration-mode — Bug A: decision-mention no longer false-fires in-mode', () => {
  it('IN-MODE — short "я выбрал Option A." (decision mention, no ?) → silent', () => {
    const tr = writeTranscript([
      aiTitle('Цель'),
      userTurn('задание'),
      assistantText('Ок, я выбрал Option A и поехал дальше.'),
    ]);
    const r = runHook({ transcript_path: tr, stop_hook_active: false }, { ORCHESTRATION_MODE_MARKER: writeMarker() });
    expect(r.status, `stderr: ${r.stderr}`).toBe(0);
    expect(r.stdout, 'decision-mention in-mode must NOT fire').toBe('');
  });

  it('IN-MODE — short text ending in "… A или B?" → still fires (trailing ? kept)', () => {
    const tr = writeTranscript([
      aiTitle('Цель'),
      userTurn('задание'),
      assistantText('Что берём — A или B?'),
    ]);
    const r = runHook({ transcript_path: tr, stop_hook_active: false }, { ORCHESTRATION_MODE_MARKER: writeMarker() });
    expect(r.stdout, 'real question in-mode must fire').not.toBe('');
    expect(JSON.parse(r.stdout).decision).toBe('block');
  });

  it('NORMAL-MODE — same "я выбрал Option A." STILL fires (byte-for-byte regression guard)', () => {
    const tr = writeTranscript([
      aiTitle('Цель'),
      userTurn('задание'),
      assistantText('Ок, я выбрал Option A и поехал дальше.'),
    ]);
    const r = runHook({ transcript_path: tr, stop_hook_active: false }); // no marker
    expect(r.stdout, 'normal mode must be unchanged — regex still active').not.toBe('');
  });
});
```

- [ ] **Step 3: Run tests, verify they fail**

Run: `npm --prefix packages/core test -- end-of-turn-reminder 2>&1 | tail -20`
Expected: the two IN-MODE tests FAIL (hook ignores the marker, so decision-mention still fires / behaves as normal). The NORMAL-MODE test passes.

- [ ] **Step 4: Add the marker read to the hook**

In `.claude/hooks/end-of-turn-reminder.sh`, immediately after line 46 (`text_length=${#text}`), insert:

```bash
# -- orchestration-mode marker (deterministic; normal mode = marker absent) ----
# In orchestration mode (driving aif-handoff, relaying state every turn) two
# triggers are re-tuned (Bug A regex dropped, recap threshold lowered); normal
# mode is byte-for-byte unchanged. Freshness (mtime within TTL) guards against a
# forgotten marker silently muting a normal session. Spec: docs/superpowers/specs/
# 2026-06-01-hook-nudge-orchestration-mode-design.md.
orch_mode=false
marker="${ORCHESTRATION_MODE_MARKER:-${CLAUDE_PROJECT_DIR:-.}/.claude/orchestration-mode}"
ttl="${ORCHESTRATION_MODE_TTL_SECONDS:-21600}"
if [ -f "$marker" ]; then
  marker_now=$(date +%s)
  marker_mtime=$(stat -f %m "$marker" 2>/dev/null || stat -c %Y "$marker" 2>/dev/null || echo 0)
  if [ "$(( marker_now - marker_mtime ))" -lt "$ttl" ]; then
    orch_mode=true
  fi
fi
```

- [ ] **Step 5: Gate the decision-regex**

In `.claude/hooks/end-of-turn-reminder.sh`, change the `elif` at `:83` (inside the `asked` block) from:

```bash
    elif echo "$tail_chunk" | grep -qiE 'Option [AB]|выбирай|decide|хочешь чтобы|which (option|approach)'; then
```

to:

```bash
    elif [ "$orch_mode" = "false" ] && echo "$tail_chunk" | grep -qiE 'Option [AB]|выбирай|decide|хочешь чтобы|which (option|approach)'; then
```

- [ ] **Step 6: Run tests, verify pass**

Run: `npm --prefix packages/core test -- end-of-turn-reminder 2>&1 | tail -20`
Expected: all three new tests PASS; all pre-existing tests still PASS.

- [ ] **Step 7: Commit**

```bash
git add .claude/hooks/end-of-turn-reminder.sh packages/core/hooks/end-of-turn-reminder.test.ts
git commit -m "feat(hook): drop fork-regex in orchestration-mode (Bug A), marker-gated

Normal mode byte-for-byte; marker .claude/orchestration-mode + mtime TTL.
Spec: docs/superpowers/specs/2026-06-01-hook-nudge-orchestration-mode-design.md.

Prior-art: skipped — internal CC hook tuning, no new capability/dependency."
```

---

## Task 2: Recap (b) — lower long_text threshold in-mode

**Files:**
- Modify: `.claude/hooks/end-of-turn-reminder.sh:68-73`
- Modify: `packages/core/hooks/end-of-turn-reminder.test.ts` (add tests)

- [ ] **Step 1: Write failing tests (recap in-mode + chatter + stale marker)**

Add a new `describe` block in `end-of-turn-reminder.test.ts`:

```ts
describe('orchestration-mode — recap (b): fires on short structured status in-mode', () => {
  const shortStructured = '## Статус\n- запарковал task на форке\n- жду ответа оператора'; // <500 chars, has markdown

  it('IN-MODE — short STRUCTURED status (<500, markdown) → recap fires', () => {
    const tr = writeTranscript([aiTitle('Цель'), userTurn('задание'), assistantText(shortStructured)]);
    const r = runHook({ transcript_path: tr, stop_hook_active: false }, { ORCHESTRATION_MODE_MARKER: writeMarker() });
    expect(r.stdout, 'short structured status in-mode must fire recap').not.toBe('');
    expect(JSON.parse(r.stdout).decision).toBe('block');
  });

  it('IN-MODE — short UNSTRUCTURED chatter "ок, удалил" → silent (markdown gate holds)', () => {
    const tr = writeTranscript([aiTitle('Цель'), userTurn('задание'), assistantText('ок, удалил')]);
    const r = runHook({ transcript_path: tr, stop_hook_active: false }, { ORCHESTRATION_MODE_MARKER: writeMarker() });
    expect(r.stdout, 'unstructured chatter must stay silent').toBe('');
  });

  it('NORMAL-MODE — short structured status → silent (threshold unchanged)', () => {
    const tr = writeTranscript([aiTitle('Цель'), userTurn('задание'), assistantText(shortStructured)]);
    const r = runHook({ transcript_path: tr, stop_hook_active: false }); // no marker
    expect(r.stdout, 'normal mode keeps 500-char threshold').toBe('');
  });

  it('STALE marker (mtime past TTL) → behaves as normal mode', () => {
    const tr = writeTranscript([aiTitle('Цель'), userTurn('задание'), assistantText(shortStructured)]);
    const m = writeMarker();
    // force mtime to 7h ago (TTL default 6h)
    execSync(`touch -t $(date -v-7H +%Y%m%d%H%M 2>/dev/null || date -d '7 hours ago' +%Y%m%d%H%M) "${m}"`);
    const r = runHook({ transcript_path: tr, stop_hook_active: false }, { ORCHESTRATION_MODE_MARKER: m });
    expect(r.stdout, 'stale marker must not enable in-mode').toBe('');
  });
});
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `npm --prefix packages/core test -- end-of-turn-reminder 2>&1 | tail -20`
Expected: the IN-MODE "short structured → recap fires" test FAILS (threshold still 500); the others pass.

- [ ] **Step 3: Make the threshold mode-aware**

In `.claude/hooks/end-of-turn-reminder.sh`, replace lines 68-73:

```bash
long_text=false
if [ "$text_length" -gt 500 ]; then
  if echo "$text" | grep -qE '^#|^- |^\* |\*\*|```|\[[^]]+\]\([^)]+\)'; then
    long_text=true
  fi
fi
```

with:

```bash
# Recap threshold is lowered in orchestration mode (status turns are short+dense)
# but the markdown-structure gate is KEPT, so unstructured chatter stays silent.
long_text=false
recap_threshold=500
if [ "$orch_mode" = "true" ]; then
  recap_threshold="${ORCHESTRATION_MODE_RECAP_MIN_CHARS:-200}"
fi
if [ "$text_length" -gt "$recap_threshold" ]; then
  if echo "$text" | grep -qE '^#|^- |^\* |\*\*|```|\[[^]]+\]\([^)]+\)'; then
    long_text=true
  fi
fi
```

> Note: the `shortStructured` fixture is ~70 chars; confirm it exceeds the in-mode `200` default at execution. If the chosen `recap_min` is tuned higher than the fixture, pad the fixture so it sits above `recap_min` but below `500` (the test's intent: in-mode fires, normal does not). Adjust the fixture, not the threshold, to keep the in-mode/normal split meaningful.

- [ ] **Step 4: Run tests, verify pass**

Run: `npm --prefix packages/core test -- end-of-turn-reminder 2>&1 | tail -20`
Expected: all new + pre-existing tests PASS.

- [ ] **Step 5: Commit**

```bash
git add .claude/hooks/end-of-turn-reminder.sh packages/core/hooks/end-of-turn-reminder.test.ts
git commit -m "feat(hook): lower recap threshold in orchestration-mode (recap-b), markdown gate kept

Prior-art: skipped — internal CC hook tuning, no new capability/dependency."
```

---

## Task 3: Brainstorm nudge in ask-question-reminder.sh (item 6)

**Files:**
- Modify: `.claude/hooks/ask-question-reminder.sh` (the reminder heredoc, ~line 52-58)
- Create: `packages/core/hooks/ask-question-reminder.test.ts`

- [ ] **Step 1: Write the failing test**

Create `packages/core/hooks/ask-question-reminder.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { execSync, spawnSync } from 'node:child_process';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { tmpdir } from 'node:os';
import { rmSync } from 'node:fs';

const HERE = dirname(fileURLToPath(import.meta.url));
const HOOK = resolve(HERE, '../../..', '.claude/hooks/ask-question-reminder.sh');
function hasJq(): boolean { try { execSync('command -v jq', { stdio: 'ignore' }); return true; } catch { return false; } }

describe.skipIf(!hasJq())('ask-question-reminder.sh — brainstorm cue', () => {
  it('fresh AskUserQuestion → reminder text contains the brainstorm cue', () => {
    const sid = 'test-brainstorm-cue-fixed';
    rmSync(`${process.env.TMPDIR ?? '/tmp'}/aif-ask-reminded-${sid}`, { force: true });
    const r = spawnSync('bash', [HOOK], {
      input: JSON.stringify({ tool_name: 'AskUserQuestion', session_id: sid }),
      encoding: 'utf8',
    });
    expect(r.status).toBe(0);
    const reason = JSON.parse(r.stdout).hookSpecificOutput.permissionDecisionReason as string;
    expect(reason).toMatch(/brainstorming/i);
  });
});
```

- [ ] **Step 2: Run test, verify it fails**

Run: `npm --prefix packages/core test -- ask-question-reminder 2>&1 | tail -15`
Expected: FAIL — reminder text has no `brainstorming` cue yet.

- [ ] **Step 3: Add the cue to the hook**

In `.claude/hooks/ask-question-reminder.sh`, inside the `reminder=$(cat <<'EOF' ... EOF)` block, add a 4th numbered line after the existing point 3:

```text
4. Если это развилка о ДИЗАЙНЕ/СТРАТЕГИИ (а не быстрый A/B по фактам) — открой `superpowers:brainstorming` вместо голой карточки: исследуй → порекомендуй с аргументами, потом спрашивай. Карточка по дизайн-форку читается как «AI punted».
```

- [ ] **Step 4: Run test, verify it passes**

Run: `npm --prefix packages/core test -- ask-question-reminder 2>&1 | tail -15`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add .claude/hooks/ask-question-reminder.sh packages/core/hooks/ask-question-reminder.test.ts
git commit -m "feat(hook): brainstorm cue in ask-question-reminder (item 6)

Design/strategy forks → superpowers:brainstorming, not a bare AUQ card.
Always-on prose nudge (judgment → injection, never a gate).

Prior-art: skipped — internal CC hook tuning, no new capability/dependency."
```

---

## Task 4: Full suite + PR

- [ ] **Step 1: Run the full hooks suite**

Run: `npm --prefix packages/core test -- hooks 2>&1 | tail -20`
Expected: all green, including the unchanged pre-existing end-of-turn cases (byte-for-byte normal-mode guard).

- [ ] **Step 2: Push + open PR to staging**

```bash
git push -u origin feat/hook-nudge-orchestration-mode
```

PR body MUST carry §1.7 Forward/Backward sections (paths touch `.claude/skills/**`? no — but `.claude/rules/**`? no; the hooks are NOT in §4b path list, so §1.7 is NOT mandated). Confirm: `.claude/hooks/**` is not in the §4b path list → §1.7 optional. Include a short "what/why" body + the spec link. Arm auto-merge: `gh pr merge <N> --auto --squash`.

---

## Self-review

**Spec coverage:** §3.1 marker → Task 1 Step 4; §3.2 Bug A → Task 1; §3.2 recap-b → Task 2; §3.3 brainstorm nudge → Task 3; §4 test matrix → Tasks 1-2 (all rows) + Task 3; §5 stale-marker risk → Task 2 stale test; §7 acceptance 1-5 → covered. Acceptance 6 (marker-path consistency) — single hook reads the marker; the shared-resolver option was NOT taken (inline read in one file), so cross-hook path drift does not arise (ask-question-reminder.sh does NOT read the marker — item 6 nudge is always-on). Consistent with spec §3.1 "OR inline".

**Placeholder scan:** none — every step has concrete code/commands. The one judgment note (fixture vs recap_min sizing, Task 2 Step 3) is an explicit execution-time check with a stated resolution, not a TBD.

**Type consistency:** `orch_mode` (bash), `ORCHESTRATION_MODE_MARKER` / `ORCHESTRATION_MODE_TTL_SECONDS` / `ORCHESTRATION_MODE_RECAP_MIN_CHARS` env names used identically in hook + tests; `runHook(stdin, env?)` signature matches all call sites (old calls pass one arg, new pass two). `writeMarker()` defined Task 1 Step 1, used Tasks 1-2.

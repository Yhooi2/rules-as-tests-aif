# aif Question-Loop PARK Primitive — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the autonomous aif agent a way to PARK itself on a genuine *hard* fork mid-implementation (stop, ask the operator, resume with the answer), closing the smoke-`701a52e3` bug where the agent flailed and finished `done` with a placeholder.

**Architecture:** A thin consumer CLI `cli/park.ts` sets `paused:true` + `blockedReason` via `PUT /tasks/:id` (the only agent-reachable stop — verified the coordinator candidate query filters `paused=false`). `cli/answer.ts` gains a symmetric `resume` decision that unpauses and injects the operator's answer into the task `plan` (the field the implementer re-reads). A guard-test pins the load-bearing dependency (`paused:true` is the stop, NOT `blockedReason` alone) so an upstream aif change fails loudly instead of silently. Soft questions already flow non-blocking to chat (existing) — this plan covers ONLY the hard-fork park.

**Tech Stack:** TypeScript (ESM), `tsx` entrypoints, Vitest (`vi.spyOn(globalThis,'fetch')`), plain HTTP to the aif-handoff REST API. No new deps, no paid LLM.

**Binding spec:** [docs/superpowers/specs/2026-06-01-aif-qloop-park-primitive-design.md](../specs/2026-06-01-aif-qloop-park-primitive-design.md) (§2 F1–F10 verified facts, §3 design, §4 guard-test, §5 BFR).

---

## File Structure

- **Create** `packages/runtime-bridge/src/cli/aifHttp.ts` — shared `getTask` + `putTask` helpers (GET/PUT with the standard `BackendError` mapping). New code only; the shipped `answer.ts` `post` helper is left untouched (DRY for new paths, zero blast radius on shipped code).
- **Create** `packages/runtime-bridge/src/cli/park.ts` — the agent-side park CLI. Pure helpers (`parseParkArgs`, `validateParkArgs`, `buildOpenQuestionPlan`) + `parkTask` + entrypoint-guarded `main`.
- **Modify** `packages/runtime-bridge/src/cli/answer.ts` — add the `resume` decision (unpause + inject answer into plan) using `aifHttp`.
- **Create** `packages/runtime-bridge/test/aif-park.test.ts` — paired pos/neg tests + the GUARD test (`paused:true` in the PUT body).
- **Create** `packages/runtime-bridge/test/aif-http.test.ts` — `getTask`/`putTask` unit tests.
- **Modify** `packages/runtime-bridge/test/aif-answer.test.ts` — add `resume` pos/neg tests + `appendAnswerToPlan` test.
- **Create** `packages/runtime-bridge/test/aif-park-live.test.ts` — OPTIONAL env-gated live contract test (the full F10 proof: paused ⇒ not advanced). Skipped unless `RUNTIME_BRIDGE_LIVE_AIF=1`.
- **Modify** `docs/runtime-bridge-setup.md` — document the agent's A-vs-B selection rule + `park.ts` usage.

---

## Task 1: Shared aif HTTP helpers (`aifHttp.ts`)

**Files:**
- Create: `packages/runtime-bridge/src/cli/aifHttp.ts`
- Test: `packages/runtime-bridge/test/aif-http.test.ts`

- [ ] **Step 1: Write the failing test**

```ts
// packages/runtime-bridge/test/aif-http.test.ts
import { describe, it, expect, vi, afterEach } from 'vitest';
import { BackendError } from '../src/backend.js';
import { getTask, putTask } from '../src/cli/aifHttp.js';

function okResponse(body: unknown = {}, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
}

afterEach(() => vi.restoreAllMocks());

describe('getTask', () => {
  it('GETs /tasks/:id and returns the parsed task', async () => {
    const task = { id: 't-1', title: 'x', status: 'implementing', plan: 'P', paused: false, blockedReason: null };
    const spy = vi.spyOn(globalThis, 'fetch').mockResolvedValue(okResponse(task));
    const got = await getTask('http://localhost:3009', 't-1');
    expect(spy.mock.calls[0][0]).toBe('http://localhost:3009/tasks/t-1');
    expect((spy.mock.calls[0][1] as RequestInit).method).toBe('GET');
    expect(got).toEqual(task);
  });
  it('maps a non-ok status to a dispatch_failed BackendError', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(okResponse({ error: 'nope' }, 404));
    await expect(getTask('http://localhost:3009', 't-x')).rejects.toMatchObject({ code: 'dispatch_failed' });
  });
});

describe('putTask', () => {
  it('PUTs /tasks/:id with the JSON body', async () => {
    const spy = vi.spyOn(globalThis, 'fetch').mockResolvedValue(okResponse({ id: 't-1', paused: true }));
    await putTask('http://localhost:3009', 't-1', { paused: true });
    expect(spy.mock.calls[0][0]).toBe('http://localhost:3009/tasks/t-1');
    const init = spy.mock.calls[0][1] as RequestInit;
    expect(init.method).toBe('PUT');
    expect(JSON.parse(init.body as string)).toEqual({ paused: true });
  });
  it('maps connection refusal to an unavailable BackendError', async () => {
    vi.spyOn(globalThis, 'fetch').mockRejectedValue(new Error('ECONNREFUSED'));
    await expect(putTask('http://localhost:3009', 't-1', {})).rejects.toBeInstanceOf(BackendError);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/runtime-bridge && npx vitest run test/aif-http.test.ts`
Expected: FAIL — `Cannot find module '../src/cli/aifHttp.js'`.

- [ ] **Step 3: Write minimal implementation**

```ts
// packages/runtime-bridge/src/cli/aifHttp.ts
/**
 * Shared aif-handoff REST helpers for the field-mutating CLIs (park, answer-resume).
 * GET a task and PUT field updates, with the same BackendError mapping as
 * answer.ts `post` (connection → unavailable, 429 → quota_exceeded, other → dispatch_failed).
 * @cc-only-rationale: pure TS over plain HTTP — no CC-only primitive, no paid LLM.
 */
import { BackendError } from '../backend.js';

/** The subset of an aif-handoff task these CLIs read/mutate (GET /tasks/:id). */
export interface AifTaskFull {
  id: string;
  title: string;
  status: string;
  plan?: string | null;
  paused?: boolean;
  blockedReason?: string | null;
}

async function request(method: 'GET' | 'PUT', baseUrl: string, path: string, body?: unknown): Promise<unknown> {
  let res: Response;
  try {
    res = await fetch(`${baseUrl}${path}`, {
      method,
      headers: body === undefined ? undefined : { 'Content-Type': 'application/json' },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    throw new BackendError(`aif-handoff ${method} ${path} unreachable: ${msg}`, 'unavailable', 'aif-handoff');
  }
  if (!res.ok) {
    const errBody = await res.text().catch(() => '');
    if (res.status === 429) {
      throw new BackendError(`aif-handoff rate limit (${method} ${path}): ${errBody}`, 'quota_exceeded', 'aif-handoff');
    }
    throw new BackendError(`aif-handoff ${method} ${path} HTTP ${res.status}: ${errBody}`, 'dispatch_failed', 'aif-handoff');
  }
  const text = await res.text();
  if (!text) return {};
  try {
    return JSON.parse(text) as unknown;
  } catch {
    return text;
  }
}

/** GET /tasks/:id → the task object. */
export async function getTask(baseUrl: string, taskId: string): Promise<AifTaskFull> {
  return (await request('GET', baseUrl, `/tasks/${taskId}`)) as AifTaskFull;
}

/** PUT /tasks/:id with a partial field update (updateTaskSchema-accepted fields only). */
export async function putTask(baseUrl: string, taskId: string, body: Record<string, unknown>): Promise<void> {
  await request('PUT', baseUrl, `/tasks/${taskId}`, body);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/runtime-bridge && npx vitest run test/aif-http.test.ts`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add packages/runtime-bridge/src/cli/aifHttp.ts packages/runtime-bridge/test/aif-http.test.ts
git commit -m "feat(runtime-bridge): aifHttp getTask/putTask helpers for field-mutating CLIs

Prior-art: skipped — thin HTTP helper extraction, no new capability (siblings of answer.ts post)"
```

---

## Task 2: park.ts pure helpers (args + plan builder)

**Files:**
- Create: `packages/runtime-bridge/src/cli/park.ts` (helpers only this task)
- Test: `packages/runtime-bridge/test/aif-park.test.ts`

- [ ] **Step 1: Write the failing test**

```ts
// packages/runtime-bridge/test/aif-park.test.ts
import { describe, it, expect, vi, afterEach } from 'vitest';
import { parseParkArgs, validateParkArgs, buildOpenQuestionPlan } from '../src/cli/park.js';

afterEach(() => vi.restoreAllMocks());

describe('parseParkArgs', () => {
  it('reads --task and --question; --task overrides HANDOFF_TASK_ID env', () => {
    const args = parseParkArgs(['--task', 't-9', '--question', 'tone: A or B?'], { HANDOFF_TASK_ID: 't-env' });
    expect(args).toMatchObject({ taskId: 't-9', question: 'tone: A or B?', json: false });
  });
  it('falls back to HANDOFF_TASK_ID when --task is absent', () => {
    const args = parseParkArgs(['--question', 'q'], { HANDOFF_TASK_ID: 't-env' });
    expect(args.taskId).toBe('t-env');
  });
});

describe('validateParkArgs', () => {
  it('rejects a missing task id', () => {
    expect(validateParkArgs({ taskId: undefined, question: 'q', json: false })).toMatch(/missing.*task/i);
  });
  it('rejects an empty question', () => {
    expect(validateParkArgs({ taskId: 't-1', question: '   ', json: false })).toMatch(/question/i);
  });
  it('accepts a valid pair', () => {
    expect(validateParkArgs({ taskId: 't-1', question: 'q', json: false })).toBeNull();
  });
});

describe('buildOpenQuestionPlan', () => {
  it('appends a marked OPEN QUESTION block to the existing plan', () => {
    const out = buildOpenQuestionPlan('# Plan\n- step 1', 'tagline tone: A=playful / B=serious');
    expect(out).toContain('# Plan\n- step 1');
    expect(out).toContain('## ⏸ OPEN QUESTION (awaiting operator)');
    expect(out).toContain('tagline tone: A=playful / B=serious');
  });
  it('handles a null/empty existing plan', () => {
    expect(buildOpenQuestionPlan(null, 'q')).toContain('## ⏸ OPEN QUESTION (awaiting operator)');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/runtime-bridge && npx vitest run test/aif-park.test.ts`
Expected: FAIL — `Cannot find module '../src/cli/park.js'`.

- [ ] **Step 3: Write minimal implementation**

```ts
// packages/runtime-bridge/src/cli/park.ts
/**
 * CLI park entrypoint — the agent-side "I hit a hard fork, stop and ask" half.
 *
 * Usage (the autonomous agent runs this on a genuine BLOCKING fork it cannot default):
 *   tsx packages/runtime-bridge/src/cli/park.ts --task <id> --question "<fork + options>"
 *   # --task defaults to $HANDOFF_TASK_ID (set in the aif agent context).
 *
 * Mechanism (spec §2 F2/F3/F5): PUT /tasks/:id { paused:true, blockedReason, plan }.
 *   - paused:true is THE stop — the coordinator candidate query filters paused=false,
 *     so the agent is NOT re-picked (blockedReason ALONE does NOT stop it — F2).
 *   - blockedReason carries the question + makes questions.ts isParked() true.
 *   - plan gains a "## ⏸ OPEN QUESTION" anchor the resume answer is injected under.
 *
 * Soft/advisory questions do NOT use this — they already flow non-blocking to chat.
 * This is ONLY for a hard fork that blocks continuing the implementation.
 *
 * Config: RUNTIME_BRIDGE_AIF_URL (default http://localhost:3009).
 * Exit codes: 0 parked; 1 bad args or REST error (message on stderr).
 *
 * @cc-only-rationale: pure TS over plain HTTP — also callable from a smoke-test
 *   and an orchestrator session. No CC-only primitive, no Superset import, no paid LLM.
 */
import { fileURLToPath } from 'node:url';
import { getTask, putTask } from './aifHttp.js';

const DEFAULT_AIF_URL = 'http://localhost:3009';

export interface ParkArgs {
  taskId?: string;
  question?: string;
  json: boolean;
}

/** Parse CLI args: --task <id> (else $HANDOFF_TASK_ID), --question <text>, --json. */
export function parseParkArgs(argv: string[], env: NodeJS.ProcessEnv): ParkArgs {
  const valueOf = (flag: string): string | undefined => {
    const i = argv.indexOf(flag);
    return i !== -1 && argv[i + 1] ? argv[i + 1] : undefined;
  };
  return {
    taskId: valueOf('--task') ?? env.HANDOFF_TASK_ID ?? undefined,
    question: valueOf('--question'),
    json: argv.includes('--json'),
  };
}

/** Validate parsed args. Returns an error message, or null when valid. */
export function validateParkArgs(args: ParkArgs): string | null {
  if (!args.taskId) return 'missing required --task <id> (or $HANDOFF_TASK_ID)';
  if (!args.question?.trim()) return 'missing required --question <text> (the fork + options)';
  return null;
}

/** Append a marked OPEN QUESTION block to the existing plan (anchor for the resume answer). */
export function buildOpenQuestionPlan(existingPlan: string | null | undefined, question: string): string {
  const base = (existingPlan ?? '').trimEnd();
  const block = `\n\n## ⏸ OPEN QUESTION (awaiting operator)\n\n${question.trim()}\n`;
  return base + block;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/runtime-bridge && npx vitest run test/aif-park.test.ts`
Expected: PASS (7 tests).

- [ ] **Step 5: Commit**

```bash
git add packages/runtime-bridge/src/cli/park.ts packages/runtime-bridge/test/aif-park.test.ts
git commit -m "feat(runtime-bridge): park.ts pure helpers (args + OPEN QUESTION plan builder)

Prior-art: skipped — pure arg/string helpers, no new capability yet (network in next commit)"
```

---

## Task 3: park.ts network (`parkTask`) + the GUARD test

**Files:**
- Modify: `packages/runtime-bridge/src/cli/park.ts` (add `parkTask` + `main`)
- Test: `packages/runtime-bridge/test/aif-park.test.ts` (add network + guard tests)

- [ ] **Step 1: Write the failing test (incl. the load-bearing GUARD)**

```ts
// append to packages/runtime-bridge/test/aif-park.test.ts
import { parkTask } from '../src/cli/park.js';

function okResponse(body: unknown = {}, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
}

describe('parkTask — GET current plan then PUT the park fields', () => {
  it('GETs the task, then PUTs { paused, blockedReason, plan-with-OPEN-QUESTION }', async () => {
    const task = { id: 't-9', title: 'x', status: 'implementing', plan: '# Plan', paused: false, blockedReason: null };
    const spy = vi.spyOn(globalThis, 'fetch').mockImplementation((url) =>
      Promise.resolve(
        String(url).endsWith('/tasks/t-9') ? okResponse(task) : okResponse({ ...task, paused: true }),
      ),
    );
    const q = 'tagline tone: A=playful / B=serious';
    await parkTask('http://localhost:3009', 't-9', q);

    // call 0 = GET, call 1 = PUT
    expect((spy.mock.calls[0][1] as RequestInit).method).toBe('GET');
    const put = spy.mock.calls[1][1] as RequestInit;
    expect(put.method).toBe('PUT');
    const body = JSON.parse(put.body as string);
    expect(body.blockedReason).toBe(q);
    expect(body.plan).toContain('## ⏸ OPEN QUESTION (awaiting operator)');
  });

  // ── THE GUARD (spec §4): paused:true is the stop, NOT blockedReason alone (F2/F3). ──
  // If a refactor ever regresses park to blockedReason-only, this fails loudly —
  // turning the undocumented "coordinator skips paused" dependency into an executable one.
  it('GUARD: the PUT body sets paused === true (blockedReason-only would NOT stop the agent)', async () => {
    const task = { id: 't-9', title: 'x', status: 'implementing', plan: '# Plan', paused: false, blockedReason: null };
    const spy = vi.spyOn(globalThis, 'fetch').mockImplementation((url) =>
      Promise.resolve(String(url).endsWith('/tasks/t-9') ? okResponse(task) : okResponse({})),
    );
    await parkTask('http://localhost:3009', 't-9', 'q');
    const putBody = JSON.parse((spy.mock.calls[1][1] as RequestInit).body as string);
    expect(putBody.paused).toBe(true);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/runtime-bridge && npx vitest run test/aif-park.test.ts`
Expected: FAIL — `parkTask is not exported`.

- [ ] **Step 3: Add `parkTask` + `main` to park.ts**

```ts
// append to packages/runtime-bridge/src/cli/park.ts

export interface ParkResult {
  taskId: string;
  paused: true;
  blockedReason: string;
}

/**
 * Park the task on a hard fork: read the current plan, append the OPEN QUESTION
 * anchor, and PUT { paused:true, blockedReason, plan }. paused:true is the stop (F3).
 */
export async function parkTask(baseUrl: string, taskId: string, question: string): Promise<ParkResult> {
  const reason = question.trim();
  const task = await getTask(baseUrl, taskId);
  const plan = buildOpenQuestionPlan(task.plan, reason);
  await putTask(baseUrl, taskId, { paused: true, blockedReason: reason, plan });
  return { taskId, paused: true, blockedReason: reason };
}

/** Render a ParkResult as a human-readable confirmation. */
export function formatParkResult(result: ParkResult): string {
  return `task:   ${result.taskId}\nparked: paused=true\nreason: ${result.blockedReason}`;
}

async function main(): Promise<void> {
  const baseUrl = process.env.RUNTIME_BRIDGE_AIF_URL || DEFAULT_AIF_URL;
  const args = parseParkArgs(process.argv.slice(2), process.env);

  const argError = validateParkArgs(args);
  if (argError) {
    process.stderr.write(`[runtime-bridge] park: ${argError}\n`);
    process.exit(1);
  }

  let result: ParkResult;
  try {
    result = await parkTask(baseUrl, args.taskId!, args.question!);
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    process.stderr.write(`[runtime-bridge] park: failed to park task: ${msg}\n`);
    process.exit(1);
  }

  process.stdout.write((args.json ? JSON.stringify(result) : formatParkResult(result)) + '\n');
  process.exit(0);
}

// Run only as a real entrypoint — importing the module (tests) must not fetch/exit.
if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main().catch((err) => {
    process.stderr.write(`[runtime-bridge] park: unhandled error: ${err}\n`);
    process.exit(1);
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/runtime-bridge && npx vitest run test/aif-park.test.ts`
Expected: PASS (9 tests, incl. the GUARD).

- [ ] **Step 5: Commit**

```bash
git add packages/runtime-bridge/src/cli/park.ts packages/runtime-bridge/test/aif-park.test.ts
git commit -m "feat(runtime-bridge): park.ts parkTask + guard-test (paused:true is the stop)

The guard pins spec §4: a paused task is excluded from coordinator candidacy
(verified data/dist/index.js:901 eq(tasks.paused,false)); regressing to
blockedReason-only fails the test loudly instead of silently shipping a no-op park.

Prior-art: prior-art-evaluations.md — no upstream deliberate-park primitive for the
autonomous pipeline (aif AskUserQuestion is chat-synchronous, different problem class, T16);
thin consumer BUILD, dual of shipped answer.ts (#323)."
```

> **NOTE for the worker:** this commit adds a new file ≥80 LOC under `packages/` → it is a **capability commit** per CLAUDE.md. The `Prior-art:` trailer above is required; if `prior-art-evaluations.md` has no matching row, add one (Verdict BUILD, rationale: no upstream pipeline park primitive) in THIS commit per the build-vs-reuse invariant.

---

## Task 4: answer.ts `resume` decision (pure parts)

**Files:**
- Modify: `packages/runtime-bridge/src/cli/answer.ts`
- Test: `packages/runtime-bridge/test/aif-answer.test.ts`

- [ ] **Step 1: Write the failing test**

```ts
// append to packages/runtime-bridge/test/aif-answer.test.ts
import { appendAnswerToPlan } from '../src/cli/answer.js';

describe('resume decision — pure parts', () => {
  it('VALID_DECISIONS includes resume', () => {
    expect([...VALID_DECISIONS]).toEqual(['request_changes', 'approve', 'retry', 'resume']);
  });
  it('resume requires --answer', () => {
    const err = validateAnswerArgs({ taskId: 't-1', answer: undefined, decision: 'resume', json: false });
    expect(err).toMatch(/requires --answer/);
  });
  it('appendAnswerToPlan appends a marked OPERATOR ANSWER block', () => {
    const out = appendAnswerToPlan('# Plan\n## ⏸ OPEN QUESTION\nq', 'use Option A');
    expect(out).toContain('## ✅ OPERATOR ANSWER (resumed)');
    expect(out).toContain('use Option A');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/runtime-bridge && npx vitest run test/aif-answer.test.ts`
Expected: FAIL — `appendAnswerToPlan` not exported; `VALID_DECISIONS` lacks `resume`.

- [ ] **Step 3: Edit answer.ts — widen the decision type + add the pure helper**

In `packages/runtime-bridge/src/cli/answer.ts`:

Change the decision type and list:

```ts
export type AnswerDecision = 'request_changes' | 'approve' | 'retry' | 'resume';

export const VALID_DECISIONS: readonly AnswerDecision[] = ['request_changes', 'approve', 'retry', 'resume'];
```

Update `validateAnswerArgs` so `resume` also requires `--answer` (replace the request_changes-only check):

```ts
  if ((args.decision === 'request_changes' || args.decision === 'resume') && !args.answer?.trim()) {
    return `decision "${args.decision}" requires --answer <text> (the resolution to push back)`;
  }
```

Add the import + pure helper near the top (after the existing imports):

```ts
import { getTask, putTask } from './aifHttp.js';

/** Append a marked OPERATOR ANSWER block to the plan (read by the implementer on the next tick). */
export function appendAnswerToPlan(existingPlan: string | null | undefined, answer: string): string {
  const base = (existingPlan ?? '').trimEnd();
  const block = `\n\n## ✅ OPERATOR ANSWER (resumed)\n\n${answer.trim()}\n`;
  return base + block;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/runtime-bridge && npx vitest run test/aif-answer.test.ts`
Expected: PASS (existing + 3 new).

- [ ] **Step 5: Commit**

```bash
git add packages/runtime-bridge/src/cli/answer.ts packages/runtime-bridge/test/aif-answer.test.ts
git commit -m "feat(runtime-bridge): answer.ts — add resume decision (pure parts)

Prior-art: skipped — extends shipped answer.ts with one decision + a pure string helper, no new capability artifact"
```

---

## Task 5: answer.ts `resume` network path (unpause + inject)

**Files:**
- Modify: `packages/runtime-bridge/src/cli/answer.ts` (`resumePark` + route it in `pushAnswer`)
- Test: `packages/runtime-bridge/test/aif-answer.test.ts`

- [ ] **Step 1: Write the failing test**

```ts
// append to packages/runtime-bridge/test/aif-answer.test.ts
describe('POSITIVE — resume: GET plan, then PUT { plan+answer, paused:false, blockedReason:null }', () => {
  it('injects the answer into the plan and unpauses', async () => {
    const task = { id: 't-7', title: 'x', status: 'implementing', plan: '# Plan\n## ⏸ OPEN QUESTION\nq', paused: true, blockedReason: 'q' };
    const spy = vi.spyOn(globalThis, 'fetch').mockImplementation((url) =>
      Promise.resolve(
        String(url).endsWith('/tasks/t-7')
          ? new Response(JSON.stringify(task), { status: 200, headers: { 'Content-Type': 'application/json' } })
          : new Response('{}', { status: 200, headers: { 'Content-Type': 'application/json' } }),
      ),
    );

    const result = await pushAnswer('http://localhost:3009', 't-7', 'resume', 'use Option A');

    // call 0 = GET, call 1 = PUT
    expect((spy.mock.calls[0][1] as RequestInit).method).toBe('GET');
    const put = spy.mock.calls[1][1] as RequestInit;
    expect(put.method).toBe('PUT');
    const body = JSON.parse(put.body as string);
    expect(body.plan).toContain('## ✅ OPERATOR ANSWER (resumed)');
    expect(body.plan).toContain('use Option A');
    expect(body.paused).toBe(false);
    expect(body.blockedReason).toBeNull();
    expect(result).toMatchObject({ taskId: 't-7', decision: 'resume', commented: false });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/runtime-bridge && npx vitest run test/aif-answer.test.ts`
Expected: FAIL — `pushAnswer` does not handle `resume` (sends an event instead of GET+PUT).

- [ ] **Step 3: Add `resumePark` + route it first in `pushAnswer`**

Add the function (after `postEvent`):

```ts
/**
 * Resume an A-park (paused mid-implementation): read the plan, inject the answer
 * under an OPERATOR ANSWER block, and PUT { plan, paused:false, blockedReason:null }.
 * The implementer re-reads the plan on its next tick (spec §3 resume / A).
 */
export async function resumePark(baseUrl: string, taskId: string, answer: string): Promise<PushResult> {
  const task = await getTask(baseUrl, taskId);
  const plan = appendAnswerToPlan(task.plan, answer);
  await putTask(baseUrl, taskId, { plan, paused: false, blockedReason: null });
  return { taskId, decision: 'resume', event: 'unpause (PUT paused=false)', commented: false };
}
```

At the TOP of `pushAnswer`, before `resolveStep`, route resume:

```ts
  if (decision === 'resume') {
    if (!answer || !answer.trim()) {
      throw new BackendError(`decision "resume" requires answer text`, 'dispatch_failed', 'aif-handoff');
    }
    return resumePark(baseUrl, taskId, answer.trim());
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/runtime-bridge && npx vitest run`
Expected: PASS (full package suite green).

- [ ] **Step 5: Commit**

```bash
git add packages/runtime-bridge/src/cli/answer.ts packages/runtime-bridge/test/aif-answer.test.ts
git commit -m "feat(runtime-bridge): answer.ts resume — unpause + inject answer into plan

Symmetric resolver for an A-park: GET plan, append OPERATOR ANSWER, PUT
{ plan, paused:false, blockedReason:null }. B-park (done→request_changes) unchanged.

Prior-art: skipped — extends shipped answer.ts resolve path, no new capability file"
```

---

## Task 6: OPTIONAL live contract test (the full F10 proof)

**Files:**
- Create: `packages/runtime-bridge/test/aif-park-live.test.ts`

> Env-gated so CI/normal runs SKIP it (the package convention is pure unit tests). Run it
> deliberately against a live aif: `RUNTIME_BRIDGE_LIVE_AIF=1 RUNTIME_BRIDGE_AIF_URL=http://localhost:3009 RUNTIME_BRIDGE_AIF_PROJECT_ID=<pid> npx vitest run test/aif-park-live.test.ts`.
> This is the executable form of spec §4's "paused ⇒ excluded from candidacy" / F10.

- [ ] **Step 1: Write the test**

```ts
// packages/runtime-bridge/test/aif-park-live.test.ts
import { describe, it, expect } from 'vitest';
import { getTask, putTask } from '../src/cli/aifHttp.js';

const LIVE = process.env.RUNTIME_BRIDGE_LIVE_AIF === '1';
const BASE = process.env.RUNTIME_BRIDGE_AIF_URL || 'http://localhost:3009';
const PID = process.env.RUNTIME_BRIDGE_AIF_PROJECT_ID;

describe.runIf(LIVE && !!PID)('LIVE contract: a paused task is not advanced by the coordinator (F10)', () => {
  it('creates a task, pauses it, and confirms it does not advance over a poll window', async () => {
    // create
    const created = await (await fetch(`${BASE}/tasks`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ projectId: PID, title: 'PARK-LIVE-PROBE-delete-me', description: 'guard', autoMode: false }),
    })).json() as { id: string };
    const id = created.id;
    try {
      await putTask(BASE, id, { paused: true, blockedReason: 'PARK-LIVE-PROBE' });
      const before = await getTask(BASE, id);
      await new Promise((r) => setTimeout(r, 15_000)); // > coordinator poll interval
      const after = await getTask(BASE, id);
      expect(after.paused).toBe(true);
      expect(after.blockedReason).toBe('PARK-LIVE-PROBE'); // not clobbered by the watchdog (F4)
      expect(after.status).toBe(before.status); // did not advance while paused
    } finally {
      await fetch(`${BASE}/tasks/${id}`, { method: 'DELETE' }); // cleanup
    }
  }, 30_000);
});
```

- [ ] **Step 2: Run it (skipped by default)**

Run: `cd packages/runtime-bridge && npx vitest run test/aif-park-live.test.ts`
Expected: 0 tests run / SKIPPED (no `RUNTIME_BRIDGE_LIVE_AIF=1`). With a live aif + the env set: PASS.

- [ ] **Step 3: Commit**

```bash
git add packages/runtime-bridge/test/aif-park-live.test.ts
git commit -m "test(runtime-bridge): optional live contract test — paused task not advanced (F10)

Env-gated (RUNTIME_BRIDGE_LIVE_AIF=1); skipped in CI. The full executable proof of
the spec §4 dependency, complementing the pure GUARD in aif-park.test.ts.

Prior-art: skipped — test-only, no capability artifact"
```

---

## Task 7: Document the agent's A-vs-B selection rule

**Files:**
- Modify: `docs/runtime-bridge-setup.md`

- [ ] **Step 1: Add a "Hard-fork park (park.ts)" section**

Append to `docs/runtime-bridge-setup.md`:

```markdown
## Hard-fork park — when the agent cannot pick a default

Soft/advisory questions already flow non-blocking to chat — the agent picks a
reasonable default and keeps going. Use the PARK primitive ONLY for a genuine
**hard fork that blocks continuing the implementation**.

- **Mid-flight hard fork (A):** the agent runs
  `tsx packages/runtime-bridge/src/cli/park.ts --question "<fork + A/B options>"`
  (`--task` defaults to `$HANDOFF_TASK_ID`). This pauses the task (`paused:true`,
  the only agent-reachable stop) and records the question. The operator resolves it
  with `answer.ts --decision resume --answer "<...>"`, which unpauses and injects
  the answer into the plan.
- **Finish-line fork (B):** the work is essentially done and the question is about
  direction/acceptance → the agent finishes to `done`; the operator answers via the
  existing `answer.ts --decision request_changes` rework path. No new code.

Never use `blockedReason` alone to stop the agent — the coordinator does not honor it
(it filters on `paused`). The `aif-park.test.ts` GUARD enforces this.
```

- [ ] **Step 2: Commit**

```bash
git add docs/runtime-bridge-setup.md
git commit -m "docs(runtime-bridge): agent A-vs-B hard-fork park selection rule

Prior-art: skipped — documentation only, no capability artifact"
```

---

## Self-Review (completed at plan-writing time)

- **Spec coverage:** §3 A-park → Tasks 2-3 (`park.ts`); §3 resume → Tasks 4-5 (`answer.ts resume`); §3 B-park → unchanged (documented Task 7); §4 guard-test → Task 3 GUARD (pure) + Task 6 (live); §3 OPEN QUESTION/ANSWER plan markers → `buildOpenQuestionPlan`/`appendAnswerToPlan`; §3 agent selection rule → Task 7; §5 BFR/Prior-art → Task 3 capability-commit note. No gaps.
- **Placeholder scan:** every code/test step shows complete code; no TBD/TODO.
- **Type consistency:** `getTask`/`putTask` (aifHttp) used identically in park.ts + answer.ts; `AifTaskFull.plan` is `string|null|undefined`, matching `buildOpenQuestionPlan`/`appendAnswerToPlan` signatures; `AnswerDecision` widened once (Task 4) and consumed in Task 5; `PushResult` shape reused by `resumePark`.
- **Known divergence from spec (intentional, noted):** park.ts both sets `blockedReason` AND writes the OPEN QUESTION anchor into the plan (spec §3 implied the anchor only) — the anchor gives `resume` a stable place to inject the answer; functionally equivalent, slightly more self-documenting.
```

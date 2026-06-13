// packages/runtime-bridge/test/aif-ensure-parallel.test.ts
import { describe, it, expect, vi, afterEach } from 'vitest';
import { ensureParallelEnabled, buildParallelEnablePut } from '../src/cli/ensure-parallel.js';
import type { AifProjectFull } from '../src/cli/aifHttp.js';

afterEach(() => vi.restoreAllMocks());

const PID = '441c1c0c-b633-4612-a34c-2cc0c4d0eaf2';

function project(overrides: Partial<AifProjectFull> = {}): AifProjectFull {
  return { id: PID, name: 'rules-as-tests-aif', rootPath: '/home/www/x', parallelEnabled: false, ...overrides };
}

function okResponse(body: unknown = {}, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
}

// Finding A self-heal (research-patch 2026-06-01-aif-task-isolation.md §2.2): aif creates
// per-task worktrees only when project.parallelEnabled=1 (gate 2 of 3). A freshly-provisioned
// instance has it 0 → tasks run in-place → dirty_worktree 409. This guard re-applies it.
describe('ensureParallelEnabled', () => {
  it('no-op when parallelEnabled is already true (GET only, NO PUT)', async () => {
    const spy = vi.spyOn(globalThis, 'fetch').mockResolvedValue(okResponse([project({ parallelEnabled: true })]));
    const r = await ensureParallelEnabled('http://localhost:3009', PID);

    expect(r).toMatchObject({ changed: false, reason: 'already-enabled', parallelEnabled: true });
    expect(spy.mock.calls).toHaveLength(1); // only the GET /projects
    expect((spy.mock.calls[0][1] as RequestInit).method).toBe('GET');
  });

  it('GETs /projects then PUTs parallelEnabled:true when disabled', async () => {
    const spy = vi.spyOn(globalThis, 'fetch').mockImplementation((url) =>
      Promise.resolve(String(url).endsWith('/projects') ? okResponse([project()]) : okResponse({})),
    );
    const r = await ensureParallelEnabled('http://localhost:3009', PID);

    expect(r).toMatchObject({ changed: true, reason: 'enabled-now', parallelEnabled: true });
    const put = spy.mock.calls[1][1] as RequestInit;
    expect(put.method).toBe('PUT');
    expect(JSON.parse(put.body as string).parallelEnabled).toBe(true);
  });

  // ── THE ANTI-CLOBBER GUARD (load-bearing). aif's PUT handler NULLs any omitted
  // *MaxBudgetUsd (@aif/data updateProject: `x ?? null`), so a minimal PUT would wipe a
  // UI-set budget. This proves the round-trip carries a set budget through verbatim.
  // RED if anyone "simplifies" the guard to a minimal {name,rootPath,parallelEnabled} PUT. ──
  it('GUARD: preserves a UI-set budget in the PUT body (does NOT clobber it to null)', async () => {
    const withBudget = project({ plannerMaxBudgetUsd: 5, implementerMaxBudgetUsd: 12 });
    const spy = vi.spyOn(globalThis, 'fetch').mockImplementation((url) =>
      Promise.resolve(String(url).endsWith('/projects') ? okResponse([withBudget]) : okResponse({})),
    );
    await ensureParallelEnabled('http://localhost:3009', PID);

    const putBody = JSON.parse((spy.mock.calls[1][1] as RequestInit).body as string);
    expect(putBody.plannerMaxBudgetUsd).toBe(5);
    expect(putBody.implementerMaxBudgetUsd).toBe(12);
    expect(putBody.parallelEnabled).toBe(true);
  });

  it('throws when the project id is not in the list', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(okResponse([project({ id: 'other' })]));
    await expect(ensureParallelEnabled('http://localhost:3009', PID)).rejects.toThrow(/not found/i);
  });
});

describe('buildParallelEnablePut — pure body builder', () => {
  it('flips parallelEnabled true and omits null budgets (schema budgets are .optional, not nullable)', () => {
    const body = buildParallelEnablePut(project({ plannerMaxBudgetUsd: null }));
    expect(body.parallelEnabled).toBe(true);
    expect(body.plannerMaxBudgetUsd).toBeUndefined(); // null → undefined → omitted (valid)
  });

  // Negative control paired with the anti-clobber guard: a numeric budget is carried, not dropped.
  it('CONTROL: carries a numeric budget through verbatim', () => {
    expect(buildParallelEnablePut(project({ reviewSidecarMaxBudgetUsd: 3 })).reviewSidecarMaxBudgetUsd).toBe(3);
  });
});

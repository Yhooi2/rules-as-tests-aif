// packages/runtime-bridge/test/harvest.test.ts
import { describe, it, expect, vi } from 'vitest';
import { harvestTask } from '../src/harvest.js';
import type { HarvestDeps } from '../src/harvest.js';

/** A deps double that records call order; each fn resolves successfully by default.
 *  Default `hasUncommittedChanges` → false (the normal approve_done path, where
 *  aif already committed) so existing positive tests stay no-op on the rework leg. */
function makeDeps(over: Partial<HarvestDeps> = {}): { deps: HarvestDeps; calls: string[] } {
  const calls: string[] = [];
  const deps: HarvestDeps = {
    hasUncommittedChanges: vi.fn(async (b: string) => {
      calls.push(`dirty?:${b}`);
      return false;
    }),
    // Default: 0 commits ahead → the true-rework leg (branch == base HEAD). Only
    // consulted when the tree is dirty; tests that exercise the stale-residue leg
    // override this to ≥1.
    commitsAhead: vi.fn(async (_b: string, base: string) => {
      calls.push(`aheadOf:${base}`);
      return 0;
    }),
    commitAll: vi.fn(async (b: string, msg: string) => {
      calls.push(`commit:${b}:${msg}`);
    }),
    pushBranch: vi.fn(async (b: string) => {
      calls.push(`push:${b}`);
    }),
    createPr: vi.fn(async (o) => {
      calls.push(`pr:${o.branch}->${o.base}`);
      return 'https://github.com/x/y/pull/42';
    }),
    enableAutoMerge: vi.fn(async (url: string) => {
      calls.push(`automerge:${url}`);
    }),
    ...over,
  };
  return { deps, calls };
}

const DONE_TASK = { id: 't1', title: 'feat: thing', status: 'done', branchName: 'feature/thing-abc' };

describe('harvestTask — positive', () => {
  it('pushes branch, opens PR vs base, enables auto-merge, returns PR url (in order)', async () => {
    const { deps, calls } = makeDeps();
    const res = await harvestTask(DONE_TASK, { baseBranch: 'staging', body: 'B', autoMerge: true }, deps);
    expect(res).toEqual({ prUrl: 'https://github.com/x/y/pull/42', branch: 'feature/thing-abc', pushed: true, autoMerge: true, committed: false, dirtyTreeLeftBehind: false });
    // dirty-check BEFORE push BEFORE pr BEFORE automerge — ordering is load-bearing
    // (can't PR an unpushed branch; clean tree → no ahead-check, no commit).
    expect(calls).toEqual(['dirty?:feature/thing-abc', 'push:feature/thing-abc', 'pr:feature/thing-abc->staging', 'automerge:https://github.com/x/y/pull/42']);
  });

  it('verified status is also harvestable (terminal)', async () => {
    const { deps } = makeDeps();
    const res = await harvestTask({ ...DONE_TASK, status: 'verified' }, { baseBranch: 'staging', body: 'B', autoMerge: false }, deps);
    expect(res.pushed).toBe(true);
  });

  it('autoMerge:false skips enableAutoMerge', async () => {
    const { deps } = makeDeps();
    await harvestTask(DONE_TASK, { baseBranch: 'staging', body: 'B', autoMerge: false }, deps);
    expect(deps.enableAutoMerge).not.toHaveBeenCalled();
  });
});

describe('harvestTask — rework-commit gap (dirty tree disambiguated by commits-ahead)', () => {
  // aif commits only on approve_done && commitOnApprove. A dirty tree is ambiguous:
  //   • 0 commits ahead of base → TRUE REWORK (request_changes→implementing→done left
  //     the work uncommitted, branch == base HEAD). Harvest commits it (ZERO LLM).
  //   • ≥1 commit ahead of base → STALE RESIDUE (aif already committed the deliverable;
  //     the dirty tree is out-of-scope base-state churn). Harvest must NOT `add -A` it.
  it('dirty tree + 0 commits ahead (true rework) → commits (templated, no LLM) BEFORE push; committed:true', async () => {
    const { deps, calls } = makeDeps({
      hasUncommittedChanges: vi.fn(async (b: string) => {
        calls.push(`dirty?:${b}`);
        return true; // rework left the tree dirty
      }),
      // default commitsAhead → 0 (branch == base HEAD)
    });
    const res = await harvestTask(DONE_TASK, { baseBranch: 'staging', body: 'B', autoMerge: true }, deps);
    expect(res.committed).toBe(true);
    expect(res.dirtyTreeLeftBehind).toBe(false);
    // ahead-check disambiguates AFTER the dirty-check; commit lands BEFORE the push.
    expect(calls).toEqual([
      'dirty?:feature/thing-abc',
      'aheadOf:staging',
      'commit:feature/thing-abc:chore(harvest): commit reworked aif task t1 — feat: thing',
      'push:feature/thing-abc',
      'pr:feature/thing-abc->staging',
      'automerge:https://github.com/x/y/pull/42',
    ]);
  });

  it('dirty tree + ≥1 commit ahead (stale residue) → does NOT commit; pushes the existing commit only; dirtyTreeLeftBehind:true', async () => {
    // The 2026-06-11 incident (aif task d037c54d, F2): aif committed the real work,
    // then left ~7 stale base-state files dirty. Old code `git add -A`'d them into the
    // PR. Now the branch's commits ARE the deliverable → push them; leave the tree.
    const { deps, calls } = makeDeps({
      hasUncommittedChanges: vi.fn(async (b: string) => {
        calls.push(`dirty?:${b}`);
        return true; // tree is dirty...
      }),
      commitsAhead: vi.fn(async (_b: string, base: string) => {
        calls.push(`aheadOf:${base}`);
        return 2; // ...but the branch already carries the real commits
      }),
    });
    const res = await harvestTask(DONE_TASK, { baseBranch: 'staging', body: 'B', autoMerge: true }, deps);
    expect(res.committed).toBe(false);
    expect(res.dirtyTreeLeftBehind).toBe(true);
    expect(res.pushed).toBe(true);
    expect(deps.commitAll).not.toHaveBeenCalled(); // the stale files are NOT add -A'd in
    // existing commit still pushed + PR'd; the dirty tree is skipped, not swept.
    expect(calls).toEqual([
      'dirty?:feature/thing-abc',
      'aheadOf:staging',
      'push:feature/thing-abc',
      'pr:feature/thing-abc->staging',
      'automerge:https://github.com/x/y/pull/42',
    ]);
  });

  it('clean tree → no ahead-check, no commit (commitsAhead + commitAll never called)', async () => {
    const { deps } = makeDeps(); // default hasUncommittedChanges → false
    const res = await harvestTask(DONE_TASK, { baseBranch: 'staging', body: 'B', autoMerge: false }, deps);
    expect(res.committed).toBe(false);
    expect(res.dirtyTreeLeftBehind).toBe(false);
    expect(deps.commitsAhead).not.toHaveBeenCalled();
    expect(deps.commitAll).not.toHaveBeenCalled();
  });

  it('commit failure on true rework → does NOT push or PR (fail-fast, operator gets the fallback)', async () => {
    const { deps } = makeDeps({
      hasUncommittedChanges: vi.fn(async () => true),
      commitsAhead: vi.fn(async () => 0), // true rework → commit is attempted
      commitAll: vi.fn(async () => {
        throw new Error('git commit failed: nothing staged');
      }),
    });
    await expect(
      harvestTask(DONE_TASK, { baseBranch: 'staging', body: 'B', autoMerge: true }, deps),
    ).rejects.toThrow(/git commit failed/);
    expect(deps.pushBranch).not.toHaveBeenCalled();
    expect(deps.createPr).not.toHaveBeenCalled();
  });
});

describe('harvestTask — paired-negative (must NOT push/PR on bad input)', () => {
  it('throws on non-terminal status and does NOT push (nothing to harvest yet)', async () => {
    const { deps } = makeDeps();
    await expect(
      harvestTask({ ...DONE_TASK, status: 'implementing' }, { baseBranch: 'staging', body: 'B', autoMerge: true }, deps),
    ).rejects.toThrow(/not terminal/i);
    expect(deps.pushBranch).not.toHaveBeenCalled();
    expect(deps.createPr).not.toHaveBeenCalled();
  });

  it('throws on missing branchName AFTER status ok, and does NOT open a PR', async () => {
    const { deps } = makeDeps();
    await expect(
      harvestTask({ ...DONE_TASK, branchName: undefined }, { baseBranch: 'staging', body: 'B', autoMerge: true }, deps),
    ).rejects.toThrow(/no branchName/i);
    expect(deps.createPr).not.toHaveBeenCalled();
  });

  it('does NOT enable auto-merge if PR creation throws (no half-merged state)', async () => {
    const { deps } = makeDeps({
      createPr: vi.fn(async () => {
        throw new Error('gh pr create failed');
      }),
    });
    await expect(harvestTask(DONE_TASK, { baseBranch: 'staging', body: 'B', autoMerge: true }, deps)).rejects.toThrow(
      /gh pr create failed/,
    );
    expect(deps.enableAutoMerge).not.toHaveBeenCalled();
  });
});

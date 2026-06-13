// packages/runtime-bridge/src/harvest.ts
/**
 * Harvest — the deterministic egress leg of the bridge.
 *
 * aif-handoff, by design, ends a task at "committed on a local feature branch +
 * auto-reviewed". It has NO push and NO PR-creation in its autonomous (HANDOFF)
 * path (verified 2026-06-01 against the running containers: `git push` lives only
 * in the LLM-driven `/aif-commit` flow, no `gh pr create` anywhere). So the
 * committed work strands inside aif's checkout, never reaching a reviewable PR on
 * the trunk.
 *
 * This is the missing return leg: take whatever aif committed (by its persisted
 * `task.branchName`), push that branch to origin, open a PR against the trunk, and
 * arm GitHub native auto-merge. It depends on NOTHING inside aif's commit state
 * machine — it ships the existing commit as-is.
 *
 * Deliberately ZERO LLM: aif's own commit flow spends a paid `claude -p` query just
 * to run `git add/commit/push` (a deterministic op). Harvest is plain git + gh, so
 * it costs nothing and complies with no-paid-llm-in-ci.md by construction.
 *
 * This module is the PURE core (dependency-injected) so it is unit-testable without
 * shelling out. The CLI wrapper (cli/harvest.ts) wires the real git/gh/docker
 * implementations.
 *
 * @cc-only-rationale: pure TS over injected deps — no CC-only primitive, no paid LLM.
 */

/** Terminal aif statuses whose work is committed and safe to harvest. */
const TERMINAL_STATUSES = new Set(['done', 'verified']);

/** The injected side-effects harvest performs, in order. */
export interface HarvestDeps {
  /**
   * Whether the branch's checkout has uncommitted changes. A dirty tree is
   * AMBIGUOUS on its own — it is the rework leg ONLY when paired with zero commits
   * ahead of base (see {@link commitsAhead}). aif's container also routinely leaves
   * a dirty tree AFTER committing the real work (stale base-state residue: reverted
   * CLAUDE.md/rules, resurrected deleted skill dirs), so "dirty" alone must NOT
   * trigger an `add -A` commit.
   */
  hasUncommittedChanges: (branchName: string) => Promise<boolean>;
  /**
   * How many commits the branch carries ahead of `base`
   * (`git rev-list --count <base>..HEAD`). This is the disambiguator the dirty-tree
   * check needs:
   *   • 0  → TRUE REWORK: aif's request_changes→implementing→done path left the work
   *          uncommitted (dirty tree, branch == base HEAD). Harvest must commit it.
   *   • ≥1 → STALE RESIDUE: aif already committed the deliverable; the dirty tree is
   *          out-of-scope base-state churn. `git add -A` would sweep those files into
   *          the PR (the #370/#457 regression class). Harvest must push the existing
   *          commit(s) only and leave the dirty tree behind.
   */
  commitsAhead: (branchName: string, base: string) => Promise<number>;
  /**
   * Deterministically commit all changes on the branch (git add -A && git commit
   * -m <message>). ZERO LLM — the message is templated from the task, never
   * generated — so the rework leg stays within no-paid-llm-in-ci.md.
   */
  commitAll: (branchName: string, message: string) => Promise<void>;
  /** Push the (already-committed) feature branch from aif's checkout to origin. */
  pushBranch: (branchName: string) => Promise<void>;
  /** Open a PR for the pushed branch against `base`; returns the PR URL. */
  createPr: (opts: { branch: string; base: string; title: string; body: string }) => Promise<string>;
  /** Arm GitHub native auto-merge on the PR (merges itself on green CI). */
  enableAutoMerge: (prUrl: string) => Promise<void>;
}

export interface HarvestOpts {
  /** Trunk the PR targets (e.g. "staging"). */
  baseBranch: string;
  /** PR body (the §1.7-compliant text the orchestrator/aif prepared). */
  body: string;
  /** Arm GitHub auto-merge after opening the PR. */
  autoMerge: boolean;
}

export interface HarvestResult {
  prUrl: string;
  branch: string;
  pushed: boolean;
  autoMerge: boolean;
  /** True when harvest had to commit a dirty tree (true-rework leg: dirty tree +
   *  0 commits ahead of base); false on the normal path where aif already committed. */
  committed: boolean;
  /** True when the tree was dirty but harvest deliberately LEFT it uncommitted
   *  because the branch already carried commits ahead of base — the committed work
   *  is the deliverable and the dirty tree is stale base-state residue that must not
   *  be `add -A`'d into the PR. Operator-visible so the CLI can warn. */
  dirtyTreeLeftBehind: boolean;
}

/** The subset of an aif task harvest reads. */
export interface HarvestableTask {
  id: string;
  title: string;
  status: string;
  branchName?: string | null;
}

/**
 * Harvest a completed aif task into a reviewable PR on the trunk.
 *
 * Order is load-bearing and fail-fast:
 *  1. guard status is terminal (work is committed) — else throw BEFORE any push.
 *  2. guard branchName present — else throw BEFORE opening a PR.
 *  3. dirty-tree disambiguation: a dirty tree is committed ONLY on the true-rework
 *     leg (0 commits ahead of base, i.e. branch == base HEAD). When the branch
 *     already carries commits, the dirty tree is stale base-state residue — push the
 *     existing commit(s), leave the tree behind (dirtyTreeLeftBehind), never
 *     `add -A`. If the rework commit throws, nothing is pushed (operator gets the
 *     printed fallback).
 *  4. push → createPr → (optional) enableAutoMerge. If createPr throws, auto-merge
 *     is never armed (no half-merged state).
 */
export async function harvestTask(
  task: HarvestableTask,
  opts: HarvestOpts,
  deps: HarvestDeps,
): Promise<HarvestResult> {
  if (!TERMINAL_STATUSES.has(task.status)) {
    throw new Error(
      `harvest: task ${task.id} status=${task.status} is not terminal (done/verified) — nothing to harvest yet`,
    );
  }
  const branch = task.branchName;
  if (!branch) {
    throw new Error(`harvest: task ${task.id} has no branchName — aif did not create/persist a feature branch`);
  }

  // Dirty-tree disambiguation. A dirty tree is NOT sufficient to trigger an
  // `add -A` commit — aif's container routinely leaves a dirty tree AFTER committing
  // the real work (stale base-state residue: reverted CLAUDE.md/rules, resurrected
  // deleted skill dirs). The commits-ahead count disambiguates the two cases:
  //   • 0 ahead  → TRUE REWORK: the request_changes→implementing→done path stranded
  //     the work uncommitted (dirty tree, branch == base HEAD). Commit it
  //     deterministically (templated message, ZERO LLM) so there is a real commit to push.
  //   • ≥1 ahead → STALE RESIDUE: the committed work IS the deliverable. `git add -A`
  //     here would sweep out-of-scope stale files into the PR (the #370/#457 regression
  //     class). Push the existing commit(s) only; leave the dirty tree behind and
  //     surface it via dirtyTreeLeftBehind so the operator is warned.
  let committed = false;
  let dirtyTreeLeftBehind = false;
  if (await deps.hasUncommittedChanges(branch)) {
    if ((await deps.commitsAhead(branch, opts.baseBranch)) === 0) {
      await deps.commitAll(branch, `chore(harvest): commit reworked aif task ${task.id} — ${task.title}`);
      committed = true;
    } else {
      dirtyTreeLeftBehind = true;
    }
  }

  await deps.pushBranch(branch);
  const prUrl = await deps.createPr({ branch, base: opts.baseBranch, title: task.title, body: opts.body });

  let autoMerge = false;
  if (opts.autoMerge) {
    await deps.enableAutoMerge(prUrl);
    autoMerge = true;
  }

  return { prUrl, branch, pushed: true, autoMerge, committed, dirtyTreeLeftBehind };
}

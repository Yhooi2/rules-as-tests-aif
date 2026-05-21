/**
 * Structural meta-tests for the Wave 10.1 dispatcher + orchestrator.
 *
 * These assert the dispatch contract that dual-implementation-discipline.md §4
 * mandates (capability-check, not brand-name) and the migration invariants that
 * keep enforcement intact (delegation through runCheck; self-tests still
 * referenced by literal path; trailer block delegated to the legacy shim).
 * The runner's own behaviour is covered by utils/run-check.test.ts.
 */
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(HERE, '../../..');
const DISPATCHER = readFileSync(resolve(REPO_ROOT, '.husky/pre-push'), 'utf8');
const ORCHESTRATOR = readFileSync(resolve(HERE, 'pre-push.ts'), 'utf8');

describe('.husky/pre-push dispatcher — capability-check, not brand-name', () => {
  it('routes on Node capability presence (command -v node)', () => {
    expect(DISPATCHER).toMatch(/command -v node/);
  });

  it('gates on a Node major-version check before using --import', () => {
    expect(DISPATCHER).toMatch(/-ge 20/);
  });

  it('execs the TS-core hook via node --import tsx/esm', () => {
    expect(DISPATCHER).toMatch(/--import tsx\/esm/);
    expect(DISPATCHER).toMatch(/packages\/core\/hooks\/pre-push\.ts/);
  });

  it('does NOT branch on a harness brand string (#brand-name-detection)', () => {
    // Falsification per dual-implementation-discipline.md §8: no conditional
    // keyed on a Claude-Code / Anthropic brand identifier.
    expect(DISPATCHER).not.toMatch(/AI_HARNESS|CLAUDE_CODE|ANTHROPIC|["']claude["']/);
  });

  it('degrades (never hard-blocks the push) when Node is unavailable', () => {
    expect(DISPATCHER).toMatch(/pre-push\.fallback\.sh/);
    expect(DISPATCHER).toMatch(/exit 0/);
  });
});

describe('pre-push.ts orchestrator — delegation folded through runCheck', () => {
  it('routes external checks through the tested runCheck helper', () => {
    expect(ORCHESTRATOR).toMatch(/from '\.\/utils\/run-check\.ts'/);
  });

  it('invokes all three audit-self self-tests by literal path', () => {
    // Keeps hook-stub-completeness.test.sh (which greps this file) satisfiable.
    for (const s of [
      'audit-ai-docs.test.sh',
      'pre-push.test.sh',
      'hook-stub-completeness.test.sh',
    ]) {
      expect(ORCHESTRATOR).toContain(`packages/core/audit-self/${s}`);
    }
  });

  it('delegates the trailer block to the legacy bash shim (ported in 10.2/10.3)', () => {
    expect(ORCHESTRATOR).toMatch(/legacy-trailer-checks\.sh/);
  });
});

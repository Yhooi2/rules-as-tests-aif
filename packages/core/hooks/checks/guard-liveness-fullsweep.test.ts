/**
 * guard-liveness-fullsweep.test.ts — coverage for the v2 full-sweep orchestrator.
 *
 * Paired-negative contract (principle 02 Stage 3C — content-level status/exit
 * assertions for files under hooks/): the gate verdict `hasFailures` has, per
 * failure source, a ❌ "a guard failed → gate FAILS" case and a ✅ "guard clean →
 * gate passes" case; the tolerance policy (skip/no-data/exempt do NOT fail) has its
 * own ✅ case. The subprocess boundary (v3 structural arm) is injected, never run.
 *
 * §2.5 (no double-fire): a deterministic test asserts the shipped workflow triggers
 * on PRs into `main` ONLY — never `staging`. This is the self-contained equivalent
 * of the kickoff's "principle 02/15 extension" (no cross-owner edit to principle
 * 02/15 needed — the assertion lives with the v2 artefact it guards).
 */
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { CheckResult } from '../utils/run-check.ts';
import type { GuardLivenessReport, ManifestRule } from './guard-liveness.ts';
import type { CmdScriptLivenessReport, CmdScriptRule } from './cmd-script-liveness.ts';
import {
  runFullSweep,
  hasFailures,
  formatReport,
  type FullSweepReport,
  type StructuralArmResult,
} from './guard-liveness-fullsweep.ts';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(HERE, '../../../..');

const emptyEslint = (): GuardLivenessReport => ({ failures: [], skipped: [], passed: [], noData: [] });
const emptyCmd = (): CmdScriptLivenessReport => ({ failures: [], passed: [], skipped: [], exempt: [], noData: [] });
const passStructural = (): StructuralArmResult => ({ passed: true, output: '' });

function report(over: Partial<FullSweepReport> = {}): FullSweepReport {
  return {
    eslint: emptyEslint(),
    cmdScript: emptyCmd(),
    structural: passStructural(),
    manualRuleIds: [],
    ...over,
  };
}

const notFound: CheckResult = { exitCode: 127, stdout: '', stderr: 'ENOENT', timedOut: false, notFound: true };

describe('hasFailures — gate verdict (paired-negative per source)', () => {
  it('✅ all arms clean → gate passes', () => {
    expect(hasFailures(report())).toBe(false);
  });

  it('❌ an ESLint guard that did not catch its violation → gate FAILS', () => {
    const r = report({
      eslint: { ...emptyEslint(), failures: [{ ruleId: 'R2', failures: ['input[0] did not trip'] }] },
    });
    expect(hasFailures(r)).toBe(true);
  });

  it('❌ a cmd/script guard that did not catch its violation → gate FAILS', () => {
    const r = report({
      cmdScript: {
        ...emptyCmd(),
        failures: [{ ruleId: 'R11', mode: 'workflow-exists', failures: ['workflow missing'] }],
      },
    });
    expect(hasFailures(r)).toBe(true);
  });

  it('❌ the v3 structural arm (principle 02) failed → gate FAILS', () => {
    const r = report({ structural: { passed: false, output: 'principle 02 red', reason: 'exited 1' } });
    expect(hasFailures(r)).toBe(true);
  });

  it('✅ skip / no-data / exempt are TOLERATED (do NOT fail the gate) — T14 tolerance policy', () => {
    const r = report({
      eslint: { ...emptyEslint(), passed: ['R2'], skipped: ['R5: plugin not registered'], noData: ['R6'] },
      cmdScript: {
        ...emptyCmd(),
        passed: ['R3'],
        skipped: ['R1 [run-and-assert]: binary unavailable'],
        exempt: ['IR3: no runnable form'],
        noData: [],
      },
    });
    expect(hasFailures(r)).toBe(false);
  });
});

describe('runFullSweep — enumerates each check.type into the right arm', () => {
  it('routes eslint / command|script / manual rules to their arms and counts manual rules', () => {
    const manifest = {
      E1: { check: { type: 'eslint', rule: 'rules-as-tests/no-such-rule' }, examples: { bad: 'x', good: 'y' } },
      C1: { check: { type: 'command', command: 'definitely-not-a-real-binary' }, fixture: { 'setup-script': 'true' } },
      M1: { check: { type: 'manual' }, 'pressure-scenario': { 'baseline-prompt': 'p' } },
    } as unknown as Record<string, ManifestRule & CmdScriptRule>;

    const r = runFullSweep({
      manifest,
      repoRoot: REPO_ROOT,
      // mock the subprocess primitive so the cmd arm never spawns a real binary
      runCheckFn: (() => notFound) as never,
      // inject the v3 structural arm so the test never spawns vitest
      structuralRunner: () => ({ passed: true, output: 'mock' }),
    });

    // eslint rule with no negative-test → no-data (not a failure)
    expect(r.eslint.noData).toContain('E1');
    expect(r.eslint.failures).toHaveLength(0);
    // command rule whose binary is not found → skipped (not a failure)
    expect(r.cmdScript.skipped.join(' ')).toContain('C1');
    expect(r.cmdScript.failures).toHaveLength(0);
    // manual rules surfaced for coverage transparency
    expect(r.manualRuleIds).toEqual(['M1']);
    expect(r.structural.passed).toBe(true);
    expect(hasFailures(r)).toBe(false);
  });
});

describe('formatReport — coverage transparency (T14)', () => {
  it('reports per-arm pass/fail/skip counts and the GREEN/FAILED verdict', () => {
    const green = formatReport(report({ manualRuleIds: ['R10', 'R13'] }));
    expect(green).toContain('FULL-SWEEP GREEN');
    expect(green).toContain('v1 ESLint arm');
    expect(green).toContain('v1.5 cmd/script arm');
    expect(green).toContain('v3 structural arm');
    expect(green).toContain('session-bound'); // LLM probe disclosure

    const red = formatReport(
      report({ eslint: { ...emptyEslint(), failures: [{ ruleId: 'R2', failures: ['boom'] }] } }),
    );
    expect(red).toContain('FULL-SWEEP FAILED');
    expect(red).toContain('R2');
  });
});

describe('§2.5 — the shipped workflow triggers on PRs into main ONLY (no double-fire on staging)', () => {
  const wf = readFileSync(resolve(REPO_ROOT, '.github/workflows/guard-liveness-fullsweep.yml'), 'utf8');
  // Extract the `on:` trigger block (up to the next top-level key) to scope the check —
  // the prose header legitimately mentions "staging", so we must not match on the whole file.
  const onBlock = wf.slice(wf.indexOf('\non:'), wf.indexOf('\npermissions:'));

  it('✅ triggers on pull_request into main', () => {
    expect(onBlock).toMatch(/pull_request:/);
    expect(onBlock).toMatch(/branches:\s*\[main\]/);
  });

  it('❌ does NOT target staging in its trigger (would double-fire with the change-scoped gates)', () => {
    expect(onBlock).not.toMatch(/staging/);
  });

  it('enforces the ≤5-min runtime budget mechanically', () => {
    expect(wf).toMatch(/timeout-minutes:\s*5/);
  });
});

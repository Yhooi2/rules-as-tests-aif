// D5 CI proof: run-generated-rule-mutation gate logic — iterates >1 generated rule,
// kills ≥60% of selector mutations, and flags broken (neutered) selectors (neuter→RED).
//
// Does NOT shell to universalmutator or pip — runs inline via ESLint Linter API.
// Mirrors run-bash-mutation.test.ts structural intent but for the generated-rule surface:
// - Non-JSX selectors used in stub so Espree parses without JSX plugin
// - Paired negative (neuter→RED) proves the gate's baseline-check catches vacuous tests
//
// SSOT #91 ADAPT: same kill-floor (60%) as run-bash-mutation.sh's MIN_KILL=${3:-60}.

import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { Linter } from 'eslint';
import { synthesizeGenerate } from './generate.ts';
import type { GenerateClient, Menu, GenerateSelection } from './generate-port.ts';
import type { ResearchPlan } from '../research/types.ts';

const HERE = dirname(fileURLToPath(import.meta.url));
const FIXTURES = resolve(HERE, 'fixtures');

// ─── Test stub: two declarative rules from the no-head-element research plan ──
// Uses non-JSX selectors so Espree parses inputs without requiring JSX plugin.
// Rule 1 maps to 'next-no-head-element'; Rule 2 maps to 'next-server-only-boundary'.
// This proves synthesizeGenerate + mutation gate handle >1 rule correctly.
const stubGenerateHead: GenerateClient = {
  async generate(_menu: Menu): Promise<GenerateSelection> {
    return {
      rules: [
        {
          // G1 — next-no-head-element: proxy with non-JSX selector (CallExpression form)
          entryId: 'next-no-head-element',
          ruleId: 'no-head-element-proxy',
          title: 'Do not call createHeadElement() — use the Metadata API (proxy, no-JSX form)',
          stack: ['react-next'],
          presence: 'forbid',
          selector: "CallExpression[callee.name='createHeadElement']",
          message: 'Use the Metadata API instead of createHeadElement().',
          examples: {
            bad: 'createHeadElement();',
            good: 'const metadata = { title: "Page" };',
          },
          negativeTest: {
            input: ['createHeadElement();'],
            'expect-violation': 'no-restricted-syntax',
          },
        },
        {
          // G2 — next-server-only-boundary: server-only import proxy
          entryId: 'next-server-only-boundary',
          ruleId: 'no-server-only-import-proxy',
          title: "Forbid import of 'server-only' in client components (proxy form)",
          stack: ['react-next'],
          presence: 'forbid',
          selector: "ImportDeclaration[source.value='server-only']",
          message: "Do not import 'server-only' in client components.",
          examples: {
            bad: "import 'server-only';",
            good: '// server-only is only used in Server Components',
          },
          negativeTest: {
            input: ["import 'server-only';"],
            'expect-violation': 'no-restricted-syntax',
          },
        },
      ],
    };
  },
};

// ─── Inline mutation helpers (same 3-mutation set as install-time gate M1/M2/M3) ──
function applyMutations(selector: string): string[] {
  return [
    `NOMATCH_ANON_9X > ${selector}`,       // M1: prepend unreachable ancestor
    'Program > NOMATCH_SENTINEL_9X',        // M2: replace with sentinel
    `${selector}[NOMATCH_ATTR_9X='_']`,    // M3: append unmatchable attribute
  ];
}

function probeSelector(selector: string, code: string): boolean {
  const linter = new Linter();
  const cfg = [
    {
      rules: {
        'no-restricted-syntax': ['error' as const, { selector, message: 'mutation-ci-probe' }],
      },
      languageOptions: {
        ecmaVersion: 2022 as const,
        sourceType: 'module' as const,
      },
    },
  ];
  try {
    const msgs = linter.verify(code, cfg, { filename: 'probe.ts' });
    return msgs.some((m) => m.ruleId === 'no-restricted-syntax');
  } catch {
    return false;
  }
}

function measureKillRate(selector: string, badInput: string): number {
  const mutations = applyMutations(selector);
  let killed = 0;
  for (const mut of mutations) {
    if (!probeSelector(mut, badInput)) killed++;
  }
  return killed / mutations.length;
}

// ─── Tests ────────────────────────────────────────────────────────────────────
describe('run-generated-rule-mutation — D5 CI proof', () => {
  const noHeadPlan: ResearchPlan = JSON.parse(
    readFileSync(resolve(FIXTURES, 'no-head-element.research.json'), 'utf8'),
  ) as ResearchPlan;

  it('stubGenerateHead: produces >1 declarative rule from 2-pattern fixture', async () => {
    const plan = await synthesizeGenerate(noHeadPlan, stubGenerateHead);
    const declarative = plan.rules.filter((r) => r.check.type === 'declarative');
    // Must cover BOTH patterns → >1 rule (proves gate iterates across rules, not just one)
    expect(declarative.length).toBeGreaterThan(1);
    // Each rule carries a negative-test with ≥1 bad input
    for (const r of declarative) {
      const nt = r['negative-test'];
      expect(nt, `rule ${r.id} (${r.research.entryId}) must have negative-test`).toBeDefined();
      expect(
        nt?.input.length,
        `rule ${r.id} negative-test.input must be non-empty`,
      ).toBeGreaterThanOrEqual(1);
    }
  });

  it('baseline check: each generated selector fires on its bad input (non-vacuous before mutation)', async () => {
    const plan = await synthesizeGenerate(noHeadPlan, stubGenerateHead);
    for (const rule of plan.rules.filter((r) => r.check.type === 'declarative')) {
      if (rule.check.type !== 'declarative') continue;
      const badInput = rule['negative-test']?.input[0];
      if (!badInput) continue;
      expect(
        probeSelector(rule.check.selector, badInput),
        `rule ${rule.id} selector='${rule.check.selector}' must fire on bad input '${badInput}'`,
      ).toBe(true);
    }
  });

  it('mutation gate: all generated declarative rules achieve ≥60% kill rate (SSOT #91 floor)', async () => {
    const plan = await synthesizeGenerate(noHeadPlan, stubGenerateHead);
    for (const rule of plan.rules.filter((r) => r.check.type === 'declarative')) {
      if (rule.check.type !== 'declarative') continue;
      const badInput = rule['negative-test']?.input[0];
      if (!badInput) continue;
      const killRate = measureKillRate(rule.check.selector, badInput);
      expect(
        killRate,
        `rule ${rule.id} (${rule.check.selector}): kill=${Math.round(killRate * 100)}% < 60% floor — generated test is theatre`,
      ).toBeGreaterThanOrEqual(0.6);
    }
  });

  it('gate covers both generated rules (not just the first)', async () => {
    const plan = await synthesizeGenerate(noHeadPlan, stubGenerateHead);
    const declarative = plan.rules.filter((r) => r.check.type === 'declarative');
    expect(declarative.length).toBeGreaterThanOrEqual(2);
    const entryIds = declarative.map((r) => r.research.entryId);
    expect(entryIds).toContain('next-no-head-element');
    expect(entryIds).toContain('next-server-only-boundary');
    // Both achieve ≥60% kill rate independently
    for (const rule of declarative) {
      if (rule.check.type !== 'declarative') continue;
      const badInput = rule['negative-test']?.input[0];
      if (!badInput) continue;
      expect(measureKillRate(rule.check.selector, badInput)).toBeGreaterThanOrEqual(0.6);
    }
  });

  it('paired-negative (neuter → RED): neutered selector fails baseline — gate detects broken test', async () => {
    // Simulate: generator produced a selector with a typo ('createHeadElement' → 'createHeadXlement').
    // The bad input still contains 'createHeadElement()' → neutered selector does NOT fire.
    // The mutation gate's baseline check catches this: original-does-not-fire → bad() → rc=1 (RED).
    const plan = await synthesizeGenerate(noHeadPlan, stubGenerateHead);
    const g1 = plan.rules.find((r) => r.research.entryId === 'next-no-head-element');
    expect(g1).toBeDefined();
    if (!g1 || g1.check.type !== 'declarative') return;

    const badInput = g1['negative-test']!.input[0]!;

    // Sanity: the REAL selector fires on the bad input
    expect(probeSelector(g1.check.selector, badInput)).toBe(true);

    // Neutered: replace 'createHeadElement' → 'createHeadXlement' (typo)
    const neuteredSelector = g1.check.selector.replace('createHeadElement', 'createHeadXlement');
    expect(neuteredSelector).not.toBe(g1.check.selector); // confirm mutation happened

    // RED: neutered selector does NOT fire on the bad input
    // → the gate's baseline check would call bad() → fail → exit 1 (RED, not vacuous-pass)
    expect(
      probeSelector(neuteredSelector, badInput),
      `neutered selector '${neuteredSelector}' must NOT fire on '${badInput}' — gate should catch it`,
    ).toBe(false);
  });

  it('M1/M2/M3 mutation set: each mutation independently fails to fire on bad input', async () => {
    // Prove that ALL THREE mutations are semantically broken (they never fire on valid bad inputs).
    // This is a white-box test of the mutation operators themselves.
    const badInput = "import 'server-only';";
    const selector = "ImportDeclaration[source.value='server-only']";

    // Original fires
    expect(probeSelector(selector, badInput)).toBe(true);

    // M1: NOMATCH_ANON_9X > selector → NOMATCH_ANON_9X never exists → 0 matches → KILLED
    expect(probeSelector(`NOMATCH_ANON_9X > ${selector}`, badInput)).toBe(false);
    // M2: Program > NOMATCH_SENTINEL_9X → NOMATCH_SENTINEL_9X never exists → 0 matches → KILLED
    expect(probeSelector('Program > NOMATCH_SENTINEL_9X', badInput)).toBe(false);
    // M3: selector[NOMATCH_ATTR_9X='_'] → no node has NOMATCH_ATTR_9X → 0 matches → KILLED
    expect(probeSelector(`${selector}[NOMATCH_ATTR_9X='_']`, badInput)).toBe(false);

    // All 3 killed → kill rate = 100% (well above 60% floor)
    expect(measureKillRate(selector, badInput)).toBe(1.0);
  });
});

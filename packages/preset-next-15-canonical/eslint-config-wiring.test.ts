// Guard: the consumer ESLint template wires R14 + R20 through the exempt-aware wrapper
// using the EXACT selectors from the shipped recipes (the recipes are the SSOT).
//
// The template (templates/eslint.config.react.mjs) is a CONSUMER artifact that no other
// repo CI step lints — the R8 `rules-as-tests/require-otel-span` dangling ref shipped broken
// (S3 deleted the rule, left the template ref; opt-in, so CI never caught it). This
// deterministic text check closes that exact blind spot for R14/R20: if a recipe selector
// changes and the template is not updated (or a copy typo creeps in), this test fails.

import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const HERE = dirname(fileURLToPath(import.meta.url));
const TEMPLATE = resolve(HERE, 'templates', 'eslint.config.react.mjs');
const RECIPES = resolve(HERE, '..', 'core', 'synthesizer', 'recipes');

const template = readFileSync(TEMPLATE, 'utf8');
const recipeCheck = (file: string): { selector: string; message: string } =>
  JSON.parse(readFileSync(resolve(RECIPES, file), 'utf8')).rule.check;
const r14 = recipeCheck('next-r14-require-form-safe-parse.json');
const r20 = recipeCheck('next-r20-require-use-server-directive.json');

describe('consumer eslint template — R14/R20 wired through the exempt-aware wrapper', () => {
  it('activates the wrapper, not the deleted handwritten rule names', () => {
    expect(template).toContain('rules-as-tests/restricted-syntax-audit-exempt');
    // Paired-negative: the deleted named-rule activations must be gone (else dangling ref).
    expect(template).not.toContain("'rules-as-tests/require-form-safe-parse'");
    expect(template).not.toContain("'rules-as-tests/require-use-server-directive'");
  });

  it('carries the EXACT R14 recipe selector + message (no copy drift)', () => {
    expect(template).toContain(r14.selector);
    expect(template).toContain(r14.message);
  });

  it('carries the EXACT R20 recipe selector + message (no copy drift)', () => {
    expect(template).toContain(r20.selector);
    expect(template).toContain(r20.message);
  });
});

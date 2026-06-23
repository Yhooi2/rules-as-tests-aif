// S4: deterministic RULES.md fragment generated from a declarative spec.
// Replaces the per-recipe handwritten rulesMdTemplate for check.type==='declarative'
// (T-MVP-A: a new forbid/require rule is added as data, not a handwritten template).
import type { SynthesizedRule } from './types.ts';

type EngineOutput = { runner: string; checkLine: string };

function resolveEngine(rule: SynthesizedRule): EngineOutput {
  if (rule.check.type !== 'declarative') {
    throw new Error(
      `resolveEngine called on non-declarative rule ${rule.id} (check.type=${rule.check.type})`,
    );
  }
  const engineName = rule.check.engine ?? 'eslint-restricted';
  const presenceLabel = rule.check.presence === 'require' ? 'require' : 'forbid';
  switch (engineName) {
    case 'eslint-restricted':
      return {
        runner: 'no-restricted-syntax',
        checkLine: `declarative \`no-restricted-syntax\` ${presenceLabel} (eslint-restricted engine)`,
      };
    case 'ast-grep':
      return {
        runner: 'ast-grep',
        checkLine: `declarative ast-grep ${presenceLabel} (ast-grep engine)`,
      };
    // G3b: codegen engine slots here
    default:
      throw new Error(`Unsupported engine: ${engineName}`);
  }
}

export function compileDeclarativeMd(rule: SynthesizedRule): string {
  if (rule.check.type !== 'declarative') {
    throw new Error(
      `compileDeclarativeMd called on non-declarative rule ${rule.id} (check.type=${rule.check.type})`,
    );
  }
  const { selector, message } = rule.check;
  const { runner, checkLine } = resolveEngine(rule);
  const why = message ?? (rule.check.presence === 'require' ? 'required construct' : 'forbidden construct');
  return [
    `## ${rule.id} — ${rule.title}`,
    '',
    `**Stack:** ${rule.stack.join(', ')}  `,
    `**Check:** ${checkLine}  `,
    `**Selector:** \`${selector}\`  `,
    `**Why:** ${why}`,
    '',
  ].join('\n');
}

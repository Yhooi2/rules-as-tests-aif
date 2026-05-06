import { noUnsafeZodParse } from './no-unsafe-zod-parse.ts';
import { noDirectTimeRandomness } from './no-direct-time-randomness.ts';
import { requireOtelSpan } from './require-otel-span.ts';
import { noServerImportsInClient } from './no-server-imports-in-client.ts';
import { requireFormSafeParse } from './require-form-safe-parse.ts';
import { requireUseServerDirective } from './require-use-server-directive.ts';

const plugin = {
  meta: {
    name: '@rules-as-tests/eslint-rules',
    version: '0.1.0',
  },
  rules: {
    'no-unsafe-zod-parse': noUnsafeZodParse,
    'no-direct-time-randomness': noDirectTimeRandomness,
    'require-otel-span': requireOtelSpan,
    'no-server-imports-in-client': noServerImportsInClient,
    'require-form-safe-parse': requireFormSafeParse,
    'require-use-server-directive': requireUseServerDirective,
  },
};

export default plugin;
export const rules = plugin.rules;

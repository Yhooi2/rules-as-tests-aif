import { noServerImportsInClient } from './no-server-imports-in-client.ts';
import { requireFormSafeParse } from './require-form-safe-parse.ts';
import { requireUseServerDirective } from './require-use-server-directive.ts';

const plugin = {
  meta: {
    name: '@rules-as-tests/preset-next-15-canonical-eslint-rules',
    version: '0.1.0',
  },
  rules: {
    'no-server-imports-in-client': noServerImportsInClient,
    'require-form-safe-parse': requireFormSafeParse,
    'require-use-server-directive': requireUseServerDirective,
  },
};

export default plugin;
export const rules = plugin.rules;

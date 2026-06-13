import { ESLintUtils, AST_NODE_TYPES } from '@typescript-eslint/utils';
import type { TSESTree } from '@typescript-eslint/utils';

const createRule = ESLintUtils.RuleCreator(
  () =>
    `https://github.com/Yhooi2/rules-as-tests-aif/blob/main/packages/preset-next-15-canonical/RULES.react-next.md#r20--server-actions`,
);

function isExempt(line: string): boolean {
  return line.includes('// audit:exempt');
}

function hasUseServerDirective(program: TSESTree.Program): boolean {
  const first = program.body[0];
  if (!first) return false;
  if (first.type !== AST_NODE_TYPES.ExpressionStatement) return false;
  const expr = first.expression;
  if (expr.type !== AST_NODE_TYPES.Literal) return false;
  return expr.value === 'use server';
}

function isAsyncExportFunction(
  stmt: TSESTree.ProgramStatement,
): TSESTree.FunctionDeclaration | null {
  if (
    stmt.type === AST_NODE_TYPES.ExportNamedDeclaration &&
    stmt.declaration?.type === AST_NODE_TYPES.FunctionDeclaration &&
    stmt.declaration.async
  ) {
    return stmt.declaration;
  }
  if (
    stmt.type === AST_NODE_TYPES.ExportDefaultDeclaration &&
    stmt.declaration.type === AST_NODE_TYPES.FunctionDeclaration &&
    (stmt.declaration as TSESTree.FunctionDeclaration).async
  ) {
    return stmt.declaration as TSESTree.FunctionDeclaration;
  }
  return null;
}

export const requireUseServerDirective = createRule({
  name: 'require-use-server-directive',
  meta: {
    type: 'problem',
    docs: {
      description:
        "Files exporting `export async function` (Server Actions) must start with a 'use server' directive (R20).",
    },
    messages: {
      missingUseServerDirective:
        "Server Action file must start with 'use server' directive at the top of the file (R20).",
    },
    schema: [],
  },
  defaultOptions: [],
  create(context) {
    const sourceCode = context.sourceCode;
    const lines = sourceCode.lines;

    return {
      Program(program: TSESTree.Program) {
        if (hasUseServerDirective(program)) return;
        for (const stmt of program.body) {
          const fn = isAsyncExportFunction(stmt);
          if (!fn) continue;
          if (isExempt(lines[stmt.loc.start.line - 1] ?? '')) continue;
          context.report({
            node: fn,
            messageId: 'missingUseServerDirective',
          });
        }
      },
    };
  },
});

import { RuleTester } from '@typescript-eslint/rule-tester';
import { afterAll, describe, it } from 'vitest';
import { requireUseServerDirective } from './require-use-server-directive.ts';

RuleTester.afterAll = afterAll;
RuleTester.describe = describe;
RuleTester.it = it;
RuleTester.itOnly = it.only;

const ruleTester = new RuleTester();

ruleTester.run('require-use-server-directive', requireUseServerDirective, {
  valid: [
    // No async export — rule does not apply
    `export function sync() { return 1; }`,
    // 'use server' present + async export — OK
    `'use server';\nexport async function action() { return 1; }`,
    // double-quoted directive — OK
    `"use server";\nexport async function action() { return 1; }`,
    // Default async export with directive — OK
    `'use server';\nexport default async function action() { return 1; }`,
    // Multiple async exports with directive — OK
    `'use server';
     export async function a() { return 1; }
     export async function b() { return 2; }`,
    // Only synchronous export named — rule does not apply
    `export const value = 42;`,
    // Exempt comment on async export line
    `export async function action() { return 1; } // audit:exempt`,
    // Async non-exported function — does not apply
    `async function helper() { return 1; }
     export const x = 1;`,
  ],
  invalid: [
    {
      code: `export async function action() { return 1; }`,
      errors: [{ messageId: 'missingUseServerDirective' }],
    },
    {
      code: `import { db } from './db';
export async function action() { return db.q(); }`,
      errors: [{ messageId: 'missingUseServerDirective' }],
    },
    {
      // Directive not first — does not count
      code: `import './side-effect';
'use server';
export async function action() { return 1; }`,
      errors: [{ messageId: 'missingUseServerDirective' }],
    },
    {
      // Non-string-literal first statement
      code: `const x = 1;
export async function action() { return 1; }`,
      errors: [{ messageId: 'missingUseServerDirective' }],
    },
    {
      // Multiple violations — one report per async export function
      code: `export async function a() { return 1; }
export async function b() { return 2; }`,
      errors: [
        { messageId: 'missingUseServerDirective' },
        { messageId: 'missingUseServerDirective' },
      ],
    },
    {
      // Default export
      code: `export default async function action() { return 1; }`,
      errors: [{ messageId: 'missingUseServerDirective' }],
    },
  ],
});

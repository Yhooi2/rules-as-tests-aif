import { RuleTester } from '@typescript-eslint/rule-tester';
import { afterAll, describe, it } from 'vitest';
import { requireFormSafeParse } from './require-form-safe-parse.ts';

RuleTester.afterAll = afterAll;
RuleTester.describe = describe;
RuleTester.it = it;
RuleTester.itOnly = it.only;

const ruleTester = new RuleTester();

ruleTester.run('require-form-safe-parse', requireFormSafeParse, {
  valid: [
    // No FormData parameter — rule does not apply
    `export async function action(input: { name: string }) { return input; }`,
    // FormData parameter + safeParse call — OK
    `export async function action(formData: FormData) {
       const parsed = schema.safeParse(Object.fromEntries(formData));
       return parsed;
     }`,
    // FormData under different name + safeParse — OK
    `export async function action(fd: FormData) {
       schema.safeParse(fd.get('name'));
     }`,
    // globalThis.FormData qualified — also OK
    `export async function action(fd: globalThis.FormData) {
       schema.safeParse(Object.fromEntries(fd));
     }`,
    // Arrow function with FormData + safeParse — OK
    `export const submit = async (formData: FormData) => {
       const result = schema.safeParse(Object.fromEntries(formData));
       return result;
     };`,
    // Exempt line on the parameter
    `export async function action(formData: FormData /* audit:exempt */) {
       return formData.get('name');
     }`,
    // safeParse used through a helper inside body
    `export async function action(formData: FormData) {
       const data = Object.fromEntries(formData);
       const parsed = userSchema.safeParse(data);
       return parsed.data;
     }`,
  ],
  invalid: [
    {
      code: `export async function action(formData: FormData) {
        return formData.get('name');
      }`,
      errors: [{ messageId: 'missingFormSafeParse' }],
    },
    {
      code: `export const submit = async (fd: FormData) => {
        const name = fd.get('name');
        return name;
      };`,
      errors: [{ messageId: 'missingFormSafeParse' }],
    },
    {
      code: `export function sync(formData: FormData) {
        const obj = Object.fromEntries(formData);
        return obj;
      }`,
      errors: [{ messageId: 'missingFormSafeParse' }],
    },
    {
      code: `export async function action(input: string, fd: FormData) {
        return fd.get(input);
      }`,
      errors: [{ messageId: 'missingFormSafeParse' }],
    },
  ],
});

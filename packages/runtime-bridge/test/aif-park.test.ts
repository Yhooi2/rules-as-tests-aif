// packages/runtime-bridge/test/aif-park.test.ts
import { describe, it, expect, vi, afterEach } from 'vitest';
import { parseParkArgs, validateParkArgs, buildOpenQuestionPlan } from '../src/cli/park.js';

afterEach(() => vi.restoreAllMocks());

describe('parseParkArgs', () => {
  it('reads --task and --question; --task overrides HANDOFF_TASK_ID env', () => {
    const args = parseParkArgs(['--task', 't-9', '--question', 'tone: A or B?'], { HANDOFF_TASK_ID: 't-env' });
    expect(args).toMatchObject({ taskId: 't-9', question: 'tone: A or B?', json: false });
  });
  it('falls back to HANDOFF_TASK_ID when --task is absent', () => {
    const args = parseParkArgs(['--question', 'q'], { HANDOFF_TASK_ID: 't-env' });
    expect(args.taskId).toBe('t-env');
  });
});

describe('validateParkArgs', () => {
  it('rejects a missing task id', () => {
    expect(validateParkArgs({ taskId: undefined, question: 'q', json: false })).toMatch(/missing.*task/i);
  });
  it('rejects an empty question', () => {
    expect(validateParkArgs({ taskId: 't-1', question: '   ', json: false })).toMatch(/question/i);
  });
  it('accepts a valid pair', () => {
    expect(validateParkArgs({ taskId: 't-1', question: 'q', json: false })).toBeNull();
  });
});

describe('buildOpenQuestionPlan', () => {
  it('appends a marked OPEN QUESTION block to the existing plan', () => {
    const out = buildOpenQuestionPlan('# Plan\n- step 1', 'tagline tone: A=playful / B=serious');
    expect(out).toContain('# Plan\n- step 1');
    expect(out).toContain('## ⏸ OPEN QUESTION (awaiting operator)');
    expect(out).toContain('tagline tone: A=playful / B=serious');
  });
  it('handles a null/empty existing plan', () => {
    expect(buildOpenQuestionPlan(null, 'q')).toContain('## ⏸ OPEN QUESTION (awaiting operator)');
  });
});

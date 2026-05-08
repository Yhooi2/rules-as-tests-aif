import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { detectStack } from './index.ts';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(HERE, '../../..');
const TMP = resolve(REPO_ROOT, '.tmp-detector-test');

function writePkg(deps: Record<string, string>, devDeps: Record<string, string> = {}) {
  mkdirSync(TMP, { recursive: true });
  writeFileSync(
    resolve(TMP, 'package.json'),
    JSON.stringify({ name: 'fake', dependencies: deps, devDependencies: devDeps }),
  );
}

describe('detectStack — manifest priority 4', () => {
  beforeEach(() => {
    rmSync(TMP, { recursive: true, force: true });
    mkdirSync(TMP, { recursive: true });
  });
  afterEach(() => {
    rmSync(TMP, { recursive: true, force: true });
  });

  it('next@^16 in deps → react-next, framework.major=16, confidence=medium', () => {
    writePkg({ next: '^16.0.1', react: '^19.0.0' });
    const r = detectStack(TMP);
    expect(r.stack).toBe('react-next');
    expect(r.framework.name).toBe('next');
    expect(r.framework.major).toBe(16);
    expect(r.confidence).toBe('medium');
    expect(r.severity).toBe('warn');
    expect(r.weight).toBe(1);
    expect(r.source).toBe('package.json');
  });

  it('next@^15 in deps → framework.major=15 (version-aware Next 15 vs 16)', () => {
    writePkg({ next: '^15.4.2' });
    const r = detectStack(TMP);
    expect(r.framework.major).toBe(15);
  });

  it('react-only (no next) → still react-next stack, framework.name=react', () => {
    writePkg({ react: '^19.0.0' });
    const r = detectStack(TMP);
    expect(r.stack).toBe('react-next');
    expect(r.framework.name).toBe('react');
  });

  it('no react/next markers → ts-server fallback, framework.name=null', () => {
    writePkg({ zod: '^3.24.0' });
    const r = detectStack(TMP);
    expect(r.stack).toBe('ts-server');
    expect(r.framework.name).toBeNull();
  });

  it('absent package.json + tsconfig.json present → priority 5 (low)', () => {
    writeFileSync(resolve(TMP, 'tsconfig.json'), '{}');
    const r = detectStack(TMP);
    expect(r.stack).toBe('ts-server');
    expect(r.confidence).toBe('low');
    expect(r.severity).toBe('info');
    expect(r.source).toBe('tsconfig.json');
  });

  it('next.config.js present (no package.json) → priority 5 react-next', () => {
    writeFileSync(resolve(TMP, 'next.config.js'), 'module.exports = {};');
    const r = detectStack(TMP);
    expect(r.stack).toBe('react-next');
    expect(r.framework.name).toBe('next');
    expect(r.confidence).toBe('low');
  });

  it('completely empty dir → unknown, source empty, low confidence', () => {
    const r = detectStack(TMP);
    expect(r.stack).toBe('unknown');
    expect(r.confidence).toBe('low');
    expect(r.source).toBe('');
  });

  it('skipAif=true bypasses .ai-factory reads (covered by read-aif tests; smoke check)', () => {
    writePkg({ next: '^16.0.0' });
    const r = detectStack(TMP, { skipAif: true });
    expect(r.source).toBe('package.json');
  });
});

describe('detectStack — self-application on this repo', () => {
  it('repo root resolves to a non-empty result', () => {
    const r = detectStack(REPO_ROOT, { skipAif: true });
    // This repo is the meta-factory itself: zod is a dep, next is not — expect ts-server.
    expect(r.stack).toBe('ts-server');
    expect(r.source).toBe('package.json');
    expect(r.confidence).toBe('medium');
  });
});

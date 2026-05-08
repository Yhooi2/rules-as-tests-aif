// Priority 4: package.json deps + lockfile signature.
// Extends detector-v0/detect-applicable-rules.ts logic — manifest-based heuristic fallback.

import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import type { DetectionResult } from './types.ts';
import { toConfidence } from './confidence.ts';
import { extractMajor, extractVersion } from './version-aware.ts';

interface PackageJson {
  dependencies?: Record<string, string>;
  devDependencies?: Record<string, string>;
}

function readPkg(projectRoot: string): { pkg: PackageJson; allDeps: Record<string, string> } | null {
  const pkgPath = resolve(projectRoot, 'package.json');
  if (!existsSync(pkgPath)) return null;
  const pkg: PackageJson = JSON.parse(readFileSync(pkgPath, 'utf8'));
  const allDeps: Record<string, string> = {
    ...(pkg.dependencies ?? {}),
    ...(pkg.devDependencies ?? {}),
  };
  return { pkg, allDeps };
}

export function readManifest(projectRoot: string): DetectionResult | null {
  const result = readPkg(projectRoot);
  if (!result) return null;
  const { allDeps } = result;

  const tuple = toConfidence(4);
  const source = 'package.json';
  const baseRules = { applicable: [] as string[], skipped: [] as string[] };

  if ('next' in allDeps) {
    const range = allDeps.next;
    return {
      stack: 'react-next',
      framework: { name: 'next', version: extractVersion(range), major: extractMajor(range) },
      runtime: { name: 'node', major: null },
      ...tuple,
      source,
      rules: baseRules,
    };
  }

  if ('react' in allDeps || '@types/react' in allDeps) {
    const range = allDeps.react ?? allDeps['@types/react'];
    return {
      stack: 'react-next',
      framework: { name: 'react', version: extractVersion(range), major: extractMajor(range) },
      runtime: { name: 'node', major: null },
      ...tuple,
      source,
      rules: baseRules,
    };
  }

  // No React/Next markers → server-side TS by default (matches setup.sh:94 fallback).
  return {
    stack: 'ts-server',
    framework: { name: null, version: null, major: null },
    runtime: { name: 'node', major: null },
    ...tuple,
    source,
    rules: baseRules,
  };
}

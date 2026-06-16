# §1.7 PR-body citation-existence gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an anti-fabrication arm to the §1.7 CI PR-body gate so a fabricated `foo.ts:42` citation fails, making real verification the cheapest path to green.

**Architecture:** New pure, fs-injected TS module `packages/core/hooks/checks/s17-pr-body.ts` (mirrors `s17.ts`) implementing L2 (block: ≥1 citation per section resolves to a real file:line at HEAD) + L3 (warn: genuine-looking citations that don't resolve or point to a filler line). A thin CLI runs it in CI after `actions/checkout` of the PR head; the existing inline bash (L1/presence/≥40-char) is left untouched (additive, zero blast radius).

**Tech Stack:** TypeScript, vitest, `node:fs`, `npx tsx`, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-06-16-s17-pr-body-citation-existence-gate-design.md`

---

## File Structure

- Create: `packages/core/hooks/checks/s17-pr-body.ts` — pure logic + `RepoFileReader` interface (parsing, predicates, L2/L3 checker).
- Create: `packages/core/hooks/checks/s17-pr-body.test.ts` — vitest, paired-negative, in-memory reader.
- Create: `packages/core/hooks/checks/s17-pr-body-cli.ts` — CI entry: env `PR_BODY` + real fs reader, annotations, exit code.
- Modify: `.github/workflows/discipline-self-check.yml` — add checkout(head) + setup-node + install + tsx step to the `verify-pr-body-sections` job.
- Modify: `.claude/skills/self-reflection/SKILL.md` — one-line note that citations are existence-checked.

**Commit/push policy:** commit to the feature branch as the TDD rhythm dictates; do **NOT** push or open a PR without explicit maintainer ask. The eventual PR is separate from the SKILL.md heading-drift doc-fix already in the tree.

---

## Task 1: Parsing core — `extractSection` + `findCitations` + `RepoFileReader`

**Files:**
- Create: `packages/core/hooks/checks/s17-pr-body.ts`
- Test: `packages/core/hooks/checks/s17-pr-body.test.ts`

- [ ] **Step 1: Write the failing test**

```ts
import { describe, it, expect } from 'vitest';
import { extractSection, findCitations } from './s17-pr-body.ts';

const BODY = [
  '### §1.7 Forward-check applied',
  'Checked packages/core/foo.ts:42 — compliant.',
  '',
  '### §1.7 Backward-check applied',
  'Swept docs/bar.md:7 and Node.js:18 prose.',
].join('\n');

describe('extractSection', () => {
  it('captures from heading to next ### (exclusive)', () => {
    const fwd = extractSection(BODY, '### §1.7 Forward-check applied');
    expect(fwd).toContain('packages/core/foo.ts:42');
    expect(fwd).not.toContain('docs/bar.md:7');
  });
  it('returns empty string when heading absent', () => {
    expect(extractSection(BODY, '### §1.7 Nonexistent')).toBe('');
  });
});

describe('findCitations', () => {
  it('extracts path + line from path.ext:line matches', () => {
    const cites = findCitations('see packages/core/foo.ts:42 here');
    expect(cites).toEqual([{ raw: 'packages/core/foo.ts:42', path: 'packages/core/foo.ts', line: 42 }]);
  });
  it('matches prose-shaped tokens too (Node.js:18)', () => {
    expect(findCitations('Node.js:18').map((c) => c.path)).toEqual(['Node.js']);
  });
  it('returns [] when no citation present', () => {
    expect(findCitations('no citations here')).toEqual([]);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/core && npx vitest run hooks/checks/s17-pr-body.test.ts`
Expected: FAIL — cannot import `./s17-pr-body.ts` (module not found).

- [ ] **Step 3: Write minimal implementation**

Create `packages/core/hooks/checks/s17-pr-body.ts`:

```ts
/**
 * s17-pr-body.ts — §1.7 CI PR-body citation-existence check (combo L2 block + L3 warn).
 *
 * Companion to checks/s17.ts (pre-push commit-trailer surface). This validates the
 * `### §1.7 Forward/Backward-check applied` sections in a PULL-REQUEST body, enforced
 * by .github/workflows/discipline-self-check.yml. Pure logic separated from fs I/O via
 * the injected RepoFileReader, so it is unit-testable + Stryker-mutatable.
 *
 * Spec: docs/superpowers/specs/2026-06-16-s17-pr-body-citation-existence-gate-design.md
 */

/** Reads repo files at the checked-out head; null = path absent. Injected for tests. */
export interface RepoFileReader {
  readLines(path: string): string[] | null;
}

export interface Citation {
  raw: string;
  path: string;
  line: number;
}

// Same shape the CI gate's awk/grep uses: non-space, dot, lowercase ext, colon, digits.
const CITATION_RE = /[^\s]+\.[a-z]+:[0-9]+/g;

/** Capture a section body: from the heading line to the next "###" (exclusive). */
export function extractSection(prBody: string, heading: string): string {
  const out: string[] = [];
  let capture = false;
  for (const line of prBody.split('\n')) {
    if (line.startsWith(heading)) { capture = true; continue; }
    if (line.startsWith('###')) capture = false;
    if (capture) out.push(line);
  }
  return out.join('\n');
}

/** All path:line citations in a section. */
export function findCitations(section: string): Citation[] {
  const out: Citation[] = [];
  for (const m of section.matchAll(CITATION_RE)) {
    const raw = m[0];
    const idx = raw.lastIndexOf(':');
    out.push({ raw, path: raw.slice(0, idx), line: Number(raw.slice(idx + 1)) });
  }
  return out;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/core && npx vitest run hooks/checks/s17-pr-body.test.ts`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add packages/core/hooks/checks/s17-pr-body.ts packages/core/hooks/checks/s17-pr-body.test.ts
git commit -m "feat(s17-pr-body): section + citation parsing for §1.7 existence gate"
```

---

## Task 2: Predicates — `looksLikeRepoPath` + `isSubstantiveLine`

**Files:**
- Modify: `packages/core/hooks/checks/s17-pr-body.ts`
- Test: `packages/core/hooks/checks/s17-pr-body.test.ts`

- [ ] **Step 1: Write the failing test** (append to the test file)

```ts
import { looksLikeRepoPath, isSubstantiveLine } from './s17-pr-body.ts';

describe('looksLikeRepoPath', () => {
  it('true for slashed paths', () => {
    expect(looksLikeRepoPath('packages/core/foo.ts')).toBe(true);
  });
  it('true for bare known extension', () => {
    expect(looksLikeRepoPath('README.md')).toBe(true);
  });
  it('false for prose like Node.js', () => {
    expect(looksLikeRepoPath('Node.js')).toBe(false);
  });
});

describe('isSubstantiveLine', () => {
  it('true for a line with identifiers', () => {
    expect(isSubstantiveLine('  const x = 1;')).toBe(true);
  });
  it('false for blank', () => {
    expect(isSubstantiveLine('   ')).toBe(false);
  });
  it('false for brace/punctuation-only', () => {
    expect(isSubstantiveLine('  });')).toBe(false);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/core && npx vitest run hooks/checks/s17-pr-body.test.ts`
Expected: FAIL — `looksLikeRepoPath`/`isSubstantiveLine` not exported.

- [ ] **Step 3: Write minimal implementation** (append to `s17-pr-body.ts`)

```ts
// A "genuine-looking" repo path: has a slash OR a known code/doc extension.
const REPO_EXT_RE = /\.(tsx?|m?js|cjs|json|md|sh|ya?ml)$/;

/** Does this citation path look like a real repo file (vs prose like "Node.js:18")? */
export function looksLikeRepoPath(path: string): boolean {
  return path.includes('/') || REPO_EXT_RE.test(path);
}

/** Non-blank and not punctuation/brace-only (has ≥1 alphanumeric/underscore char). */
export function isSubstantiveLine(text: string): boolean {
  return /[A-Za-z0-9_]/.test(text);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/core && npx vitest run hooks/checks/s17-pr-body.test.ts`
Expected: PASS (11 tests).

- [ ] **Step 5: Commit**

```bash
git add packages/core/hooks/checks/s17-pr-body.ts packages/core/hooks/checks/s17-pr-body.test.ts
git commit -m "feat(s17-pr-body): repo-path + substantive-line predicates"
```

---

## Task 3: The combo checker — `checkPrBodyCitations` (L2 block + L3 warn)

**Files:**
- Modify: `packages/core/hooks/checks/s17-pr-body.ts`
- Test: `packages/core/hooks/checks/s17-pr-body.test.ts`

- [ ] **Step 1: Write the failing test** (append). Paired-negative is mandatory.

```ts
import { checkPrBodyCitations, type RepoFileReader } from './s17-pr-body.ts';

// In-memory reader: map of path -> lines.
function reader(files: Record<string, string[]>): RepoFileReader {
  return { readLines: (p) => files[p] ?? null };
}

const FILES = {
  'packages/core/foo.ts': ['line1', 'const real = 1;', 'line3'],
  'docs/bar.md': ['# Title', '', 'body'],
};

function bodyWith(fwd: string, bwd: string): string {
  return [
    '### §1.7 Forward-check applied',
    fwd,
    '',
    '### §1.7 Backward-check applied',
    bwd,
  ].join('\n');
}

describe('checkPrBodyCitations — L2 block', () => {
  it('fabricated citation (resolves to nothing) → blocker', () => {
    const body = bodyWith('see nonexistent/x.ts:9 here', 'see nonexistent/y.ts:9 here');
    const { blockers } = checkPrBodyCitations(body, reader(FILES));
    expect(blockers.length).toBe(2); // both sections fail
  });

  it('PAIRED-NEGATIVE / mutation arm: a resolving citation must clear the blocker', () => {
    // If the existence check were removed, the fabricated-only case above would also pass.
    const body = bodyWith('packages/core/foo.ts:2 verified', 'docs/bar.md:1 swept');
    const { blockers } = checkPrBodyCitations(body, reader(FILES));
    expect(blockers).toEqual([]);
  });

  it('≥1 resolves among a fabricated + real mix → no blocker', () => {
    const body = bodyWith('packages/core/foo.ts:2 real + nonexistent/x.ts:9 fake', 'docs/bar.md:1 ok');
    const { blockers } = checkPrBodyCitations(body, reader(FILES));
    expect(blockers).toEqual([]);
  });

  it('out-of-range line on a real file does not resolve → blocker if sole citation', () => {
    const body = bodyWith('packages/core/foo.ts:9999 claim', 'docs/bar.md:1 ok');
    const { blockers } = checkPrBodyCitations(body, reader(FILES));
    expect(blockers.length).toBe(1); // forward fails, backward ok
  });

  it('no citations in a section → no L2 blocker (L1 bash owns presence)', () => {
    const body = bodyWith('prose only, no citation', 'docs/bar.md:1 ok');
    const { blockers } = checkPrBodyCitations(body, reader(FILES));
    expect(blockers).toEqual([]);
  });
});

describe('checkPrBodyCitations — L3 warn', () => {
  it('genuine-looking citation that does not resolve → warning, no blocker', () => {
    const body = bodyWith('packages/core/foo.ts:2 real + docs/missing.md:3 stale', 'docs/bar.md:1 ok');
    const { blockers, warnings } = checkPrBodyCitations(body, reader(FILES));
    expect(blockers).toEqual([]);
    expect(warnings.some((w) => w.includes('docs/missing.md:3'))).toBe(true);
  });

  it('citation to a filler (blank) line → warning', () => {
    const body = bodyWith('docs/bar.md:2 (blank line)', 'docs/bar.md:1 ok');
    const { warnings } = checkPrBodyCitations(body, reader(FILES));
    expect(warnings.some((w) => w.includes('docs/bar.md:2'))).toBe(true);
  });

  it('prose Node.js:18 is ignored by L3 (not a repo path)', () => {
    const body = bodyWith('packages/core/foo.ts:2 real, also Node.js:18', 'docs/bar.md:1 ok');
    const { warnings } = checkPrBodyCitations(body, reader(FILES));
    expect(warnings.some((w) => w.includes('Node.js:18'))).toBe(false);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/core && npx vitest run hooks/checks/s17-pr-body.test.ts`
Expected: FAIL — `checkPrBodyCitations` not exported.

- [ ] **Step 3: Write minimal implementation** (append to `s17-pr-body.ts`)

```ts
export interface CitationResult {
  blockers: string[];
  warnings: string[];
}

const SECTIONS = [
  '### §1.7 Forward-check applied',
  '### §1.7 Backward-check applied',
] as const;

function resolvesCitation(c: Citation, reader: RepoFileReader): boolean {
  const lines = reader.readLines(c.path);
  return lines !== null && c.line >= 1 && c.line <= lines.length;
}

export function checkPrBodyCitations(
  prBody: string,
  reader: RepoFileReader,
): CitationResult {
  const blockers: string[] = [];
  const warnings: string[] = [];

  for (const heading of SECTIONS) {
    const citations = findCitations(extractSection(prBody, heading));

    // L2 (block): if the section has citations, ≥1 must resolve at HEAD.
    if (citations.length > 0 && !citations.some((c) => resolvesCitation(c, reader))) {
      blockers.push(
        `${heading}: no citation resolves to an existing file:line at HEAD ` +
          `(checked ${citations.length}: ${citations.map((c) => c.raw).join(', ')}). ` +
          `Cite at least one real path.ext:line.`,
      );
    }

    // L3 (warn): genuine-looking citations that don't resolve or point to a filler line.
    for (const c of citations) {
      if (!looksLikeRepoPath(c.path)) continue;
      const lines = reader.readLines(c.path);
      if (lines === null || c.line < 1 || c.line > lines.length) {
        warnings.push(
          `${heading}: citation ${c.raw} does not resolve (file absent or line out of range).`,
        );
        continue;
      }
      if (!isSubstantiveLine(lines[c.line - 1])) {
        warnings.push(
          `${heading}: citation ${c.raw} points to a non-substantive line (blank/punctuation-only).`,
        );
      }
    }
  }
  return { blockers, warnings };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/core && npx vitest run hooks/checks/s17-pr-body.test.ts`
Expected: PASS (all tests).

- [ ] **Step 5: Commit**

```bash
git add packages/core/hooks/checks/s17-pr-body.ts packages/core/hooks/checks/s17-pr-body.test.ts
git commit -m "feat(s17-pr-body): combo L2-block + L3-warn citation-existence checker"
```

---

## Task 4: CLI entry — `s17-pr-body-cli.ts`

**Files:**
- Create: `packages/core/hooks/checks/s17-pr-body-cli.ts`

- [ ] **Step 1: Write the implementation** (no unit test — thin I/O shim; verified by manual run in Step 2)

```ts
/**
 * s17-pr-body-cli.ts — CI entry for the §1.7 PR-body citation-existence gate.
 * Reads PR_BODY from env, resolves citations against the checked-out repo (cwd),
 * prints GH Actions annotations, exits 1 iff there are L2 blockers. L3 warnings
 * never fail the job (calibration window). Invoked from discipline-self-check.yml.
 */
import { readFileSync } from 'node:fs';
import { checkPrBodyCitations, type RepoFileReader } from './s17-pr-body.ts';

const SKIP_RE = /^### §1\.7 Skipped:.{60,}/m;

const fsReader: RepoFileReader = {
  readLines(path) {
    try {
      return readFileSync(path, 'utf8').split('\n');
    } catch {
      return null;
    }
  },
};

const body = process.env.PR_BODY ?? '';

if (SKIP_RE.test(body)) {
  console.log('✅ §1.7 Skipped marker present — citation-existence check bypassed.');
  process.exit(0);
}

const { blockers, warnings } = checkPrBodyCitations(body, fsReader);
for (const w of warnings) console.log(`::warning::${w}`);
for (const b of blockers) console.log(`::error::${b}`);

if (blockers.length > 0) {
  console.log('');
  console.log('§1.7 substance (L2): each section must cite at least one REAL file.ext:line.');
  console.log('A fabricated citation that does not resolve at HEAD fails this gate.');
  console.log('Skip marker: ### §1.7 Skipped: <reason ≥60 chars>.');
  process.exit(1);
}
console.log(`✅ §1.7 citation-existence check passed (${warnings.length} warning(s)).`);
```

- [ ] **Step 2: Manual smoke from repo root — fabricated body fails, real body passes**

Run (fabricated → expect exit 1 + `::error::`):
```bash
PR_BODY=$'### §1.7 Forward-check applied\nsee nonexistent/x.ts:9\n\n### §1.7 Backward-check applied\nsee nonexistent/y.ts:9' \
  npx tsx packages/core/hooks/checks/s17-pr-body-cli.ts; echo "exit=$?"
```
Expected: prints `::error::…`, `exit=1`.

Run (real citations → expect exit 0). Pick two real lines first:
```bash
# verify the lines exist, then cite them
sed -n '1p' packages/core/hooks/checks/s17-pr-body.ts
PR_BODY=$'### §1.7 Forward-check applied\npackages/core/hooks/checks/s17-pr-body.ts:1 checked\n\n### §1.7 Backward-check applied\npackages/core/hooks/checks/s17-pr-body.test.ts:1 swept' \
  npx tsx packages/core/hooks/checks/s17-pr-body-cli.ts; echo "exit=$?"
```
Expected: prints `✅ …`, `exit=0`.

- [ ] **Step 3: Commit**

```bash
git add packages/core/hooks/checks/s17-pr-body-cli.ts
git commit -m "feat(s17-pr-body): CI CLI entry (PR_BODY env, fs reader, annotations)"
```

---

## Task 5: Wire the workflow (additive — existing bash untouched)

**Files:**
- Modify: `.github/workflows/discipline-self-check.yml` (the `verify-pr-body-sections` job, after the existing bash step ~line 95)

- [ ] **Step 1: Confirm the exact install step audit-self uses (mirror it)**

Run: `grep -nA3 'hoists tsx to root' .github/workflows/audit-self.yml | head`
Expected: shows the workspace-install step (e.g. `npm install` at root or with a prefix). Mirror it verbatim in Step 2.

- [ ] **Step 2: Add steps to the `verify-pr-body-sections` job** (append AFTER the existing "Check PR body for §1.7 sections or skip marker" step; pinned action SHAs match the repo's other workflows)

```yaml
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
        with:
          ref: ${{ github.event.pull_request.head.sha }}
      - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020  # v4.4.0
        with:
          node-version: 20
      - name: Install workspace deps (hoists tsx to root)
        run: npm install --no-audit --no-fund   # MIRROR audit-self.yml's step exactly per Step 1
      - name: §1.7 citation-existence check (L2 block + L3 warn)
        env:
          PR_BODY: ${{ github.event.pull_request.body }}
        run: npx tsx packages/core/hooks/checks/s17-pr-body-cli.ts
```

> Security note (repo threat model): this runs `tsx` on the checked-out PR head. Acceptable for this single-maintainer, same-repo-PR project (base = staging). If external PRs are ever accepted, revisit (run the checker from base, read head files).

- [ ] **Step 3: Validate the workflow YAML**

Run: `npx --yes @action-validator/cli .github/workflows/discipline-self-check.yml 2>/dev/null || npx --yes actionlint .github/workflows/discipline-self-check.yml 2>/dev/null || echo "validate with whatever the repo uses (see pre-push actionlint step)"`
Expected: no syntax errors. If actionlint unavailable locally, rely on the repo's existing actionlint pre-push step.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/discipline-self-check.yml
git commit -m "feat(ci): wire §1.7 citation-existence check into discipline-self-check"
```

---

## Task 6: Document existence-checking in the SKILL Output contract

**Files:**
- Modify: `.claude/skills/self-reflection/SKILL.md` (Output-contract section, after the "≥1 `file.ext:line` citation in BOTH sections" bullet)

- [ ] **Step 1: Add the note**

Add this bullet under the gate-requirements list:

```markdown
- **Citations are existence-checked (L2 block).** At least one `file.ext:line` per section must resolve to a real file with the line in range at the PR head — a fabricated `foo.ts:42` that does not resolve fails the gate ([s17-pr-body.ts](../../../packages/core/hooks/checks/s17-pr-body.ts)). Genuine-looking citations that don't resolve, or point to a blank/brace-only line, surface as `::warning::` (L3, calibration).
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/self-reflection/SKILL.md
git commit -m "docs(self-reflection): note §1.7 citations are existence-checked (L2/L3)"
```

---

## Task 7: Full suite + self-application check

- [ ] **Step 1: Run the full packages/core test suite**

Run: `npm --prefix packages/core run test`
Expected: all green, including `s17-pr-body.test.ts`.

- [ ] **Step 2: Confirm the new test is actually collected (not silently skipped)**

Run: `npm --prefix packages/core run test 2>&1 | grep -i s17-pr-body`
Expected: shows the test file with passing counts.

- [ ] **Step 3: Self-application — the PR body must pass its own gate**

When opening the PR (only on maintainer ask), its `### §1.7 Forward-check applied` / `### §1.7 Backward-check applied` sections must each cite ≥1 real, resolving `path:line` (e.g. `packages/core/hooks/checks/s17-pr-body.ts:NN`). Verify by running the CLI against the drafted body locally before pushing.

---

## Self-Review (writing-plans)

**Spec coverage:** §3 combo table → Tasks 1-3; §4 architecture (module/CLI/workflow) → Tasks 1-5; §5 testing/paired-negative → Task 3 + Task 7; §5 live-sample FP check → folded into Task 7 Step 3 + execution judgment; §7 self-application + SKILL note → Tasks 6-7. §6 scope-out items intentionally have no task.

**Placeholder scan:** the only deliberate deferral is Task 5 Step 1 ("mirror audit-self's install step") — concrete instruction with a grep to resolve it, not a placeholder.

**Type consistency:** `RepoFileReader.readLines`, `Citation{raw,path,line}`, `CitationResult{blockers,warnings}`, `checkPrBodyCitations`, `extractSection`, `findCitations`, `looksLikeRepoPath`, `isSubstantiveLine` — names identical across Tasks 1-4 and the CLI.

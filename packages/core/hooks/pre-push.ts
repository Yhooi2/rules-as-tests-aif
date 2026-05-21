/**
 * pre-push.ts — TS-core pre-push orchestrator (Wave 10.1).
 *
 * Invoked by the 10-line `.husky/pre-push` dispatcher via
 * `node --import tsx/esm packages/core/hooks/pre-push.ts`. Replaces the bash
 * body of the former 476-line hook. Every "pure delegation" section (§3.1
 * OWN-BUILD classification) runs through the single tested `runCheck()` helper
 * (utils/run-check.ts), which is the Aider-derived abstraction adopted in
 * research patch §4.8.X.1 — turning previously un-unit-tested `execSync`
 * shell-outs into thin, individually-tested call sites (closes C3 for the
 * delegation sections).
 *
 * The two trailer-PARSING sections (§7 Prior-art trailer, §1.7 discipline
 * trailer) remain in `legacy-trailer-checks.sh` for now and are invoked here via
 * runCheck('bash', …) so enforcement is uninterrupted. They migrate to TS in
 * Wave 10.2 (checks/prior-art.ts) and Wave 10.3 (checks/s17.ts); the shim then
 * shrinks to empty and is deleted.
 *
 * Behaviour parity with the former bash hook is byte-faithful for the delegation
 * sections; documented deviations:
 *   - actionlint is invoked with an explicit, fs-resolved `.github/workflows/*.yml`
 *     list (vs shell glob) — equivalent set, and empty-dir is skipped rather than
 *     passing a literal unmatched glob.
 *   - section output is captured and re-emitted after each check rather than
 *     streamed live (acceptable for sub-second checks).
 */
import { existsSync, readdirSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { runCheck, type CheckResult } from './utils/run-check.ts';

const HERE = dirname(fileURLToPath(import.meta.url));
// packages/core/hooks → repo root
const REPO_ROOT = resolve(HERE, '../../..');
const CORE = resolve(REPO_ROOT, 'packages/core');

const run = (cmd: string, args: readonly string[] = []): CheckResult =>
  runCheck(cmd, args, { cwd: REPO_ROOT });

/** Re-emit a captured result's output to the operator. */
function emit(r: CheckResult): void {
  if (r.stdout) process.stdout.write(r.stdout);
  if (r.stderr) process.stderr.write(r.stderr);
}

/** Print message (+ optional captured output) and abort the push. */
function die(msg: string, r?: CheckResult): never {
  process.stderr.write(`${msg}\n`);
  if (r) emit(r);
  process.exit(1);
}

function workflowYmlFiles(): string[] {
  const dir = resolve(REPO_ROOT, '.github/workflows');
  if (!existsSync(dir)) return [];
  return readdirSync(dir)
    .filter((f) => f.endsWith('.yml'))
    .map((f) => `.github/workflows/${f}`);
}

/** A required external binary check: missing → install hint + fail. */
function requireTool(
  cmd: string,
  args: readonly string[],
  installHint: string,
): void {
  const r = run(cmd, args);
  if (r.notFound) die(`❌ ${cmd} not found in PATH.\n${installHint}`);
  if (r.exitCode !== 0) die(`❌ ${cmd} reported problems:`, r);
  emit(r);
}

/** A bash self-test script that must exist and exit 0. */
function requireSelfTest(scriptRelPath: string): void {
  if (!existsSync(resolve(REPO_ROOT, scriptRelPath))) {
    die(`❌ ${scriptRelPath} missing or not executable`);
  }
  const r = run('bash', [scriptRelPath]);
  if (r.exitCode !== 0) die(`❌ ${scriptRelPath} failed:`, r);
  emit(r);
}

function main(): void {
  // ── 1. actionlint ──────────────────────────────────────────────────────────
  const workflows = workflowYmlFiles();
  if (workflows.length > 0) {
    requireTool(
      'actionlint',
      workflows,
      '   Install: brew install actionlint   (macOS)\n' +
        '         or: go install github.com/rhysd/actionlint/cmd/actionlint@latest',
    );
  }

  // ── 2. zizmor ────────────────────────────────────────────────────────────────
  requireTool(
    'zizmor',
    ['--format', 'plain', '.github/workflows/'],
    '   Install: pip install zizmor',
  );

  // ── 3. Self-test pipeline ─────────────────────────────────────────────────────
  requireSelfTest('packages/core/audit-self/audit-ai-docs.test.sh');
  requireSelfTest('packages/core/audit-self/pre-push.test.sh');

  // ── 3a. Hook stub completeness ────────────────────────────────────────────────
  requireSelfTest('packages/core/audit-self/hook-stub-completeness.test.sh');

  // ── 3b. Skill drift check (D-AuditC-5 channel 2) ──────────────────────────────
  if (existsSync(resolve(REPO_ROOT, 'scripts/check-skill-drift.sh'))) {
    const r = run('bash', ['scripts/check-skill-drift.sh']);
    if (r.exitCode !== 0) die('❌ skill drift check failed', r);
    emit(r);
  }

  // ── 4. Manifest render drift ──────────────────────────────────────────────────
  {
    const r = run('npx', ['tsx', 'packages/core/render/render-rules.ts', '--check']);
    if (r.notFound) {
      die('❌ npx not found. Install Node.js to enable manifest render drift check.');
    }
    if (r.exitCode !== 0) die('❌ manifest render drift detected:', r);
    emit(r);
  }

  // ── 5. Principles meta-tests (Phase 2) ───────────────────────────────────────
  {
    const r = run('npm', ['--prefix', CORE, 'run', 'test:principles']);
    if (r.notFound) {
      die('❌ npm/npx not found. Install Node.js to enable principles meta-tests.');
    }
    if (r.exitCode !== 0) die('❌ principles meta-tests failed — fix before push', r);
    emit(r);
  }

  // ── 6. Spec discipline (Phase 1.C) — dormant defensive guard ─────────────────
  // .claude/orchestrator-prompts/ is gitignored; this fires only if such a file
  // is force-added past gitignore. Faithful port of the former bash guard.
  {
    const diff = run('git', [
      'diff',
      'origin/main...HEAD',
      '--name-only',
      '--diff-filter=ACM',
    ]);
    const specFiles = diff.stdout
      .split('\n')
      .filter((f) => /^\.claude\/orchestrator-prompts\/.*\.md$/.test(f));
    if (specFiles.length > 0) {
      process.stdout.write('Validating force-added orchestrator-prompts in this push...\n');
      const r = run('npx', [
        'tsx',
        'packages/core/spec-validation/validate-batch-spec.ts',
        ...specFiles,
      ]);
      if (r.exitCode !== 0) die('❌ spec-validate findings — fix before push', r);
      emit(r);
    }
  }

  // ── 7 + §1.7. Trailer checks (delegated to legacy bash until 10.2 / 10.3) ─────
  // Prior-art trailer (§7) + §1.7 discipline trailer. The bash handles its own
  // warn-only calibration and exits non-zero only on hard failures; we always
  // surface its output (warnings included) and propagate its exit code.
  {
    const r = runCheck('bash', [resolve(HERE, 'legacy-trailer-checks.sh')], {
      cwd: REPO_ROOT,
      env: process.env,
    });
    emit(r);
    if (r.exitCode !== 0) process.exit(r.exitCode);
  }

  // ── 8. lychee offline link check on changed *.md ─────────────────────────────
  {
    const diff = run('git', [
      'diff',
      '--name-only',
      'origin/main..HEAD',
      '--diff-filter=ACMR',
    ]);
    const changedMd = diff.stdout.split('\n').filter((f) => f.endsWith('.md'));
    if (changedMd.length > 0) {
      const r = run('lychee', ['--offline', '--no-progress', ...changedMd]);
      if (r.notFound) {
        process.stdout.write('⚠ lychee not found in PATH — offline link check skipped.\n');
        process.stdout.write('  Install: cargo install lychee   OR   brew install lychee\n');
      } else {
        emit(r);
        if (r.exitCode !== 0) {
          die('❌ lychee found broken links in changed Markdown files — fix before push', r);
        }
      }
    }
  }

  process.exit(0);
}

try {
  main();
} catch (err) {
  process.stderr.write(`❌ pre-push hook crashed: ${(err as Error).message}\n`);
  process.exit(1);
}

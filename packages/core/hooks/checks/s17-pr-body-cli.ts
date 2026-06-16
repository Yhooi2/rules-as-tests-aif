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

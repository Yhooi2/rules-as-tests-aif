# Contributing to rules-as-tests-aif

## Local setup

Clone the repo, then run once:

```bash
make install-hooks
```

This sets `core.hooksPath = .husky` via `git config` (no npm/husky package required)
and makes both hooks executable. After this, Git will automatically run the hooks
on `git commit` and `git push`.

## What hooks check

### pre-commit (target: <5 seconds)

Runs on every `git commit` against staged files only:

| Check | Files | Tool |
|---|---|---|
| Bash syntax | `*.sh` | `bash -n` |
| JSON validity | `*.json` | `python3 json.load` |
| YAML validity | `*.yml`, `*.yaml` | `python3 yaml.safe_load` |
| Markdown ≤500 lines | `*.md` | `awk` |

All checks are scoped to `git diff --cached --diff-filter=ACM` — only files staged
for the current commit are inspected.

### pre-push (target: ≤30 seconds)

Runs on every `git push`:

| Check | Scope | Tool |
|---|---|---|
| Workflow linting | `.github/workflows/*.yml` | `actionlint` |
| Security scan | `.github/workflows/` | `zizmor` |
| Self-test pipeline | `tests/audit/` | `bash tests/audit/audit-ai-docs.test.sh` |
| Manifest render drift | `factory/rules-manifest.json` ↔ `factory/RULES.md` | `npx tsx scripts/render-rules.ts --check` |

## What if you must bypass

```bash
git commit --no-verify   # skips pre-commit
git push --no-verify     # skips pre-push
```

**Warning:** the CI job `enforce-husky-presence` in `audit-self.yml` does NOT catch
`--no-verify` bypasses of the hook content, but it does verify that `.husky/pre-commit`
and `.husky/pre-push` exist, are executable, and contain the expected probes. If you
delete or stub out the hooks, the CI gate will fail on your next push.

See `docs/meta-factory/PROPOSAL.md` §13.9 for the rationale behind the CI gate as
a second line of defence against `--no-verify` normalisation.

## Tools required

Before your first push, ensure these are installed:

### macOS

```bash
brew install actionlint        # workflow linter
pip install zizmor             # security scanner
```

Python 3 is pre-installed on macOS 12+. Node.js (for `npx tsx`) is required for
`scripts/render-rules.ts`. Install via `brew install node` or `nvm`.

### Linux

```bash
go install github.com/rhysd/actionlint/cmd/actionlint@latest
pip install zizmor
```

If `actionlint` or `zizmor` are missing, the pre-push hook prints install instructions
and exits 1 — it will not silently skip the check.

## Run hooks manually

```bash
make pre-commit-check    # run pre-commit probe without committing
make pre-push-check      # run pre-push probe without pushing
make self-audit          # run both
```

## Reference

- `docs/meta-factory/self-application.md` — why author-side enforcement exists
  and the full Decision matrix (§3) behind each probe choice
- `docs/meta-factory/EXECUTION-PLAN.md` §6 Batch 1.A — Phase 1 scope and acceptance criteria
- `docs/meta-factory/PROPOSAL.md` §13.9 — rationale for `enforce-husky-presence` CI gate

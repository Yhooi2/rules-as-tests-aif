<!-- scope:final-quality-audit-s1-a -->
# FQA Stage-1 sub-wave A — shipped-surface audit (install payload)

> **Read-only R-phase.** Run inline by the orchestrator (S1-A aif task `b19b4bf2` auto-paused on runtime quota until 2026-06-14; completed here in-session to unblock Stage 1). Mode A.
> **Verdict in one line:** **BLOCKER cluster — shipped rules are inert in the consumer.** install.sh ships rule *files* + a complete CI *shell*, but NOT the wiring they need: it skips the `eslint-rules-local/index.ts` barrel its own config imports (→ eslint dies → R2/R7/R8 dead), defers `.dependency-cruiser.cjs` to legacy `setup.sh` (dead on the `./setup` path, same root as S1-B P1), never ships `audit-r4.ts`, and leaves `package.json` scripts as a manual step (→ every ci.yml `npm run X` + AGENTS.md command fails). The project thesis «every rule = executable artifact failing at the earliest channel» is violated in its own shipped form. **P2 (MAJOR, verify≠deliver, aif-orchestrator-discipline)** is a real but smaller instance of the same delivery-discipline gap. **Maintainer-surfaced (consumer-repo check), orchestrator-verified on fresh install + source.**
>
> **Honest correction to the maintainer's table:** «CI partial — no coverage/arch/mutation/ci-success/security» does NOT reproduce on a current fresh install — `ci.yml` contains all those jobs (ci.yml:48/63/95/142/183). The checked consumer is likely an older/divergent install. Net effect is still inert (the jobs call `npm run X`, scripts absent), but the CI *yaml* is not the defect — the script/config/barrel wiring is.

## §population (enumerated BEFORE sampling — T1/T9/T10)

- **Verify-list:** `SHIPPED_DOCS` array, `install.sh:89-108` → **17 entries** (enumerated verbatim, not sampled).
- **Copy-list:** every `copy_safe`/`cp -r` target in `install.sh` (skills 214-248, agents 304, templates 310-350, skill-context 320-323, audit 338-341, hooks 352-356, eslint 369-398).
- **Landed surface:** two FRESH e2e installs from this worktree tip (`install.sh` `PROJECT_ROOT=$(pwd)`), both `rc=0`:
  - `ts-server` → `/tmp/fqa-s1a-ts.2kUpXX` — `.claude/skills` 51 files · `.claude/agents` 5 · `.ai-factory` 6 · `.ai-factory/skill-context` 2 · `scripts` 1.
  - `react-next` → `/tmp/fqa-s1a-rn.Voa8pH` — same skill-context (2) + react-next-specific `RULES.react-next.md` + `ARCHITECTURE.react-next.md` landed · `eslint-rules-local` 6 files · `.claude/settings.json` (2 hook entries).

## §method

Three-way diff: `SHIPPED_DOCS` (verify) ↔ copy-step targets ↔ `ls`/`cat` in a LANDED consumer (T-FQA-A: delivery evidenced in the consumer, never by the package-side list). Plus: content-currency greps on landed skills/agents; cross-ref-rewrite sanity on a landed skill; install-log anomaly scan.

## §findings (severity-tagged, evidence each — T3, no prose-only)

| # | Sev | Evidence | Finding |
|---|---|---|---|
| **P2** | **MAJOR** | `install.sh:100` (SHIPPED_DOCS lists `…/skill-context/aif-orchestrator-discipline/SKILL.md`) vs `install.sh:320-323` (copy step `mkdir_safe`+`copy_safe` ONLY `aif-review` + `aif-rules-check`). Landed (ts-server): `ls .ai-factory/skill-context/` → `aif-review`, `aif-rules-check` only — **`aif-orchestrator-discipline` MISSING**. Same on react-next. Install printed `✓ all 17 shipped artefacts carry valid headers` then shipped 16. | **verify≠deliver.** The header-verify gate iterates all 17 SHIPPED_DOCS; the copy step is a separate hand-maintained block that lists only 2 of the 3 skill-context overrides. Consumer's aif-orchestrator sidecar has no override to read. |
| F-A | INFO (mechanism) | grep: `aif-orchestrator-discipline` count in install.sh = 1 (the SHIPPED_DOCS line) only; **zero** in the copy region 315-335. | Root cause = two independent lists (verify array vs copy statements) with no shared source. P2 is the live drift instance; any future skill-context addition repeats it. |
| F-B | PASS (T13/T16 instrument audit) | The install-time header check (`install.sh:79-128`) is the instrument that "passed" while delivery broke — it pattern-matches **header presence in the package**, never **landed in the consumer**. Named per T-FQA-A: this is the exact instrument that missed P2 and why. | Not a new bug — explains why P2 survived. The CI `Self-install on tmp consumer` jobs install but don't assert per-file skill-context landing. |
| F-C | PASS | `grep 'github.com/Yhooi2/.../blob' landed pipeline/SKILL.md` → 9; unrewritten `](../../../{docs,packages,README}` → **0**. | Cross-ref rewrite (`transform_internal_refs`) healthy: repo-internal refs → GitHub blob URLs, none leaked. |
| F-D | PASS (T7 false-positive withdrawn) | First grep flagged 4 landed files with `/meta-orchestrator`; precise re-grep (`/meta-orchestrator($\| \|\`)` minus `meta-orchestrator-`) → **0**. All matches were the dir-name `meta-orchestrator-prior-art` (a gitignored binding-spec path), NOT a stale `/meta-orchestrator` slash-command. | No stale post-rename slash-command refs in landed skills. (The `meta-orchestrator` *skill-dir* duplication is S1-D F2's scope, not a shipped-surface defect.) |
| F-E | PASS | `install2.log` scan: no `skip`/`warn`/`missing`/`already exists`; both stacks `rc=0`. No `≤500`/`500-line` stale gate refs in landed skills/`.ai-factory`. | No delivery anomalies; no removed-flag currency drift on the landed surface. |

## §findings-2 — execution-wiring (maintainer-led, orchestrator-verified — the headline cluster)

> This is the dimension the first S1-A pass under-covered (file-delivery checked; does-it-execute not). Maintainer checked a real consumer repo; each line re-verified below against a fresh `install.sh ts-server` + the source repo. **Severity is BLOCKER-class** because it breaks the project's central invariant on the shipped product.

| # | Sev | Evidence (file:line) | Finding |
|---|---|---|---|
| **W1** | **BLOCKER** | `templates/ts-server/eslint.config.mjs:12` `import customRules from './eslint-rules-local/index.ts'` vs `install.sh:363-368` loop `*/index.ts) continue` (skips the barrel) → landed `eslint-rules-local/` = 3 rule files, **no `index.ts`**. Source barrel exists: `packages/core/eslint-rules/index.ts`. | Shipped eslint config imports a barrel the installer deliberately refuses to copy → **eslint fails to load → ALL custom rules (R2/R7/R8 + react rules) are dead paper** in every consumer. The exact «rule = paper» the project exists to prevent. |
| **W2** | **MAJOR** | `install.sh:387` comment `# .dependency-cruiser.cjs is generated by setup.sh via 'depcruise --init'`; `templates/ts-server/dependency-cruiser.cjs` EXISTS in source but is never `copy_safe`'d; landed consumer has no `.dependency-cruiser.cjs`. | R3 `arch:check` cannot run — config not shipped, deferred to legacy `setup.sh` which the `./setup` path never invokes (**same root cause as S1-B P1**). A copyable template exists; the deferral is the bug. |
| **W3** | **MAJOR** | `packages/core/probes/audit-r4.ts` exists in source; no `copy_safe` line ships it; landed consumer has no `audit-r4.ts`. | R4 probe never reaches the consumer — ship-gap. |
| **W4** | **MAJOR** | landed `package.json` `scripts = {}`; install prints «5. Add scripts to package.json (see INSTALL.md §3)» (manual); `AGENTS.md:78-90` advertises `npm run test`/`test:coverage`/`test:mutation`/`validate`/`arch:check`. | AGENTS.md promises commands that don't exist post-install. Every `ci.yml` job (`npm run lint`/`typecheck`/`arch:check`/`test:coverage`) + `test:mutation` fails `Missing script` until extensive manual wiring. AGENTS.md-vs-package.json drift. |
| **W5** | **MAJOR** | landed `stryker.config.json` present; no `test:mutation` script (W4); `ci.yml:95-130` mutation job calls it. | L4 mutation: config + CI job ship, but nothing runs (no script). Config-without-runner. |
| W6 | INFO (correction) | `ci.yml:48 (Architecture rules), :63 (Tests→test:coverage), :95 (Mutation), :142 (Security: npm audit+gitleaks), :183 (CI passed)` all PRESENT on fresh install. | The maintainer's «CI partial» line does NOT reproduce on the current template. Flagged to reconcile which consumer was checked (older/divergent install suspected). |

**Unifying root cause (W1–W5):** install.sh ships the *artefacts* (rule files, CI yaml, stryker/eslint configs) but not the *wiring* (the `index.ts` barrel it skips, the dep-cruiser config it defers, the `package.json` scripts left manual, the `audit-r4.ts` it omits). The CI shell and AGENTS.md are written as if the wiring exists; it doesn't. **Recursive-self-application note (T15):** my first S1-A instrument (SHIPPED_DOCS↔landed file diff) missed W1–W5 for the same reason the install header-check missed P2 — it tests *presence*, not *execution*. The audit needs a «does a fresh consumer's `npm run validate` actually pass» probe, not just `ls`.

## §fix-list (for a later S3 I-phase — NOT applied here; S1 is read-only / T-FQA-C)

| Ref | Sev | Target | Fix shape |
|---|---|---|---|
| P2 | MAJOR | `install.sh:89-108` + `:320-323` | **Single-source the skill-context set** so one array drives BOTH the header-verify and the copy step (e.g. a `SKILL_CONTEXT=(aif-review aif-rules-check aif-orchestrator-discipline)` loop that both verifies and copies). Eliminates the drift class, not just the instance. Per umbrella §5 S3: P2 fix MUST make verify-list and copy-list structurally single-sourced OR add a landed-side check to the CI self-install jobs. |
| F-B | MAJOR (CI gap) | `.github/workflows` self-install jobs | Add a landed-side assertion: after `install.sh` into the tmp consumer, assert each `SHIPPED_DOCS` skill-context entry exists under `.ai-factory/skill-context/`. Turns verify≠deliver into a gate (the channel where P2 should have failed). |

| W1 | BLOCKER | `install.sh:363-368` + `templates/ts-server/eslint.config.mjs:12` | Ship the barrel: drop the `*/index.ts) continue` skip for the consumer (or generate an `eslint-rules-local/index.ts` re-exporting the copied rule files) so the config's import resolves. Falsifier: fresh install → `npx eslint --print-config` loads without `Cannot find module './eslint-rules-local/index.ts'`. |
| W2 | MAJOR | `install.sh:387` | Copy `templates/<stack>/dependency-cruiser.cjs` → consumer `.dependency-cruiser.cjs` directly (stop deferring to legacy `setup.sh`). Same fix-family as S1-B P1 (de-legacy the install path). |
| W3 | MAJOR | `install.sh` (no copy line) | Add `copy_safe packages/core/probes/audit-r4.ts → scripts/` (or wherever `arch:check`/`validate` expects it). |
| W4 | MAJOR | `install.sh` post-install + `AGENTS.md.template` | Either inject the canonical `scripts` block into the consumer `package.json` at install time (merge, not clobber), or make AGENTS.md's command list conditional/accurate. Single-source the script names against what ci.yml calls. |
| W5 | MAJOR | `package.json` (script) | Folds into W4 — add `test:mutation` so the shipped stryker config + ci.yml mutation job have a runner. |

> **W1–W5 are a cluster, not isolated:** the S2 plan should treat them as one «de-inert the shipped quality gates» fix-wave (likely the highest-priority S3 cluster), with a single acceptance test: *fresh `install.sh <stack>` into a clean dir, add the documented manual steps, then `npm run validate` exits 0* — the executable proof the rules actually run.

**Falsifier for the P2 fix:** *wrong if,* after the single-source change, a fresh `install.sh ts-server` into a clean dir does NOT land `.ai-factory/skill-context/aif-orchestrator-discipline/SKILL.md`, OR the install-time count and the landed count diverge. Re-run the three-way diff to verify.

## §adversarial-counter-prompt (run + quoted — T7)

«What surface did I NOT enumerate?»
1. **Both stacks?** — yes, ts-server AND react-next installed; skill-context copy is stack-independent (runs for both) → P2 holds on both. react-next-specific files (RULES/ARCHITECTURE.react-next) landed.
2. **Non-skill-context SHIPPED_DOCS?** — all 16 others (4 agents, 2 tool-bootstrapping, templates, RULES, ARCHITECTURE) confirmed LANDED. P2 is the sole miss.
3. **Adjacent payload not in SHIPPED_DOCS?** — settings.json hook block (2 hooks) + eslint-rules-local (6) landed; checked, no drift.
4. **Did I confuse package-presence with delivery (the P2 trap itself)?** — no: every "landed" claim is `ls` in the consumer dir, not the SHIPPED_DOCS list (T-FQA-A honoured).

No missed surface changes the verdict.

## §coverage (T14 — mandatory; coverage stated, not "clean")

- **Three-way delivery diff:** 17/17 SHIPPED_DOCS + skill-context + agents + eslint + settings hooks, BOTH stacks → **high coverage** on the delivery dimension. P2 = sole verify≠deliver; high confidence (mechanical, both stacks).
- **Cross-ref rewrite:** sampled on landed `pipeline/SKILL.md` (9 rewritten, 0 leaked) — **partial**: one file, not the ≥10-file sweep the kickoff floor suggests. Other landed skills NOT cross-ref-sampled → **INSUFFICIENT-COVERAGE on cross-refs beyond pipeline**, not "clean".
- **Execution-wiring (W1–W5):** NOW COVERED (second pass, maintainer-led). Each verified mechanically against a fresh install + source file:line. **High confidence** — W1/W2/W3 are deterministic (file present in source, absent in landed); W4/W5 follow from `scripts={}`. This is the dimension the first pass missed (presence ≠ execution, T15).
- **AI-doc best-practices (Authoritative-for / hot-cold / progressive-disclosure / AI-agnostic wording):** only the install-time header-presence check (17/17) leveraged; independent per-doc `/ai-doc`-standard review NOT run → still **INSUFFICIENT-COVERAGE on prose best-practice substance** (distinct from execution-wiring). Fold into S2.
- **CI-yaml reconciliation (W6):** the maintainer's «CI partial» does not reproduce on a fresh install; which consumer repo was checked is **the one open uncertainty** — it determines whether W6 is install-drift (old consumer) or a divergent template. Flagged for maintainer.
- **Calibration:** P2 + W1–W5 confidence very-high (mechanical, fresh install + source, ts-server confirmed, react-next shares the install code path); W6 needs the maintainer's repo identity to close.

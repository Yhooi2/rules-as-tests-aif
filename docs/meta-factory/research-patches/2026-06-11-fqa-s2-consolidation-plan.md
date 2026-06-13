<!-- scope:final-quality-audit-s2-consolidation -->
# FQA Stage 2 — consolidation plan (merged fix-list → S3 clusters + DECISION-NEEDED)

> **Mode A inline** (orchestrator, 2026-06-11). Input = the 4 Stage-1 research-patches (`2026-06-11-fqa-{a,b,c,d}-*.md`), all committed locally + Phase -1 GO (verdict in `final-quality-audit-meta-launch/state.md §3`). Output = this plan. **Read-only synthesis — no source fixes here; S3 applies them after maintainer GO on the DECISION-NEEDED list.**

## §1 Unifying root cause (the headline)

**The shipped product installs its rules as inert files.** `install.sh` copies rule *artefacts* (eslint rules, configs, CI yaml, stryker, skill-context) + a complete CI *shell*, but NOT the *wiring* that makes them execute — and defers critical wiring to legacy `setup.sh`, which the current `./setup` entry never invokes. The project's own thesis — «every rule = executable artifact failing at the earliest channel» (README#why-this-exists) — is violated in its own consumer install. This is one coherent BLOCKER theme spanning S1-A (W1–W5, P2) + S1-B (P1).

## §2 Deduped fix-list (severity-ordered, cross-referenced to source patch)

| ID | Sev | Source | One-line | Root |
|---|---|---|---|---|
| W1 | **BLOCKER** | A | eslint.config imports `eslint-rules-local/index.ts`; install skips the barrel → eslint dead | ship-gap (loop skip) |
| P1 | **BLOCKER** | B | deps-change re-eval automation dead on `./setup` (tool-decisions.md never seeded) | legacy-setup.sh deferral |
| W2 | MAJOR | A | `.dependency-cruiser.cjs` not copied (deferred to setup.sh) → `arch:check` can't run | legacy-setup.sh deferral |
| W3 | MAJOR | A | `audit-r4.ts` exists in source, never shipped | ship-gap |
| W4 | MAJOR | A | consumer `package.json` scripts `{}`; AGENTS.md advertises validate/arch:check/test:mutation | manual-step + drift |
| W5 | MAJOR | A | stryker config + CI job ship, no `test:mutation` runner | folds into W4 |
| P2 | MAJOR | A | `aif-orchestrator-discipline` in SHIPPED_DOCS verify-list but not copy-list → 2/3 land | verify≠deliver |
| P3 | MAJOR | B | tool-bootstrapping SKILL.md (2026-05-11) stale: context7-via-setup.sh contract + companion refs | doc currency |
| F1(D) | MAJOR | D | principle-15 `enumerateSkills()` not git-aware → 25 false RED on installer-populated clones | test-scope bug |
| F2-FIX | MAJOR | D | delete untracked `meta-orchestrator/` stale orphan (pre-#397 rename; pipeline is successor) | hygiene |
| F-A/F-B | MAJOR | B | self-audit detects P1 symptom but points at dead setup.sh; no install→seed→detect integration test | instrument gap |
| F3(D) | INFO→act | D | delete `probe-cc-perm/` (purpose completed at #277 closure) | hygiene |
| F1–F6(C) | MINOR | C | dangling skill ref, stale self-name, ./setup not in CLAUDE.md, count drift | doc currency |
| F4(D) | MINOR | D | tool-bootstrapping dual-pair `@dual-pair`/`spec:` markers missing (forward-going) | marker drift |

## §3 S3 fix-waves (file-disjoint clustering)

> Clustering rule: waves that touch the SAME file cannot run in parallel (parallel-subwave-isolation). `install.sh` is the contention point — W1/W2/W3/W4/W5/P2/P1 all touch it → they are **one sequential cluster**, not parallel waves.

- **S3-C1 — «de-inert the shipped quality gates» (BLOCKER, top priority, SEQUENTIAL within).** Files: `install.sh` (+ `setup.d/*`, `AGENTS.md.template`, `packages/core/eslint-rules/` barrel handling). Fixes: W1, P1, W2, W3, W4, W5, P2. **Acceptance (executable):** fresh `install.sh <stack>` into a clean dir + documented manual steps → `npm run validate` exits 0 AND `npx eslint --print-config` loads AND the deps-change hook emits its WARN after a dependency is added (P1 paired-negative: install without seed → probe fails; with → passes). Per umbrella §5: P1 fix MUST include a paired-negative test; P2 fix MUST single-source verify↔copy.
- **S3-C2 — principle-15 git-aware (MAJOR, parallel-safe).** File: `packages/core/principles/15-skill-paired-negative.test.ts`. Fix: F1(D) — filter `enumerateSkills()` via `git ls-files` / `git check-ignore`. Disjoint from install.sh → parallel with C1. §1.7 mandate applies (principle file). EXEMPT-allowlist probe in Phase -1.
- **S3-C3 — hygiene deletions (MAJOR/INFO, parallel-safe).** Delete `.claude/skills/meta-orchestrator/` orphan (F2-FIX, preserve unique residue into pipeline/ first per T18) + `.claude/skills/probe-cc-perm/` (F3). Disjoint.
- **S3-C4 — doc currency (MINOR, parallel-safe).** Files: tool-bootstrapping SKILL.md (P3), CLAUDE.md (S1-C F5), dual-implementation-discipline.md:65 (S1-C F1), living-docs-auditor.md:159 (S1-C F2), dual-pair markers (F4). §1.7 mandate applies (CLAUDE.md, .claude/rules/**, agents/**).

## §4 DECISION-NEEDED (maintainer GO required before S3; auditors surfaced, did not pick)

- **DN-1 (S1-B) — P1 seed HASH-STAMPING policy** (seed *location* is NOT a fork — S1-B decided it on merits: inside `install.sh`, co-located with the `.ai-factory/` deploy block, with a falsifier). The genuine fork is what hash to write at seed time: Option A → stamp the real deps-hash (quiet-by-default, but `install.sh` runs *before* `npm install` so the hash is often stale-from-birth → WARNs on first real dep-add anyway). Option B → copy verbatim with `deps-hash: <pending>` sentinel (WARNs every session until `/tool-bootstrapping` stamps it — louder, self-correcting onboarding nudge, no package.json dependency at install). **Orchestrator lead: Option B** (A's quiet-by-default premise is false on the deploy-before-deps flow; B is self-correcting). Maintainer confirms — taste/strategy call.
- **DN-2 (S1-B) — context7 «recursive bootstrap stage 1» guarantee:** Option A → restore (installer guarantees context7 present). Option B → drop the guarantee + rewrite SKILL.md §3. Touches manifest schema + skill design contract.
- **DN-3 (S1-C Q1) — EXECUTION-PLAN.md ≤500 references — orchestrator DECIDES (not a maintainer fork):** the markdown gate moved to 600 (#448/#454/#456), so ≤500 references are stale. C4 will bump them to ≤600. *Escape hatch:* if ≤500 was a deliberate stricter budget for EXECUTION-PLAN specifically, say so and C4 leaves them.
- **DN-4 (S1-A W6, orchestrator-added) — which consumer repo did the maintainer check?** The «CI partial / no arch/mutation/ci-success/security» finding does NOT reproduce on a fresh install (ci.yml has all jobs). Need the repo identity to classify W6 as install-drift (old consumer) vs a divergent template (real bug I can't see from here).

## §5 NOT fixing (explicit, with reason)

- **W6 ci.yml «partial»** — does not reproduce on current-template fresh install; pending DN-4. Not a current-template defect.
- **S1-C F3 count-drift / historical snapshots** — explicitly timestamped historical claims (defensible, not bugs).
- **S1-C INCONCLUSIVE-needs-CI runtime-pass** — Phase -1 noted a reviewer reached vitest via global `npx` and ran principle 15 GREEN; the gap is narrower than S1-C stated but not a fix target.
- **F4(D) dual-pair markers** — forward-going per dual-implementation-discipline §9 (add at next touch), not a retroactive sweep.

## §6 AI-traps (per ai-laziness-traps.md §2 — S2-active)

T3 (every fix-list row traces to a source patch finding with its ID), T14 (severity carried from source, not re-guessed), T15 (this plan's own clustering re-checked against parallel-subwave-isolation file-contention — install.sh contention forced C1 sequential). **T-FQA-A/B carried forward:** S3-C1 acceptance is execution-based (`npm run validate` exits 0), not presence-based — the exact lesson from W1–W5.

## §7 Stage-gate status (local mode)

Push deferred (Clash TUN down). Stage-1 «merged» gate substituted by: 4 patches committed locally (`84c2b44`) + S1-D REVISE (`b239711`) + Phase -1 GO (state §3). S3 dispatch still gated on **maintainer GO on §4 DN-1..DN-4** — that gate is NOT substitutable; it is the genuine human fork-set.

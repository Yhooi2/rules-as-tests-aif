# §1.7 PR-body citation-existence gate — design (combo L2-block + L3-warn)

> **Authoritative for:** design of the anti-fabrication arm added to the §1.7 CI PR-body gate ([`.github/workflows/discipline-self-check.yml`](../../../.github/workflows/discipline-self-check.yml)) — the L2 (block) + L3 (warn) citation-existence checks, their home module, testability contract, and blast-radius decisions.
> **NOT authoritative for:** project goal — see [README.md#why-this-exists](../../../README.md#why-this-exists). The §1.7 rule itself — see [`.claude/rules/phase-research-coverage.md §1.7`](../../../.claude/rules/phase-research-coverage.md). The pre-push commit-trailer surface — that is [`packages/core/hooks/checks/s17.ts`](../../../packages/core/hooks/checks/s17.ts) (a different surface; see §6 scope-out).

> **Date:** 2026-06-16. **Status:** approved design, pre-implementation.

## §1 Problem

The §1.7 CI gate ([`discipline-self-check.yml`](../../../.github/workflows/discipline-self-check.yml)) requires each of the `### §1.7 Forward-check applied` / `### §1.7 Backward-check applied` PR-body sections to contain ≥1 `file.ext:line` citation (regex `[^[:space:]]+\.[a-z]+:[0-9]+`, lines 100-132). The regex only checks that a citation is **shaped** like `path:line` — it never confirms the path exists or the line is in range. A lazy agent can fabricate a plausible `foo.ts:42` and pass.

This is the `#discipline-theatre` failure ([phase-research-coverage.md §4](../../../.claude/rules/phase-research-coverage.md)) and trap **T3** — whose documented counter is already "file:line citation **+ the line's actual content**" ([ai-laziness-traps.md:47](../../../.claude/rules/ai-laziness-traps.md)). The gate under-enforces its own declared counter.

**Goal (maintainer framing, 2026-06-16):** make fabricating a plausible citation cost *more* than actually opening the file and citing a real line — so the cheapest path to a green gate is doing the real verification.

## §2 Constraints

- **No paid LLM in CI** ([no-paid-llm-in-ci.md](../../../.claude/rules/no-paid-llm-in-ci.md)) — all checks deterministic (file read / line count / substring). Relevance ("does the line support the claim?") is semantic → stays at review (AI-agnostic sub-agent / human), never CI.
- **Never ship a blocking check at unmeasured false-positive rate** — established precedent: narrow-B verdict-scan dropped at FP 84% ([recommendation-laziness-discipline.md:44](../../../.claude/rules/recommendation-laziness-discipline.md)); §1.7 pre-push trailer shipped warn-only on a D1 calibration window ([self-reflection/SKILL.md:104](../../../.claude/skills/self-reflection/SKILL.md)); `#gate-where-judgment-needed` ([rule-enforcement-channel-selection.md:79](../../../.claude/rules/rule-enforcement-channel-selection.md)).
- **Testable-check pattern:** pure logic + injected provider + side-by-side vitest, paired-negative mandatory — mirror [`s17.ts`](../../../packages/core/hooks/checks/s17.ts) (`packages/core/hooks/checks/<name>.ts` + `<name>.test.ts`).
- **CI already runs TS** via `actions/checkout` + `setup-node` + `npx tsx` (e.g. [audit-self.yml:373](../../../.github/workflows/audit-self.yml)). No new infra. No bats in repo.

## §3 The combo (escalation ladder by fabrication cost)

| Arm | Check | Mode |
|---|---|---|
| L1 (exists today) | section contains ≥1 `path:line` match | block (unchanged) |
| **L2** (new) | **≥1** of the section's citations **resolves**: file exists at PR head AND line ≤ file length | **block** |
| **L3** (new) | citations that *look* like real repo paths (contain a `/`) but do **not** resolve, OR resolve to a non-substantive line (blank / punctuation-or-brace-only) | **warn** (`::warning::`, never fails the job) |

**Why "≥1 resolves" for the block arm, not "all resolve":** the citation regex is loose — it also matches prose like `Node.js:18` or `config.yml:5`. Requiring *all* matches to resolve would false-block on such prose. "≥1 must resolve" mirrors the existing "≥1 must be present" semantics and still has teeth: an all-fabricated section has zero resolving citations → block; passing requires ≥1 real, in-range citation → the author opened ≥1 real file. The stricter "every genuine-looking citation resolves" lives in the **L3 warn** arm — calibrate, then promote to block on measured low FP (§5).

**Honest ceiling:** L2 does not prove relevance. A lazy author can cite one trivially-real file (e.g. the rule file being edited) and fabricate the rest; the block passes, and L3 surfaces the non-resolving others as warnings for the reviewer. Mechanical floor = "≥1 real line"; relevance ceiling stays at review.

## §4 Architecture

**New module — `packages/core/hooks/checks/s17-pr-body.ts`** (pure, mirrors `s17.ts`):

- `RepoFileReader` interface — injected fs provider: `readLines(path: string): string[] | null` (null = file absent). Keeps logic pure / unit-testable / Stryker-mutatable without shelling out.
- `extractSection(prBody, headingRe): string` — port of the gate's awk: capture from `^### §1\.7 <Section>` to next `^###`.
- `findCitations(sectionText): Citation[]` — `Citation = { raw, path, line }`, using the gate regex `[^\s]+\.[a-z]+:[0-9]+`.
- `looksLikeRepoPath(path): boolean` — contains a `/`; gates the L3 warn set so prose like `Node.js:18` (bare, no slash) is ignored. Bare filenames are ambiguous → not warned by L3, but still count toward L2's "≥1 resolves". (Refined from an earlier "slash OR known extension" during TDD: `Node.js` ends in `.js` and would have false-warned.)
- `isSubstantiveLine(text): boolean` — non-blank, not punctuation/brace-only (has ≥1 alphanumeric/identifier char).
- `checkPrBodyCitations(prBody, reader): { blockers: string[], warnings: string[] }` — runs L2 (block) + L3 (warn) over both Forward and Backward sections.

**New CLI entry** — thin `npx tsx` wrapper: reads `PR_BODY` from env, `reader` reads from `process.cwd()` (the checked-out head), prints `::error::`/`::warning::`, exits 1 iff `blockers.length > 0`. Warnings never set a non-zero code.

**Workflow change — `discipline-self-check.yml`, `verify-pr-body-sections` job (additive):**
- Keep the existing inline bash (presence / ≥40-char / L1) untouched — it is green; do not churn it.
- Add `actions/checkout` (`ref: github.event.pull_request.head.sha`) + `setup-node` + an install + a step running the new CLI for L2/L3.

Mild duplication (bash parses citations for L1; TS re-parses for L2/L3) is an accepted trade for zero blast radius on the working gate.

## §5 Testing & calibration

- **Paired-negative (mandatory)** in `s17-pr-body.test.ts` using an in-memory `RepoFileReader`:
  - fabricated citation (`nonexistent/foo.ts:999`, reader returns null) → L2 blocker. **Mutation arm:** removing the existence check makes this case pass → test fails.
  - real file, line out of range (`real.ts:9999`, file has 10 lines) → L2 blocker.
  - real file + in-range + substantive line → clean (no blocker, no warning).
  - real file + in-range but blank/brace-only line → L3 warning, **no** blocker.
  - prose `Node.js:18` (not a repo path) → ignored by L3, does not warn.
  - section with one resolving citation + one fabricated → **no** L2 blocker (≥1 resolves), fabricated one → L3 warning.
- **Live-sample check (during test authoring):** sample real merged §1.7 sections to measure how often citations reference non-repo paths or use `:digit` in prose — confirms L2 "≥1-resolves" FP stays ~0 before shipping it as a blocker. If a real §1.7 corpus shows L2 false-blocks, fall back to L2-warn too.
- **Calibration window:** L3 ships warn-only. Promotion of "every genuine-looking citation resolves" from L3-warn to block is a follow-up gated on measured FP < 20% (narrow-B threshold) over the window — mirrors the D1 precedent.

## §6 Scope-out (observations, NOT this PR — atomic-PR discipline)

1. The pre-push `s17.ts` trailer ([packages/core/hooks/checks/s17.ts:37](../../../packages/core/hooks/checks/s17.ts)) has the same presence-only `FILE_LINE_RE` and could gain the same existence check — separate surface, separate PR.
2. Porting the existing untested inline-bash L1 into the new TS module (de-dup) — deferred to keep blast radius zero.
3. Promoting L3 warn → block after calibration.

## §7 §1.7 self-application

This change is itself discipline-bearing, so its own PR body must carry compliant `### §1.7 Forward-check applied` / `### §1.7 Backward-check applied` sections with ≥1 resolving citation each — i.e. it must pass the very gate it strengthens (recursive self-application, invariant #2). The SKILL.md Output contract gains a one-line note that citations are now existence-checked.

## See also

- [`.claude/rules/phase-research-coverage.md §1.7`](../../../.claude/rules/phase-research-coverage.md) — the rule.
- [`.claude/skills/self-reflection/SKILL.md`](../../../.claude/skills/self-reflection/SKILL.md) — the Output contract authors follow.
- [`packages/core/hooks/checks/s17.ts`](../../../packages/core/hooks/checks/s17.ts) — testable-check pattern + the sibling pre-push surface.
- [`.claude/rules/ai-laziness-traps.md`](../../../.claude/rules/ai-laziness-traps.md) T3 — the counter this implements.
- [`.claude/rules/no-paid-llm-in-ci.md`](../../../.claude/rules/no-paid-llm-in-ci.md) — why deterministic-only.

# Multi-stack monorepo (§13.5) — I-phase kickoff

> Scope: I-phase implementation kickoff for the `multi-stack-monorepo` umbrella (opens open-question §13.5). NOT authoritative for project goal — see [README.md#why-this-exists](../../../README.md#why-this-exists). Research basis: [docs/meta-factory/multi-stack-monorepo-research.md](../../../docs/meta-factory/multi-stack-monorepo-research.md).

> **Staging-placement reminder ([kickoff-staging-placement.md §1](../../rules/kickoff-staging-placement.md)):** this kickoff is a tracked dispatch-input. Merge it to `staging` **before** handing out `/pipeline multi-stack-monorepo` or initiating any aif dispatch — a kickoff that lives only on a feature branch is invisible to the dispatch consumer (which runs on `staging`).

## §0 Why

Issue **#780** (fresh `./setup -y` fails loud instead of auto-detecting the stack) + its secondary multi-stack-monorepo nuance (timeliner: Hono `apps/api` + Expo `apps/mobile` + Drizzle in one pnpm monorepo). The maintainer's **A-decision (2026-06-27)** opens **§13.5** now (overriding the Phase-9+ deferral — deliberate, not a regression; see research §0). Full origin + the #646-vs-§13.5 distinction + the sequencing pointers are in the research doc §0.

**Two layers in scope (BOTH):** Layer 1 = install/CLI surface (express + detect multiple stacks); Layer 2 = enforcement (per-workspace rule scoping via `applies-to`/native ESLint `files:`).

## §1 Build-vs-reuse headline (from research §1 — verdicts already established)

- **Layer 2 enforcement scoping = REUSE** the existing `applies-to: string[]` primitive (`packages/core/synthesizer/types.ts:58`, read by `packages/core/diff/preset-similarity.ts:77-82`) **+ REFERENCE** native ESLint flat-config `files:` (it *is* the §13.5 hypothesis). **BUILD only** the per-workspace *emission* — the live wirer emits a **global** element today (`packages/core/install/wire-eslint-r2.ts:421-423`, T-MS-A gap).
- **Layer 1 detection = REUSE** `_detect_stack_from_pkg` (`setup.d/15-companions-stack.sh:24-59`); **BUILD (thin)** the per-workspace walk; **REFERENCE** Nx/pnpm/Turborepo (per-project inference + workspace discovery — they stop short of stack classification).
- **REJECT** Nx/Turborepo/Rush/Lerna as runtime dependencies (monorepo-orchestration class, not our enforcement-generator class).

Draft SSOT entries #111–#113 are in research §1 — the capability-commit author appends them to `prior-art-evaluations.md` **with** the commit (never out-of-band; the SSOT is append-only).

## §2 Phased task list

> **Per-commit discipline (all tasks):** every capability commit carries a `Prior-art:` trailer ([CLAUDE.md](../../../CLAUDE.md) — `Prior-art:` references `prior-art-evaluations.md#<ID>`, or the escape hatch with a ≥20-char rationale for non-capability commits). Before any "build X", confirm against the [CLAUDE.md capability-commit definition](../../../CLAUDE.md) + consult the SSOT (research §1 did the consult; cite #111–#113 / #11 / #17).

> **Pre-dispatch in-flight probe ([CLAUDE.md](../../../CLAUDE.md)):** before dispatching any task below, re-probe `feat/547-install-auto-wire-r2`, `chore/install-ast-wiring-kickoff`, `feat/generator-install-wiring`, `claude/react-native-install-wiring` (PR + ahead-commits) — they edit overlapping `install.sh` regions. Resolve the §4 coordination fork (below) **before** I-2 Layer-2 work, or you risk `#parallel-evolution-creep`.

### Phase I-1 — install-surface single-stack auto-detect (the direct #780 fix)

**Goal.** A fresh `./setup -y` (and `install.sh` with no positional `STACK`) **auto-detects** the single-root stack instead of `exit 1`.

**Tasks.**
1. Wire `_detect_stack_from_pkg` (`setup.d/15-companions-stack.sh:24-59`) into the install stack pick: when no positional `STACK` is supplied, run single-root detection; `exit 1` **only** when it returns `unknown` (replacing the unconditional fail at `install.sh:197-198`). REUSE the detector; do not reimplement signal logic.
2. Mirror the same default into `setup` (`setup:13` yes-path requirement, `setup:25/35`).
3. Align the repo-read with `feat/547-install-auto-wire-r2`'s "thin bash probe → repo-read at install" pattern + shared install-time runtime model (install runs **before** consumer deps, node-optional). Do **not** add a second repo-reading harness.

**Acceptance.**
- Fresh `./setup -y` in a single-stack repo (e.g. only `next` in `package.json`) installs the correct preset **without** an explicit stack arg; the old `exit 1` path fires **only** for a genuinely-`unknown` repo.
- A test under `tests/install-sh/` proves: (a) no-arg + detectable repo → correct stack; (b) no-arg + `unknown` repo → precise error (not a silent wrong install).
- Explicit positional `STACK` still wins (back-compat: `install.sh:67` last-positional behaviour preserved).
- **State in the PR whether I-1 closes #780** (research §4: closes the titled core; the multi-stack nuance tracks under I-2 — recommend closing #780 on I-1 with that note).

**Likely a non-capability commit** (wiring an existing function + a small bash branch). Confirm against the capability-commit definition; if it stays non-capability, use the `Prior-art: skipped — …` escape hatch with a ≥20-char rationale.

### Phase I-2 — multi-stack monorepo (per-workspace detection + enforcement scoping)

**Goal.** One meta-factory invocation on a multi-stack monorepo (timeliner shape) detects each workspace's stack and scopes enforcement per workspace dir.

**Tasks.**
1. **Layer-1 monorepo detection.** Enumerate workspace dirs (read `pnpm-workspace.yaml packages:` globs / root `package.json workspaces` — thin reader, no install-time dependency on pnpm/turbo) × per-dir `_detect_stack_from_pkg` → `{dir → stack}` map. Extend `architecture.md` Layer-1 `structure` field (currently v2-backlog, `docs/meta-factory/architecture.md:67`) toward a workspace-aware kind; the authoritative contract is `packages/core/detector/types.ts`.
2. **Layer-2 enforcement scoping.** Make synth/render/lock **emit per-workspace `applies-to`/`files:`** (close the T-MS-A gap: `applies-to` exists in the type + scoring, but `wire-eslint-r2.ts:421-423` emits global today). REUSE the `applies-to` primitive + native ESLint `files:`; the lock-file carries `applies-to apps/web/**` markers (the field already supports it). **BUILD only** the per-workspace emission.
3. **CLI expression.** Per-workspace auto-detect as primary (research §3 Fork 1c); `--stack a,b` as the explicit override (subject to §6-fork-3 — confirm whether to ship it at all).
4. **Coordination (gate, do FIRST):** reconcile Layer-2 emission with `chore/install-ast-wiring-kickoff` (per-package consumer-config editing) per the §4 fork — fold / sequence / REUSE / keep-independent. Do not parallel-build.

**Acceptance.**
- On a fixture monorepo (≥2 stacks, e.g. ts-server `apps/api` + react-native `apps/mobile`), one invocation produces a config where **each** workspace's rules are scoped to its dir (proven by `eslint --print-config` per workspace showing the stack-appropriate rules, and the secondary stack is **not** silently dropped — the #780 nuance).
- The lock-file shows per-rule `applies-to <dir>/**` markers for the multi-stack case.
- Single-stack repos are unaffected (no regression vs I-1 / the #646 multi-preset baseline).
- The `{dir → stack}` detection handles the `EXECUTION-PLAN.md:564` ambiguity edge (each workspace individually unambiguous) and degrades cleanly on a per-workspace `unknown` (research §6 fork-2 default: re-checkable marker, not `exit 1`).

**Capability commits expected** (new per-workspace detector walk; new per-workspace emission path may exceed the ≥80-LOC threshold). Each carries a `Prior-art:` trailer citing #111–#113 (and #11 ESLint `extends:` / #17 workspace-globs where apt).

### New-artefact obligations (likely for I-2 Layer-2 enforcement scoping)

If any I-phase introduces a **new rule / principle / discipline artefact** (a `.claude/rules/*.md`, a `packages/core/principles/*.test.ts`, or a discipline-bearing doc edit — likely for the per-workspace-scoping discipline in I-2):

- It MUST carry a **§1.7 forward/backward self-reflexive note** ([phase-research-coverage.md §1.7](../../rules/phase-research-coverage.md) — forward-check against `no-paid-llm-in-ci.md` / `build-first-reuse-default.md` / `doc-authority-hierarchy.md` / `dual-implementation-discipline.md`; backward-check that it codifies the §13.5 work and supersedes nothing silently). Use the `self-reflection` skill.
- It MUST carry a **doc-authority header** ([doc-authority-hierarchy.md §3](../../rules/doc-authority-hierarchy.md)): `> **Class:** A/B/C` + `Authoritative-for` + `NOT authoritative for: project goal — see README#why-this-exists`. New `.claude/rules/*.md` files MUST be registered in `packages/core/principles/09-doc-authority-hierarchy.test.ts` `REQUIRED_HEADER_DOCS` (else principle 09 fails).
- If the artefact ships both a CC-native and a portable channel, apply [dual-implementation-discipline.md §5](../../rules/dual-implementation-discipline.md) (`@dual-pair:` anchor on both).

## §3 AI-laziness traps — concrete per-task T-enumeration

Per [ai-laziness-traps.md §3](../../rules/ai-laziness-traps.md), this kickoff cites the rule **and** enumerates concrete T-numbers per task **and** adds domain-specific traps. A blanket `see ai-laziness-traps.md` would itself be `#trap-catalogue-blanket-reference` (T-MS-B applied recursively to this kickoff). See [.claude/rules/ai-laziness-traps.md §2](../../rules/ai-laziness-traps.md) for the canonical catalogue.

**Active traps for Phase I-1: T3, T8, T16, T19.**
- **T3** (no prose-only findings) — every "this branch already does X" claim about `feat/547-install-auto-wire-r2` must be a freshly-read file:line, not recalled.
- **T8** (don't ask what the kickoff answers) — the I-1 default ("auto-detect, `exit 1` only on `unknown`") is decided here; don't re-ask the maintainer.
- **T16** (pattern-matching-on-name) — `547-install-auto-wire-r2` *sounds* like the auto-detect we need, but it auto-wires **R2 (a rule)**, not the **stack**. Verify the surface before REUSE; write "547 class = rule-injection-by-repo-read; I-1 class = stack-pick-by-repo-read; match? pattern only".
- **T19** (own cold-QA before handoff) — run a fresh adversarial review of the I-1 diff (CI-green ≠ design-reviewed) before handoff.

**Active traps for Phase I-2: T1, T3, T7, T11, T12, T15, T16, T-MS-A, T-MS-B, T18.**
- **T1 / T11 / T12** — if Layer-2 design tempts a "we should just build a scoping engine", STOP: the research already ran DeepWiki ×5 + WebSearch ×3 (ESLint native `files:` = REFERENCE). Re-run a search only if proposing a *new* capability slice not covered in research §1; do not re-derive from memory.
- **T-MS-A** (primitive-present ≠ pipeline-uses-it) — do **not** declare "native ESLint `files:` solves Layer 2"; the gap is *emission* (`wire-eslint-r2.ts:421-423` emits global). Prove the per-workspace `files:` is actually emitted (per-workspace `eslint --print-config`), not just that the field type exists.
- **T16** — for each REFERENCE (Nx, pnpm, Turborepo), restate "upstream class X vs our class Y, match?" before reusing any pattern; do not import a runtime because the name fits.
- **T7** (adversarial "what option/prior-art did I miss?") — at Layer-2 design close, run "what scoping approach / what monorepo tool / what in-flight branch did I miss?" once; if it returns nothing, rephrase and run again.
- **T15** (self-application) — the per-workspace-scoping discipline (if codified as a rule) must self-apply: does the rule itself carry the §1.7 + doc-authority header it mandates?
- **T18** (preserve unique residue, don't just rebuild) — when coordinating with `install-ast-wiring` (§4 fork), if a slice overlaps, REUSE/coordinate; never delete-and-rebuild the other branch's design.
- **T-MS-B** (recursive kickoff-authoring) — already discharged in this kickoff (concrete per-task T-lists above), but any *sub*-kickoff this umbrella spawns must do the same, not blanket-ref.

**Domain-specific trap (this umbrella):**
- **T-MSM-A** — "tempted to treat the timeliner *root* `package.json` as the stack signal." In a pnpm monorepo the root often has neither `react-native` nor `next` as direct deps; root-detect returns `ts-server` or `unknown` and silently drops the Expo app — reproducing the exact #780 bug at the detection layer. Counter: detection MUST walk **per-workspace** `package.json`, never root-only, for the multi-stack case.
- **T-MSM-B** — "tempted to close #780 on I-2 (the hard half)." #780's titled core is closed by **I-1**; holding the issue open until I-2 ships couples a shipped fix to an unshipped extension. Counter: close #780 on I-1 with a note that the multi-stack nuance tracks under §13.5/I-2 (research §4).

## §4 Coordination fork (the principal `#parallel-evolution-creep` risk — resolve before I-2 Layer 2)

`chore/install-ast-wiring-kickoff` already targets **per-package eslint config editing in a monorepo** (its acceptance fixture is a monorepo with a per-package `eslint.config.mjs`). I-2 Layer-2 (emit per-workspace `applies-to`/`files:`) is an adjacent slice. Resolve **one** of: (A) fold I-2 Layer-2 into install-ast-wiring; (B) sequence I-2 after it and REUSE its AST config-editing primitive; (C) keep independent (I-2 scopes *our generated* config; install-ast-wiring edits the *consumer-authored* config) with an explicit file boundary. **This is open decision #1 for the maintainer (research §6) — surface it, do not silently pick.**

## §5 Open decisions for the maintainer (from research §6)

1. **[BIGGEST]** I-2 Layer-2 vs `install-ast-wiring` — fold / sequence / REUSE / independent (§4 above).
2. Non-interactive `-y` with a genuinely-`unknown` workspace — strict `exit 1` vs scope-detected + re-checkable marker (research §3 Fork 4 / §6 fork-2; recommended default = marker).
3. Ship `--stack a,b` at all, given robust per-workspace auto-detect? (surface-minimisation call; research §6 fork-3).

Surface these via `AskUserQuestion` at the appropriate decision point; do not bake them into a silent action ([recommendation-laziness-discipline.md §3](../../rules/recommendation-laziness-discipline.md)).

## §6 See also

- [docs/meta-factory/multi-stack-monorepo-research.md](../../../docs/meta-factory/multi-stack-monorepo-research.md) — the R-phase research (prior-art verdicts, REUSE-map, fork resolution, draft SSOT #111–#113).
- [docs/meta-factory/open-questions.md §13.5](../../../docs/meta-factory/open-questions.md) — the open question this umbrella opens.
- [docs/meta-factory/architecture.md §2.3](../../../docs/meta-factory/architecture.md) — Layer-1 Stack Detector (the v2-backlog `structure` field I-2 extends).
- [.claude/rules/ai-laziness-traps.md](../../rules/ai-laziness-traps.md) — §2 canonical trap catalogue (this kickoff's §3 enumerates from it).
- [.claude/rules/build-first-reuse-default.md](../../rules/build-first-reuse-default.md) — the build-vs-reuse discipline the research §1 verdicts follow.
- [.claude/rules/doc-authority-hierarchy.md](../../rules/doc-authority-hierarchy.md) + [.claude/rules/phase-research-coverage.md §1.7](../../rules/phase-research-coverage.md) — new-artefact header + self-reflexive obligations.

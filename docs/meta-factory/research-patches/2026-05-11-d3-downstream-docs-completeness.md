<!-- scope:§13.29-incident-4 -->
# D-3 downstream-docs completeness — `DOWNSTREAM_DOCS` curated manually, not derived from grep

> Scope: 2026-05-11 finding surfaced during Wave 8 (§13.29) framing discussion — D-3 probe in `audit-ai-docs.sh` checks goal-phrase parity across a manually-curated list (`DOWNSTREAM_DOCS`), and that list was built from memory; at least two active downstream docs containing the canonical phrase are missing from coverage. Incident 4 of the `#discipline-theatre` shape that Wave 8 (§13.29) is consolidating — same root cause, different surface.

## Problem

The D-3 probe at [packages/core/audit-self/audit-ai-docs.sh:145-184](../../../packages/core/audit-self/audit-ai-docs.sh) enforces «canonical goal-phrase parity»: every entry in `DOWNSTREAM_DOCS` must contain `CANON_PHRASE` (`"AI agents can't silently bypass undocumented conventions"`) or `CANON_ALT` (`"AI cannot silently bypass what fails CI"`). On 2026-05-11, a paired negative test was added in PR #37 (commit `03b6382`) — closing Incident 2 of Wave 8's ORIGIN section.

The negative test verifies the **probe fires when an enrolled file is mutated**. It does *not* verify the **enrollment list itself is complete**.

`grep -F` sweep over the repo (excluding `node_modules`, `.git`, frozen historical research-patches, and test infrastructure that defines the canon) yields the following active downstream surface:

| File | In `DOWNSTREAM_DOCS`? |
|---|---|
| `.claude/session-bootstrap.md` | ✓ |
| `CLAUDE.md` | ✓ |
| **`.claude/hooks/inject-session-bootstrap.sh`** | ✗ (dyrа #1) |
| **`docs/meta-factory/EXECUTION-PLAN.md`** | ✗ (dyrа #2) |

Both missing files contain the literal canonical phrase, both are active (not frozen per [doc-authority-hierarchy §4 frozen-doc rule](../../../.claude/rules/doc-authority-hierarchy.md)), and both are exactly the *load-bearing* downstream surface — the hook injects the phrase into every Claude session prompt, and EXECUTION-PLAN is the operational planning document whose goal-drift caused Incident 3 (2026-05-09) of Wave 8's ORIGIN.

## Root Cause

`DOWNSTREAM_DOCS` was **curated by recall**, not **derived by grep**. The list was set during Wave 7 sub-wave 7.1.d (commit `2b0a505`) by listing the docs the author remembered as goal-bearing — `session-bootstrap.md` (because it's the operational restatement file) and `CLAUDE.md` (because it's the auto-load file). Other surfaces — the hook, EXECUTION-PLAN — were *not* considered because they were not present in the author's working memory at curation time.

This is the **third documented occurrence** of `DOWNSTREAM_DOCS` curation drift in the project's history:

| When | Surface | Discovery mechanism |
|---|---|---|
| Wave 7 sub-wave 7.1.d (2026-05-11) | D-3 list created with 2 entries | author recall |
| 2026-05-11 (this session, manual review) | `.claude/hooks/inject-session-bootstrap.sh` missing | external reviewer noted the hook's hardcoded heredoc as a possible drift point |
| 2026-05-11 (this session, follow-up grep) | `docs/meta-factory/EXECUTION-PLAN.md` missing | grep-driven sweep done to verify the first finding's blast radius |

Each finding surfaced **post-fact** — after the probe was declared «done», during an unrelated discussion, by accident. None of the three originated from a systematic process. The pattern is `#own-stack-blind-spot` ([phase-research-coverage.md §4](../../../.claude/rules/phase-research-coverage.md)) applied to *the project's own canonical-phrase surface*: the author treats the curation list as authoritative because they wrote it, and does not subject it to the same adversarial check that other negative-existence claims receive (§1.4).

The deeper failure mode is the same as Wave 8 (§13.29)'s central thesis — `#discipline-theatre`:

| Form (what the probe checks) | Substance (what the probe is supposed to enforce) |
|---|---|
| «Every file in `DOWNSTREAM_DOCS` contains canonical phrase» | «No active downstream doc with canonical phrase drifts from canon» |

The form is satisfied (the 2 enrolled files have the phrase). The substance is not (2 additional files have the phrase and drift unprotected). The presence-check probe was built; the completeness-of-the-checked-set was not. This is Incident 4 of the Wave 8 pattern, at one level of indirection: it's a discipline-theatre instance applied to the *coverage list* of an anti-discipline-theatre probe.

## Solution

Two-layer fix — **surface** (close the 2 known dyrы) + **structural** (close the *class* of dyrа):

1. **Surface fix.** Extend `DOWNSTREAM_DOCS` in [audit-ai-docs.sh:163-166](../../../packages/core/audit-self/audit-ai-docs.sh) to include the two missing paths:
   - `.claude/hooks/inject-session-bootstrap.sh`
   - `docs/meta-factory/EXECUTION-PLAN.md`

2. **Structural fix — D5 completeness probe.** Add a new D5 probe in `audit-ai-docs.sh` that asserts the inverse direction:
   - Run `grep -lF "$CANON_PHRASE"` and `grep -lF "$CANON_ALT"` across the repo (excluding `node_modules`, `.git`).
   - Compute `FOUND = grep results`, `ENROLLED = DOWNSTREAM_DOCS`, `EXEMPT = explicit allowlist patterns`.
   - **Invariant**: `FOUND ⊆ ENROLLED ∪ EXEMPT`. Any file in `FOUND` but not in `ENROLLED ∪ EXEMPT` is a coverage gap → D5 fails.
   - Exemption patterns enumerate the three legitimate categories of «canonical phrase appears but enrollment unnecessary»:
     - **`FROZEN_PATTERNS`** — `docs/meta-factory/research-patches/*.md`, `docs/audits/*.md` (frozen historical artefacts per [doc-authority-hierarchy §4 frozen-doc rule](../../../.claude/rules/doc-authority-hierarchy.md)).
     - **`TEST_INFRASTRUCTURE_PATTERNS`** — `packages/core/audit-self/audit-ai-docs.sh` itself (defines `CANON_PHRASE`/`CANON_ALT`), `packages/core/audit-self/audit-ai-docs.test.sh` (test fixture), `packages/core/audit-self/template-render.audit.ts` (synonym whitelist for template-render audit).
     - **`FALSE_POSITIVE_ALLOWLIST`** — `packages/preset-next-15-canonical/RULES.md` (contains the unrelated phrase «to silently bypass it» which substring-matches but is semantically distinct; one-line exemption with rationale comment).

3. **Paired negative test for D5** (per [audit-ai-docs.sh:32 discipline](../../../packages/core/audit-self/audit-ai-docs.sh) and Wave 8 §13.29 thesis) — `test_D5` in `audit-ai-docs.test.sh`:
   - Mutation: write a tmp file under `docs/` containing the canonical phrase, not in any exemption category.
   - Assert: D5 emits FAIL referencing the orphan file.
   - Cleanup: remove tmp file, assert D5 returns to green.

4. **Hook-stdout snapshot test** (the «paired negative» for the hook itself, distinct from D5 list-coverage):
   - Run `bash .claude/hooks/inject-session-bootstrap.sh`, capture stdout.
   - Assert stdout contains `CANON_PHRASE`.
   - Negative arm: in test fixture, replace heredoc with empty string, re-run, assert assertion fails.
   This catches behavioural drift orthogonal to the source-level grep — e.g., heredoc syntax break, hook permission stripped, anything that prevents the phrase from reaching the user prompt context.

The four edits together transition D-3 from «N files curated manually carry the phrase» (form) to «every file carrying the phrase is either enrolled or explicitly exempt, and the enrolled hook actually delivers it at runtime» (substance).

## Prevention

PRIORITY CHECK rule, applied before adding a new entry to any **closed enumerated list** used as a CI gate (`DOWNSTREAM_DOCS`, `REQUIRED_HEADER_DOCS`, `EXEMPT_PATTERNS`, `MATERIAL_SOURCES`, equivalent allowlists):

> If the list enumerates files-that-contain-property-X, the same commit must add (or extend) a meta-test that asserts `{ files in repo with property X } ⊆ list ∪ exempt-allowlist`. Curating from memory without the meta-test is the failure mode; the form (presence-check on enrolled items) is incomplete without the meta-check (completeness of the enrollment).

Concretely:
- For `DOWNSTREAM_DOCS` (this incident) — D5 probe per Solution §2.
- For `REQUIRED_HEADER_DOCS` (principle 09) — already partially covered by EXEMPT_PATTERNS + the principle test, but no inverse-direction sweep verifying «every authority-bearing doc in repo is enumerated». Potential follow-up.
- For `MATERIAL_SOURCES` (install.sh `SHIPPED_DOCS` array) — Wave 5 follow-up `18d32c6` already added MATERIAL_SOURCES sync, but the inverse direction (every shipped doc referenced in any consumer-facing artefact is in `SHIPPED_DOCS`) is not enforced. Potential follow-up.

The general shape — «curated enumeration + presence-check probe → vulnerable to manual-curation drift unless paired with inverse-completeness probe» — is the abstraction. D5 is the bootstrap exemplar for canonical-phrase parity; the same pattern applies to every analogous gate in the project.

## §1.7 self-review (recursive)

**Forward — does the proposed D5 probe + completeness-rule comply with existing disciplines?**

| Layer | Compliance |
|---|---|
| Principle 08 (`Prior-art:` trailer) | New D5 probe is a refactor/test addition, not a capability commit (no new dep, no new ≥50/80 LOC file under `packages/core/<new>/` or `packages/`). Escape hatch acceptable. Implementation commit will surface this verdict explicitly. |
| Build-vs-reuse SSOT | D5 is a within-project extension of an existing probe (D-3), not a new capability area. No SSOT entry required; if implementation diverges (e.g. extracts a shared completeness-check helper used by other probes), revisit. |
| Doc-authority hierarchy | This research-patch lives in `research-patches/` (folder-level authority per [doc-authority-hierarchy §5](../../../.claude/rules/doc-authority-hierarchy.md)); no per-file Authoritative-for header needed. Scope marker `<!-- scope:§13.29-incident-4 -->` per Wave 4 convention (SSOT #29). |
| Trigger sweep (§1.6) | §13.29 (Wave 8) is the relevant trigger; this patch is incident-4 evidence for it. No other §13.x entry obviously bears on D-3 enrollment specifically. |
| Paired-negative discipline | Solution §3 (test_D5) + §4 (hook stdout snapshot) explicitly ship paired-negative tests — exactly the discipline this incident reveals as previously missing. |

**Backward — complete sweep of artefacts under «curated enumerated list used as CI gate» scope.**

Inventory of comparable lists in the project (those I can grep up):

| List | Location | Inverse-completeness gate exists? |
|---|---|---|
| `DOWNSTREAM_DOCS` | `audit-ai-docs.sh:163` | ✗ — this patch closes it (D5) |
| `REQUIRED_HEADER_DOCS` | `09-doc-authority-hierarchy.ts:27` | partial (principle test enforces forward direction; no inverse sweep checks «every authority-bearing doc enumerated») |
| `EXEMPT_PATTERNS` | `09-doc-authority-hierarchy.ts:97` | n/a (exemption list; inverse direction would be «every file matching pattern is genuinely fixture» — not mechanically checkable) |
| `MATERIAL_SOURCES` / `SHIPPED_DOCS` | `install.sh` | partial (Wave 5 follow-up `18d32c6` added forward sync; no inverse sweep) |
| `CANONICAL_PROMPT_FILES` | (check if exists) | not yet investigated |

The full sweep is **deferred** — fixing all three with D5-shape probes in this patch would mix concerns. This patch closes `DOWNSTREAM_DOCS` only; the meta-rule (Prevention section above) records the general shape so future analogous list additions trigger the same gate. Listed in the Prevention paragraph as «Potential follow-up» for `REQUIRED_HEADER_DOCS` and `MATERIAL_SOURCES` — these become independent armed triggers if/when an incident surfaces in either list.

## Tags

- `#discipline-theatre` (Wave 8 §13.29 parent — form satisfied, substance not verified)
- `#recursive-self-application-gap` ([phase-research-coverage.md §4](../../../.claude/rules/phase-research-coverage.md) — D-3 probe was created to prevent drift, but its own enrollment was not subjected to drift-detection)
- `#own-stack-blind-spot` ([phase-research-coverage.md §4](../../../.claude/rules/phase-research-coverage.md) — manual recall of «which downstream docs exist» treated as authoritative; not adversarially checked)
- `#curated-list-without-completeness-gate` (new — proposed addition to [phase-research-coverage.md §4](../../../.claude/rules/phase-research-coverage.md) anti-pattern catalogue if a second list-class incident lands)

## See also

- [open-questions.md §13.29](../open-questions.md) — Wave 8 «Substantive Compliance Verification» (parent; this finding is Incident 4 of its origin set; cross-reference back from Wave 8 research-patch when it lands)
- [phase-research-coverage.md §1.4](../../../.claude/rules/phase-research-coverage.md) — adversarial counter-prompt rule that would have caught the manual-curation gap had it been applied to the list itself
- [phase-research-coverage.md §1.9](../../../.claude/rules/phase-research-coverage.md) — SSOT citation existence-check (Wave 7 M2) — same shape (verify cited thing exists, don't trust the trailer's claim); D5 is the same pattern (verify enrolled list is complete, don't trust the curator's claim)
- [packages/core/audit-self/audit-ai-docs.sh:145-184](../../../packages/core/audit-self/audit-ai-docs.sh) — D-3 probe source
- [packages/core/audit-self/audit-ai-docs.test.sh:test_D3](../../../packages/core/audit-self/audit-ai-docs.test.sh) — D-3 paired negative test (Incident 2 closure, 2026-05-11 PR #37)
- Wave 8 implementation prompt: `.claude/orchestrator-prompts/wave-8-substantive-compliance/d3-completeness-fix.md` (DRAFT-pending-wave-8-research)

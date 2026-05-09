# Doc authority hierarchy — discipline rule

> **Origin:** 2026-05-09 goal-hierarchy restructure incident — `EXECUTION-PLAN.md §1` silently re-defined the project's goal as «recursive self-application is the north star», overriding `README.md#why-this-exists`. The drift went uncaught for months because the project had code-level discipline (R1-R20, principles 01-08, build-vs-reuse SSOT, search-coverage rule) but no doc-authority discipline.
>
> **Self-reflection:** the project's own thesis — «documents lie; tests don't» — was scoped to *user code*, never to *its own documentation structure*. Pain-driven discipline accumulation finally surfaced this layer when the drift bit a reviewer cycle. Recursive-self-application gap (anti-pattern `#recursive-self-application-gap` in [phase-research-coverage.md §4](phase-research-coverage.md)) — discipline applied bottom-up to user code, not top-down to own design.
>
> **Companion principle:** [`packages/core/principles/09-doc-authority-hierarchy.test.ts`](../../packages/core/principles/09-doc-authority-hierarchy.test.ts) — executable test enforcing this rule on the canonical doc list.

This rule formalises **doc-authority hierarchy** as a project invariant, parallel to:
- code-level discipline (R1-R20 lint rules)
- decision-level discipline (Prior-art trailers + SSOT)
- search-level discipline ([phase-research-coverage.md](phase-research-coverage.md))

The rule applies to canonical project docs **and** to docs the framework generates for consumer projects (templates under `templates/`, sub-agent prompts under `.ai-factory/`, generated `RULES.md` / `CLAUDE.md` / `AGENTS.md`). Generated-doc compliance is deferred per [open-questions.md §13.21](../../docs/meta-factory/open-questions.md) — current rule scope is project-internal docs only.

## §1 Problem this solves

Multi-doc projects accumulate authority drift over time. Operational documents («Phase N plan», «Roadmap», «Architecture decisions») start as scope-bound artifacts but their authors slip into project-wide framings («north star», «central thesis», «main goal»). When two docs describe the same thing differently, downstream readers (humans + AI agents) pattern-match on whichever they read first. AI agents are particularly vulnerable: per [arxiv:2505.02709](https://arxiv.org/html/2505.02709v1), goal drift is caused by pattern-matching on observed authoritative-language in context, not by token-distance forgetting.

The fix is **explicit per-doc authority scope**, declared at the top of every canonical doc:
- *what this doc owns* (Authoritative-for)
- *what falls outside its scope* (NOT authoritative-for, when ambiguity exists)

Conflicting authority claims become detectable at review time and at session-start (Step 0 read).

## §2 When a doc needs Authoritative-for header

**Required for:**
- Project-root docs: `README.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `INSTALL.md`, `INSTALL-FOR-AI.md`
- Operational docs declaring project-wide scope or invariants: anything under `docs/meta-factory/*.md` (excluding sub-folders for retros/research-patches)
- Skill primary docs + cold references: `skills/*/SKILL.md`, `skills/*/references/*.md`
- Hot operational docs: `.claude/session-bootstrap.md`, `.claude/rules/*.md`
- Phase orchestration prompts: `*-PROMPT.md` files (declare scope: «Phase N orchestration; transient artifact»)

**Folder-level authority (single header in folder README):**
- `docs/meta-factory/retros/` — folder README declares «closed historical artifacts post-merge; individual files scope-bound by phase ID»
- `docs/meta-factory/research-patches/` — folder README declares «one patch per coverage gap, append-only; individual files scope-bound by gap»
- `.claude/orchestrator-prompts/` — historical orchestration prompts; folder README sufficient

**Not required for:**
- Generated artifacts (rules-lock.json, snapshots, fixtures) — they have schema, not prose
- Tests (test names ARE the documentation per «documents lie; tests don't»)
- Code files (TypeScript/JS) — JSDoc comments serve different purpose

## §3 Header format

Insert at the top of the doc, after the title and any existing status block, as a Markdown blockquote:

```markdown
# Doc title

> **Status:** ...                   ← existing status block (if any)
> **Date:** ...
>
> **Authoritative for:** <one-sentence scope statement>.
> **NOT authoritative for:** <when ambiguity exists — what falls outside>; see [<canonical doc>](path).
```

**Scope statement style:**
- Specific, not «everything related to X»
- Names the artifact type (e.g. «phase 9 acceptance criteria», «6-layer architecture description», «build-vs-reuse SSOT register»)
- Mentions canonical authority for what's NOT in scope (e.g. «NOT authoritative for project goal — see [README.md#why-this-exists](../../README.md#why-this-exists)»)

**Examples** (from goal-hierarchy restructure, 2026-05-09):

| Doc | Authoritative for | NOT authoritative for |
|---|---|---|
| README.md `§Why this exists` | project goal, methodology, design invariants | (root authority — owns what others delegate to) |
| CLAUDE.md | AI-tooling conventions, capability-commit gates, build-vs-reuse discipline, Artifact Ownership Contract | project goal — see README#why-this-exists |
| EXECUTION-PLAN.md | phase scope, sequencing, acceptance criteria, operational decisions | project goal — see README#why-this-exists |
| PROPOSAL.md | design history and original architectural proposal (Phase 0.5 – 1.D snapshot, May 2026) — **FROZEN** | current goal hierarchy (see README); do not retroactively rewrite |
| .claude/session-bootstrap.md | operational restatement of goal + invariants for AI session start | (delegates upward — operational artifact) |

## §4 Anti-patterns

- **`#operational-doc-redefines-goal`** — operational doc (EXECUTION-PLAN, ROADMAP, phase prompt) introduces «north star» / «central thesis» / «main goal» language. Authority creep — surface as a coverage-gap patch.
- **`#missing-authority-header`** — canonical doc has no Authoritative-for declaration. Default-implicit authority leaves scope ambiguous; future readers (and AI agents) pattern-match on whatever language sounds authoritative.
- **`#contradicting-authority-claims`** — two docs claim authority for the same scope without subordination marker. Resolve by promoting one to authoritative + adding subordinate marker to the other.
- **`#frozen-doc-still-edited`** — doc marked FROZEN (e.g. PROPOSAL.md) receives substantive content edits beyond its scope. Frozen docs may receive ONLY: (a) authority-header updates, (b) typo fixes, (c) link repairs. Substantive content updates require either un-freezing (with rationale) or moving content to a current authoritative doc.

## §5 Folder-level authority pattern

For directories with many small files of similar shape (retros, research-patches, orchestrator-prompts), require **one** `README.md` at the folder root declaring scope:

```markdown
# <Folder name>

> **Authoritative for:** <category description, one sentence>. Individual files are scope-bound by their <key dimension — phase ID / gap ID / etc.>.
> **NOT authoritative for:** project goal — see [README.md#why-this-exists](path-up-to-root).
> **Append-only:** ...  ← if applicable
```

Individual files in such folders inherit folder authority and do **not** need their own Authoritative-for header. They MAY include a one-line scope marker at the top (e.g. «Scope: Phase 8 retro»).

## §6 Promotion / demotion / retirement

- **Promotion to mandatory CI gate:** when 3 cross-doc authority drift incidents are surfaced via reviewer cycles within a 6-month window. Promotion path: principle 09 test + (optionally) custom pre-push hook checking that designated authority-bearing docs have valid headers.
- **Widening scope to generated docs:** when [open-questions.md §13.21](../../docs/meta-factory/open-questions.md) trigger fires (templates layer L3 work).
- **Retirement:** if no authority drift incident occurs for 12 consecutive months AND principle 09 test reports zero violations across the same window, the rule may be archived to prose guidance in CLAUDE.md (parallel to phase-research-coverage rule §retirement criteria).

## See also

- [packages/core/principles/09-doc-authority-hierarchy.test.ts](../../packages/core/principles/09-doc-authority-hierarchy.test.ts) — executable principle.
- [.claude/session-bootstrap.md](../session-bootstrap.md) — Step 0 file linking to README as canonical goal source.
- [CLAUDE.md `Artifact Ownership Contract`](../../CLAUDE.md) — read-only / read-write boundaries per agent class.
- [docs/meta-factory/open-questions.md §13.21](../../docs/meta-factory/open-questions.md) — generated-doc compliance trigger (deferred L3 work).
- [.claude/rules/phase-research-coverage.md §4 anti-patterns](phase-research-coverage.md) — `#recursive-self-application-gap` parent anti-pattern category.

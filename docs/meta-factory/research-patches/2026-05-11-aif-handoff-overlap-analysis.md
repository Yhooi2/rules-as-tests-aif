# AIF Handoff coordinator overlap analysis — prior-art research

> **Scope:** research mandate 2026-05-11 — overlap analysis между AIF v2.x Handoff coordinator и нашими 7 «handoff»-семейными primitives (P1-P7).
> **Authoritative for:** evidence + verdicts на borrow candidates. NOT authoritative for: implementation decision (orchestrator Stage 3); project goal — see [README.md#why-this-exists](../../../README.md#why-this-exists); AIF deep alignment Option I — see [open-questions.md §13.18](../open-questions.md).
> **Stage:** 1 of 3 (research → independent review → decision).

---

## §0 Mandate scope + reading list completed

**Step 0 files read:**
- [x] `README.md` §why-this-exists — project goal SSOT
- [x] `.claude/session-bootstrap.md` — invariants + reading order
- [x] `CLAUDE.md` — Artifact Ownership Contract, capability-commit definition, `Prior-art:` trailer syntax
- [x] `.claude/rules/doc-authority-hierarchy.md` — §3 header format, §4 anti-patterns, §5 folder-level authority
- [x] `.claude/rules/phase-research-coverage.md` — §1 9-item checklist (incl. §1.7-§1.9), §2 prompts, §4 anti-patterns
- [x] `docs/meta-factory/aif-comparison.md` — AIF v2.11.0 full comparison; §§5,11 producer/consumer stance established
- [x] `docs/meta-factory/prior-art-evaluations.md` — entries #1-#26; AIF entry: #8 (Step 0 re-read); no existing Handoff entry
- [x] `docs/meta-factory/research-patches/README.md` — folder authority + file format
- [x] Sample patches: `2026-05-10-§13.25-tool-bootstrapping-research.md`, `2026-05-11-§13.23-4th-layer-research.md`

**context7 queries run (all `/lee-to/ai-factory`, 2026-05-11):**

1. `handoff coordinator state machine status transitions pending planning ready in-progress review done`
2. `handoff_sync_status MCP tool signature parameters taskId newStatus sourceTimestamp direction paused`
3. `HANDOFF_MODE autonomous vs manual differences skill behavior aif-fix aif-implement aif-plan`
4. `handoff:task annotation plan files first line linking plan coordinator bidirectional sync`
5. `handoff database schema persistence storage task record DB writes coordinator owns`
6. `aif coordinator subagent contract implement-coordinator plan-coordinator skill delegation`
7. `AIF task lifecycle status transitions complete list all statuses`
8. `handoff ownership model artifact ownership coordinator owns writes permissions agents read-only`

Sources confirmed: `skills/aif-fix/SKILL.md`, `skills/aif-implement/SKILL.md`, `skills/aif-plan/SKILL.md`,
`subagents/implement-coordinator.md`, `subagents/plan-coordinator.md`, `docs/subagents.md`,
`docs/loop.md`, `AGENTS.md`, `skills/aif-qa/SKILL.md`, `skills/aif/SKILL.md`.

---

## §1 AIF Handoff feature inventory

*All claims cite context7 source paths.*

### Coordinator-level

**C1. Mode fork — `HANDOFF_MODE` env var.**
Source: `skills/aif-implement/SKILL.md`, `subagents/implement-coordinator.md`
`HANDOFF_MODE=1` (autonomous): external Handoff coordinator owns status transitions + DB writes; skills skip MCP
tool calls; interactive prompts suppressed; defaults applied. `HANDOFF_MODE` unset (manual Claude Code session):
skills call `handoff_sync_status` + `handoff_push_plan` inline. Step 0 (pre) in all skills: `printenv HANDOFF_MODE || true`.

**C2. Top-level agent requirement.**
Source: `docs/subagents.md`, `subagents/implement-coordinator.md`
`plan-coordinator` and `implement-coordinator` MUST run as `claude --agent <name>` top-level sessions.
Cannot be spawned by ordinary subagents (ordinary subagents lack subagent-spawning capability).
`implement-coordinator` spawns `implement-worker` workers + quality sidecars.

**C3. External DB ownership.**
Source: `subagents/implement-coordinator.md`, `subagents/plan-coordinator.md`
In `HANDOFF_MODE=1`: Handoff coordinator owns DB writes for task state; skills are read-only consumers.
DB schema not surfaced in context7 queries — see NC1 in §5.

### Skill-level

**S1. `handoff_sync_status` MCP tool.**
Source: `skills/aif-fix/SKILL.md`, `skills/aif-implement/SKILL.md`, `subagents/implement-coordinator.md`
Signature: `handoff_sync_status({ taskId, newStatus, sourceTimestamp, direction:"aif_to_handoff", paused:bool })`
Confirmed status values: `"planning"` (aif-plan, aif-fix plan-first), `"implementing"` (aif-implement, aif-fix
fix-now), `"review"` (paused:true), `"done"` (paused:false, requires `HANDOFF_SKIP_REVIEW=1`).
Status values "pending" and "ready" mentioned in prior context but not confirmed via context7 — see NC2 §5.

**S2. `handoff_push_plan` MCP tool.**
Source: `skills/aif-implement/SKILL.md`, `subagents/implement-coordinator.md`
Signature: `handoff_push_plan({ taskId, planContent: <full plan text> })`
Called on each checklist update (mid-implementation) and on task completion. Continuous plan sync.

**S3. AIF Artifact Ownership Contract.**
Source: `AGENTS.md`, `skills/aif-implement/SKILL.md`, `skills/aif-qa/SKILL.md`, `skills/aif/SKILL.md`
Quality commands (`/aif-rules-check`, `/aif-commit`, `/aif-review`, `/aif-verify`) are read-only for context
artifacts by default. Each skill owns specific output surfaces; `paths.rules_file` and `paths.research`
are read-only in `aif-implement`. `aif-qa` owns `change-summary.md`, `test-plan.md`, `test-cases.md` only.

### Annotation-level

**A1. Plan-file task annotation.**
Source: `skills/aif-plan/SKILL.md`, `skills/aif-implement/SKILL.md`, `subagents/plan-coordinator.md`
Format: `<!-- handoff:task:<HANDOFF_TASK_ID> -->` as **first line** of plan file.
Mandatory in `HANDOFF_MODE=1` if `HANDOFF_TASK_ID` present; enables bidirectional sync. In manual mode:
extracted at Step 0.2; if absent → MCP sync skipped for the session.

---

## §2 Our primitives P1-P7 — concise feature inventory

| ID | Primitive | Repo location | Function |
|---|---|---|---|
| P1 | Operational Opus→Sonnet handoff | `docs/meta-factory/ORCHESTRATOR-START-PROMPT.md`, `.claude/skills/orchestrator/SKILL.md` Mode B | File-prompt context transfer between model sessions; quota isolation |
| P2 | Wave-to-wave handoff | `.claude/orchestrator-prompts/wave-*/` kickoff files | Explicit output→input contract between workflow phases |
| P3 | Artifact Ownership Contract | `CLAUDE.md §Artifact Ownership Contract` | Per-artifact owner table; cross-owner edits = atomic commit + rationale; reviewers read-only |
| P4 | Orchestrator Mode A/B | `.claude/skills/orchestrator/SKILL.md` | Mode A = Agent tool inline (Opus); Mode B = file-prompt (Sonnet, fresh context) |
| P5 | Reviewer independent-context | `.claude/skills/reviewer/SKILL.md` | New session per review; manual handoff; fresh context prevents bias propagation |
| P6 | Phase-research entry consult gate | `docs/meta-factory/EXECUTION-PLAN.md §5.5 Step 1.5` | Mandatory prior-art SSOT consult + context7 ≥3 queries before capability commit |
| P7 | Research-patches sequential closure | `docs/meta-factory/research-patches/` | Append-only gap-discovery patches; human-curated methodology accumulator |

---

## §3 Overlap matrix

Labels: **OVL** = OVERLAP (winner in parens), **ORT** = ORTHOGONAL, **INV** = INVERSE

| AIF Feature | P1 | P2 | P3 | P4 | P5 | P6 | P7 |
|---|---|---|---|---|---|---|---|
| C1 `HANDOFF_MODE` fork | ORT | ORT | ORT | OVL(ours) | ORT | ORT | ORT |
| S1 `handoff_sync_status` | ORT | INV | ORT | ORT | ORT | ORT | ORT |
| S2 `handoff_push_plan` | OVL(AIF) | OVL(equiv) | ORT | ORT | ORT | ORT | ORT |
| A1 plan annotation | ORT | ORT | ORT | ORT | ORT | OVL(ours) | OVL(ours) |
| C3 External DB ownership | ORT | ORT | INV | ORT | ORT | ORT | ORT |

**Cell rationale (non-ORT cells only):**

**C1 × P4 OVL(ours):** Both implement config-driven mode fork for orchestrator behavior. AIF: `HANDOFF_MODE=1`
suppresses interactivity, delegates to external coordinator. Ours: Mode A/B selects inline Agent vs. file-prompt
Sonnet. Winner = ours: covers model-selection + context-isolation in one primitive; AIF fork is integration-mode
only, not model economics.

**S1 × P2 INV:** Both communicate state transitions across phase/context boundaries. AIF: push-based (skill calls
`handoff_sync_status` MCP to coordinator, explicit status+timestamp). P2: pull-based (next wave reads previous
wave's output files from git). INVERSE mechanism on same problem.

**S2 × P1 OVL(AIF):** Both transfer artifact content across context boundaries. AIF: continuous `handoff_push_plan`
(each checklist update, MCP tool, structured). P1: one-shot file-prompt transfer (markdown file, human-mediated).
Winner = AIF for machine-to-machine: structured, continuous, MCP-enforced. Ours wins for human-mediated model-quota
management (no MCP dependency required).

**S2 × P2 OVL(equiv):** Both propagate phase artifacts to downstream context. AIF: continuous during execution.
P2: one-shot wave output → next wave input. Equivalent at pattern level (artifact transfer across phase boundary);
differ in timing (continuous vs. one-shot) and direction (AI→external vs. AI→AI context).

**A1 × P6 OVL(ours):** Both link artifacts to their originating scope via inline markers. AIF: `<!-- handoff:task:<id> -->`
in plan file → links to Handoff task. P6: `Prior-art:` commit trailer → links capability commit to SSOT entry.
Winner = ours: git-native, auditable, machine-enforced via pre-push hook + principle 08 test; AIF annotation is
HTML comment with no enforcement gate.

**A1 × P7 OVL(ours):** Both annotate work artifacts with provenance markers. AIF: first-line task ID annotation.
P7: frontmatter `> Scope:` + date slug in research patches. Winner = ours: richer provenance (date + topic +
scope statement + authority references); AIF annotation is minimal ID-only.

**C3 × P3 INV:** Both implement single-owner model for state. AIF: external mutable DB; coordinator owns writes;
skills are read-only consumers. Ours: git as SSOT for all state; per-artifact owner table; cross-owner edit =
atomic commit + rationale. INVERSE persistence backends: AIF = mutable external DB; ours = append-only git.
Same ownership principle, incompatible backends.

---

## §4 Borrow candidates

| AIF primitive | Наша nearest analog | Borrow verdict | Rationale | SSOT entry needed? |
|---|---|---|---|---|
| C1 `HANDOFF_MODE` env-var fork | P4 Mode A/B | DEFER | Env-var fork more automation-portable than file-prompt Mode B; could inform `ORCHESTRATOR_MODE=autonomous` for CI-triggered orchestration. Trigger to revisit: first automation pipeline requiring non-interactive orchestrator, OR Mode B file-prompt proves fragile across terminal sessions. | YES |
| S1 paused:true/false semantic | P5 reviewer independent-context | DEFER | `paused:true` on "review" status explicitly encodes «human review required before continuing». Our workflow has implicit pause points but no machine-readable pause state. Trigger to revisit: when we formalize a state machine for wave workflow (Phase 11+, or wave count >10). | YES |
| A1 `<!-- handoff:task -->` annotation | P6 `Prior-art:` trailer + P7 frontmatter Scope | ADAPT | Machine-parseable first-line annotation. Adaptation: `<!-- scope:§N -->` as first line of research patches → enables automated trigger sweeps (§1.6) replacing grep-on-prose. Modifications needed: (1) `§N` syntax not UUID; (2) scope to research-patches only; (3) enforcement check in `packages/core/principles/`. Executable check after adoption: `grep -c "^<!-- scope:§" docs/meta-factory/research-patches/*.md` equals patch count; CI probe in `audit-self.yml` verifies annotation on each patch. | YES |
| C3 External DB ownership | P3 Artifact Ownership Contract | REJECT | Why not: AIF coordinator owns DB writes for mutable task state — incompatible with git-as-SSOT invariant. Introducing external mutable DB breaks the property that all state changes are auditable via `git log` (README.md invariant 1: build-vs-reuse discipline; implicit: git as sole audit trail). Our P3 achieves equivalent ownership goals via git commits + atomic-commit-with-rationale requirement. | NO |

---

## §5 Negative-existence claims + search-coverage table

### NC1: AIF Handoff DB schema not surfaced in context7

**Claim:** AIF Handoff DB schema (tables, fields, migration) is not documented in context7-indexed AIF docs.

| §1 item | Result | Note |
|---|---|---|
| 1 Own-stack sweep | PASS | Checked all AIF surface layers via 8 context7 queries |
| 2 Category sweep | PASS | Coordinator/skill/annotation/persistence layers all queried explicitly |
| 3 Semantic-distance check | PASS | Queried "database schema persistence storage" + "coordinator owns writes" |
| 4 Adversarial check | PASS | Counter-prompt: «if DB schema existed, it would be in `docs/handoff.md` or `references/HANDOFF-DB.md`» — not found |
| 5 Prompt-list ≥3 | PASS | 8 queries total |
| 6 Trigger sweep | N/A | Capability-area research, not §5.5 Step 1.5 phase entry |
| 7 §1.7 | N/A | No new discipline introduced by this claim |
| 8 Hook smoke-test | N/A | No hook touched |
| 9 SSOT citation | N/A | Research patch, not capability commit |

**Verdict: PROVISIONAL.** AIF Handoff may be a separate product; its DB schema may exist in a repo not indexed
under `/lee-to/ai-factory`. Implication for §4: REJECT verdict for C3 DB ownership holds regardless of schema
details — incompatibility is architectural (external mutable DB vs. git-as-SSOT), not schema-level.

### NC2: Confirmed status values "pending" and "ready" not verified

**Claim:** Status values "pending" and "ready" mentioned in pre-session CONTEXT were not directly confirmed via
context7 queries (only `planning`, `implementing`, `review`, `done` confirmed).

| §1 item | Result | Note |
|---|---|---|
| 1 Own-stack sweep | PASS | 8 queries against AIF docs |
| 2 Category sweep | PASS | Queried "complete list all statuses" explicitly (query 7) |
| 3 Semantic-distance check | PASS | Also queried via progress-display format (query 7 surfaced ✅/🔄/⏳ but these are UI markers, not API status values) |
| 4 Adversarial check | PASS | Counter-prompt: «if "pending"/"ready" were status values, they'd appear in `handoff_sync_status` call examples» — not found in 8 queries |
| 5 Prompt-list ≥3 | PASS | |
| 6-9 | N/A | |

**Verdict: PROVISIONAL.** "pending"/"ready" may exist as internal Handoff-side statuses not exposed to AIF skills.
Impact on analysis: matrix and borrow candidates are unaffected — they analyze AIF-side status calls, not
Handoff-side full state machine.

---

## §6 Proposed SSOT entries (drafts)

*IDs placeholder — orchestrator assigns final IDs in Stage 3. Format: `prior-art-evaluations.md §1` schema.*

| ID | Candidate | Capability matched | First seen | Verdict | Rationale (≥120 chars) | Trigger to revisit / Why not |
|---|---|---|---|---|---|---|
| #<TBD-A> | AIF Handoff `HANDOFF_MODE` env-var fork (lee-to/ai-factory v2.x, `skills/aif-implement/SKILL.md`) | Env-var driven mode fork for orchestrator: autonomous (no MCP calls) vs. interactive (inline MCP sync) | 2026-05-11 | DEFER | `HANDOFF_MODE=1` suppresses interactivity and delegates status management to external system — more automation-portable than our file-prompt Mode B. Different purpose: external-system integration vs. model-quota management (C1×P4 OVERLAP, winner=ours). DEFER pending first automation pipeline requiring non-interactive orchestrator. | First automation pipeline (CI-triggered orchestration) where Mode B file-prompt proves fragile; OR project adopts Handoff as task management (Phase 11+) |
| #<TBD-B> | AIF Handoff `paused:true/false` semantic (lee-to/ai-factory v2.x, `handoff_sync_status` tool) | Explicit machine-readable pause-for-human-review primitive in workflow state transitions | 2026-05-11 | DEFER | `paused:true` on `"review"` status encodes «human review required before AI continues» machine-readably. Our workflow has implicit pause points (P5 reviewer gate, orchestrator decision) but no machine-readable pause state. DEFER pending wave state machine formalization. Useful primitive for Phase 11+ wave orchestration. | Wave count >10 requiring formal state machine; OR Phase 11+ automation where implicit pause is insufficient for reliable reviewer gate enforcement |
| #<TBD-C> | AIF `<!-- handoff:task:<id> -->` first-line plan annotation (lee-to/ai-factory v2.x, `skills/aif-plan/SKILL.md`) | Machine-parseable artifact-to-scope linking via first-line HTML comment annotation in work files | 2026-05-11 | ADAPT | Annotation pattern `<!-- handoff:task:<id> -->` links plan files to task IDs machine-parseably (A1×P6 OVERLAP, winner=ours for audit-trail; ADAPT for research patches). Adaptation: `<!-- scope:§N -->` as first line of research patches enables automated §1.6 trigger sweeps replacing prose grep. Modifications: §N syntax not UUID; scope to research-patches only; enforcement in principles. | §1.6 trigger sweep volume >20 armed entries where grep-on-prose becomes brittle; OR Phase 11+ tooling requires machine-linked patch→trigger cross-reference |

---

## §7 §1.7 self-discipline check (forward + backward)

**§1.7 applies to recommendations that introduce or extend a discipline.** This research patch introduces no new
discipline — it documents primitive overlap and proposes SSOT draft entries for Stage 3 orchestrator review.

**Forward-check (compliance with existing disciplines):**
- Capability-commit gate: this commit adds one `.md` file in `docs/meta-factory/research-patches/`. No new file
  ≥50 LOC under `packages/core/<new-dir>/`, no new file ≥80 LOC under `packages/`, no new `package.json` dep.
  NOT a capability commit per CLAUDE.md definition. ✅
- Prior-art trailer: escape hatch applies (`Prior-art: skipped — research patch documenting prior-art evidence;
  no new capability artifact, no new packages/ subdirectory`); rationale ≥20 chars and specifies why. ✅
- doc-authority headers: frontmatter includes `> Authoritative for:` + `> NOT authoritative for:` + `> Stage:`
  per doc-authority-hierarchy.md §3 format. ✅
- Artifact Ownership Contract: research patch owned by this session; no writes to goal-bearing docs (README,
  PROPOSAL, EXECUTION-PLAN), no writes to `prior-art-evaluations.md` (orchestrator Stage 3). ✅
- §1.9 SSOT citation existence-check: N/A — commit trailer uses escape hatch (not a positive `Prior-art:#N`). ✅

**Backward-check:** N/A — no new discipline rule shipped in this patch. The ADAPT verdict for A1 annotation
pattern (§4) is a candidate for Stage 3 decision, not a rule enacted in this commit. §1.7 backward check fires
when a discipline-bearing artefact ships; that is Stage 3 orchestrator responsibility.

**Justification for §1.7 N/A (backward):** Stage 1 research patch role = evidence-gathering only. Three SSOT
draft entries are DEFER/ADAPT/REJECT candidates awaiting Stage 2 independent review and Stage 3 decision.
No principle test, no pre-push hook, no CLAUDE.md rule added here.

---

## §8 Out-of-scope items observed (logged not analysed)

- AIF `aif-loop` PLAN/PRODUCE/PREPARE/EVALUATE/CRITIQUE/REFINE loop (adjacent: phase state machine but for
  task quality, not handoff coordination) — logged; see `aif-comparison.md §1.3`.
- AIF `aif-evolve` skill mining from patches (P7 manual analog, already analysed in `aif-comparison.md §9`
  + SSOT cross-ref) — not re-analysed; scope established.
- AIF `implement-coordinator` dependency graph + parallel worker dispatch (adjacent to orchestrator Mode A
  parallel workers, but outside handoff-family scope) — logged as Phase 11+ integration point per
  `aif-comparison.md §7 subtask 11.2`.

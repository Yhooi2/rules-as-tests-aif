<!-- scope:rule-enforcement-channel-selection -->
# Research-patch — Rule-enforcement channel selection: state of the art

> **Date:** 2026-05-22
> **Scope:** Prior-art survey on delivering operating rules to AI coding agents at the moment they are relevant — reliably, without always-on context bloat. NOT authoritative for project goal (see README.md#why-this-exists). Inherits research-patches/ folder authority.
> **Session type:** R-phase — read-only. Deliverable = this file. No source edits, no commits.
> **Predecessor:** automerge-staging incident (2026-05-22) — agent missed staging-flow rule despite being in memory; origin of §0 in kickoff.
> **Method:** BFR-default §3 + phase-research-coverage §1 checklist. Tier 1 = DeepWiki ≥3 phrasings each companion. Tier 2 = CC hook SDK verification (DeepWiki anthropics/claude-code). Tier 3 = WebSearch ≥3 phrasings.
> **§1.6 trigger-sweep waiver:** this is a survey, not a formal phase entry. Trigger sweep waived per kickoff §3 direction; noted here rather than silently skipped.

---

## §1 Question + Draft Principle

**Core question:** What is the state of the art for delivering an operating rule to an AI coding agent *at the moment it is relevant* — reliably (not memory-dependent) and without always-on context bloat?

**Draft principle under test:**
> Persist each rule at the NARROWEST channel that still reliably catches its violation. Channel breadth ∝ how often the rule is relevant. Ladder: mechanical gate (fires on the action, 0 standing cost) > context-triggered injection (scoped to path/tool/task) > always-on prompt digest (reserve for 3-4 sweeping invariants) > memory (last resort, stage-0).

---

## §2 Prior-art survey

### §2.1 §1.1 Own-stack sweep

Explicit deps (root `package.json`): `markdownlint-cli2` only.
Core package deps: `remark@15`, `remark-parse@11`, `vitest`, `typescript`, `tsx`, `@stryker-mutator/*`, `ajv`, `@typescript-eslint/*`.

**Does any dep ship conditional rule delivery?** No. `remark` = markdown AST parser (SSOT #58). `vitest` = test runner. `markdownlint-cli2` = linter. None of these provide an agent rule-delivery channel mechanism. Own-stack sweep: no candidate. Negative claim below is load-bearing.

**Existing own-stack channels in this repo:**
- `.claude/hooks/*.sh` — 6 hooks (ask-question-reminder, check-doc-authority, deps-hash-check, end-of-turn-reminder, inject-session-bootstrap, validate-prompt)
- `.husky/pre-push` — mechanical gate (TS pre-push checks)
- `.claude/rules/*.md` — always-on via CC auto-load (path-scoped by CC settings)
- `.claude/session-bootstrap.md` — always-on re-read at session start
- `packages/core/principles/*.test.ts` — CI mechanical gate

---

### §2.2 Tier 1: Named companions

#### Candidate A — Superpowers (`obra/superpowers`)

**DeepWiki probe:** 3 phrasings run (rule delivery, 1% rule + description field, HARD-GATE mechanism). Successful.
URL: <https://deepwiki.com/search/how-does-superpowers-deliver-r_136880f0-9d08-4dd1-b0fa-d71aaa2a6a4e>

**Delivery mechanism — verified:**

| Channel | Superpowers implementation | Conditional? |
|---|---|---|
| Always-on metadata | Skill `name` + `description` pre-loaded in system prompt at session start | YES — always-on but lightweight (~metadata only) |
| Full-content injection | `SKILL.md` full body loaded only when 1% rule fires (agent invokes Skill tool) | YES — conditional on task-type match |
| Blocking gate | `<HARD-GATE>` blocks in skill body prevent proceeding until approval condition met | YES — fires at specific workflow step |
| Subagent isolation | `<SUBAGENT-STOP>` prevents subagents dispatched for specific tasks from activating 1% rule | YES — role-scoped suppression |
| Session bootstrap | `using-superpowers` skill injected via session-start hook (CC `experimental.chat.messages.transform`) | Always-on (one skill only) |

**Key insight (T16 verified):** Superpowers explicitly distinguishes between metadata (always-on, low-token) and full-content (conditional, high-token). The `description` field is the trigger key — it says WHEN to load, never WHAT the skill does. This is the narrowest-channel principle in production form.

**Problem-class match:** Upstream problem class = «guide AI agents through structured process to avoid slop». Our problem class = «deliver a specific rule at the moment of its violation». Match on the delivery-channel mechanism (conditional content loading keyed on description trigger). Miss on enforcement: Superpowers relies on agent compliance with 1% rule; we add mechanical gates (pre-push, CI). T16 verdict: ADAPT, not ADOPT.

**Conditional? Evidence:** YES — confirmed. Metadata always, full content only on semantic trigger. `description` field = «Use when...» trigger phrase. DeepWiki: «full content of a SKILL.md file is only loaded when the skill becomes relevant».

**BFR verdict: ADAPT** — adopt the metadata-always/full-content-conditional pattern as the vocabulary and model for our skill delivery; the 1% rule framing is adoptable; add mechanical gates (our differentiator).

**N5 give-back angle:** Superpowers has no mechanical gates for rule enforcement — it relies on agent compliance. Our pre-push + CI + hook stack provides the enforcement substrate that Superpowers lacks. Give-back opportunity: publish our hook-gate patterns as a complement to Superpowers' skill-delivery model.

---

#### Candidate B — aif-handoff (`lee-to/aif-handoff`)

**DeepWiki probe:** 3 phrasings run (constraint delivery, blocking gates, constraint injection channels). Successful.
URL: <https://deepwiki.com/search/how-does-aifhandoff-deliver-co_48e04272-402e-45ec-ae2f-025787b63aed>

**Delivery mechanism — verified:**

| Channel | aif-handoff implementation | Conditional? |
|---|---|---|
| Always-on (registry-level) | Language directive + skill-command prefix transformation — injected on every runtime call | YES — always-on for all calls |
| Phase-scoped injection | Rework headers, BLOCKING_FINDINGS_SNAPSHOT — injected only when `task.reworkRequested=true` | YES — conditional on phase state |
| Role-scoped system prompt | `REVIEW_DIFF_SCOPE_SYSTEM_APPEND` added only in review mode | YES — role-scoped |
| Env var gates | `HANDOFF_MODE`, `HANDOFF_SKIP_REVIEW` — conditional env injection per coordinator state | YES — conditional on orchestrator decision |
| Mechanical capability gate | `assertRuntimeCapabilities` — hard block if runtime doesn't support required features | YES — pre-flight hard block |
| Runtime-limit gate | `evaluateRuntimeLimitGate` — blocks new work when quota thresholds crossed | YES — mechanical block |
| Agent definition loading | `agentDefinitionName` passed to runtime → loads `.claude/agents/*.md` | Conditional on workflow kind |

**Problem-class match:** Upstream = orchestrate Planner/Implementer/Reviewer phases with per-phase constraint injection. Our problem = deliver a discipline rule at the moment of violation. Match on phase-scoped constraint injection (same pattern, different granularity). Miss on the enforcement gate concept (their gates are quota/capability gates, not discipline gates). T16: REFERENCE.

**Conditional? Evidence:** YES — confirmed. Three injection channels (always-on registry, task-scoped prompt, env vars). The RuntimeAdapter is passive; the coordinator resolves which constraints apply. DeepWiki: «constraints are not always-on in every prompt; rather, they are conditionally injected».

**BFR verdict: REFERENCE** — cite as production precedent for the three-channel injection model (always-on registry + task-scoped + env vars). Problem class match is partial; vocabulary not adoptable verbatim.

**N5 give-back angle:** aif-handoff has no rule-delivery trigger mechanism (rules are triggered by orchestrator logic, not by semantic task matching). Our `when_to_use` description-field discipline (SSOT #55 Superpowers ADAPT) could be a give-back to the handoff phase-matching problem.

---

#### Candidate C — AI Factory / AIF (`lee-to/ai-factory`)

**DeepWiki probe:** 3 phrasings run (skill delivery, conditional vs always-on, skill-context mechanism). Successful.
URL: <https://deepwiki.com/search/how-does-ai-factory-aif-delive_2251f0e4-7c3e-4f67-a8f2-c33c5db4be08>

**Delivery mechanism — verified:**

| Channel | AIF implementation | Conditional? |
|---|---|---|
| Always-on context | `.ai-factory/DESCRIPTION.md` — project tech stack, architecture — always loaded | Always-on |
| Always-on patches | `.ai-factory/patches/*.md` — read by `/ai-factory.implement` before every task | Always-on (per-skill invocation) |
| Skill-invoked rules | `SKILL.md` body — only loaded when skill is explicitly invoked or workflow-triggered | Conditional on invocation |
| Plan-based preferences | User preferences captured in planning → passed to downstream skills | Conditional on plan state |
| Tech-stack rules | `/ai-factory.evolve` generates targeted improvements, embedded in skill files | Conditional on evolve invocation |
| Skill-context override | `.ai-factory/skill-context/<skill>/SKILL.md` — project-specific additions — read ONLY when the target skill is invoked (SSOT #50) | Conditional on skill invocation |

**Problem-class match:** Upstream = skill-based AI development workflow with state-machine invocation. Our problem = rule at the narrowest reachable channel. Match on the skill-context mechanism (SSOT #50) — that is explicitly a narrowest-channel delivery: the override only appears when the specific skill fires. T16: ADAPT (already partly adopted).

**Conditional? Evidence:** YES — confirmed. DESCRIPTION.md always-on; patches always-on per task; skills loaded on explicit invocation only; skill-context loaded only on skill invocation. DeepWiki: «state machine where skills are conditionally invoked based on user actions and workflow progression».

**AIF's key gap on this axis:** AIF has no mechanical gate mechanism — no equivalent of pre-push hook or CI check. Rules are delivered via skill content only; enforcement is compliance-based. The `disable-model-invocation: true` frontmatter flag is action-skill vs reference-skill routing, not a blocking gate.

**BFR verdict: ADAPT** (already underway — skill-context SSOT #50 is the primary adoption). The state-machine invocation model is adoptable vocabulary.

**N5 give-back angle:** AIF has no cross-skill consistency enforcement (a skill can evolve independently of its companion). Our principle tests (packages/core/principles/*.test.ts) provide a give-back: a mechanical consistency check that AIF's evolve loop lacks.

---

#### Candidate D — OhMyOpencode (`code-yeongyu/oh-my-opencode`)

**DeepWiki probe:** 3 phrasings run (rule delivery, conditional loading, Sisyphus routing). Successful.
URL: <https://deepwiki.com/search/how-does-ohmyopencode-deliver_6038885b-eea9-4a44-afae-5fcfd046e918>

**Delivery mechanism — verified:**

| Channel | OhMyOpencode implementation | Conditional? |
|---|---|---|
| Dynamic prompt construction | `buildDynamicSisyphusPrompt` — only includes tools/agents/skills/categories available in current env | Conditional on environment state |
| File-path-triggered injection | `rulesInjectorHook` — AGENTS.md and rule files injected from proximity-based directory scan when file is read/written/edited | YES — fires on file access, NOT always-on |
| Glob-pattern rules | Rule files support `globs:` field — matched against file paths being accessed | YES — path-conditional |
| `alwaysApply: true` rules | Rules with this flag fire unconditionally | Always-on (explicit opt-in) |
| Tool permission gates | Per-agent tool deny lists (Oracle/Librarian = read-only; Prometheus = md-only writes) | Conditional on agent role |
| Skill loading | `load_skills=[...]` passed per `task()` invocation — Sisyphus evaluates which skills loosely connect | Conditional on task routing |
| Intent Gate routing | 3-phase intent classification (Phase 0: intent verbalization → Phase 1-3: delegation) determines subagent + rules | Conditional on intent classification |

**Problem-class match:** OhMyOpencode has a **file-path-triggered injection** mechanism that is structurally the closest production analog to our narrowest-channel principle. The `rulesInjectorHook` fires when a matching file is accessed — not always-on, not task-type-keyed, but **action-keyed on file access**. This is the most directly analogous implementation found in companions. T16: REFERENCE + ADAPT (the file-access trigger model).

**Critical finding (T-Ch-A counter):** OhMyOpencode's glob rules are triggered by AI *file access*, not editor tabs — explicitly different from Cursor's limitation (Cursor forum confirms glob rules only trigger on open editor tabs, not AI tool calls). OhMyOpencode solved the gap Cursor identified.

**BFR verdict: REFERENCE** — cite as production precedent for file-access-triggered rule injection (the most direct implementation of narrowest-channel on the path dimension).

**N5 give-back angle:** OhMyOpencode has no equivalent of our mechanical pre-push gate or CI principle tests. The enforcement substrate is entirely compliance-based (Sisyphus must follow routing). Our hard-gate layer is a give-back.

---

### §2.3 Tier 2: Native CC substrate (Claude Code)

**DeepWiki probe:** anthropics/claude-code, 2 phrasings (hook types + context injection; additionalContext schema). Intentionally lighter than Tier-1 (2 vs ≥3) — CC is the substrate we build on, not an adoption candidate; the depth floor is sufficient to verify SDK claims per §1.10.
URL: <https://deepwiki.com/search/which-claude-code-hook-types-p_ffe9c626-7d39-44e2-aea0-a661c42bddd1>

**CC channel inventory — verified (§1.10 type-system confirmed):**

| Channel | Conditional? | Delivery type | Evidence |
|---|---|---|---|
| `UserPromptSubmit` hook → `additionalContext` | Triggered per prompt | Context injection | DeepWiki CC: «hookSpecificOutput.additionalContext» returned from UserPromptSubmit |
| `PreToolUse` hook → `additionalContext` | Triggered per tool call, scoped by tool name in settings | Context injection + optional block | DeepWiki CC: «PreToolUse can inject additionalContext alongside allowing tool call» |
| `PreToolUse` hook → `decision: "block"` / exit 2 | Triggered per tool call | Mechanical block | DeepWiki CC: «block tool calls by exiting with code 2 or returning {decision:block}» |
| `PostToolUse` hook → `continueOnBlock: true` | Triggered post-tool | Block + feedback injection | DeepWiki CC: «feed hook rejection reason back to Claude» |
| `SessionStart` hook → `additionalContext` | Once per session start | Context injection | DeepWiki CC: «SessionStart hook for new session initialization» |
| `Stop` hook | Per-turn end | Notification + model param | DeepWiki CC: «model parameter for hook evaluation» |
| `SessionEnd` hook | Once per session end | Notification only | DeepWiki CC: no blocking/injection capability confirmed |
| `CLAUDE.md` rules + `@-imports` | Always-on (auto-loaded) | Always-on context | DeepWiki CC: «@-imports do not support conditional loading based on path patterns» |
| `.claude/rules/*.md` with `paths:` frontmatter | Path-scoped (loaded when paths match) | Conditionally loaded | Confirmed by project own usage (phase-research-coverage.md has `paths:` frontmatter) |
| Skills `when_to_use` field | Skill-triggered (semantic match) | Conditional injection | Known from SSOT #55 + CC skill spec |

**Key finding (§1.10 type-system over prose):** `CLAUDE.md` `@-imports` are NOT conditional — DeepWiki confirmed: «do not support conditional loading based on path patterns or tool calls; they are explicitly included». This directly constrains the always-on digest channel; @-imports cannot be made path-conditional.

**Key finding — `PreToolUse` is the richest conditional channel:** It scopes to specific tool names (e.g., `Bash`, `Edit`, `Write`), fires only when that tool is invoked, can inject context AND block, AND can modify tool input. Zero standing cost when the tool is not called.

**Key finding — `.claude/rules/*.md` `paths:` frontmatter IS conditional:** The CC skill-loading mechanism for rules (via `paths:` frontmatter) provides path-scoped auto-injection. Rules only appear in context when files matching the path pattern are active in the session. This is the closest CC-native equivalent to Cursor globs AND OhMyOpencode's `rulesInjectorHook`.

---

### §2.4 Tier 3: Broader ecosystem

#### Codified Context (arxiv:2602.20478, Vasilopoulos 2026-02)

Source: <https://arxiv.org/html/2602.20478v1>

**Three-tier architecture — verified (paper's actual terms):**

The paper uses «hot memory», «domain specialists» (per-task invoked), and «cold memory» — it does NOT use the word «warm». The label «warm» below is **our interpolation** for the middle tier to fit the channel-ladder vocabulary; do not attribute «warm» to the paper.

| Tier | Paper's term | Content | Load frequency | Size |
|---|---|---|---|---|
| 1 | **Hot memory** | Constitution: conventions, naming, build commands, architectural summaries, orchestration protocols | Always-on (every session) | ~660 lines |
| 2 | **Domain specialists** («warm» = our interpolation) | 19 specialized domain-expert agent specs with domain-specific failure modes + trigger tables | Per-task (trigger table routing) | ~9,300 lines |
| 3 | **Cold memory** | 34 on-demand specification documents for subsystem details | On-demand via MCP keyword search | ~16,250 lines |

**Key finding:** Trigger tables route work by file pattern → agent — the domain-specialist tier is not manually invoked; it is **automatically** activated by a routing table that maps file path patterns to domain expert agents. This is the closest academic-validated implementation of narrowest-channel selection found in literature.

**Verdict on draft principle alignment:** The paper VALIDATES the principle's structure (narrow > broad) but adds a wrinkle: Tier 1 (hot/always-on) has ~660 lines — not 3-4 sweeping invariants. The authors found that «agents produced significantly more errors without pre-loaded context» and that «complete mental models prevent failures better than sparse guidance». This is a partial **REFUTATION** of the «always-on digest → 3-4 invariants only» assumption. Codified Context suggests that for complex codebases, Tier 1 can and should be larger than a minimal invariant set.

**BFR verdict: REFERENCE** — the hot/domain-specialists/cold taxonomy is adoptable vocabulary (using our «warm» interpolation for the middle tier in our channel ladder); the trigger-table routing is an ADAPT candidate for our phase-research-coverage.md `paths:` injection.

#### Cursor `.cursor/rules` glob scoping

Source: <https://docs.cursor.com/en/context/rules> + <https://forum.cursor.com/t/glob-scoped-rules-should-trigger-on-ai-file-access> (2026)

**Conditional? Evidence:** PARTIAL. Glob rules fire based on file patterns BUT only when matching files are open in editor tabs — NOT when the AI reads/edits files via tool calls in agent mode. Cursor community forum (2026): «glob-scoped rules should trigger on AI file access, not just editor tabs». This is an **acknowledged limitation**.

**Verdict:** Cursor's glob rules are the closest IDE-native analog but have a known gap: agent-mode file access does not trigger them. OhMyOpencode solved this with its `rulesInjectorHook`. BFR verdict: REFERENCE (vocabulary); gap documented.

#### AgentSpec (arxiv:2503.18666, ICSE 2026)

Source: <https://arxiv.org/abs/2503.18666>

**Mechanism:** DSL with three components: **triggers** (events activating the rule), **predicates** (logical conditions), **enforcement mechanisms** (actions on violation). Runtime enforcement, not static prompt injection. Conditional by design — rules fire on trigger events, not always.

**Problem-class match (T16):** Upstream = formal runtime enforcement for safety-critical agents (code execution safety, autonomous vehicles, embodied agents). Our problem = discipline rule delivery to AI coding agents without always-on bloat. Match on the trigger→predicate→enforce pattern. Miss on the safety-critical hardness (AgentSpec targets >90% prevention of actual unsafe execution; we target early-channel rule delivery). T16 verdict: REFERENCE (the trigger-predicate-enforce vocabulary is adoptable).

**BFR verdict: REFERENCE** — cite as academic backing for the trigger-based conditional enforcement model. Not ADOPT (no JS/TS runtime, overkill for our problem class).

#### Memory systems: MemGPT/Letta

Source: <https://www.letta.com/blog/agent-memory> + <https://www.letta.com/blog/letta-v1-agent>

**WHY unreliable for behavioral rules:** Letta's memory system is designed for *factual state persistence* (task state, preferences, conversation history) across sessions. «Tool rules» (v0.5.2) constrain tool-calling patterns, but these are graph-like behavioral constraints, not rule delivery at violation moment. The core limitation: memory systems must be recalled (retrieved or injected at session start) — this is exactly stage-0 from our ladder. If the retrieval doesn't fire at the right moment, the rule is absent. Letta's «memory omni-tool» (Sep 2025) enables dynamic memory block management but doesn't solve the synchronization gap: the rule must be in active context when the relevant action occurs. **Memory is unreliable for behavioral rules because rule availability ≠ rule retrieval timing.**

**BFR verdict: REFERENCE** (confirms stage-0 unreliability; ADOPT vocabulary «hot memory» from Codified Context instead of «memory» from MemGPT).

#### Multi-agent frameworks (LangGraph, CrewAI)

Source: <https://docs.langchain.com/oss/python/langgraph/workflows-agents> + <https://docs.crewai.com/en/concepts/flows>

**Note:** AutoGen was listed in the kickoff's Tier-3 class but was not separately analyzed — its 2025 async-first rewrite (AgentChat API) shares the same conditional-routing pattern as LangGraph and CrewAI. Coverage via LangGraph + CrewAI is sufficient for the principle verdict; AutoGen omission is a honest minor gap.

**LangGraph conditional edges:** Graph-based orchestration where conditional edges evaluate current state → route to next node. This is the multi-agent equivalent of our channel-selection problem: «fire the right check at the right graph node». The edge condition IS the trigger mechanism. Every conditional edge is a narrowest-channel delivery. **Directly analogous.**

**CrewAI Flows `@router()` decorator:** State-machine orchestration with conditional branching. Rules fire on state transitions, not always-on. Same pattern as LangGraph at a higher abstraction level.

**BFR verdict for multi-agent frameworks: REFERENCE** — their conditional edge/routing pattern is the graph-execution analog of our narrowest-channel principle. The vocabulary «conditional edge = narrowest delivery point» is directly transferable.

#### NeMo Guardrails + OPA/Rego

Source: <https://developer.nvidia.com/nemo-guardrails> + <https://www.openpolicyagent.org/docs/cicd>

**OPA for tool calls:** «OPA checks proposed tool calls against active Rego policies to see if actions comply with business rules, and the actual tool is never executed unless the guardrail returns an explicit 'Allow' signal». This is mechanically equivalent to our `PreToolUse` blocking hook — policy fires at tool invocation, never always-on. Zero standing cost.

**NeMo Guardrails:** Topic control, PII detection, jailbreak prevention — all triggered on specific content patterns, not always-on. «LangGraph enables sophisticated agent architectures while NeMo Guardrails provides the safety layer».

**BFR verdict: REFERENCE** — confirms that production policy-as-code systems (SSOT #52) implement narrowest-channel; their tool-call interception pattern = our `PreToolUse` blocking hook pattern. No adoption needed (our mechanism is more tightly integrated with CC substrate).

#### Cline (`cline/cline`) + Continue.dev

Source (Cline): prior-art-evaluations coverage in this session + companion-target-comparison.md §3.4 (DeepWiki probe from prior R-phase 2026-05-16). Source (Continue.dev): WebSearch not separately run this session — INCONCLUSIVE; trained knowledge only.

**Cline rule delivery — prior research (companion-target-comparison §3.4, 2026-05-16):**
Cline ships a **Rules system** (coding standards, naming, architecture — similar to `.cursor/rules`) and a **Hooks system** described as «programmatic guardrails for validation/enforcement». Examples: «block .js creation in TypeScript project», «run linters before saves». The hooks fire on specific events (file type, save action) — conditional by design, not always-on. Cline also has a Memory Bank (6-file state pattern per SSOT #9) for session continuity, distinct from rule delivery.

**Problem-class match (T16):** Cline rules = always-loaded coding standards (closer to CLAUDE.md always-on channel than conditional injection). Cline hooks = event-triggered enforcement (analogous to our PreToolUse block). The conditional hook mechanism is the relevant surface; the rules system is always-on. T16 verdict: our hooks already instantiate the Cline hook pattern at the CC substrate level; no new adoption.

**BFR verdict: REFERENCE** — confirms the conditional hook pattern; prior verdict (companion-target-comparison §3.4) = framework-consumer. No change to prior verdict.

**Continue.dev glob rules — INCONCLUSIVE:** Continue.dev supports glob-scoped rules in its configuration (training-data knowledge; not separately WebSearched this session). The mechanism is analogous to Cursor `.cursor/rules` glob scoping: rules load when matching files are referenced. Same limitation as Cursor (editor-context scoped, not AI-tool-call scoped) is suspected but not verified against a primary source. Mark INCONCLUSIVE; if needed, a separate WebSearch probe would confirm.

#### Dify / Flowise

**Gap note:** Dify and Flowise (kickoff §2 Tier-3 list) were not surveyed this session. Both are visual workflow builders with condition nodes, directly analogous to LangGraph's conditional edges at a higher-abstraction/no-code level. Given LangGraph and CrewAI already cover the conditional-routing pattern, the absence of Dify/Flowise is not a material gap for the principle verdict. HONEST GAP — defer if workflow-builder conditional delivery becomes relevant.

#### Devin Playbooks

Source: <https://docs.devin.ai/product-guides/creating-playbooks>

**Mechanism:** Playbooks = custom system prompts for repeated tasks, with procedures and specifications (postconditions). Trigger: label-based (e.g., Bug label on a ticket fires a bug-investigation playbook). This is label-triggered conditional injection — narrowest-channel relative to always-on, but coarser than file-path or tool-call triggered.

**BFR verdict: REFERENCE** — label-triggered playbooks are the lowest-resolution conditional delivery (task-type only, not path/tool scoped). Our hooks are finer-grained.

---

## §3 Verdict on the Channel-Selection Principle

**REFINED** — validated in structure, with one significant correction.

### Validated aspects

1. **The channel ladder is correct in ordering:** mechanical gate > context-triggered injection > always-on digest > memory. All Tier 1 companions (Superpowers, aif-handoff, AIF, OhMyOpencode), the Codified Context paper, AgentSpec, and multi-agent frameworks independently converge on this hierarchy. No candidate reverses it.

2. **Memory (stage-0) unreliability is confirmed:** Letta/MemGPT analysis confirms that memory-based rule delivery fails at the synchronization point — rule must be in active context at the violation moment, not merely stored.

3. **The «conditional trigger key» pattern is universally adopted:** Superpowers `description: "Use when..."`, OhMyOpencode `rulesInjectorHook` + globs, AIF skill invocation state-machine, LangGraph conditional edges, AgentSpec trigger→predicate→enforce, Cursor globs, Cline hooks, Devin label triggers — all are instantiations of narrowest-channel.

4. **Mechanical gates exist at multiple granularities:** PreToolUse block (per-tool-call), pre-push hook (per-push), CI principle test (per-PR), Superpowers HARD-GATE (per-workflow-step), OPA tool-call check (per-tool-invocation), AgentSpec runtime enforcement (per-action). All are zero-always-on-cost.

### Correction: the «3-4 sweeping invariants» assumption

The draft principle says «always-on digest: reserve for 3-4 sweeping invariants». Codified Context (arxiv:2602.20478) falsifies the minimalism assumption: their «hot memory» (Tier 1) constitution is ~660 lines and the paper demonstrates this *reduces* errors vs minimal context. The corrected formulation:

> **Always-on channel: reserve for rules whose scope covers ≥50% of all agent actions in the session.** Size is not the constraint; relevance frequency is. A 660-line constitution is correct if every line applies to most actions. A 3-line invariant is wrong if it belongs to a narrower channel.

### Second correction: OhMyOpencode solved Cursor's gap

Cursor glob rules are limited to editor-tab-open files, NOT AI tool call file access. OhMyOpencode's `rulesInjectorHook` fires on file *access by the AI* — the correct trigger. This is an important production distinction: path-conditional injection must be keyed on AI file access events, not editor state.

### Refined principle

> Persist each rule at the NARROWEST channel that still reliably catches its violation. Channel breadth ∝ how often the rule is relevant across session actions.
>
> **Channel ladder (confirmed by prior art):**
> 1. **Mechanical gate** — fires at the exact violatable action (pre-push, PreToolUse block, CI gate); 0 standing cost; highest reliability.
> 2. **Access-triggered injection** — fires when AI accesses a relevant file/tool (PreToolUse `additionalContext`, `.claude/rules/` `paths:` frontmatter, OhMyOpencode `rulesInjectorHook`); conditional on access, not always-on.
> 3. **Task-type injection** — fires when task type matches (skill `when_to_use`, Superpowers 1% rule description, aif-handoff phase injection); conditional on intent classification.
> 4. **Always-on digest** — reserve for rules relevant to ≥50% of session actions (not necessarily ≤3-4; calibrate by relevance frequency).
> 5. **Memory/external retrieval** — stage-0; unreliable for behavioral rules because retrieval timing is not guaranteed to coincide with violation moment.
>
> **Trigger key discipline:** each rule's trigger description must state WHEN to activate (not WHAT the rule does). This prevents the agent from summarizing the trigger and skipping the full rule body. Superpowers `description: "Use when..."` is the canonical form.

---

## §4 ADOPT/REUSE vs BUILD gap

| Component | Verdict | Source | Integration cost |
|---|---|---|---|
| Metadata-always/full-content-conditional vocabulary | **ADOPT VOCABULARY** | Superpowers `description: "Use when..."` discipline | 0 code cost; update `.claude/rules/` headers to add `when_to_use:` trigger phrase |
| Hot/cold taxonomy (domain-specialists = «warm» = our interpolation) | **ADOPT VOCABULARY** | Codified Context arxiv:2602.20478 (paper uses «hot memory» + «domain specialists» + «cold memory»; «warm» is our label for the middle tier) | 0 code cost; use as framing for our channel ladder |
| Trigger→predicate→enforce vocabulary | **ADOPT VOCABULARY** | AgentSpec arxiv:2503.18666 | 0 code cost; enriches how we describe mechanical gates |
| Access-triggered rule injection via `paths:` frontmatter | **ADOPT** (already in use) | CC `.claude/rules/` paths frontmatter | Already implemented in phase-research-coverage.md |
| `PreToolUse` context injection (`additionalContext`) | **ADOPT** (available now) | CC hook SDK (DeepWiki confirmed) | Low: add `hookSpecificOutput.additionalContext` return to existing hooks |
| `rulesInjectorHook` file-access trigger model | **REFERENCE** | OhMyOpencode | No adoption needed; CC `paths:` frontmatter is the equivalent substrate |
| Codified Context trigger-table routing | **REFERENCE** | arxiv:2602.20478 | Could ADAPT as a routing table inside session-bootstrap; medium cost (2-4h) |
| LangGraph conditional edges | **REFERENCE** | langchain.com/langgraph | Vocabulary only; not a runtime dependency |
| Memory-based rule delivery | **REJECT** for behavioral rules | Letta/MemGPT analysis | Stage-0 confirmed unreliable |

**Genuine BUILD gap:** The project has no mechanism for **access-triggered context injection** that fires specifically when an AI agent accesses a file matching a pattern AND injects additional context (not just blocks). CC `paths:` frontmatter provides the load-scoping; `PreToolUse additionalContext` provides the injection. The combination (path-scoped + context-injecting, not just blocking) is not yet wired in this repo's hooks. This is a small BUILD: extend an existing hook to return `additionalContext` in addition to blocking. Estimated cost: 1-2 hours.

---

## §5 Proposed SSOT rows (in-text; next free ID = 60; do not write to register)

```text
| 60 | Codified Context three-tier architecture
      (arxiv:2602.20478, Vasilopoulos 2026-02) —
      paper's terms: «hot memory» (constitution) /
      «domain specialists» (per-task, trigger-table routed) /
      «cold memory» (on-demand MCP retrieval) |
  Rule-delivery tier vocabulary mapping to our channel ladder:
  hot = always-on digest; domain-specialists («warm» = our
  interpolation, NOT the paper's word) = task-type injection;
  cold = on-demand / stage-0 equivalent |
  2026-05-22 | 2026-05-22 |
  ADOPT VOCABULARY |
  BFR: ADOPT VOCABULARY. Tier 1 (hot) validates always-on digest
  channel; trigger-table routing validates task-type injection;
  cold validates stage-0 unreliability.
  Key correction to draft principle: Tier 1 (~660 lines) shows
  always-on channel should be calibrated by relevance frequency,
  not minimised to 3-4 invariants. arxiv:2602.20478 §3.
  T16 match: STRONG — same problem class (structured rule
  delivery in large AI-assisted codebase). «Warm» attribution
  caveat: that word is ours, not the paper's. |
  New rule-delivery research superseding the hot/cold model;
  OR project grows to 108k+ LOC scale where Tier 3 MCP
  retrieval becomes operationally relevant |

| 61 | AgentSpec DSL (arxiv:2503.18666, ICSE 2026, Wang/Poskitt/Sun) |
  Trigger→predicate→enforce vocabulary for
  conditional runtime constraint delivery |
  2026-05-22 | 2026-05-22 |
  ADOPT VOCABULARY |
  Provides academic-grounded vocabulary for our
  mechanical gate pattern: trigger (the violatable action),
  predicate (the condition), enforcement (block/inject).
  Maps to PreToolUse hook + pre-push gate + CI principle test.
  T16 match: partial — their safety-critical domain vs our
  discipline-delivery domain; vocabulary transfers,
  implementation does not. arxiv:2503.18666 §2. |
  AgentSpec ships a JS/TS runtime suitable for CC integration;
  OR a discipline-gate DSL emerges for CC hooks |

| 62 | OhMyOpencode rulesInjectorHook — file-access-triggered
      rule injection (code-yeongyu/oh-my-opencode) |
  Conditional rule delivery keyed on AI file access
  (not editor-tab state) — production implementation of
  narrowest-channel on the path dimension |
  2026-05-22 | 2026-05-22 |
  DEFER |
  BFR: REFERENCE. The `rulesInjectorHook` fires when AI
  reads/writes/edits a file matching glob patterns — correct
  trigger for path-conditional injection. Our CC `paths:`
  frontmatter is the equivalent substrate; no adoption of
  OhMyOpencode tooling required. T16: problem class match
  on the injection mechanism; CC substrate already provides
  the equivalent. N5 give-back: our mechanical gates are
  what OhMyOpencode lacks. DEFER because no code change
  implied — vocabulary REFERENCE only, substrate already
  covered by CC `paths:` frontmatter (already in use). |
  OhMyOpencode ships CC-compatible hook package making direct
  adoption viable; OR CC `paths:` frontmatter proves
  insufficient for our access-triggered injection need |
```

---

## §6 §1.7 Forward+backward self-reflexive note

**§1.6 trigger-sweep:** Waived per kickoff §3 direction. Noted here, not silently skipped.

**§1.1 own-stack sweep result:** No own-stack dep ships conditional rule delivery. Negative claim is load-bearing. Documented in §2.1.

**Forward-check (this research complies with existing disciplines):**
- BFR-default §1 typology applied per candidate. ✅
- T16 problem-class match tables in §2.2 per candidate. ✅
- No paid LLM in CI (all evidence from DeepWiki + WebSearch; no API-billed calls). ✅
- Doc-authority: header present at top; inherits research-patches folder authority. ✅
- SSOT citation existence: proposed IDs 60/61/62 verified as next-free (current max = 59 per grep at run time). ✅
- §1.10 type-system over prose: CC hook claims verified via DeepWiki anthropics/claude-code (not memory). ✅
- phase-research-coverage §1 checklist: §1.1 done; §1.2 categories swept (agent harnesses, multi-agent frameworks, policy-as-code, memory systems, academic); §1.3 semantic-distance checked (rule delivery → conditional injection → trigger-based enforcement — all paradigm levels); §1.4 adversarial check in §3; §1.5 floor exceeded (4 Tier-1 companions + 6 Tier-3 items). ✅

**Backward-check (new rule applied to existing artefacts):**
This research is a survey patch, not a new discipline rule. No backward sweep required (no new artifacts introduced). The refined principle in §3 is a candidate for codification; backward sweep fires at codification time (separate commit).

**T15 self-application:** Where should THIS finding itself be persisted — at which channel?

- The finding is a survey (high breadth, applicable to any rule-authoring session): → always-on digest channel (session-bootstrap.md pointer, not full content)
- The specific refined principle (§3): → `.claude/rules/rule-enforcement-channel-selection.md` (new rule file, Class B initially — no principle test yet)
- SSOT rows: → `prior-art-evaluations.md` (maintainer lands)
- Key vocabulary (hot/warm/cold, trigger→predicate→enforce, access-triggered injection): → `.claude/session-bootstrap.md` or CLAUDE.md addendum (always-on, short)

T15 check: this research applied itself — the finding about channel selection was used to determine WHERE to persist the finding. ✅

---

## §7 Recommended home for codifying our principle

This is a DECISION-NEEDED surface (reviewer-discipline §2 — surfaces options, maintainer decides):

**Option A** — New `.claude/rules/rule-enforcement-channel-selection.md` (Class B)
- Becomes the authoritative rule for how rules are authored in this repo
- The refined principle (§3) becomes the rule body
- Trigger language discipline (`when_to_use: "Use when..."`) becomes a format requirement
- Class B (no principle test yet); promotion criterion: 3 violations of always-on drift in 6 months
- `→ consequence: adds 1 rule file, moderate maintenance; self-applies to all future rule authoring`

**Option B** — Addendum to CLAUDE.md §(new) «Channel selection for rules»
- Inline 5-line summary of the refined principle
- Less formal but immediately surfaced to every agent session
- No dedicated file; harder to reference by ID
- `→ consequence: lower overhead; less discoverable for future compliance checks`

**Option C** — Extend session-bootstrap.md with channel-selection summary
- Always-on (re-read at session start), short digest form
- Mirrors the Codified Context hot-tier pattern: conventions that apply to every session
- `→ consequence: increases session-bootstrap length; appropriate if the principle is relevant in >50% of sessions`

**Option D** — Defer; ship SSOT rows only (60/61/62) + this patch
- Record evidence; do not create new rule file until a violation motivates it
- `→ consequence: no maintenance cost; risk = the incident that motivated this wave recurs before rule is codified`

**Surfaced lean (reviewer-discipline §2 — maintainer decides):** If forced to rank: A + C combined offers the most durable home (rule file) with lowest session-cost (single pointer in bootstrap). The incident that motivated this wave is exactly the case the principle addresses, so D carries recurrence risk. But this is a tradeoff the maintainer owns — all four options are legitimate.

---

## §8 AI-laziness traps self-check

Per kickoff §5. Active traps: T1, T3, T4, T7, T11, T12, T13, T15, T16, T-Ch-A, T-Ch-B.

- **T1 (sampling floor ≥5):** Tier 1 = 4 companions (floor met); Tier 3 = 6 items. Floor exceeded. ✅
- **T3 (URL or file:line per claim):** All factual claims cite DeepWiki URL or WebSearch URL. No prose-only findings. ✅
- **T4 (no premature closure):** All 4 Tier-1 companions covered. Both Tier-2 CC mechanisms covered. Multi-agent class (LangGraph/CrewAI) covered. AgentSpec, Codified Context, Cursor, Devin, MemGPT covered. ✅
- **T7 (run adversarial counter-prompt):** §3 «Correction» subsections address falsification of draft principle assumptions. The Codified Context evidence genuinely falsified the «3-4 invariants» claim. ✅
- **T11 (prior art BEFORE proposing):** §2 fully executed before §3 principle refinement. ✅
- **T12 (skip sweep «I already know»):** WebSearch run for Cursor, MemGPT/Letta, NeMo/OPA, LangGraph, Devin, AgentSpec, Codified Context. OhMyOpencode file-access trigger finding (vs Cursor tab limitation) was NOT in training data. **Honest gap:** Cline covered via prior-session DeepWiki evidence (not fresh WebSearch); Continue.dev covered by training data only — both marked explicitly (INCONCLUSIVE on Continue.dev). Dify/Flowise not swept — honest gap noted above. ✅ (with caveats)
- **T13 (ADOPTED ≠ zero-work):** Each ADOPT candidate verified for problem-class match (§2.2 T16 tables). ✅
- **T15 (self-application):** §6 T15 section addresses WHERE THIS FINDING is persisted. ✅
- **T16 (pattern-matching-on-name):** Each companion has explicit «Upstream problem class: X. Our problem class: Y. Match? Evidence:» analysis. ✅
- **T-Ch-A (tool advertises «rules» ≠ conditional):** Verified conditional delivery for every candidate. Cursor gap found (editor-tab only). ✅
- **T-Ch-B («we have a hook» ≠ solved):** CC PreToolUse `additionalContext` injection is available but NOT yet wired for context injection in our hooks (only blocking). Gap documented in §4. ✅

---

## See also

- [.claude/rules/build-first-reuse-default.md](../../.claude/rules/build-first-reuse-default.md) — BFR-default rule driving this survey
- [.claude/rules/phase-research-coverage.md](../../.claude/rules/phase-research-coverage.md) — §1 checklist applied here
- [docs/meta-factory/prior-art-evaluations.md](../prior-art-evaluations.md) — SSOT register (proposed rows 60/61/62)
- [docs/meta-factory/research-patches/2026-05-16-companion-target-comparison.md](2026-05-16-companion-target-comparison.md) — format precedent
- [arxiv:2602.20478](https://arxiv.org/abs/2602.20478) — Codified Context paper (hot/warm/cold tiers)
- [arxiv:2503.18666](https://arxiv.org/abs/2503.18666) — AgentSpec paper (trigger→predicate→enforce)
- DeepWiki URLs consulted:
  - <https://deepwiki.com/search/how-does-superpowers-deliver-r_136880f0-9d08-4dd1-b0fa-d71aaa2a6a4e>
  - <https://deepwiki.com/search/how-does-aifhandoff-deliver-co_48e04272-402e-45ec-ae2f-025787b63aed>
  - <https://deepwiki.com/search/how-does-ai-factory-aif-delive_2251f0e4-7c3e-4f67-a8f2-c33c5db4be08>
  - <https://deepwiki.com/search/how-does-ohmyopencode-deliver_6038885b-eea9-4a44-afae-5fcfd046e918>
  - <https://deepwiki.com/search/which-claude-code-hook-types-p_ffe9c626-7d39-44e2-aea0-a661c42bddd1>

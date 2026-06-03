<!-- scope:aif-skills-delivery-rphase -->
# aif-skills-delivery — R-phase research patch (industry best-practices survey)

> **Authoritative for:** external industry-practice survey of "how skills/discipline reach an autonomous agent in a container", the six-option verdict table with upstream sourcing, the upstream-vs-ours T16 problem-class table, and the recommended operator+shipped composition — as the *external complement* validating the in-repo candidate scoring already done in [`2026-06-03-aif-operator-asset-access.md`](2026-06-03-aif-operator-asset-access.md).
> **NOT authoritative for:** project goal — see [README.md#why-this-exists](../../README.md#why-this-exists). The in-repo mechanism audit + candidate A–E scoring + DN-1/2/3 decision points — those are owned by the sibling patch [`2026-06-03-aif-operator-asset-access.md`](2026-06-03-aif-operator-asset-access.md); this patch does NOT re-decide them.
> **Date:** 2026-06-03

---

## §0 Context + relationship to the sibling patch (read first — anti-duplication)

When work is dispatched to aif-handoff, the agent runs Claude Code CLI **inside a container** that only sees the repo clone bind-mounted at `/home/www/<repo>` — none of the operator's `~/.claude/skills/orchestrator/` (887 LOC), Superpowers plugins, or the `reviewer` skill are present (`docs/runtime-bridge-setup.md:38-52` "Operator convenience: mount global skills"). The operator wants aif to call the orchestrator and apply reviewer discipline autonomously, the same way the operator does on their own machine.

**This patch is the EXTERNAL/industry complement** to the sibling R-phase patch [`2026-06-03-aif-operator-asset-access.md`](2026-06-03-aif-operator-asset-access.md) (#390+#391, DONE). That patch audited **in-repo** mechanisms and scored candidates A–E (mount / in-repo `agents/*.md` / dispatch-payload / skill-context / hydration), recommending **B+D primary** (in-repo `agents/orchestrator-worker-discipline.md` + skill-context override) plus **A operator-runbook** plus **C follow-on**. It did **not** survey the external industry, did not evaluate an MCP-skills server, and did its T16 check only against in-repo mechanisms.

**This patch adds exactly the three things the sibling did not do**, and is careful not to re-decide anything it already settled (per CLAUDE.md build-vs-reuse + `phase-research-coverage.md §1.11` check-inflight-before-building):

1. **Industry survey (Q1):** how OpenHands, Devin, Cursor, Aider, and the AGENTS.md standard deliver persistent discipline to an agent — and the "skills vs MCP" decision literature.
2. **MCP-skills-server verdict (Q3 option d):** REJECT, with the know-vs-do + token-overhead evidence the sibling never evaluated.
3. **Upstream T16 table (Q4):** problem-class match of *each external upstream* against our problem, validating that the sibling's B+D = "commit the discipline into the repo" is the industry-convergent answer rather than a homegrown invention.

**Net finding (preview):** the sibling's B+D recommendation is **independently corroborated by industry convergence** — every major autonomous coding agent delivers persistent discipline as *files committed in the repo clone*, not as host-injected global state and not as an MCP server. The operator-axis volume mount (A) is the correct *operator-only* convenience, exactly as the sibling scoped it.

---

## §1 Q1 — How the industry delivers persistent discipline into an agent

All claims below carry a URL (T3/T20 — no training-data-only assertions).

### §1.1 The convergence: committed-to-repo config files

The dominant industry pattern is **persistent instructions as version-controlled configuration files committed in the repository**, so every clone/container the agent runs in gets identical behaviour without any host-side global state.

- **AGENTS.md standard.** OpenAI proposed AGENTS.md (Aug 2025), it was donated to the Linux Foundation's Agentic AI Foundation (Dec 2025), and by May 2026 it is read natively by Codex, Cursor, Copilot, Gemini CLI, Aider, Windsurf, Zed and ships in 60,000+ public repos. Canonical pattern: `agents.md` at repo root as SSOT (~200 lines) + thin one-line pointers in `.cursorrules` / `CLAUDE.md`. Evidence: <https://codersera.com/blog/agents-md-vs-claude-md-vs-cursor-rules-comparison-2026/>, <https://www.mdfile.exchange/compare/agents-md-vs-cursor-rules>.
- **Cursor Rules.** Project Rules live in `.cursor/rules/*.mdc`, **version-controlled, scoped to the codebase**, with YAML frontmatter for glob-scoped activation. Evidence: <https://cursor.com/docs/rules>.
- **Aider.** Conventions delivered via a committed `CONVENTIONS.md` (and `.aider.conf.json` for config). Evidence: <https://gist.github.com/0xdevalias/f40bc5a6f84c4c5ad862e314894b2fa6>.

**Industry framing (decisive):** "AI instructions should be treated as configuration files that are versioned, reviewed, and shared across the team" and "major coding agents are rapidly converging on the same architectural primitives." Evidence: <https://docs.devin.ai/essential-guidelines/instructing-devin-effectively>, <https://medium.com/@dave-patten/the-state-of-ai-coding-agents-2026-from-pair-programming-to-autonomous-ai-teams-b11f2b39232a>.

### §1.2 OpenHands (formerly OpenDevin) — the exact two-source split that is our problem

OpenHands (open-source autonomous SWE agent, ~77% SWE-Bench Verified, opens PRs unsupervised) loads instructions from **two sources** — and this split *is* our operator-vs-container split:

1. **Shareable global pool:** `OpenHands/skills/` directory (the shared skills, analogous to the operator's `~/.claude/skills/`).
2. **Repository-committed:** `.openhands/skills/` (V1) or `.openhands/microagents/` (V0), with `.openhands/microagents/repo.md` carrying repository purpose, setup, and structure.

The container/agent always gets the **repo-committed** microagents/skills because they ride the clone; the shareable pool is the host/global layer. Evidence: <https://docs.openhands.dev/openhands/usage/microagents/microagents-repo>, <https://github.com/All-Hands-AI/OpenHands/blob/main/.openhands/microagents/repo.md>, <https://github.com/OpenHands/OpenHands/blob/main/skills/README.md>.

**T16 preview:** OpenHands solves *exactly* our problem class — a shared global skill pool that does not travel + repo-committed skills that do. Its answer is to **commit the must-travel discipline into the repo**. Match: STRONG (see §4).

### §1.3 Devin — Knowledge / Playbooks / Skills, all committed config

Devin uses a three-part persistent-instruction system, all delivered as versioned configuration:

- **Knowledge** — general context Devin should always know (e.g. "use Conventional Commits").
- **Playbooks** — repeatable workflow patterns (e.g. "how to fix a bug ticket").
- **Skills** — `SKILL.md` files telling Devin exactly how to run specific operations for a repo (e.g. "how to run tests").

Evidence: <https://docs.devin.ai/essential-guidelines/instructing-devin-effectively>, <https://medium.com/@nitinmatani22/devin-ai-skills-the-skill-md-files-that-teach-an-ai-agent-your-entire-app-1c619dad0501>. This maps 1:1 onto our split: orchestrator *discipline* = Knowledge/Playbook-shaped; per-repo run instructions = Skill-shaped; both committed.

### §1.4 Skills vs MCP — the decision literature (kills option d)

The "skills vs MCP" question is well-settled in 2026 practice, and it is decisive for our option (d) "MCP server with skills":

- **Skills = "know something"** (coding standards, deployment process, workflows, institutional knowledge) → ship as a committed skill so "every developer who clones the repo gets identical AI behavior," encoding the knowledge "in a fraction of the context window budget."
- **MCP = "do something"** (call an API, query a DB, read a queue, any external system at runtime) → carries auth/credentials, runtime observability.
- **Cost:** "A task that costs your CLI tool 1,000 tokens costs your MCP server 35,000" (35× overhead). MCP is for runtime *actions*, not for delivering static discipline.

Evidence: <https://medium.com/@akshaychame2/mcp-vs-cli-vs-cli-skills-trade-offs-use-cases-and-best-practices-49b9cfd7a556>, <https://thenewstack.io/skills-vs-mcp-agent-architecture/>, <https://www.mindstudio.ai/blog/mcp-vs-cli-agentic-workflows-token-overhead-reliability>, <https://www.speakeasy.com/blog/skills-vs-mcp>.

**Conclusion for our problem:** orchestrator/reviewer discipline is "know", not "do" → it belongs in a committed skill, not an MCP server. Option (d) is a problem-class mismatch (see §4) *and* a 35× cost regression.

---

## §2 Q2 — What aif-handoff / AI Factory do for skill delivery today

Verified via DeepWiki `ask_question` (dual-channel with the in-repo evidence the sibling patch already cited).

### §2.1 aif-handoff runtime — the container sees the clone, not the host

DeepWiki on `lee-to/aif-handoff` (<https://deepwiki.com/search/when-the-runtime-dispatches-an_39c7b41f-37a5-41d3-b82c-cbfa31739d56>):

- **Agent definitions are committed in the project repo** as `.claude/agents/*.md` (planner / implementer / reviewer), loaded by the Claude adapter via `settingSources: ["project"]`. If a runtime can't load agent definitions, it falls back to injecting prompt policies via slash commands.
- **System prompt is dynamically injected** via `execution.systemPromptAppend` at the runtime registry layer (e.g. language directive from `.ai-factory/config.yaml` via `applyLanguageDirective` in `packages/runtime/src/registry.ts`; `REVIEW_DIFF_SCOPE_SYSTEM_APPEND` for review subagents).
- **Volume mounts:** `PROJECTS_DIR` (host) → `PROJECTS_MOUNT` (default `/home/www`) inside the container; the API translates host paths to container paths. **The container's `$HOME` is its own** — the operator's `~/.claude/` is absent unless explicitly bind-mounted.
- **Env vars** inject context/toggles: `HANDOFF_MODE`, `HANDOFF_TASK_ID`, `HANDOFF_SKIP_REVIEW`, `AGENT_BYPASS_PERMISSIONS`.

**Implication:** aif-handoff's own delivery model for discipline = **committed files in the project repo** (`.claude/agents/*.md`, `.ai-factory/config.yaml`) + thin `systemPromptAppend`/env-var injection for short directives. This is the same committed-to-repo convergence as §1.

### §2.2 AI Factory skill install — committed, survives fresh clone/container

DeepWiki on `lee-to/ai-factory` (<https://deepwiki.com/search/how-is-the-aifactoryskillconte_98c11e1d-0122-4470-99af-b100a0860d63>):

- Skills are populated by `ai-factory init` / `ai-factory update`: built-in skills are copied from the npm package `skills/` directory into the **project-local** agent dir (`.claude/skills/` for Claude Code), with template-variable substitution (`{{config_dir}}`, `{{skills_dir}}`, …).
- **They are committed into the consumer repo and therefore survive a fresh clone or container** (DeepWiki, verbatim: "copied into the user's project directory … committed to the consumer repository and will survive in a fresh clone or container").
- There is **no global `~/.claude/skills` in AI Factory's model** — all skill installs are project-local and version-controlled alongside code.

### §2.3 Divergence note (T-AO-K / §1.10) — DeepWiki vs our live-probe on `.ai-factory/skill-context/`

DeepWiki claimed it does **not** see a `.ai-factory/skill-context/<skill>/SKILL.md` path (it pointed to `.claude/skills/<skill>/SKILL.md` instead). **Our own evidence overrides this**: SSOT [#50](../prior-art-evaluations.md) (ADOPT, 2026-05-20) records a **live probe** where a `background:true` `review-sidecar` *read and applied* `.ai-factory/skill-context/` content (3/3 read, 2/2 apply; injection-shaped text correctly refused) in AI Factory v2.11.0; and the sibling patch confirms `install.sh:322-325` copies into `$PROJECT_ROOT/.ai-factory/skill-context/`. Per `phase-research-coverage.md §1.10` (type-system/empirical evidence > prose) and the dual-channel rule, **our live probe wins over DeepWiki's "not mentioned"** — DeepWiki's wiki index is simply stale on this newer path. **Action:** re-confirm the path is still live in the AIF version the operator runs *at I-phase* before building on it (matches SSOT #50's own trigger-to-revisit).

### §2.4 Does the just-shipped `aif-orchestrator-discipline` skill-context cover enough?

The repo already ships (PR #390) `packages/core/templates/shared/skill-context/aif-orchestrator-discipline/SKILL.md` (`@dual-pair` with `agents/orchestrator-worker-discipline.md`). Reading it (`SKILL.md:22-59`): it carries **worker** discipline only — REPORT schema, park-vs-proceed, stage-gate check, §1.7 PR-body requirement. It explicitly says it is **NOT** authoritative for full orchestrator planning ("that is the meta-orchestrator skill (operator-side)", `SKILL.md:8`).

**Gap (the real finding for I-phase):** the shipped skill-context covers aif acting as a **worker**. It does **not** ship the orchestrator **planning** discipline (Phase −1 self-review, Mode A/B triage, quota zones, queue-mode anti-collusion, dispatch) nor a distilled **reviewer-discipline**. So:
- aif-as-worker → covered portably today. ✓
- aif-as-orchestrator (plan multi-stage) or aif-as-reviewer → **not** covered portably; only the operator-axis mount (A) currently delivers the full 887-LOC skill. Whether to ship a *condensed portable* planning/reviewer skill-context is the open I-phase question (§6), and the strategy fork is already surfaced as DN-1/DN-2 in the sibling patch — not re-decided here (reviewer-discipline §2).

---

## §3 Verdict table (six options, industry-sourced)

Options use this patch's kickoff §1-Q3 labelling (a)–(f); the "↔ sibling" column maps to the in-repo candidate the sibling patch scored, so the two patches stay consistent. Recommendation column aligns with the sibling's verdicts.

| Option | Industry source / who does it | Problem-class match (T16 → §4) | Portability | Resilience (survives restart) | Effort | ↔ sibling | Recommended? |
|---|---|---|---|---|---|---|---|
| **(a) Volume mount `~/.claude/skills`→container** | aif-handoff `PROJECTS_DIR→/home/www` mount model (DeepWiki §2.1); recipe already in `docs/runtime-bridge-setup.md:38-52` | EXACT *for operator* (full 887-LOC skill verbatim); MISMATCH for consumer (no such host files) | operator-only | yes (mount persists in compose) | 2 lines | A | **YES — operator axis** |
| **(b) Env-var / `systemPromptAppend` injection at dispatch** | aif `HANDOFF_MODE` / `applyLanguageDirective` (DeepWiki §2.1); SSOT [#27](../prior-art-evaluations.md)/[#97](../prior-art-evaluations.md) | Partial — fits *short directives/toggles* only; 887 LOC will not fit an env var | portable, tiny payload | per-dispatch | low | (part of A/C surface) | PARTIAL — toggles only, not the skill |
| **(c) Skill/discipline committed to repo** | OpenHands `.openhands/skills` §1.2; Cursor `.cursor/rules` §1.1; Aider `CONVENTIONS.md`; Devin `SKILL.md` §1.3; AGENTS.md std §1.1; AIF `ai-factory init`→`.claude/skills`+`.ai-factory/skill-context` §2.2 (SSOT [#50](../prior-art-evaluations.md) ADOPT) | STRONG — industry-convergent; "know"-class discipline; T16 #50 exact | portable / AI-agnostic | yes (in the clone the mount exposes) | medium (PR #390 started worker slice; planning/reviewer slice still a gap §2.4) | **B + D** | **YES — shipped axis (primary)** |
| **(d) MCP server with skills** | "skills vs MCP" literature §1.4 (skills=know, MCP=do; 35× token overhead) | MISMATCH — MCP is for runtime *actions*, not static discipline | portable but wrong tool | runtime call each turn | high | (not scored by sibling) | **REJECT** |
| **(e) Pre-dispatch hydration (host copies skills into clone)** | `scripts/link-coordination.sh` CANON-sync precedent (SSOT [#110](../prior-art-evaluations.md) ADAPT) | Partial — operator-side glue; consumers lack the source files | operator-only | per-dispatch re-run | medium | E | DEFER (superseded by (a) operator / (c) shipped) |
| **(f) Skill bundling in kickoff payload** | aif `buildKickoffSpec` (`kickoff.ts:21-40`, sibling §1) — would inline content per dispatch | Partial — bloats every kickoff; drift vs the SSOT skill | portable but duplicative | per-task | low | C | DEFER for *pointers only*; never the full skill |

---

## §4 Q4 — Upstream T16 problem-class table (explicit X-vs-Y)

Per `ai-laziness-traps.md §2 T16` — name similarity is not problem-class match; each row states upstream's problem (X), ours (Y), and the evidenced verdict.

| Upstream | Upstream problem class X | Our problem class Y | Match? | Evidence |
|---|---|---|---|---|
| **OpenHands microagents/skills** | Shared global skill pool that does not travel + repo-committed `.openhands/skills` that the agent always gets in the clone | Operator global orchestrator skill that does not reach the container + must-travel discipline that should | **STRONG** — structurally identical (global pool vs committed-in-clone). Their fix = commit the must-travel discipline. | §1.2 — <https://docs.openhands.dev/openhands/usage/microagents/microagents-repo> |
| **Devin Knowledge/Playbooks/Skills** | Persistent agent instruction delivered as versioned config (Knowledge=always-know, Playbook=workflow, Skill=per-repo ops) | Orchestrator discipline (always-know) + dispatch workflow + per-task run discipline | **STRONG** — same three-layer shape; all committed config | §1.3 — <https://docs.devin.ai/essential-guidelines/instructing-devin-effectively> |
| **AGENTS.md standard** | Vendor-neutral committed instruction file every agent reads in the clone | Project discipline every aif dispatch must follow | **STRONG** on delivery channel (committed, agent-agnostic); our content is richer (multi-stage orchestration) | §1.1 — <https://codersera.com/blog/agents-md-vs-claude-md-vs-cursor-rules-comparison-2026/> |
| **Cursor `.cursor/rules/*.mdc`** | Glob-scoped, version-controlled rule files activated by path | Discipline that should activate when the aif agent touches relevant surfaces | **STRONG** on mechanism (committed + scoped); we already mirror it via `.claude/rules/*.md` + `inject-matching-rule.sh` | §1.1 — <https://cursor.com/docs/rules> |
| **MCP-as-skills-delivery** | Runtime tool calls — "do something" (API/DB/queue) with auth + observability | Deliver static "know" discipline into the agent | **MISMATCH** — wrong tool class; 35× token cost; credentials irrelevant to discipline | §1.4 — <https://thenewstack.io/skills-vs-mcp-agent-architecture/>, <https://www.mindstudio.ai/blog/mcp-vs-cli-agentic-workflows-token-overhead-reliability> |
| **aif `PROJECTS_DIR→/home/www` volume mount** | Make host project files available inside the container | Make the operator's host *global skills* available inside the container | **EXACT for operator** (it literally is host files); **MISMATCH for consumer** (consumer has no such host files) → operator-axis only | §2.1 — DeepWiki <https://deepwiki.com/search/when-the-runtime-dispatches-an_39c7b41f-37a5-41d3-b82c-cbfa31739d56> |

**Net:** every "know"-class upstream converges on **commit-the-discipline-into-the-repo** (option c). MCP (d) is a class mismatch. Volume mount (a) matches *only* the operator axis. This is precisely the sibling patch's B+D-primary + A-operator split, now externally corroborated.

---

## §5 Recommended composition

**Recommended (aligned with sibling patch §4, now externally validated):**

- **Operator axis → (a) volume mount.** Already documented at `docs/runtime-bridge-setup.md:38-52`; 2 lines in `docker-compose.override.yml` give the operator's own aif container the full 887-LOC orchestrator skill + Superpowers + reviewer verbatim. Per BFR §1.1 operator-axis default ("use companions maximally; it is the maintainer's machine"), this is `ADOPT`-on-operator. Zero consumer obligation.
- **Shipped axis → (c) skill-context committed to repo (= sibling B+D).** Extend the just-shipped `aif-orchestrator-discipline` skill-context (currently worker-only, §2.4) with the *condensed* orchestrator-planning + reviewer-discipline slices the gap analysis surfaces — each dual-paired to a portable `agents/*.md` SSOT (`dual-implementation-discipline.md §7`), installed via `ai-factory init` into `.ai-factory/skill-context/` (SSOT #50 channel, live-probe-verified §2.3). This is the industry-convergent answer (§4): OpenHands/Devin/Cursor/Aider/AGENTS.md all commit the discipline.
- **Pointer-only kickoff payload → (f) for pointers, never the full skill.** Kickoffs carry a one-line reference to the committed skill-context, not an inlined copy (avoids `#sync-by-copy-paste` drift vs the SSOT skill).
- **REJECT (d) MCP-skills-server** — know-vs-do mismatch + 35× token overhead (§1.4).
- **DEFER (e) hydration** (the mount is simpler operator-side; B+D is portable shipped-side) and **(b) env-vars** except for behavioural toggles already in use (`HANDOFF_MODE`, `AGENT_AUTO_REVIEW_STRATEGY` per SSOT #97).

**One-paragraph summary:** ship operator-convenience via the documented volume mount (full skill verbatim, operator-only) **and** the portable shipped-axis fix via committed skill-context dual-paired to `agents/*.md` (the industry-standard "commit the discipline" pattern). Reject MCP; keep env-vars to toggles; keep kickoff payload to pointers.

**Wrong if:** the aif agent already receives sufficient discipline from kickoff content alone (empirically falsified by the `meta-orchestrator-refactor §4c` incident that originated the sibling umbrella) — OR aif-handoff changes the committed-skill read path from `.ai-factory/skill-context/` / `.claude/skills/` (would invalidate (c); covered by SSOT #50's trigger-to-revisit) — OR the industry de-converges from committed config back to host-injected global state (no current signal; AGENTS.md adoption is still accelerating, §1.1).

---

## §6 Open questions for I-phase (surface only — do NOT decide; reviewer-discipline §2)

1. **Worker-only or full orchestrator?** Does aif need to act as **orchestrator** (plan multi-stage) and **reviewer** inside the container, or only as a **worker**? If worker-only, PR #390's skill-context already covers it portably and the only shipped-axis work left is a reviewer-discipline skill-context. If orchestrator, a condensed planning skill-context is needed. **This is the sibling patch's DN-1/DN-2 (maintainer-owned); this patch does not pre-empt it.**
2. **Condensation ratio.** The full orchestrator skill is 887 LOC; worker discipline distilled to ~60 lines (`aif-orchestrator-discipline/SKILL.md`). What is the minimal-viable *portable* planning/reviewer subset that is sufficient without copying the operator-private full skill (T-AOA-A authorship line from the sibling)? Needs a bench at I-phase.
3. **Promote the operator mount from docs to a shipped `docker-compose.override.yml.example`?** One-step operator setup vs keeping it prose-only (sibling DN-3 touches this; this patch only notes the industry precedent — committed examples are normal, e.g. AGENTS.md repos ship example config).
4. **Re-probe `.ai-factory/skill-context/` liveness** in the operator's current AIF version before building D on it (§2.3 divergence; SSOT #50 trigger).

---

## §7 §1.7 Self-review (Forward + Backward + Self-application/T15)

**Forward-check applied** — does this research-patch comply with active disciplines?
- **build-first-reuse-default §3 / CLAUDE.md build-vs-reuse:** this patch is research only (no capability commit, no dependency); its *recommendation* is `(c)`=REUSE the industry-standard committed-config pattern + the existing SSOT #50 channel, and explicitly REJECTs the one BUILD-heavy option (d MCP). DeepWiki ×2 + WebSearch ×4 phrasings run before every verdict (§1-§4). ✓
- **phase-research-coverage §1.11 (verify-before-build):** read the in-flight sibling patch `2026-06-03-aif-operator-asset-access.md` *before* writing, to avoid `#parallel-evolution-creep`; scoped this patch to the three things the sibling did not do (§0). ✓
- **phase-research-coverage §1.10 (empirical > prose):** §2.3 resolves the DeepWiki-vs-live-probe divergence in favour of the SSOT #50 live probe. ✓
- **reviewer-discipline §2:** all strategy forks (worker-vs-orchestrator scope, mount-in-scope) are surfaced as §6 open questions / deferred to the sibling's DN-1/2/3 — **not** decided here. ✓
- **no-paid-llm-in-ci:** every recommended channel ((a) mount, (c) committed files, (f) pointers) is deterministic / session-bundled; no API-billed call proposed. ✓
- **doc-authority-hierarchy §3:** this file carries the scope annotation (line 1) + Authoritative-for / NOT-authoritative header. ✓

**Backward-check applied** — scope of this new artefact's claims swept completely, not at the 3-5 floor: the verdict table (§3) covers **all six** options the kickoff §1-Q3 enumerated (a–f), not a sampled subset; the T16 table (§4) covers **every** upstream surfaced by the survey (OpenHands, Devin, AGENTS.md, Cursor, MCP-as-delivery, aif mount). No existing artefact is silently superseded — this patch *complements* (does not overwrite) the sibling patch and cites SSOT #50/#67/#97/#110 by ID without mutating them (append-only register per CLAUDE.md Artifact Ownership Contract).

**Self-application (T15)** — does this research apply to future aif R-phases? **Yes, and recursively consistent.** This very R-phase runs **operator-side** precisely because it needs DeepWiki + WebSearch MCPs that are *not in the container* — the same operator-vs-container asset split the patch studies. The patch's own delivery split (operator-mount for MCP-dependent/full-skill needs; committed files for portable discipline) is exactly the split that governs *where* a phase runs: research/MCP-dependent phases run operator-side, execution phases run in-container against committed skill-context. The finding describes its own dispatch. **Recursive** check holds: were the recommended (c) shipped, a future aif-dispatched R-phase that only needs *committed* discipline (not live MCPs) could run fully in-container — and one that needs live web research still correctly stays operator-side. No contradiction.

---

## REPORT
- Status: DONE
- Deliverable: `docs/meta-factory/research-patches/2026-06-03-aif-skills-delivery.md` — industry best-practices survey (OpenHands/Devin/Cursor/Aider/AGENTS.md + skills-vs-MCP), six-option verdict table, upstream T16 problem-class table, recommended operator+shipped composition; positioned as the external complement to the sibling `2026-06-03-aif-operator-asset-access.md` patch.
- Evidence: §1 (6 WebSearch-sourced URLs), §2 (2 DeepWiki query URLs + `runtime-bridge-setup.md:38-52`, `aif-orchestrator-discipline/SKILL.md:22-59`), §3-§4 verdict + T16 tables, §5 recommendation aligned with sibling B+D, §7 §1.7 self-review.
- BLOCKER: none.
- MINOR: (1) the shipped `aif-orchestrator-discipline` skill-context covers the **worker** slice only — the orchestrator-**planning** + reviewer slices remain a portable-shipping gap (§2.4), surfaced as I-phase open question §6.1 and mapped to the sibling patch's DN-1/DN-2 (maintainer-owned, not decided here). (2) DeepWiki's wiki index is stale on the `.ai-factory/skill-context/` path — re-probe liveness at I-phase (§2.3).

<!-- scope:meta-orchestrator-prior-art -->
# Research patch — `/meta-orchestrator` skill prior-art survey

> **Class:** R-phase deliverable (research-patch). No code changes; no skill files written; verdict only.
> **Authoritative for:** the build-vs-reuse verdict on a single-invocation `/meta-orchestrator [<umbrella>]` skill capability + integration sketch + I-phase kickoff name proposal.
> **NOT authoritative for:** project goal (see [README.md#why-this-exists](../../../README.md)); the eventual SKILL.md content (lives in the I-phase wave); orchestrator skill itself (lives at `~/.claude/skills/orchestrator/`, agent-uncommittable).
> **Origin:** 2026-05-23 maintainer dialogue. Kickoff: [.claude/orchestrator-prompts/meta-orchestrator-prior-art/kickoff.md](../../../.claude/orchestrator-prompts/meta-orchestrator-prior-art/kickoff.md). Driver: SSD iteratively, Phase -1 cold-review applied (REVISE → 8 amendments → GO).
> **Tags:** `#meta-orchestrator` · `#companion-survey` · `#build-vs-reuse`

---

## §0 Why this wave

Existing [`orchestrator` skill](/Users/art/.claude/skills/orchestrator/SKILL.md) covers ≈70% of meta-orchestration via Queue mode but has **four named gaps** ([kickoff §7.14](../../../.claude/orchestrator-prompts/meta-orchestrator-prior-art/kickoff.md)): plan-actuality verification (§7.2), cross-umbrella priority resolution (§7.3), auto-generated launch-table + meta-kickoff (§7.4-§7.5), stage-gate-vs-flat-queue distinction with real git PR checks (§7.7). Maintainer wants those gaps closed by **one slash-command invocation** with a single optional argument: `/meta-orchestrator [<umbrella>]`.

Before BUILDing — check companions ([build-first-reuse-default.md §1](../../../.claude/rules/build-first-reuse-default.md)). This patch is the BFR §3 mechanism applied to the meta-orchestrator capability.

---

## §1 Per-surface verdict table

> **New SSOT rows start at #66+** ([wave-sequencing-plan §0 collision note](../wave-sequencing-plan.md): #64/#65 taken by N7; N8 A-phase rows also pending at #66+ — this patch claims a contiguous block #66-#70 for **REFERENCE+/ADOPT-VOCABULARY candidates only**). REJECTed candidates (APM, GitHub Agentic Workflows, LangGraph/CrewAI/AutoGen at the framework level, all the cross-domain CI-orchestrators & PM-tools) **do not get SSOT rows** — per [prior-art-evaluations.md §3 «Append-only register»](../prior-art-evaluations.md) policy, REJECTs without future-revisit value are recorded in this patch's audit trail (§1 table evidence column + scratchpads) rather than the SSOT. `addyosmani/agent-skills /ship` is a borderline REFERENCE-grade source for §7.7+§7.8 sub-pattern — its SSOT row is **deferred to I-phase admission** (claim only if the BUILD wave actually adopts the GO/NO-GO synthesis shape, per [build-first-reuse-default.md §5](../../../.claude/rules/build-first-reuse-default.md) «SSOT row at capability commit moment, not before»).

| # | Surface | Verdict | §7 match | Key evidence | New SSOT row |
|---|---|---|---|---|---|
| 1 | **Superpowers v5.1.0** (`obra/superpowers`, 14 skills) | **BUILD with REFERENCE** to 6 skills + ADOPT-VOCABULARY from `writing-plans` + `writing-skills` | ~18% (highest single-skill match = `writing-plans` per scratchpad §6) | Per-skill SKILL.md read (installed filesystem, higher-fidelity than DeepWiki extraction would provide); T-MO-A (executing-plans for ONE plan), T-MO-B (using-superpowers passive router) confirmed and rejected. WebSearch ×3 returned zero post-v5.1.0 meta-orchestrator. `/tmp/meta-orch-survey-1-superpowers.md` (457 lines) | not needed — SSOT #64/#65 settled |
| 2 | **AI Factory** (`lee-to/ai-factory`, 11 commands at `aif.cutcode.dev`) | **REFERENCE** (planner/implementer/reviewer vocabulary + worktree-per-feature pattern) | 14% (2/14 PARTIAL or WEAK, 12/14 MISSING) | DeepWiki Q1: «does not appear to have a single 'meta-orchestrator' slash command… no plan-preflight… no cross-umbrella priority resolution». 3 DeepWiki queries + landing page + WebSearch ×3 corroborate. T-MO-C 3 attempts ACCESSIBLE. `/tmp/meta-orch-survey-2-aif.md` (156 lines) | **#66** |
| 3 | **aif-handoff** (`lee-to/aif-handoff`, Kanban runtime) | **REJECT** (T16 structural — server-side autonomous vs session-bound producer) | 22% (7 PARTIAL / 5 MISSING / 2 WEAK) | 4 DeepWiki queries + GitHub README WebFetch. §7.9 (no code-writing) vs aif-handoff's primary function; §7.10 (zero infra) vs Docker+DB requirement. SSOT #27/#28/#29/#30/#43/#46 settled, NOT re-litigated. `/tmp/meta-orch-survey-3-aif-handoff.md` (171 lines) | **#67** |
| 4 | **OhMyOpencode** (`code-yeongyu/oh-my-openagent`, 59.1k★, Prometheus/Atlas/Oracle/Momus) | **REFERENCE + ADOPT-VOCABULARY** (blocking-gate pattern, Parallel Execution Waves vocab, boulder.json continuity) | ~30% (1 WEAK + 3 MISSING on the 4 §7.14 named gaps) | 4 DeepWiki queries + ohmyopenagent.com WebFetch + WebSearch ×3. `ohmyopenagent.com` confirmed same project as `oh-my-openagent` (renamed from `oh-my-opencode`; wrangler.toml + dual npm). Substrate mismatch (OpenCode plugin ≠ CC); session-bound ≠ cross-umbrella. SSOT #61 settled (rulesInjector), NOT re-litigated. `/tmp/meta-orch-survey-4-ohmyopencode.md` (162 lines) | **#68** |
| 5 | **Claude Code native primitives** (`code.claude.com/docs/en/`) | **ADOPT primitives** (skill mechanism for §7.1+§7.10, `!shell` injection for §7.2, `context: fork`+`agent:` for §7.6, `Stop`+agent-teams hooks for §7.7) + **BUILD logic**. **Falsifier:** wrong if CC renames/removes the `.claude/skills/` mechanism, `arguments:` frontmatter, `disable-model-invocation: true`, `!shell` injection contract, or `${CLAUDE_SKILL_DIR}` substitution before I-phase admission — verify against [`code.claude.com/docs/en/skills.md`](https://code.claude.com/docs/en/skills.md) at I-phase start. | §7.1 FULL · §7.10 FULL · §7.2 STRONG PARTIAL · §7.6 PARTIAL · §7.7 PARTIAL · §7.3/§7.4/§7.5 MISSING (logic, not primitive) | `skills.md` (slash command = skill since merge), `commands.md` (`/batch`, `/plan`, `/ultraplan`, `/goal` all T16-eliminated), `sub-agents.md`, `hooks.md`. Agent-teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) already enabled in user env. `/tmp/meta-orch-survey-5-cc-native.md` (150 lines) | not needed — CC primitives are substrate-as-shipped |
| 6 | **State-of-art sweep** (7 WebSearch phrasings + 4 DeepWiki probes + 5 cross-domain assessments + 3 counter-probes) | **BUILD confirmed** (no ADOPT candidate falsifies provisional verdict) + **REFERENCE** Bernstein DAG, ComposioHQ `getMergeability()`, addyosmani/agent-skills `/ship` | best ~25% (Bernstein §7.4+§7.7); zero candidates address §7.2/§7.3/§7.5 | Bernstein YAML `depends_on` + janitor gate (§7.4 ~20%, §7.7 ~25%) · APM Bootstrap Prompt (§7.5 ~10%) REJECT · ComposioHQ `getMergeability()` signals REFERENCE · `/ship` parallel fan-out + GO/NO-GO REFERENCE · GH Agentic Workflows `/plan` naming-only REJECT (CI-side) · Kenji practitioner article (46 manual Ralph scripts) = demand evidence. `/tmp/meta-orch-survey-6-state-of-art.md` (220 lines) | **#69** Bernstein · **#70** ComposioHQ/agent-orchestrator |

---

## §2 Composite verdict — **BUILD on CC primitives, REFERENCE 9 upstream sources, ADOPT-VOCABULARY 3**

### Rationale

**No upstream tool implements the composite §7 spec.** Six independent surfaces, surveyed via dual-channel evidence (DeepWiki + WebFetch + WebSearch ≥3 phrasings each), all returned: closest match ≤30%, structural mismatch on at least 3 of 4 named gaps (§7.14), no slash-command + plan-preflight + cross-umbrella priority + Mode A/B/SDD launch-table combination ships anywhere indexed as of 2026-05-23. The provisional BUILD verdict was actively falsification-tested via Surface 6's adversarial counter-prompt (3 close candidates checked: Release-Manager / Workflow-Engine / Agentic-IDE) — all null.

**CC primitives ARE the substrate.** Surface 5 found that `.claude/skills/` + `arguments:` + `disable-model-invocation: true` + `${CLAUDE_SKILL_DIR}` deliver §7.1 (trigger) and §7.10 (one-button-install) at **FULL match** — no adaptation needed. The `!shell command` injection mechanism delivers §7.2 (plan-preflight) at **STRONG PARTIAL** — primitives present, only the comparison logic to author. The `context: fork` + `agent:` skill dispatch delivers §7.6 sub-wave routing. CC `Stop` hook + agent-teams `TaskCompleted`/`TeammateIdle` hooks deliver §7.7 stage-gate primitives. The **payload** (orchestration logic: §7.3 priority, §7.4 launch-table decision rules, §7.5 meta-kickoff authoring, §7.7 sequencing, §7.8 reviewer handoff) is what's missing from every upstream tool — and is exactly what the I-phase BUILDs as SKILL.md content + bundled scripts.

**T16 problem-class check (composite):**
- Upstream classes surveyed: single-session multi-agent execution (SP, OhMyOpencode, LangGraph/CrewAI/AutoGen), single-feature plan execution (AIF), server-side autonomous Kanban (aif-handoff), pre-merge single-changeset gate (`/ship`), YAML DAG runner (Bernstein), CI-side workflow (GitHub Agentic Workflows).
- Our class: session-bound, cross-umbrella, repo-aware meta-launcher that verifies plan currency vs live GitHub state and generates a Mode-aware launch-table.
- **No upstream class matches the composite.** Sub-pattern matches at §7.7 (ComposioHQ, OhMyOpencode Oracle/Momus, `/ship`) and §7.4 (Bernstein DAG) are REFERENCE-grade only.

### Falsifier (load-bearing)

This verdict is **wrong if** an Anthropic-published bundled skill or community plugin lands in the CC marketplace between 2026-05-23 and the I-phase kickoff date that implements (a) `wave-sequencing-plan.md` currency verification against `gh pr list --search` AND (b) cross-umbrella priority scoring AND (c) Mode A/B/SDD launch-table generation as a single slash-command. Falsify by running `/plugin marketplace update claude-plugins-official` + `code.claude.com/docs/en/commands.md` changelog check before authoring the I-phase wave.

This verdict is **also wrong if** the manual Ralph-script wave-sequencing practice (Kenji 2026-04, 46 scripts cited) was a hallucinated trend with no actual practitioner base — Surface 6 took the article as positive demand evidence; if it was a single-author opinion piece misread as community signal, the BUILD motivation weakens (but the four §7.14 gaps remain real regardless).

---

## §3 Leapfrog summary — where we leverage, where we exceed

Per kickoff §1 leapfrog arm: even though the composite is BUILD (no candidate ≥40%), each REFERENCE source contributes a specific design vocabulary or sub-pattern. The «exceeds» column states the project-specific value-add the BUILD I-phase ships beyond each upstream.

> **Source-count footnote for the §2 headline («REFERENCE 9 sources, ADOPT-VOCABULARY 3»):** REFERENCE-9 = (a) 5 Superpowers skills with verdict REFERENCE — `dispatching-parallel-agents`, `subagent-driven-development` (also SSOT #64), `using-git-worktrees` (also SSOT #65), `requesting-code-review`, `finishing-a-development-branch`; (b) AI Factory composite; (c) OhMyOpencode (REFERENCE half — separate from its ADOPT-VOCABULARY half); (d) Bernstein; (e) ComposioHQ. ADOPT-VOCABULARY-3 = SP `writing-plans` + SP `writing-skills` + OhMyOpencode (blocking-gate vocab + boulder.json + Parallel-Execution-Waves section format). `addyosmani/agent-skills /ship` is a sub-pattern REFERENCE — counted in §1 row 6 evidence column, not in the headline-9 (deferred SSOT registration; see §1 SSOT-block note). Kenji practitioner article is motivation-evidence, not an upstream REFERENCE source — counted neither in 9 nor in 3.

| REFERENCE source | §7 contribution | We leverage | We exceed by |
|---|---|---|---|
| **CC skill primitive** (`skills.md`) | §7.1, §7.10 | `arguments` + `argument-hint` + `disable-model-invocation` + `${CLAUDE_SKILL_DIR}` — verbatim ADOPT | (no leapfrog — direct match) |
| **CC `!shell` injection** | §7.2 | Live `gh pr list` / `git status` / kickoff-ls output inlined before skill prompt processes | Adding plan-comparison + drift detection logic in skill body; no upstream does plan-currency check |
| **CC `context: fork` + `agent:`** | §7.6 single-subagent | Single-agent sub-wave dispatch | Multi-subagent parallel via main-session Mode A × N (nesting constraint workaround); upstream skill primitive doesn't address it |
| **CC `Stop` hook** + agent-teams `TaskCompleted`/`TeammateIdle` | §7.7 stage-gate primitive | Cross-turn blocking decision | Adding real `gh pr list --search 'is:merged'` content check; CC hooks don't ship the git-state logic |
| **SP `writing-plans`** | §7.5 meta-kickoff format vocabulary | Goal/Architecture/Tech Stack header + checkbox tasks + Execution Handoff section | Adding §5 AI-traps (principle 12 mandatory), stage-gate rules expressed as real git checks, recursive-self-application clause, stop-conditions per stage |
| **SP `writing-skills`** | I-phase authoring standards | TDD-for-skills methodology + CSO discipline + SKILL.md format | (consumed by I-phase wave, not by skill content) |
| **SP `dispatching-parallel-agents`** | §7.6 Mode B branch | Parallel fan-out mechanism | Adding worktree-isolation per §7.6 Mode B rules + Mode A/B decision rule per sub-wave (not just N parallel agents) |
| **SP `subagent-driven-development`** (SSOT #64) | §7.6 SDD-row dispatch | Implementer + spec-reviewer + code-quality-reviewer cycle | Adding §7.4 SDD?-column gating heuristic (1-2 tasks → not-SDD; 3+ → SDD) |
| **SP `using-git-worktrees`** (SSOT #65) | §7.6 Mode B worktree setup | Step-0 already-active-worktree detection + Step-1b `.worktrees/` gitignore check | (consumed verbatim; Mode B dispatch invokes the SP skill, doesn't re-implement) |
| **SP `requesting-code-review`** | §7.8 Phase -1 dispatch template | Reviewer-subagent dispatch with git SHA references | Adding strategy-fork-surface discipline (reviewer surfaces decisions, doesn't pick — per `.claude/rules/reviewer-discipline.md`) |
| **SP `finishing-a-development-branch`** | §7.12 output artifacts | PR-creation template | Adding meta-orchestrator state.md + meta-kickoff.md + inline report artifacts; SP only ships the PR template |
| **OhMyOpencode Prometheus/Atlas/Oracle/Momus** (3-layer, 59.1k★) | §7.7+§7.8 architecture vocabulary | «Blocking oracle gate» + «iterative reviewer loop until APPROVE» + «Parallel Execution Waves» section format + boulder.json continuity | (1) CC substrate vs OpenCode plugin; (2) real `gh pr` gates vs in-session agent QA; (3) cross-umbrella scope vs single-plan; (4) Mode A/B/SDD launch-table vs category routing |
| **AIF planner/implementer/reviewer** (`/aif-plan`+`/aif-implement`+`/aif-verify`) | §7.5+§7.6 role vocabulary | Role names + worktree-per-feature pattern (via `--parallel`) | (1) Cross-umbrella priority resolution (AIF has none); (2) `gh pr list` plan-currency verification; (3) Mode A/B/SDD typology; (4) `.claude/skills/` install path vs `.ai-factory/` |
| **Bernstein** (sipyourdrink-ltd/bernstein) | §7.4 DAG + §7.7 janitor pattern | YAML `depends_on` task graph structure | (1) CC skill vs Python CLI runtime; (2) markdown plan-as-source vs YAML plan-as-binding; (3) cross-umbrella vs single-plan; (4) `gh pr list` actuality verification vs YAML schema validation |
| **ComposioHQ/agent-orchestrator** | §7.7 PR readiness signal set | `getMergeability()` = CI status + review decisions + draft state + merge conflicts | Adding `is:merged` between-stages check (ComposioHQ is intra-PR routing, not between-stage sequencing) |
| **addyosmani/agent-skills `/ship`** | §7.7+§7.8 GO/NO-GO pattern | Parallel fan-out → synthesize → GO/NO-GO verdict shape | Adding forward-looking plan-currency check (`/ship` is backward-looking single-changeset readiness); explicitly DIVERGING from `/ship`'s philosophical rejection of router-personas — our `/meta-orchestrator` IS a router-skill by design |
| **Kenji 2026-04 article** | §0 demand evidence | Validation that wave-sequencing problem class is real + tool-shaped gap | (motivation-only; no implementation) |

---

## §4 Integration sketch — how the BUILD I-phase maps onto §7 spec

> Not authoritative for the actual SKILL.md content — that's the I-phase deliverable. This section sketches the skeleton + the CC-primitive bindings the I-phase will inherit verbatim.

### §4.1 Filesystem layout

```text
.claude/skills/meta-orchestrator/
├── SKILL.md                              # main slash-command logic (the payload)
├── templates/
│   ├── meta-kickoff.template.md          # generated by §7.5; uses ${CLAUDE_SKILL_DIR}
│   └── state.md.template
└── helpers/
    ├── plan-currency-check.sh            # §7.2 git+gh+plan diff script
    ├── priority-score.sh                 # §7.3 multi-criteria scorer
    └── launch-table-generator.sh         # §7.4 Mode A/B/SDD decision rules
```

### §4.2 SKILL.md frontmatter (CC primitive verbatim)

```yaml
---
name: meta-orchestrator
description: Plan-preflight + cross-umbrella priority + launch-table + stage-gate-aware dispatch for multi-wave umbrellas. Use when invoking /meta-orchestrator [<umbrella>] to verify wave-sequencing-plan currency + decide next wave + generate meta-kickoff + dispatch with real git gates.
when_to_use: User explicit invocation only via /meta-orchestrator slash command. Not auto-triggered.
arguments: [umbrella]
argument-hint: "[umbrella-name]"
disable-model-invocation: true
allowed-tools:
  - Bash(git *)
  - Bash(gh *)
  - Bash(ls *)
  - Bash(cat *)
  - Read
  - Write
  - Edit
  - Agent
model: opus
---
```

### §4.3 SKILL.md body — section map (per §7 binding)

| §7 sub-section | SKILL.md section | CC primitive used | New logic to BUILD |
|---|---|---|---|
| §7.1 Trigger | `### §0 Invocation` | `arguments` + `disable-model-invocation` | one-line ack |
| §7.2 Plan-preflight | `### §1 Plan-currency check` | `` !`git status` `` + `` !`gh pr list --search...` `` + `` !`cat docs/meta-factory/wave-sequencing-plan.md` `` + `` !`ls .claude/orchestrator-prompts/<umbrella>/` `` | Drift detection logic — compare plan claims vs live git/PR state; emit «План актуален» OR drift list |
| §7.3 Priority resolution (no-arg mode) | `### §2 Priority` | (none — pure logic) | Multi-criteria scorer: blocks-others × give-back × size × maintainer-prefs. Recommend winner per [phase-research-coverage.md §1.12](../../../.claude/rules/phase-research-coverage.md) |
| §7.4 Launch-table | `### §3 Launch-table` | (none — pure logic) | Mode A/B/SDD/Queue decision rules per sub-wave type. Worktree-aware. Volume column (NOT time) |
| §7.5 Meta-kickoff authoring | `### §4 Meta-kickoff write` | Write tool + `${CLAUDE_SKILL_DIR}/templates/meta-kickoff.template.md` | §5 AI-traps section per principle 12 + stage-gate rules as `gh pr list` commands + recursive self-application clause + stop conditions per stage |
| §7.6 Dispatch routing | `### §5 Dispatch tree` | `context: fork` + `agent:` for single dispatch; main-session Mode A × N for parallel | Mutually-exclusive scenario routing per §7.6 amended bridge |
| §7.7 Stage-gate semantics | `### §6 Stage gates` | `Stop` hook OR inline `` !`gh pr list --search 'is:merged head:<branch>'` `` assertion | Real merge-state check; Phase -1 mandatory between stages |
| §7.8 Reviewer handoff | `### §7 Reviewer dispatch` | `Agent` tool with reviewer SP `requesting-code-review` template | Strategy-fork-surface discipline per [reviewer-discipline.md](../../../.claude/rules/reviewer-discipline.md) |
| §7.9 Anti-scope | `### §8 Anti-scope` | (none — prose constraint) | Don't write sub-wave code · Don't finalize strategy · Don't modify `~/.claude/skills/orchestrator/` · Don't violate no-paid-llm-in-ci · Don't add npm deps |
| §7.10 One-button install | (filesystem layout) | `.claude/skills/`+`${CLAUDE_SKILL_DIR}` | (verbatim ADOPT) |
| §7.11 Recursive self-application | `### §9 Dogfood test` | (none — discipline obligation) | First invocation runs §1-§7 on this very BUILD wave's umbrella |
| §7.12 Output artifacts | `### §10 Output` | Write tool | state.md + meta-kickoff.md + inline report |
| §7.13 Failure-mode handling | `### §11 Failures` | (none — prose) | Stale plan → write stub + ask. Ambiguous → ask maintainer. Tool unavailable → escalate with diagnostic |
| §7.14 Named gaps | (composite of §1-§7) | — | All 4 closed by the above sections |

### §4.4 Constraint compliance (audit-ready)

- **No-paid-LLM-in-CI** ([no-paid-llm-in-ci.md §1](../../../.claude/rules/no-paid-llm-in-ci.md)): skill runs in session, not CI. `!shell` injections are deterministic bash. ✓
- **Substrate-purity** ([build-first-reuse-default.md C-guard](../../../.claude/rules/build-first-reuse-default.md)): zero npm deps; bash + markdown + CC primitives only. ✓
- **One-button installability**: `.claude/skills/meta-orchestrator/` is project-scope, committed to repo, ships in `install.sh` payload as a directory copy. `${CLAUDE_SKILL_DIR}` ensures embedded scripts work in consumer repos. ✓
- **Channel-selection** ([rule-enforcement-channel-selection.md §3](../../../.claude/rules/rule-enforcement-channel-selection.md)): deterministic slash-command trigger (not semantic phrase-matching). ✓
- **Doc-authority-hierarchy** ([doc-authority-hierarchy.md §2-§3](../../../.claude/rules/doc-authority-hierarchy.md)): SKILL.md will carry Authoritative-for header. ✓

---

## §5 Next-wave kickoff name + skeleton

**Proposed I-phase kickoff:** `.claude/orchestrator-prompts/meta-orchestrator-build/kickoff.md`

**Skeleton (sketched, not authored — author at I-phase admission):**

```markdown
# KICKOFF — I-phase: BUILD `/meta-orchestrator` skill

> **Type:** I-phase execution (skill code). Output = `.claude/skills/meta-orchestrator/` directory + tests.
> **Origin:** R-phase verdict 2026-05-23 (this patch). Prior-art: BUILD on CC primitives, REFERENCE 9 upstream sources, ADOPT-VOCABULARY 3.
> **Deliverable:** `.claude/skills/meta-orchestrator/SKILL.md` + helpers + templates + tests + recursive-self-application dogfood evidence.

## §1 Spec
See §7 of R-phase kickoff verbatim (preserved in §6 of the R-phase patch).

## §2 Sub-waves (Mode B × N worktrees if ≥2 parallel)
- Sub-wave A: SKILL.md frontmatter + §0 + §1 + §2 (trigger, plan-preflight, priority)
- Sub-wave B: SKILL.md §3 + §4 + helpers/launch-table-generator.sh (launch-table + meta-kickoff)
- Sub-wave C: SKILL.md §5 + §6 + §7 (dispatch routing, stage-gates, reviewer)
- Sub-wave D: §8 + §9 + §10 + §11 + tests + dogfood evidence

## §3 §5 AI-traps section (principle 12 mandatory)
Active T1/T3/T4/T5/T7/T11/T15/T16/T19 + domain-specific T-MOB-A through T-MOB-D (to author).

## §4 Recursive self-application
First invocation MUST run on this very BUILD umbrella and produce a valid launch-table for the BUILD work itself (dogfood test). Failure = principle 12 violation, blocks merge.

## §5 §1.7 forward+backward check
Forward: respects no-paid-llm-in-ci + substrate-purity + doc-authority-hierarchy + channel-selection + reviewer-discipline + dual-implementation-discipline (single channel = CC slash-command; if maintainer wants portable agent fallback for non-CC consumers, add `agents/meta-orchestrator-portable.md` per [dual-implementation-discipline.md §3](../../../.claude/rules/dual-implementation-discipline.md) — defer to maintainer judgment, this skill is consumer-facing).
Backward: supersedes nothing; extends the existing `orchestrator` skill workflow with a single-invocation entry point. Existing `orchestrator` skill remains the queue/dispatch primitive that meta-orchestrator calls.
```

**Trigger to admit I-phase:** maintainer GO on this R-phase patch + SSOT row block (#66-#70) registered.

---

## §6 §7 spec preservation (verbatim appendix)

> Per kickoff §4 item 5: «§7 spec preservation — copy this kickoff's §7 verbatim into the patch as an appendix (the spec is the contract; whatever path is chosen must deliver it).»

The full §7.1-§7.14 functional spec is preserved verbatim at the source kickoff: [.claude/orchestrator-prompts/meta-orchestrator-prior-art/kickoff.md#§7](../../../.claude/orchestrator-prompts/meta-orchestrator-prior-art/kickoff.md) lines 75-185. **Authoritative location.** Copying the full text here would inflate this patch past the [500-line md gate](../../../CLAUDE.md) without authority benefit — the kickoff file is committed, versioned, and read-only after this wave closes (orchestrator-prompts authority per [doc-authority-hierarchy.md §2 filename-convention](../../../.claude/rules/doc-authority-hierarchy.md)). Future readers MUST treat the kickoff §7 as the binding contract for the I-phase BUILD.

**Spec checksum (must hold at I-phase admission):**
- 14 sub-sections (§7.1-§7.14)
- Header: «THIS SECTION IS LOAD-BEARING»
- 4 named gaps in §7.14 explicitly listed (plan-actuality / cross-umbrella priority / launch-table / stage-gate vs flat-queue)
- §7.10 one-button-install + §7.11 recursive self-application + §7.9 anti-scope are all present

I-phase admission MUST verify these markers exist in the kickoff before authoring SKILL.md. If `git log` shows the kickoff modified between this patch landing and I-phase admission — re-verify the spec hasn't drifted.

---

## §7 §1.7 forward+backward note

### Forward-check

This patch complies with:
- **[build-first-reuse-default.md §1](../../../.claude/rules/build-first-reuse-default.md)** — all 7 verdicts (ADOPT / ADOPT-VOCABULARY / ADAPT / REFERENCE / KEEP-NARROW / BUILD / REJECT) used appropriately across 6 surfaces; BUILD chosen only after §3 mechanism (DeepWiki + WebSearch ≥3 phrasings + SSOT consult) executed on every candidate.
- **[no-paid-llm-in-ci.md §1](../../../.claude/rules/no-paid-llm-in-ci.md)** — proposed skill is session-bound; `!shell` injections are deterministic; no API-billed call anywhere. GitHub Agentic Workflows REJECTED partly on this constraint.
- **[phase-research-coverage.md §1.7](../../../.claude/rules/phase-research-coverage.md)** — every verdict cites file:line / URL / DeepWiki quote; falsifiers present per surface AND composite; recommendation discipline (cite SSOT + give evidence + state falsifier) applied throughout.
- **[ai-laziness-traps.md §3](../../../.claude/rules/ai-laziness-traps.md)** — kickoff §5 enumerated T1/T3/T4/T7/T11/T12/T13/T14/T15/T16 + T-MO-A/B/C + explicit T8/T10 dismissals; every Worker REPORT addressed T-MO-B (pattern-match-on-name) explicitly (T-MO-A applied at Surface 1; T-MO-B at Surface 1 using-superpowers + Surface 5 `/batch`/`/ultraplan`/agent-teams; T-MO-C 3-attempts at every external surface).
- **[doc-authority-hierarchy.md §2-§3](../../../.claude/rules/doc-authority-hierarchy.md)** — this patch carries the Authoritative-for header; folder authority inherited from `docs/meta-factory/research-patches/` (append-only).
- **[rule-enforcement-channel-selection.md](../../../.claude/rules/rule-enforcement-channel-selection.md)** — proposed skill is deterministic slash-command + path-scoped (project-scope `.claude/skills/`), not memory/semantic.
- **[reviewer-discipline.md §2](../../../.claude/rules/reviewer-discipline.md)** — proposed skill respects strategy-fork-surface discipline (§7.3 item 5: «If genuine tie / true strategy fork: ask maintainer»).
- **[dual-implementation-discipline.md §3](../../../.claude/rules/dual-implementation-discipline.md)** — consumer-facing default = dual channel; this patch defers the «portable agent fallback» decision to the I-phase BUILD kickoff per §3 deviation-accountability marker.
- **CLAUDE.md `Artifact Ownership Contract`** — proposed skill at `.claude/skills/meta-orchestrator/` (project-scope, committed). Does NOT modify `~/.claude/skills/orchestrator/` (agent-uncommittable, global, owner=maintainer).

### Backward-check

This patch **supersedes nothing**. It clears the meta-orchestrator question for the I-phase. SSOT row block (#66-#70) extends the prior-art register additively per its append-only convention. The existing `orchestrator` skill remains the queue/dispatch primitive that meta-orchestrator will call (single-button entry point above, not replacement). No existing rule, principle test, or agent prompt is silently changed.

**Spot-check evidence:**
- `grep -n "meta-orchestrator" docs/meta-factory/prior-art-evaluations.md` — currently 0 rows; this patch adds the first 5 (at IDs #66-#70).
- `grep -n "meta-orchestrator" .claude/rules/*.md` — currently 0 mentions; no rule supersedes.
- `grep -n "meta-orchestrator" packages/core/principles/*.test.ts` — currently 0 hits; no principle test affected.
- `grep -n "meta-orchestrator" agents/*.md` — currently 0 hits; no AI-agnostic agent supersedes.

---

## §8 §9 closing checklist (per kickoff §9)

- [x] **BFR §3 mechanism executed** (≥3 WebSearch phrasings — fulfilled 2.3× at Surface 6 = 7 phrasings; DeepWiki on each external candidate — Surfaces 2/3/4/6 (4 probes/Surface 4, 4 repos in Surface 6); Surface 1 used installed-filesystem SKILL.md read for Superpowers — higher-fidelity than DeepWiki extraction since the source is locally installed; SSOT consult — Surfaces 1/2/3/4 confirmed existing rows settled).
- [x] **T16 problem-class check per candidate** — explicit «Upstream X vs Our Y. Match? Evidence: …» on every verdict cell.
- [x] **No-paid-LLM-in-CI honored** — proposed skill is session-bound; GH Agentic Workflows REJECTED partly on this ground.
- [x] **Substrate-purity confirmed** — zero npm deps proposed; skill is bash + markdown + CC primitives.
- [x] **One-button-installability respected** — `.claude/skills/meta-orchestrator/` project-scope, templatable via `${CLAUDE_SKILL_DIR}`, ships in `install.sh` payload.
- [x] **§7 spec preserved** — referenced verbatim at kickoff §7 with checksum requirements (§6 above) instead of copy-paste (500-line gate trade-off).
- [x] **§1.7 forward+backward note written** — §7 above.
- [x] **Verdict explicit** — **BUILD on CC primitives, REFERENCE 9 sources, ADOPT-VOCABULARY 3** — with falsifier («wrong if Anthropic ships a bundled equivalent between 2026-05-23 and I-phase admission»).

---

## §9 Proposed SSOT rows (paste-ready for I-phase capability commit)

> **Policy:** per [`.claude/rules/build-first-reuse-default.md §5`](../../../.claude/rules/build-first-reuse-default.md) — SSOT row landing'ится **при capability commit**, не в R-phase. Эти 5 строк подготовлены как drafts, готовы к paste в [`docs/meta-factory/prior-art-evaluations.md`](../prior-art-evaluations.md) после строки #65 при первом I-phase capability commit с `Prior-art:` trailer.
>
> **Reviewer #2 task:** проверить formulations этих 5 строк до landing (особенно T16 problem-class формулировки + falsifier-trigger fields). Если formulations ОК — landing с capability commit процедурно безопасен.

```markdown
| 66 | AI Factory (`lee-to/ai-factory`) — single-feature workflow pipeline: `/aif-plan` (decompose to tasks) + `/aif-implement` (sequential execution with commit checkpoints) + `/aif-verify` (quality gate) + `/aif-evolve` (skill self-improvement via `.ai-factory/patches/`) + 7 other slash-commands; `--parallel` mode = worktree-per-feature dispatch; landing page aif.cutcode.dev | `/meta-orchestrator` skill — planner/implementer/reviewer role vocabulary + worktree-per-feature pattern as design references | 2026-05-23 | 2026-05-23 | REFERENCE | Meta-orchestrator R-phase patch [§1 row 2 + §3 leapfrog table(./2026-05-23-meta-orchestrator-prior-art.md) (DeepWiki ×3, WebFetch landing page, WebSearch ×3 — 2026-05-23). **T16 problem-class check:** upstream = «execute single-feature plan with commit checkpoints + post-implementation quality check; single project scope»; ours = «meta-level portfolio orchestration across multiple parallel umbrellas with plan-currency verification + cross-umbrella priority resolution». **Match? Partial — vocabulary only.** Match score 14% (2/14 §7 sub-sections PARTIAL or WEAK, 12/14 MISSING). AIF planner/implementer/reviewer naming + worktree-per-feature pattern transfer as design references; the 4 §7.14 named gaps (plan-actuality, cross-umbrella priority, launch-table, stage-gate) all completely absent in AIF. | AIF ships a `/aif-meta-orchestrate` or equivalent multi-umbrella dispatcher; OR `/aif-roadmap` evolves from single-project milestones into multi-umbrella priority scoring |
| 67 | aif-handoff (`lee-to/aif-handoff`) Kanban runtime — server-side autonomous task pipeline (planning → plan-checker → implementing → review) via `pollAndProcess` cron-driven scheduler; Docker + PostgreSQL/SQLite + Node.js + React Kanban UI; REST API + WebSocket events as user interface (no slash commands) | `/meta-orchestrator` slash-command capability — **REJECT** | 2026-05-23 | 2026-05-23 | REJECT | Meta-orchestrator R-phase patch [§1 row 3(./2026-05-23-meta-orchestrator-prior-art.md) (4 DeepWiki queries + GitHub README WebFetch + WebSearch ×3 — 2026-05-23). **T16 problem-class check:** upstream = «server-side autonomous Kanban runtime — AI agents plan, implement, review tasks via persistent cron pipeline; Docker+DB infrastructure; single-project»; ours = «session-bound slash-command skill verifying multi-umbrella plan + dispatching, zero infrastructure, project-scope installable». **Match? No — structural mismatch on three axes:** (a) `§7.9` (must NOT write code) vs aif-handoff's primary function (writes code); (b) `§7.10` (zero infra) vs Docker+DB requirement; (c) `§7.1` (user-invoked slash) vs cron-driven (no user-facing slash). Match score 22% surface-level only. Distinct from existing aif-handoff rows (#27 HANDOFF_MODE, #28 paused:true, #29 task annotation, #30 P/I/R pipeline, #43 RuntimeAdapter, #46 Subagents/Skills) — those address different problem classes; this row addresses the meta-orchestrator question specifically. | `/meta-orchestrator` scope expands to include persistent autonomous agent runtime (different product); OR aif-handoff ships a CC-native session-bound slash-command wrapper |
| 68 | OhMyOpencode (`code-yeongyu/oh-my-openagent`) Prometheus/Metis/Momus/Oracle/Atlas 3-layer orchestration architecture (planning → execution → verification) with blocking gates between layers, boulder.json session-continuity, `.omo/plans/*.md` Parallel-Execution-Waves section format, 11 agents + 52+ hooks; 59.1k★ + 2.6M+ downloads (`ohmyopenagent.com` = same project as `oh-my-openagent`, renamed from `oh-my-opencode`); BEYOND SSOT #61 (rulesInjector channel-selection use case) | `/meta-orchestrator` §7.7+§7.8 architecture vocabulary — blocking-oracle-gate pattern + iterative-reviewer-loop-until-approve + Parallel-Execution-Waves section format + boulder.json continuity = **ADOPT VOCABULARY (sub-pattern)**; full architecture validates problem class is real and solvable = **REFERENCE** | 2026-05-23 | 2026-05-23 | REFERENCE + ADOPT VOCABULARY | Meta-orchestrator R-phase patch [§1 row 4 + §3 leapfrog table(./2026-05-23-meta-orchestrator-prior-art.md) (4 DeepWiki queries + WebFetch ohmyopenagent.com landing + docs/guide/orchestration.md + docs/reference/features.md + WebSearch ×3 — 2026-05-23). **T16 problem-class check:** upstream = «multi-agent orchestration within single OpenCode session, task-level parallelism, in-session QA gates, single project, OpenCode plugin substrate»; ours = «cross-session, multi-umbrella, repo-aware meta-launcher with real GitHub PR state gates, CC `.claude/skills/` slash-command, install.sh-templatable». **Match? Partial at abstract level; diverges on substrate (OpenCode ≠ CC) + session model (single ≠ cross-umbrella) + 3-of-4 §7.14 gaps (cross-umbrella priority, launch-table, real-git-PR gates).** Match score ~30%. Adopted vocabulary: «blocking oracle gate» (→ Phase -1 cold-review naming), «Parallel Execution Waves section» (→ launch-table structure), «boulder.json continuity» (→ state.md output). Distinct from SSOT #61 (rulesInjector ADAPT, channel-selection injection) — this row addresses the meta-orchestration capability of OhMyOpencode separately. | OhMyOpencode ships CC-native distribution (currently OpenCode plugin); OR Prometheus/Atlas 3-layer architecture proves insufficient for `/meta-orchestrator` §7.3 cross-umbrella scope |
| 69 | Bernstein (`sipyourdrink-ltd/bernstein`) — Python CLI multi-agent orchestration with YAML DAG (`depends_on` task graph) + janitor agent (validation gate between tasks) + per-task tool restrictions; deterministic parallel agent execution with audit-grade logging | `/meta-orchestrator` §7.4 launch-table DAG structure + §7.7 per-task stage gate — **REFERENCE** for DAG model and janitor-as-gate pattern | 2026-05-23 | 2026-05-23 | REFERENCE | Meta-orchestrator R-phase patch [§1 row 6 + §3 leapfrog table(./2026-05-23-meta-orchestrator-prior-art.md) (DeepWiki + WebSearch — Surface 6 BFR §3 sweep, 2026-05-23). **T16 problem-class check:** upstream = «deterministic parallel agent execution on a defined YAML task graph; assumes plan IS the YAML binding; audit-grade logging»; ours = «verify a markdown plan's currency vs live `gh pr list` state; cross-umbrella scope; CC skill». **Match? Partial structurally — DAG `depends_on` transfers as launch-table model; janitor-as-gate transfers as Phase -1 review pattern.** Match score ~20% on §7.4 + ~25% on §7.7. Not ADOPT — Python CLI runtime; YAML-as-binding assumption breaks our markdown-plan-as-source model; no cross-umbrella scope; no `gh pr list` actuality check. | Bernstein ports to a CC skill or pure-bash distribution; OR `/meta-orchestrator` §7.4 launch-table grows beyond DAG semantics requiring a richer task-graph engine |
| 70 | ComposioHQ/agent-orchestrator — parallel-agent fleet manager with `getMergeability()` PR-readiness signal set (CI status + review decisions + draft state + merge conflicts as composable boolean signals); routes CI failures back to responsible agent | `/meta-orchestrator` §7.7 stage-gate signal vocabulary — **REFERENCE** for the PR-readiness signal set (CI + reviews + draft + conflicts as `is:merged` decomposition inputs) | 2026-05-23 | 2026-05-23 | REFERENCE | Meta-orchestrator R-phase patch [§1 row 6 + §3 leapfrog table(./2026-05-23-meta-orchestrator-prior-art.md) (DeepWiki + WebSearch — Surface 6 BFR §3 sweep, 2026-05-23). **T16 problem-class check:** upstream = «manage fleets of parallel coding agents; route CI failures back to responsible agent based on intra-PR mergeability signals»; ours = «check whether Stage 1 PRs are merged on GitHub before dispatching Stage 2». **Match? Sub-pattern only — the PR-readiness signal set (CI + reviews + draft + conflicts) transfers as `gh pr list --state merged` decomposition vocabulary.** Match score ~15% on §7.7. Not ADOPT — ComposioHQ is intra-PR routing (single PR, multiple agents), not between-stage sequencing (multiple PRs, one stage at a time). | ComposioHQ extends to between-stage sequencing capability beyond intra-PR routing; OR `/meta-orchestrator` §7.7 signal set diverges from CompositoHQ's `getMergeability()` decomposition |
```

**SSOT-row count by verdict:** 1 REJECT (#67) · 3 REFERENCE (#66, #69, #70) · 1 REFERENCE+ADOPT-VOCABULARY (#68). Total 5 rows.

**Other surfaces — no SSOT row needed:**
- **Surface 1 (Superpowers)** — SSOT #64/#65 already cover dogfooded skills; remaining 12 SP-skills are intra-§7 REFERENCE-grade integration points, not new dependencies. No new row.
- **Surface 5 (CC native primitives)** — substrate-as-shipped (Claude Code itself), not a third-party precedent to register. No new row.

**REJECTed candidates from Surface 6 — NOT given SSOT rows** (audit trail kept in scratchpad `/tmp/meta-orch-survey-6-state-of-art.md`):
- APM (`sdi2200262/agentic-project-management`) — REJECT (context-window management, not orchestration)
- GitHub Agentic Workflows — REJECT (CI-side, violates no-paid-llm-in-ci constraint)
- addyosmani/agent-skills `/ship` — borderline REFERENCE for §7.7+§7.8 GO/NO-GO shape; **SSOT row deferred** to I-phase admission per [build-first-reuse-default.md §5](../../../.claude/rules/build-first-reuse-default.md) «row at capability commit moment, not before» — claim only if I-phase actually adopts the shape
- LangGraph / CrewAI / AutoGen / CI orchestrators / PM tools / build meta-launchers — REJECT (cross-domain mismatch)

---

## §10 See also

- Kickoff: [`.claude/orchestrator-prompts/meta-orchestrator-prior-art/kickoff.md`](../../../.claude/orchestrator-prompts/meta-orchestrator-prior-art/kickoff.md)
- Phase -1 + dispatch state: [`.claude/orchestrator-prompts/meta-orchestrator-prior-art/state.md`](../../../.claude/orchestrator-prompts/meta-orchestrator-prior-art/state.md)
- Worker scratchpads (ephemeral): `/tmp/meta-orch-survey-{1..6}-*.md` — primary evidence chain; promote to SSOT row evidence at next maintainer touch
- SSOT register: [`docs/meta-factory/prior-art-evaluations.md`](../prior-art-evaluations.md) (rows #66-#70 to be claimed)
- Wave plan: [`docs/meta-factory/wave-sequencing-plan.md`](../wave-sequencing-plan.md)
- BFR rule: [`.claude/rules/build-first-reuse-default.md`](../../../.claude/rules/build-first-reuse-default.md)
- AI-laziness rule: [`.claude/rules/ai-laziness-traps.md`](../../../.claude/rules/ai-laziness-traps.md)
- Doc-authority rule: [`.claude/rules/doc-authority-hierarchy.md`](../../../.claude/rules/doc-authority-hierarchy.md)
- Principle 12 test: [`packages/core/principles/12-ai-laziness-traps.test.ts`](../../../packages/core/principles/12-ai-laziness-traps.test.ts)

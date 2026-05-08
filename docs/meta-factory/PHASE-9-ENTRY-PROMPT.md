# Phase 9 Entry Research Prompt — capability scoping for Phase 9 implementation

> **Назначение:** self-contained prompt для orchestrator session. Phase 9 entry **research**, NOT implementation. Output = `phase-9-entry-research.md` capability matrix + go/no-go decisions + verdict (GO/REVISE/STOP) для последующего Phase 9 implementation prompt.
> **Версия:** 1.0.0 — 2026-05-08 (post-Phase-8.8-merge `a971728`).
> **Triggered by:** Phase 8 close + Phase 8.8 close. §13.10 entry #2 trigger fired at Phase 8 close (Path A LLM gen ROI scoping).
> **Honest time estimate:** 1-3 часа wall-clock single session. ~5-7 atomic commits + retro = 6-8 total. Mirrors phase-8-entry.md scale; significantly smaller than Phase 8 / 8.8 implementation.

---

## 1. Identity & Context

**Repo:** `/Users/art/code/rules-as-tests-aif`
**Base branch:** create new `docs/phase-9-entry-research` from `main` (current HEAD `a971728`, the merge commit of PR #12 closing Phase 8.8).
**You are:** Opus orchestrator + entry research lead. **Research only — no code, no impl.** Output is a sized, prioritized capability matrix that informs the next-session Phase 9 implementation prompt.

**Phase 8.8 mechanism is now in production.** This session is the **first downstream consumer** — every claim must cite SSOT, every capability commit needs `Prior-art:` trailer, principle 08 will catch missed citations in CI.

## 2. Обязательное чтение (в порядке)

1. [retros/phase-8.8.md](retros/phase-8.8.md) — § «Phase 8 retroactive audit» (the 6 Phase 8 decisions with verdict «zero reinvention») + § «Open questions for Phase 9 entry»
2. [retros/phase-8.md](retros/phase-8.md) — § «Open questions for Phase 9 entry» (6 items) + Self-reflection #5/#6 (recipe duplication, glob-weight calibration)
3. [retros/phase-7.5.md](retros/phase-7.5.md) — structural pattern reference for entry-research retro
4. [EXECUTION-PLAN.md §6.0](EXECUTION-PLAN.md) — v2-trigger areas table (5 areas: LLM L2, Path A L3, Path B L3, gate 5 L4, gate 3 L4)
5. [EXECUTION-PLAN.md §5.5](EXECUTION-PLAN.md) — Phase entry gate including **Step 1.5 mandatory SSOT consult** (Phase 8.8 T6 deliverable)
6. [open-questions.md §13.10](open-questions.md) — LLM v2 trigger conditions SSOT (5 entries; #2 fired at Phase 8 close; #1 still armed)
7. [open-questions.md §13.11](open-questions.md) — gate-5 invocation shape decision (per-plan + Opus + advisory + cached, decided in Phase 8)
8. [prior-art-evaluations.md](prior-art-evaluations.md) — SSOT, 3 entries shipped (Autogrep DEFER / Netlify framework-info WATCHLIST / fitness functions ADOPT VOCABULARY)
9. [packages/core/principles/08-prior-art-cited.test.ts](../../packages/core/principles/08-prior-art-cited.test.ts) — citation requirement for new research files (this session's output WILL be checked)
10. [aif-comparison.md §9](aif-comparison.md) — reuse matrix (already includes aif-evolve overlap row + Phase 8.8 cross-ref); §10 — 4 confirmed differentiators
11. [CONTRIBUTING.md «Build-vs-reuse + Prior-art trailer convention»](../../CONTRIBUTING.md) — trailer syntax + escape-hatch rules
12. [CLAUDE.md](../../CLAUDE.md) — agent-side summary of the same convention

## 3. Phase 8.8 mechanism — mandatory dogfooding

This session is the **first phase using the convention as a forward gate** (Phase 8.8 itself dogfooded retroactively). Three enforcement layers active:

| Layer | Surface | Catches |
|---|---|---|
| §5.5 Step 1.5 process gate | phase research drafting | missed prior-art consult |
| Principle 08 meta-test | CI on `phase-9-entry-research.md` | broken / absent SSOT citations |
| Pre-push hook + commit trailer | every capability commit | trailer absent / placeholder rationale / <20 chars |

**Mandatory steps for every capability area (per §5.5 Step 1.5):**
1. Check SSOT (`prior-art-evaluations.md`) for matches on «Capability matched» field. **3 entries currently:**
   - **#1 Autogrep** (L3 LLM-driven rule generation, DEFER) — re-evaluation trigger fired at Phase 8 close per §13.10 #2; **this session re-evaluates Autogrep**
   - **#2 Netlify framework-info** (L1 multi-framework version-aware detection, WATCHLIST) — Phase 9 detector v2 entry research fires; **this session re-evaluates Netlify**
   - **#3 Fitness functions** (vocabulary ADOPT VOCABULARY) — adopted; staleness check only
2. On match: update `Last reviewed` to today's date in same commit; include candidate in capability matrix with current verdict + rationale; if verdict is DEFER/WATCHLIST add explicit re-evaluation note.
3. On no match: continue Step 0 sub-step 3 (`mcp__context7__resolve-library-id`) + sub-step 4 (`mcp__context7__query-docs` ≥3 phrasings); if new candidate surfaces, **add new SSOT entry in same commit** as capability research.

## 4. Capability areas to scope (Phase 9 entry research scope)

Phase 9 entry research scopes WHAT Phase 9 implementation might cover. The matrix decides priority + go/no-go; the next-session implementation prompt commits to a subset. Initial candidates:

### High-priority (triggers fired)

1. **Path A LLM gen «picks from menu»** — §13.10 entry #2 trigger fired at Phase 8 close. ROI question: does LLM-pick from curated menu beat hand-rolled recipe-by-recipe? Cost model: per-plan, advisory in v2.
2. **Autogrep re-evaluation** (SSOT #1) — `Last reviewed` 2026-05-08; trigger fires at LLM v2 evaluation. Did Semgrep ship a rule-synthesis-from-docs feature since 2026-05-08? context7 lookup mandatory.

### Medium-priority (triggers armed but not fired)

3. **§13.10 entry #1 LLM-driven research extension** — armed for «first real consumer reports gap on non-curated framework». Has Art (first real consumer) hit a gap? Phase 8 closed without one. Trigger status: armed, not fired.
4. **Gate 5 two-AI review build** — cost-scoping decision DONE in Phase 8 §13.11 (per-plan + Opus + advisory + cached). Phase 9 entry: does verification-gate FP-rate threshold (<20% on 10+ real PRs per §13.10 #4) require Phase 9 implementation cycle, or wait for more PRs?
5. **Path B AST gen** — §13.10 entry #3 trigger «Phase 9+; new pattern with no existing ESLint plugin». Did Phase 9 entry surface such a pattern? If no, defer.

### Housekeeping (Phase 8 retro flags)

6. **Recipe duplication** (Phase 8 retro Self-reflection #6) — `react-server-components.json` + `next-r12-no-server-imports-in-client.json` both emit same plugin rule. Single-source policy decision: collapse to one canonical recipe (detector + named-selection paths) OR document layering as intentional?
7. **`next/any/` resolution tier** (Phase 8 retro Self-reflection #5) — collapses 15.x ↔ 16.x duplication for version-agnostic patterns. Authoring convention question: when does an entry deserve `any/` vs versioned dirs?
8. **Glob-overlap weight calibration** (Phase 8 retro Self-reflection #6, post-PR-#11-fix `9fe5a5b`) — 0.4/0.4/0.2 initial guess. First Phase 9 LLM-gen run produces calibration data; entry research scopes test-corpus design for calibration.

### Phase 11.1 closure tail

9. **AIF GATE-RESULT-CONTRACT.md schema validation** — Phase 8 partial-closed via `aif-gate-result` JSON emission; validation against AIF schema is the remaining 11.1 acceptance criterion. context7 fetch fresh per the «AIF schema may have evolved» caveat.

## 5. Hard constraints

1. **Research only — NO code, NO impl.** Output is `phase-9-entry-research.md` + retro. Implementation prompts are next-session.
2. **NO LLM at runtime in research** — context7 only for live lookups; SSOT updates are manual based on context7 output.
3. **§5.5 Step 1.5 mandatory** for every capability area listed in §4 above + any newly discovered ones during research.
4. **Principle 08 will run on `phase-9-entry-research.md`** (first phase research file post-T3 baseline). File MUST cite all matched SSOT entries by ID format `[prior-art-evaluations.md#N]`. Broken refs caught universally.
5. **Capability commits need `Prior-art:` trailer** — mostly research-doc edits won't be capability commits per hook definition (path is `docs/`, not `packages/`); but new SSOT entries (T2-style) do warrant trailers per convention.
6. **NO new explicit deps** in package.json (still §6.0 #2 stop-rule).
7. **NO yargs/commander, NO Path B AST gen during research** (deciding-not-doing).
8. **Atomic commits, conventional-commits, English subjects, no emoji.**
9. **≤500 lines** per shipped reference doc (`phase-9-entry-research.md` is transient; ≤200 line guideline applies).
10. **Apply principle to itself** — context7 query (≥3 phrasings) per capability area BEFORE adding SSOT entry.

## 6. Task list (5-7 atomic commits + retro)

### T1 — Capability matrix draft (Step 0 sub-steps 1)

**File:** `docs/meta-factory/phase-9-entry-research.md` (NEW transient artifact, ≤200 LOC).

**Content:** §1 header (date, branch, scope = entry research) + §2 capability area list (initial 9 from §4 above; expand if research surfaces more).

**Verification:** `test -f docs/meta-factory/phase-9-entry-research.md && grep -E "^## §2 Capability areas" docs/meta-factory/phase-9-entry-research.md`

**Commit:** `docs(phase-9-entry): capability matrix scaffold + 9 initial areas`

### T2 — Step 1.5 SSOT consult — 3 existing entries match-check

For each of the 3 existing entries (Autogrep, Netlify, fitness functions): determine which capability areas in §2 match. Update `Last reviewed` in same commit. Add re-evaluation notes for DEFER/WATCHLIST verdicts if trigger conditions have fired (Autogrep entry #1 trigger DID fire per §13.10 #2; Netlify entry #2 trigger MAY fire if §6.0 #2 stance shifts in Phase 9).

**Edit 1:** `prior-art-evaluations.md` — bump `Last reviewed` for any matched entries; add re-evaluation note column or inline if verdict needs status update.

**Edit 2:** `phase-9-entry-research.md` §3 — record each match with format:

```
- Capability area X — matches [prior-art-evaluations.md#1] (Autogrep, DEFER); re-evaluation status: <still applies | trigger fired | new evidence>; rationale: ...
```

**Verification:** `git log -p prior-art-evaluations.md` shows `Last reviewed` bumps; `grep -E "\[prior-art-evaluations\.md#" phase-9-entry-research.md | wc -l` ≥ 1.

**Commit:** `docs(prior-art): T2 — Step 1.5 SSOT match consult + Last reviewed bumps`

### T3 — Step 2 + Step 3: context7 resolve + queries per unmatched capability

For capability areas NOT covered by existing SSOT entries (after T2): run `mcp__context7__resolve-library-id` + `mcp__context7__query-docs` (≥3 phrasings each per Hard Constraint #5). Document results in `phase-9-entry-research.md` §4.

**Capability areas needing fresh context7 (per §4 priority):**
- Path A LLM gen «picks from menu» — query «LLM rule generation menu pick framework agnostic»; check Cody, Cursor, Continue.dev, Aider rule-gen features
- Gate 5 build (advisory two-AI review) — query «AI code review framework agentic Anthropic OpenAI» — already have AIF; check independent alternatives
- Path B AST gen — query «AST code generation rules from documentation diff» — Codemod, jscodeshift, ts-morph, Comby
- §13.10 entry #1 LLM-driven research extension — query «LLM web search docs extraction framework» — context7 itself, Anthropic web_search_20250305
- AIF schema fresh fetch — query «AIF GATE-RESULT-CONTRACT.md schema» (already known; verify no schema evolution)

**New SSOT entries:** add for any production-grade analog surfaced. Same-commit policy: SSOT update + research file edit in single commit per area.

**Verification:** `grep -cE "context7 lookup" phase-9-entry-research.md` reflects ≥3 queries per fresh area.

**Commits:** 1 atomic commit per capability area researched (3-5 expected). Each: `docs(phase-9-entry): T3.<n> — context7 + SSOT update for <capability area>`.

### T4 — Step 4 build matrix + Step 5 go/no-go per capability

**Edit:** `phase-9-entry-research.md` §5 — final matrix table:

| Capability area | Existing analog (SSOT #N) | Verdict | Rationale | Phase 9 priority |
|---|---|---|---|---|
| ... | ... | BUILD / REUSE / DEFER | ... | P0 / P1 / P2 / OUT |

**Verdicts:**
- BUILD — proceed in Phase 9 implementation; rationale why no analog suffices
- REUSE — adopt existing solution (SSOT entry verdict ADOPT or ADOPT VOCABULARY)
- DEFER — capability stays in WATCHLIST/DEFER; no Phase 9 work
- (NEW: STOP — capability is now obsolete; remove from backlog)

**Phase 9 priority levels:**
- P0 — must ship in Phase 9 (acceptance gate)
- P1 — should ship if scope permits
- P2 — backlog for Phase 9.X
- OUT — drop, document trigger condition for re-entry

**Verification:** `grep -E "^\| .* \| (BUILD|REUSE|DEFER|STOP) \|" phase-9-entry-research.md | wc -l` ≥ number of capability areas in §2.

**Commit:** `docs(phase-9-entry): T4 — build vs reuse matrix + Phase 9 priority`

### T5 — Stop-rule audit + cost projection (forward-looking)

**Edit:** `phase-9-entry-research.md` §6.

For each P0/P1 capability with verdict BUILD: project §6.0 stop-rule compliance:
- NO LLM at runtime — does Path A LLM gen require runtime LLM? If yes, this **violates** the stop-rule; Phase 9 needs amendment to §6.0 OR Path A scope must change.
- NO new explicit deps — does Path B AST gen require ts-morph / jscodeshift dep? Cost-benefit.
- NO yargs/commander — CLI for any new tool stays within ≤60 LOC argparse.

For Path A LLM gen specifically:
- Cost model: $X/1M tokens × Y plans/year × Z queries/plan
- §13.11 invocation shape (per-plan + Opus + advisory + cached) applies
- Phase 8 §13.11 decision: gate 5 advisory only; same shape proposed for Path A?

**Verification:** §6 contains explicit projection table per P0/P1 capability.

**Commit:** `docs(phase-9-entry): T5 — stop-rule audit + cost projection per P0/P1 capability`

### T6 — Phase 9 entry retro + verdict for Phase 9 implementation

**File:** `docs/meta-factory/retros/phase-9-entry.md` (NEW, ≤200 LOC, mirror retros/phase-8-entry.md structure).

**Sections:**
1. Header (date, branch, phase = 9 entry, verdict)
2. Scope — what entry research covered
3. Verification block (acceptance criteria)
4. Capability matrix summary (compact table)
5. Self-application — Phase 8.8 mechanism dogfooded? §5.5 Step 1.5 + principle 08 + trailer evidence
6. Stop-rule audit
7. Time-vs-plan ratio (target 1-3h)
8. **Verdict: GO/REVISE/STOP к Phase 9 implementation prompt drafting**

If GO → next session drafts `PHASE-9-PROMPT.md` based on this matrix. If REVISE → entry research re-opens with specific findings. If STOP → Phase 9 cancelled, document why.

**Commit:** `docs(phase-9-entry): T6 — retro + verdict for Phase 9 implementation`

## 7. Acceptance criteria (overall)

```bash
# Docs-only branch
git diff main --name-only | grep -vE "^(docs/meta-factory/(phase-9-entry-research|prior-art-evaluations|retros/phase-9-entry)\.md)$" | grep -v "^$" && echo "FAIL: unexpected files" || echo "OK: docs-only"

# Atomic commits — ~5-7 task commits + retro
git log main..HEAD --oneline | wc -l   # 6-8 expected

# Conventional commits
git log main..HEAD --pretty=format:'%s' | grep -cE '^(docs|chore)(\(.+\))?: '

# Prior-art trailers on capability commits (those that add new SSOT entries or reference existing entries)
git log main..HEAD --pretty=format:'%H %s%n%b%n---' | grep -cE '^Prior-art:'   # ≥1 (T2 always; T3 per new entry)

# Principle 08 catches research file
cd packages/core && npm test --run principles/08-prior-art-cited 2>&1 | tail -3   # green; phase-9-entry-research.md cites ≥1 SSOT entry

# Pre-push hook on push (capability commit detection)
# T2-T3 commits adding SSOT entries are NOT capability commits per hook def (path docs/, not packages/);
# but they should still carry Prior-art: trailers per CONTRIBUTING.md convention.

# Each shipped reference doc within size limits
for f in docs/meta-factory/phase-9-entry-research.md docs/meta-factory/retros/phase-9-entry.md; do
  lines=$(wc -l < "$f"); echo "$f: $lines"; [ "$lines" -le 200 ] || echo "FAIL: $f exceeds 200 lines"
done

# SSOT remains ≤500 lines after edits
[ "$(wc -l < docs/meta-factory/prior-art-evaluations.md)" -le 500 ]
```

## 8. What NOT to do

1. **DO NOT decide Phase 9 IMPLEMENTATION scope here.** Entry research SCOPES; implementation prompt COMMITS. Don't pre-commit to capabilities without the matrix + go/no-go discipline.
2. **DO NOT skip §5.5 Step 1.5 SSOT consult** for each capability area — even if «obviously no analog», the ≥3 context7 phrasings per Hard Constraint #5 are mandatory.
3. **DO NOT add new SSOT entries casually.** Each entry needs: capability match + first seen date + verdict + rationale (≤500 chars, citing context7 result) + trigger to revisit. Vague entries fail Phase 9.X review.
4. **DO NOT write impl code in this session.** No `.ts` / `.sh` files added. Pure docs.
5. **DO NOT bypass principle 08** by adding `phase-9-entry-research.md` to `BASELINE_EXCEPTIONS` — file is post-T3, must cite ≥1 SSOT entry.
6. **DO NOT bundle multiple capability areas into one commit** — atomic per area (per Step phase OR per capability research) keeps git log auditable.
7. **DO NOT skip the §13.10 trigger-fired re-evaluation.** §13.10 entry #2 (Path A LLM gen ROI) is the entire reason for Phase 9 entry; treating it casually defeats the purpose.
8. **DO NOT preemptively change §6.0 stop-rules.** If Phase 9 capability requires a stop-rule change (e.g. Path A LLM gen requires LLM at runtime), document the conflict in §6 of phase-9-entry-research.md and route via the T6 retro verdict — `REVISE` if conflict surfaces.

## 9. PR plan

After Phase 9 entry close on `docs/phase-9-entry-research` branch:

```
gh pr create --base main --head docs/phase-9-entry-research \
  --title "docs: Phase 9 entry research — capability matrix + verdict for Phase 9 implementation" \
  --body "$(cat docs/meta-factory/retros/phase-9-entry.md | head -60)"
```

PR description = retro head section. Reviewer (you / future Claude session) verifies acceptance criteria from §7.

## 10. Post-merge

1. **GO verdict** → next session drafts `PHASE-9-PROMPT.md` based on the matrix; Phase 9 implementation begins. Entry research becomes the SSOT for Phase 9 scope.
2. **REVISE verdict** → entry research re-opens with specific findings; ~1 atomic delta commit per finding addressed; new retro.
3. **STOP verdict** → Phase 9 cancelled. Document why. Phase 8.8 mechanism remains active for any Phase N+ research.

After Phase 9 implementation closes: this entry-research file becomes historical reference (NOT deleted; cross-referenced from phase-9.md retro).

---

**Reference materials packed для self-contained execution. Branch from `main` (HEAD `a971728`). Atomic commits. Research only — no code. Phase 8.8 mechanism is the live forward gate; this session is its first downstream consumer.**

<!-- scope:1a-drafts-pre-ship-review -->
# Research-patch — Pre-ship substantive review of goal-clarity-dialogue 1A drafts

> **Date:** 2026-05-16
> **Session type:** Post-1A coordination — §6.6 pre-ship substantive review batch
> **Predecessor:** [2026-05-16-goal-clarity-dialogue.md](2026-05-16-goal-clarity-dialogue.md) — 1A research-patch
> **Kickoff:** [.claude/orchestrator-prompts/post-1a-coordination/kickoff.md](../../../.claude/orchestrator-prompts/post-1a-coordination/kickoff.md) §6.6
> **Reviewed drafts:** all 8 in [.claude/orchestrator-prompts/goal-clarity-dialogue/drafts/](../../../.claude/orchestrator-prompts/goal-clarity-dialogue/drafts/) (gitignored)
> **T7 template:** Problem → Root Cause → Solution → Prevention → Tags
> **Outcome:** **2 BLOCKs, 5 REVISEs, 1 PASS.** Commit 1 cannot ship as currently scoped.

## §1 Problem

The 1A dialogue (2026-05-16) produced 8 drafts but did not ship a self-review patch closing the §1.7 self-reflexive trigger ([phase-research-coverage.md §1.7](../../../.claude/rules/phase-research-coverage.md)). One instance of `#discipline-theatre` was already caught in 1A's prose-rules audit by maintainer pushback. The drafts themselves were never substantively probed before being declared «READY» in [atomic-commit-plan.md](../../../.claude/orchestrator-prompts/goal-clarity-dialogue/drafts/atomic-commit-plan.md).

Per kickoff §6.6: «if one 1A output contained syntactic-OK / substantive-untested claims, others may too.» This pre-ship review tests that hypothesis. **Result: 7 of 8 drafts carry at least one substantive defect; 2 carry blocking defects.** The hypothesis is confirmed; pre-ship review caught what 1A's own self-application sections missed.

## §2 Per-draft verdicts (substantive evidence required)

### Draft 1 — `README-why-this-exists-revised.md` — **REVISE**

**VERIFIABLE claim audit:**

- ✅ Subline restructure preserves punchline shape — verified by reading current [README.md:8](../../../README.md#L8) and comparing to draft AFTER.
- ✅ New invariant «Multi-channel enforcement» wording empirically matches existing channels — verified against actual `.husky/pre-push` (449 lines, present), `eslint.config.mjs` (present), `audit-ai-docs.sh` (311 lines, present).
- ⚠️ **Forward-reference defect**: the revised «Build-vs-reuse discipline» invariant says «Macro-level operating philosophy: `.claude/rules/build-first-reuse-default.md`», but that file does not exist yet — it ships in Commit 2. If Commit 1 ships alone, README references a non-existent path. Tolerable if Commits 1 and 2 ship within the same maintainer window; broken-link rot risk if Commit 2 slips.

**Probe:**
```bash
ls .claude/rules/build-first-reuse-default.md
# ls: .claude/rules/build-first-reuse-default.md: No such file or directory
```

**Verdict: REVISE.** Either ship Commits 1 and 2 same-window OR omit the forward-reference in Commit 1, add it in Commit 2.

### Draft 2 — `CLAUDE-md-goal-pointer-revised.md` — **PASS**

**VERIFIABLE claim audit:**

- ✅ Mirror of README §Why-this-exists wording — verified line-by-line.
- ✅ Does NOT add forward-reference to BFR-default rule (cleaner than Draft 1) — verified.
- ✅ Punchline preserved («AI agents can't silently bypass undocumented conventions») — verified.

**Verdict: PASS.** Cleanest draft of the eight. Ships as-is.

### Draft 3 — `session-bootstrap-md-goal-section-revised.md` — **BLOCK**

**VERIFIABLE claim audit:**

- ✅ Draft's «BEFORE» (labelled «approximate») is in fact EXACT verbatim match of current [.claude/session-bootstrap.md:11](../../../.claude/session-bootstrap.md#L11) — verified.
- ❌ **BLOCKING defect: hook script hardcodes the digest text, NOT extracted from session-bootstrap.md.** The atomic-commit-plan §Commit-1 «Verification post-commit» says «open a fresh session, verify auto-injected digest reflects new text. If old text persists — inspect `.claude/hooks/inject-session-bootstrap.sh` for cache or path issue.» This framing is wrong — there is no cache or path issue. The hook hardcodes text via heredoc:

**Probe:**
```bash
cat .claude/hooks/inject-session-bootstrap.sh
```
Output:
```bash
#!/usr/bin/env bash
cat <<'DIGEST'
[session-bootstrap digest — auto-injected at prompt submit]
Goal: AI agents can't silently bypass undocumented conventions — every codified rule fails CI on violation. (README.md#why-this-exists)
Invariants: (1) build-vs-reuse SSOT consult before capability commit; (2) recursive self-application green (make self-audit); (3) search-coverage 6-item checklist on negative-existence claims.
Step-0 reading order: README.md → .claude/session-bootstrap.md → CLAUDE.md → task-specific docs.
Full bootstrap + reviewer drift-prevention flowchart: .claude/session-bootstrap.md
[/session-bootstrap digest]
DIGEST
```

The hook does not `cat .claude/session-bootstrap.md` nor `sed` / `awk` over it. Editing `.claude/session-bootstrap.md` produces NO change in hook output. The self-reinforcing drift persists unmodified.

**Implication for Commit 1 anti-drift purpose:**

The entire stated reason for prioritising Commit 1 («fix self-reinforcing drift — every session sees narrow framing first») does NOT trigger from Commit 1 as currently scoped. Maintainer still sees narrow framing in every new session.

**Verdict: BLOCK.** Commit 1 must include `.claude/hooks/inject-session-bootstrap.sh` edit to update hardcoded text. OR Commit 1 scope must explicitly drop the «fixes self-reinforcing drift» promise and the hook update becomes Commit 1.5.

### Draft 4 — `build-first-reuse-default-rule.md` — **BLOCK**

**VERIFIABLE claim audit:**

- ✅ Rule body §1 verdict typology (ADOPT / ADOPT VOCABULARY / ADAPT / REFERENCE / KEEP NARROW / BUILD / REJECT) — internally consistent.
- ✅ §3 mechanism replaces context7 with DeepWiki + WebSearch — matches maintainer 2026-05-16 correction.
- ✅ Anti-patterns section (`#parallel-evolution-creep`, `#own-stack-blind-spot`, etc.) — substantive, not theatre.
- ❌ **BLOCKING defect: principle 10 slot already occupied by a different test as of 2026-05-13** — three days BEFORE the 1A dialogue.

**Probe:**
```bash
ls packages/core/principles/10-*.test.ts
```
Output:
```text
packages/core/principles/10-research-patch-annotation.test.ts
```

The existing file [packages/core/principles/10-research-patch-annotation.test.ts](../../../packages/core/principles/10-research-patch-annotation.test.ts) was committed 2026-05-13 and enforces the `<!-- scope:<slug> -->` annotation on research-patches (SSOT #29, ADAPT verdict). It is operational; principle 10 is taken.

Draft 4 §5 «Promotion timeline» references «companion principle test `packages/core/principles/10-build-first-reuse-default.test.ts`» — direct slot collision.

**Implication for Commit 2:**

Cannot ship as drafted. Must either:
- (a) Renumber BFR-default principle to slot 11; atomic-commit-plan's «Commit 4 — Principle 11 ai-laziness-traps» shifts to slot 12; Commit 5 shifts to slot 13. Cascade renumbering required.
- (b) Pause Commit 2; resolve slot allocation by amending the 1A roadmap.

The atomic-commit-plan §Commit 4 «Numbering caveat» line («if Commit 2's principle 10 is renumbered to 11 to make room for a higher-priority test») is too soft — does not flag that slot 10 is already occupied since pre-1A, not «potentially preempted later».

**Verdict: BLOCK.** Requires roadmap-level renumbering decision; cannot be silently fixed in Commit 2 execution.

### Draft 5 — `principle-10-build-first-reuse-default-design.md` — **BLOCK** (same slot collision)

**VERIFIABLE claim audit:**

- ✅ Design sketch is markdown not TypeScript (matches kickoff §6.2 «sketch only»).
- ✅ Open design questions explicit (Q1-Q5) — substantive.
- ❌ Same BLOCKING defect as Draft 4 — references `packages/core/principles/10-build-first-reuse-default.design.md` and `.test.ts` at slot 10.
- ⚠️ Additional REVISE concern: design sketch §1 invariant («every shipped capability has SSOT entry OR Prior-art trailer rationale») partially overlaps with existing [packages/core/principles/08-prior-art-cited.test.ts](../../../packages/core/principles/08-prior-art-cited.test.ts) (research-files cite SSOT by ID) and `.husky/pre-push` capability-commit Prior-art trailer enforcement. §2 of sketch acknowledges hook complementarity but does not explicitly deduplicate vs principle 08. Recommend revising §1 to articulate the distinct gap (aggregate-state drift not caught by per-research-file or per-commit checks).

**Verdict: BLOCK.** Slot collision same as Draft 4. Plus REVISE on principle-08 overlap clarity.

### Draft 6 — `reviewer-discipline-compensating-mechanism-patch.md` — **REVISE**

**VERIFIABLE claim audit:**

- ✅ Patch text body is coherent — compensating mechanism articulated, cross-references concrete (`agents/compliance-verifier.md` exists at the cited path).
- ✅ Cited compensating mechanism [agents/compliance-verifier.md](../../../agents/compliance-verifier.md) does exist and actually performs the claimed semantic check (verified by reading its «What you check» sections — Forward-check substance + citation integrity + Backward-check sweep completeness).
- ❌ **REVISE defect: internal inconsistency in renumbering instructions.** Current rule structure is:

**Probe:**
```bash
grep -nE "^## " .claude/rules/reviewer-discipline.md
```
Output:
```text
8:## §1 The discipline
16:## §2 Surface-as-decision-needed pattern
27:## §3 Anti-patterns
33:## §4 Promotion / retirement
38:## See also
```

The draft says «Insert as new §5... currently sections jump from §4 anti-patterns directly to See also. Renumber existing §5 (currently retirement) to §6.»

Two errors:
1. §3 is anti-patterns; §4 is promotion/retirement. The draft conflated §3 and §4.
2. There is NO existing §5 to renumber. §4 IS retirement.

The drafter likely meant: «Insert new §5 «Compensating mechanism» between current §4 (Promotion/retirement) and See also. No renumbering needed — §5 is new.»

**Verdict: REVISE.** Easy fix: rewrite the «Renumbering» section to: «Insert new §5 «Compensating mechanism» between existing §4 «Promotion / retirement» and «See also». No renumbering required — §5 did not previously exist.»

Note: Commit 3 is independently blocked on the prose-rules audit R-phase per atomic-commit-plan, so this REVISE is not on the critical path; but it must be applied before Commit 3 ships post-R-phase.

### Draft 7 — `wave-10-kickoff-learn-from-upstream-patch.md` — **REVISE**

**VERIFIABLE claim audit:**

- ✅ Patch content body is substantive (≥3 upstream surfaces to mine, format requirements for §findings sub-sections).
- ✅ Wave 10 kickoff exists at the cited path — verified.
- ❌ **REVISE defect: insertion-point description wrong.** Draft says «Insert as new subsection §6.X (after existing §6 acceptance criteria, before §7)».

**Probe:**
```bash
grep -nE "^## §" .claude/orchestrator-prompts/wave-10-hook-architecture/kickoff.md
```
Output:
```text
89:## §5 R-phase methodology
148:## §6 I-phase sub-waves (предварительный outline)
183:## §7 AI laziness traps — прочитай перед R-phase
```

Wave 10 §6 is «I-phase sub-waves», NOT acceptance criteria. The R-phase scope (where «learn-from-upstream mandate» logically belongs) is §5 with subsections §5.-1, §5.0, §5.1 «R-phase output requirements (binding)».

If the mandate sits under §6 (I-phase), it triggers AFTER R-phase has already produced its findings — too late. The mandate must live in §5 (R-phase methodology), most likely as new §5.2 «Learn-from-upstream mandate» or appended into §5.1's binding requirements.

**Verdict: REVISE.** Re-target insertion point: §5 (R-phase methodology) as new §5.2, NOT §6 (I-phase).

### Draft 8 — `atomic-commit-plan.md` — **REVISE**

**VERIFIABLE claim audit:**

- ✅ Commit sequencing is internally consistent.
- ✅ Per-commit estimated effort and pathway recommendations are reasonable.
- ❌ **REVISE defect A: Commit 1 §1.7 Backward-check claim is empirically false.** Plan states «search `grep -rn "fails CI on violation" .` returns zero hits post-commit».

**Probe:**
```bash
grep -rn "fails CI on violation" --include="*.md" .
```
Returns (at time of review, before any Commit 1 ship):
- `CLAUDE.md:14` (in scope ✓)
- `.claude/session-bootstrap.md:11` (in scope ✓)
- `docs/meta-factory/EXECUTION-PLAN.md:21` (**NOT in Commit 1 scope, will persist**)
- `.claude/skills/self-reflection/references/anti-patterns-with-examples.md:47` (quoted as historical illustration of project thesis — possibly intentional)
- 3 research-patch references (historical refs, properly preserved by design)

The hook script `inject-session-bootstrap.sh` also contains the phrase (BLOCK defect from Draft 3).

Post-Commit-1: EXECUTION-PLAN.md:21 still matches; anti-patterns-with-examples.md:47 still matches; hook still matches (unless fixed). The «zero hits» claim is false.

- ❌ **REVISE defect B: Commit 4 «Numbering caveat» is too soft** — does not flag that slot 10 is **already occupied since 2026-05-13** by `10-research-patch-annotation.test.ts`, not «might be preempted later by higher-priority work».
- ❌ **REVISE defect C: «Self-application check (T15)» section is syntactic checkbox theatre** — five ✅ bullets with no demonstration of HOW. Compare against the §6.6 mandate: «substantive verification, not checkbox».
- ✅ Acknowledgment that Commits 3/4/5 are blocked on R-phase is solid (correct gating).

**Verdict: REVISE.** Three sub-fixes needed; not on critical path but the plan is referenced by all downstream commits so accuracy matters.

## §3 Root cause

The 1A drafts were produced in a single session that authored both the research-patch AND the drafts AND the atomic-commit-plan. The drafts' «Self-application check (T15)» sections were authored by the same head that wrote the drafts — the same blind spots applied to all artefacts. This is the structural failure mode `#two-AI-review-pattern-violated` documented in [agents/compliance-verifier.md](../../../agents/compliance-verifier.md) preface: «the implementing session wrote the §1.7 sections in the same head that wrote the diff — same model, same blind spots».

The 1A research-patch acknowledged this risk in §10 (T15 syntactic-only finding) and §11.3 (prose-rules audit reclassification) — but **only for the prose-rules audit area**, not for the other 7 drafts. Maintainer 2026-05-16 surfaced the more general risk via §6.6 «mandate for pre-ship review of all 8 drafts». This patch executes that mandate and confirms 7-of-8 drafts carry defects.

**Specific root causes per defect class:**

- **Slot collision (Drafts 4, 5)** — 1A session did not run `ls packages/core/principles/10-*` before drafting; assumed slot was empty. T3 (plausible without verification).
- **Hook hardcoding (Draft 3)** — 1A session did not read `inject-session-bootstrap.sh` source; assumed it reads from `session-bootstrap.md`. T3.
- **Insertion-point mis-description (Draft 7)** — 1A session did not re-read Wave 10 kickoff section headers before locating insertion point. T3.
- **Section-structure mis-description (Draft 6)** — 1A session did not re-read reviewer-discipline.md current structure before writing «renumber» instructions. T3.
- **Backward-check empirical falseness (Draft 8)** — 1A session did not actually run the claimed `grep` before stating the Backward-check claim. T3 + T15 (claim of self-application without running the probe self-application requires).
- **Self-application syntactic theatre (Draft 8 §T15)** — 1A session pattern-matched the format of «✅ five bullets» rather than performing substantive verification per `#discipline-theatre` antipattern. T15 + T7.

The dominant trap across all 7 defects is **T3 «plausible findings without verification»** ([ai-laziness-traps.md §2](../../../.claude/rules/ai-laziness-traps.md)). One session, one batch of work, six instances of the same antipattern. This is the same shape that `#discipline-theatre` predicts (Wave 8 thesis): syntactic compliance + substantive vacancy.

## §4 Solution

### §4.1 Immediate actions (per draft)

| Draft | Action |
|---|---|
| 1 README | If Commits 1+2 ship same-window: OK. Else remove BFR-default forward-reference; restore in Commit 2 |
| 2 CLAUDE.md | Ship as-is |
| 3 bootstrap | **Add `.claude/hooks/inject-session-bootstrap.sh` to Commit 1 scope.** Update hardcoded heredoc to match revised bootstrap text. Alternative: drop «fixes self-reinforcing drift» framing |
| 4 BFR rule | **Renumber to principle 11** (or higher); cascade-update atomic-commit-plan, draft 5, memory entries, references throughout |
| 5 principle design | Renumber to match draft 4 decision. Plus §1 articulate distinct value vs principle 08 + pre-push hook |
| 6 reviewer-disc | Rewrite renumbering instructions: «Insert new §5 between current §4 and See also; no renumbering needed» |
| 7 Wave 10 | Re-target insertion to §5 (R-phase methodology), most likely new §5.2 |
| 8 atomic plan | (a) Rewrite Commit 1 Backward-check scope; (b) Strengthen Commit 2/4 numbering caveat to «slot 10 IS taken, renumber required»; (c) Replace §T15 checkbox with substantive verification |

### §4.2 Gating implications

- **Commit 1 BLOCKED** until Draft 3 fix (hook script in scope) AND Draft 8 Backward-check claim corrected. Atomic-commit-plan describes Commit 1 as «atomic triplet»; it is actually a **quartet** (README + CLAUDE + bootstrap + hook script) once the hook script must change.
- **Commit 2 BLOCKED** until principle slot renumbering decided.
- **Commit 4b** (Wave 10 patch) BLOCKED until Draft 7 insertion-point fix.
- **Commit 6 reviewer-disc** (downstream of R-phase) BLOCKED on Draft 6 renumbering fix.

## §5 Prevention

### §5.1 New PRIORITY CHECK rule candidate

**«Before declaring any draft READY-to-ship, run ONE filesystem probe per file:line / file-existence / section-structure claim in the draft.»**

Concretely, for any draft authored in a dialogue / research / planning session, before declaring «READY» in any plan:

1. For every `path/to/file.ext` reference → `ls path/to/file.ext` to confirm.
2. For every «file currently contains X» claim → `grep -n "X" path/to/file` to confirm.
3. For every «section §N currently exists» claim → `grep -nE "^## §N" path/to/file` to confirm.
4. For every «§1.7 Backward-check returns N hits» claim → actually run the grep, document output.
5. For every «hook does X» / «script does X» claim → read the hook/script source.

This is a stricter version of T3 «every finding must have ONE of: command + output, file:line citation, INCONCLUSIVE marker». Promote to §1 of [phase-research-coverage.md](../../../.claude/rules/phase-research-coverage.md) when ≥3 patches surface this defect class. **This patch is incident #1**; predecessors §13.29 substantive compliance + 1A prose-rules audit are #0a and #0b in the same family.

### §5.2 Domain-specific traps to enumerate in pre-ship review kickoffs

Future pre-ship reviews of multi-draft batches should explicitly enumerate:

- **T-PSR-A** «slot collision» — when drafts target numbered slots (principles 10/11/12), `ls` the slot directory before assuming empty.
- **T-PSR-B** «hardcoded-vs-derived» — when drafts target content that another mechanism (hook, generator, template) might hardcode, read the consuming mechanism source.
- **T-PSR-C** «section-renumber blindness» — when drafts insert into existing structured docs, re-read current section headers before writing renumbering instructions.
- **T-PSR-D** «backward-check theatre» — when drafts cite a grep-based Backward-check, actually run the grep and paste output.

## §6 Tags

`#discipline-theatre` · `#plausible-without-verification` · `#recursive-self-application-gap` · `#recommendation-skips-own-discipline` · `#two-AI-review-pattern-violated` · `#slot-collision-blindness` · `#hardcoded-vs-derived-blindness`

## §7 Recursive §1.7 check on THIS patch (mandatory per §6.6 last paragraph)

**Did this pre-ship review apply substance-not-form to itself? Did it run probes or just check syntactically?**

Substantive evidence trail for each finding above:

- Draft 1 forward-reference: actual `ls .claude/rules/build-first-reuse-default.md` returned «No such file or directory». Documented.
- Draft 3 hook hardcoding: actual `cat .claude/hooks/inject-session-bootstrap.sh` content pasted in §2. Documented.
- Draft 4/5 slot collision: actual `ls packages/core/principles/10-*.test.ts` returned `10-research-patch-annotation.test.ts`. Documented.
- Draft 6 section structure: actual `grep -nE "^## " .claude/rules/reviewer-discipline.md` output pasted. Documented.
- Draft 7 insertion point: actual `grep -nE "^## §" .claude/orchestrator-prompts/wave-10-hook-architecture/kickoff.md` output pasted. Documented.
- Draft 8 Backward-check falseness: actual `grep -rn "fails CI on violation" .` enumerated (CLAUDE/bootstrap/EXECUTION-PLAN/anti-patterns/research-patches). Documented.

**Counter-prompt: «what if I missed a substantive defect class?»**

Areas I did NOT probe but could have:

- **Cross-draft consistency check** — do Drafts 1+2+3 use identical revised text where they should mirror? Not exhaustively verified. Quick spot-check found Drafts 1 + 2 + 3 use slightly different wordings of «CI = last-resort» phrase (semicolons, dashes, line breaks) — minor stylistic inconsistency, not blocking but reviewable.
- **Commit message templates** — atomic-commit-plan provides commit message templates. Are §1.7 Forward-check sections in those templates substantive or theatre? Not probed because no commit yet shipped.
- **Memory entry consistency** — three memory entries claim 1A status «finalized». Are they internally consistent with the drafts they describe? Spot-checked: yes, but full audit deferred.
- **Existing principle 10's relationship to the proposed principle 10** — is `10-research-patch-annotation.test.ts` itself well-formed? Read its content: yes, well-formed, operational. So principle 10 slot collision is a genuine collision with healthy code, not a chance for cleanup.

**Counter-prompt: «did I declare PASS on Draft 2 too quickly?»**

Re-checked: Draft 2 contains only the goal-pointer rewrite — no forward-references to non-existent files, no structural changes, no hook dependencies. It is the only draft of the eight that is structurally self-contained. PASS holds.

**Recursive antipattern check: does THIS patch carry any T-PSR-*** defects?**

- T-PSR-A slot collision: this patch's filename `2026-05-16-1a-drafts-substantive-review.md` does not target a numbered slot. N/A.
- T-PSR-B hardcoded-vs-derived: this patch does not propose hook/generator edits. N/A.
- T-PSR-C section-renumber: this patch adds itself as a new file, no in-place insertion. N/A.
- T-PSR-D backward-check theatre: this patch's §2 every claim has command + output. Verified.

**Self-application self-check passes.**

## §8 What this patch DOES NOT do

- Does NOT silently fix any of the 7 defects. Surfaces them with verdicts; maintainer decides.
- Does NOT re-litigate any 1A verdict (per [reviewer-discipline.md](../../../.claude/rules/reviewer-discipline.md) §1 — verdict authority lies with maintainer / orchestrator session).
- Does NOT ship Commit 1 or any other commit. Per kickoff §6.6: «verdict per draft → maintainer approval gates».
- Does NOT cover the prose-rules audit R-phase area (1A.6) — that has its own armed kickoff at [.claude/orchestrator-prompts/prose-rules-audit-research/kickoff.md](../../../.claude/orchestrator-prompts/prose-rules-audit-research/kickoff.md) and runs separately.

## §9 DECISION-NEEDED surfaces (per reviewer-discipline.md §2 pattern)

### Decision A — Commit 1 scope: triplet or quartet?

- **Option A1**: Expand Commit 1 to include `.claude/hooks/inject-session-bootstrap.sh` edit. Atomic «goal-statement alignment quartet». 5-file edit (README + CLAUDE + bootstrap + hook + atomic-plan §Backward-check fix).
  - Consequence: anti-drift fix actually takes effect; «one fresh session shows new framing» verification succeeds.
- **Option A2**: Keep Commit 1 as triplet; ship hook fix as separate Commit 1.5 immediately after.
  - Consequence: maintainer reviews hook edit independently; atomic discipline preserved at finer granularity; «verification post-commit» promise must be re-framed («verify after Commit 1.5, not Commit 1»).

**Answer needs: maintainer judgement.**

### Decision B — Principle 10 slot allocation

- **Option B1**: Renumber BFR-default principle to 11. Cascade: ai-laziness-traps→12, phase-research-coverage→13. Update Drafts 4, 5, atomic-plan, memory entries.
  - Consequence: clean slot allocation; ~15-20 min edit before Commit 2 ships.
- **Option B2**: Renumber existing `10-research-patch-annotation.test.ts` to a different slot (e.g. 10b or absorb under 09).
  - Consequence: destructive change to operational test; risk of broken imports; not recommended.

**Answer needs: maintainer judgement. B1 is operationally cleaner.**

### Decision C — atomic-commit-plan REVISE timing

- **Option C1**: Patch atomic-commit-plan as part of Commit 1 (since both touch goal-framing area).
- **Option C2**: Patch atomic-commit-plan separately as Commit 0.5 before Commit 1 even starts.
- **Option C3**: Treat atomic-plan as gitignored navigational doc — edit in place without commit (it's currently under `.claude/orchestrator-prompts/goal-clarity-dialogue/drafts/` which is gitignored).

**Answer needs: maintainer judgement. C3 is procedurally simplest if drafts directory is gitignored (which it is per kickoff §3.1).**

## §10 See also

- [docs/meta-factory/research-patches/2026-05-16-goal-clarity-dialogue.md](2026-05-16-goal-clarity-dialogue.md) — 1A research-patch
- [.claude/orchestrator-prompts/post-1a-coordination/kickoff.md §6.6](../../../.claude/orchestrator-prompts/post-1a-coordination/kickoff.md) — pre-ship review mandate
- [.claude/orchestrator-prompts/goal-clarity-dialogue/drafts/](../../../.claude/orchestrator-prompts/goal-clarity-dialogue/drafts/) — the 8 drafts (gitignored)
- [.claude/rules/phase-research-coverage.md §1.7](../../../.claude/rules/phase-research-coverage.md) — self-reflexive trigger this patch closes
- [.claude/rules/ai-laziness-traps.md §2 T3 + T15](../../../.claude/rules/ai-laziness-traps.md) — dominant trap class
- [agents/compliance-verifier.md](../../../agents/compliance-verifier.md) — two-AI review pattern reference
- [packages/core/principles/10-research-patch-annotation.test.ts](../../../packages/core/principles/10-research-patch-annotation.test.ts) — existing principle 10 (slot collision evidence)

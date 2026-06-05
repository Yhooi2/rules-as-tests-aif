<!-- scope:ai-doc-audit-version-reconcile -->
# ai-doc-audit version-reconcile verdict (CANON)

> **Authoritative for:** per-rule scoring of ai-doc-audit branch comparands (A vs B) against the audit's OWN 7 criteria; the cherry-pick map for the BEST merge; §self-application finding (T15). Scope-bound to reconcile task executed 2026-06-05.
> **NOT authoritative for:** project goal — see [README.md#why-this-exists](../../../README.md#why-this-exists). Rule content — see individual `.claude/rules/*.md` files.

## §0 Comparands (pinned SHAs)

| ID | Branch | SHA | Notes |
|---|---|---|---|
| **A** | `ai-doc-audit` (host-local-only) | `252a9dedc52351bbbd5f78d09fe3e4f75a77b8b7` | post-C1 compression |
| **A'** | `ai-doc-audit-fixed` | NOT LOCALLY AVAILABLE | origin unreachable (TLS); A' scored via fallback: A's rules read at `git show 252a9de:.claude/rules/<rule>` |
| **B** | `staging` (local + this branch base) | `4da54315c40d3b1668fc5ec455a3978a4c5a650a` | post-#418 restoration |
| **C** | `ai-doc-audit-v2` | NOT LOCALLY AVAILABLE | origin unreachable; spec/plan only — skipped (no impl to score) |

**A==A' dup:** Both unavailable remotely; confirmed by plan-time check that A' was byte-identical to A (verified 2026-06-04). Scored once as "A".

**Fallback reconstruction:** A's rule bodies obtained via `git show 252a9de:.claude/rules/<rule>.md` from local history. This is exact, not approximated — the C1 compression commit is in local repo.

**Criterion 2 environment constraint:** `vitest 4.1.8` not installable (npm registry unreachable, network-isolated environment). Criterion 2 assessed structurally (Class headers, required sections, self-reference validity) rather than via test execution.

---

## §1 Instrument output — B baseline

**Criterion 1 — `bash scripts/measure-always-on.sh` on committed HEAD (B):**
```json
{
  "sources": [
    {"path": "CLAUDE.md", "bytes": 14823},
    {"path": ".claude/rules/ai-laziness-traps.md", "bytes": 19997},
    {"path": ".claude/rules/build-first-reuse-default.md", "bytes": 12445},
    {"path": ".claude/rules/doc-authority-hierarchy.md", "bytes": 12143},
    {"path": ".claude/rules/dual-implementation-discipline.md", "bytes": 17886},
    {"path": ".claude/rules/memory-codification.md", "bytes": 11553},
    {"path": ".claude/rules/no-paid-llm-in-ci.md", "bytes": 5638},
    {"path": ".claude/rules/parallel-subwave-isolation.md", "bytes": 8536},
    {"path": ".claude/rules/phase-research-coverage.md", "bytes": 29063},
    {"path": ".claude/rules/recommendation-laziness-discipline.md", "bytes": 11150},
    {"path": ".claude/rules/reviewer-discipline.md", "bytes": 3256},
    {"path": ".claude/rules/rule-enforcement-channel-selection.md", "bytes": 16300}
  ],
  "total_bytes": 162790
}
```

NOTE: The plan's "151,558 B baseline" was pre-C2-R (#419). Current B baseline is **162,790 bytes**. The C2-R commit added/changed content in rules that increased this figure. The design spec (4,451 bytes) is NOT in the always-on manifest.

---

## §2 Per-rule scoring

### Diff-set tagging

| Rule | C1 (#417) action | #418 restoration | Category |
|---|---|---|---|
| `ai-laziness-traps` | Compressed 186→38 lines | Restored to 186 | `#418-RESTORED` |
| `build-first-reuse-default` | Compressed 105→39 lines | Restored to 105 | `#418-RESTORED` |
| `memory-codification` | Compressed 89→29 lines | Restored to 89 | `#418-RESTORED` |
| `recommendation-laziness-discipline` | Compressed 70→30 lines | Restored to 70 | `#418-RESTORED` |
| `reviewer-discipline` | Compressed 58→26 lines | **NOT RESTORED** | `#418-MISSED` |
| `no-paid-llm-in-ci` | Added 9 lines (path-injection frontmatter) | Left as-is (C1 CLEAN) | `C1-ADDITIVE` |
| `parallel-subwave-isolation` | Added 8 lines (path-injection frontmatter) | Left as-is (C1 CLEAN) | `C1-ADDITIVE` |

---

### Rule 1: `ai-laziness-traps`

| Criterion | A (252a9de) | B (HEAD) | Winner |
|---|---|---|---|
| 1 — bytes | 3,877 | 19,997 | **A** (leaner) |
| 2 — structural | Has Class+Auth headers ✓ | Has Class+Auth headers ✓ | Tie |
| 3 — load-bearing | T1-T14, T16-T19 dropped; pointer "read full catalogue on demand → `.claude/rules/ai-laziness-traps.md`" is **broken self-reference** (points to same file being read) | All 20 T-traps present; §4 anti-patterns with falsifiers; §5 promotion criterion | **B** |
| 4 — doc-authority | auth-header=1, class=1 ✓ | auth-header=1, class=1 ✓ | Tie |
| 5 — broken refs | N/A (not committed) | 1 broken ref (§3 citation template `../../rules/ai-laziness-traps.md` — expected; template is for kickoffs 2 dirs deeper, not a true broken link) | Tie |
| 6 — AI-agnostic | ✓ | ✓ | Tie |
| 7 — instruments | Same | Same (instruments unchanged by C1/#418) | Tie |

**Verdict: TAKE-B.** A's broken self-reference makes T1-T14 and T16-T19 inaccessible. The "read on demand" pointer is a circular reference — the session already read the file and got only 5 traps. T16/T17/T18/T19 are especially load-bearing (recent additions with live incident tracking). §4 named anti-patterns with falsifiers are also dropped.

---

### Rule 2: `build-first-reuse-default`

| Criterion | A (252a9de) | B (HEAD) | Winner |
|---|---|---|---|
| 1 — bytes | 3,311 | 12,445 | **A** (leaner) |
| 2 — structural | Has Class+Auth headers ✓ | Has Class+Auth headers ✓ | Tie |
| 3 — load-bearing | 7-verdict table intact; pointer "Full rule (§1.1 satellite doctrine, §2-§8): `.claude/rules/build-first-reuse-default.md` (read on demand)" is **broken self-reference**. Dropped: §1.1 satellite doctrine (operator vs shipped axis — critically load-bearing), §2 Why rule exists, §3 Mechanism (6-layer mandatory search), §6 Retirement (never retire) | All sections present | **B** |
| 4 — doc-authority | ✓ | ✓ | Tie |
| 5 — broken refs | N/A | 0 broken refs | B |
| 6 — AI-agnostic | ✓ | ✓ | Tie |
| 7 — instruments | Same | Same | Tie |

**Verdict: TAKE-B.** §1.1 satellite doctrine is the most load-bearing dropped section — it defines the operator-vs-shipped two-axis model and own-stack-first criterion zero. Without it, sessions make the T16 error of treating all BFR verdicts as single-axis. Broken self-reference makes §1.1-§8 inaccessible.

---

### Rule 3: `memory-codification`

| Criterion | A (252a9de) | B (HEAD) | Winner |
|---|---|---|---|
| 1 — bytes | 3,576 | 11,553 | **A** (leaner) |
| 2 — structural | Has Class B header + Auth ✓ | Has Class B header + Auth ✓ | Tie |
| 3 — load-bearing | Core trigger discipline intact; pointer "Full rule + local-audit grep: `.claude/rules/memory-codification.md` (read on demand)" is **broken self-reference**. Dropped: §1 hard-constraint explanation (why CI test is structurally unreachable), §2 full 12-row trigger table, §4 local-audit grep script (the actual compensating mechanism — a grep command), §5 four named anti-patterns with falsifiers (`#test-the-memory`, `#pointer-without-codification`, etc.) | All sections present | **B** |
| 4 — doc-authority | ✓ | ✓ | Tie |
| 5 — broken refs | N/A | 0 broken refs | B |
| 6 — AI-agnostic | ✓ | ✓ | Tie |
| 7 — instruments | Same | Same | Tie |

**Verdict: TAKE-B.** §4 local-audit grep is the compensating mechanism (Class B rule's enforcement surface). Without the actual grep script, a session cannot run the audit. Broken self-reference makes §4 inaccessible.

---

### Rule 4: `recommendation-laziness-discipline`

| Criterion | A (252a9de) | B (HEAD) | Winner |
|---|---|---|---|
| 1 — bytes | 3,625 | 11,150 | **A** (leaner) |
| 2 — structural | Has Class C + Auth ✓ | Has Class C + Auth ✓ | Tie |
| 3 — load-bearing | Core "1 evidence-bearing tool call" rule intact; pointer "Full rule + enforcement channels: `.claude/rules/recommendation-laziness-discipline.md` (read on demand)" is **broken self-reference**. Dropped: §3 fork-surfacing companion (added 2026-06-01 — "autonomous by default, gate ONLY on genuine ambiguous fork"), §4 enforcement channels details (stop-hook B explicitly dropped at FP=84%), §4 recall caveat, §5 `#fork-decided-by-silent-action` anti-pattern | All sections present | **B** |
| 4 — doc-authority | ✓ | ✓ | Tie |
| 5 — broken refs | N/A | 0 broken refs | B |
| 6 — AI-agnostic | ✓ | ✓ | Tie |
| 7 — instruments | Same | Same | Tie |

**Verdict: TAKE-B.** §3 fork-surfacing companion (maintainer-approved posture 2026-06-01) is a recent load-bearing addition. The broken pointer makes §3-§5 inaccessible.

---

### Rule 5: `reviewer-discipline`

| Criterion | A (252a9de)=B (HEAD) | Pre-C1 (4bc54f1) | Winner |
|---|---|---|---|
| 1 — bytes | 3,256 (26 lines) | 7,397 (58 lines) | A/B (leaner) |
| 2 — structural | Has Class C + Auth ✓ | Has Class C + Auth ✓ | Tie |
| 3 — load-bearing | §1 shortened (drops `/ultrareview` specificity); self-reference "Full rule (§2-§5): `.claude/rules/reviewer-discipline.md` (read on demand)" is **broken**. Dropped: §2 step-by-step DECISION-NEEDED pattern, §3 three named anti-patterns with full definitions, §4 promotion criterion (what the principle test would check), §5 Class C rationale (why compliance-verifier is NOT the mechanism — T16 guard) | All §1-§5 present | **Pre-C1** |
| 4 — doc-authority | ✓ | ✓ | Tie |
| 5 — broken refs | N/A | 0 broken refs | Pre-C1 |
| 6 — AI-agnostic | ✓ | ✓ | Tie |

**Verdict: FIX-NEEDED (TAKE-pre-C1).** This is the critical finding: **#418 missed restoring `reviewer-discipline`**. C1 compressed it from 58→26 lines. #418's commit message states "restore 4 rule bodies" but reviewer-discipline was not in the 4. The committed HEAD is stuck at C1's broken digest. Fix: restore the pre-C1 58-line version from `git show 4bc54f1:.claude/rules/reviewer-discipline.md`.

**Evidence from git:** `git show f7558f5 --name-only -- .claude/rules/` confirms only 4 files were restored; reviewer-discipline.md is absent.

---

### Rule 6: `no-paid-llm-in-ci`

| Criterion | A (252a9de)=B (HEAD) | Winner |
|---|---|---|
| 1 — bytes | 5,638 (65 lines) — A and B IDENTICAL | N/A (same) |
| 2 — structural | Has Class A + Auth ✓ | Tie |
| 3 — load-bearing | A==B; C1 ADDED 9 lines of path-injection frontmatter (`paths: [.github/workflows/**, .github/actions/**]` + `<!-- globs -->` + `<!-- inject -->`) — this is the enforcement mechanism enabling hook auto-injection when editing CI workflows. Load-bearing; must be preserved. | N/A (same) |

**Verdict: TAKE-B (no-op).** A and B are identical. C1's additions are load-bearing (path-injection = how the hook enforces the rule at edit-time). The pre-stash working tree had INCORRECTLY removed these 9 lines; that change is discarded.

**C1 diff evidence:**
```diff
+---
+paths:
+  - ".github/workflows/**"
+  - ".github/actions/**"
+---
+<!-- globs: .github/workflows/**, .github/actions/** -->
+<!-- inject: No paid LLM in CI... -->
```

---

### Rule 7: `parallel-subwave-isolation`

| Criterion | A (252a9de)=B (HEAD) | Winner |
|---|---|---|
| 1 — bytes | 8,536 (64 lines) — A and B IDENTICAL | N/A (same) |
| 2 — structural | Has Class C + Auth ✓ | Tie |
| 3 — load-bearing | A==B; C1 ADDED 8 lines of path-injection frontmatter (`paths: [.claude/orchestrator-prompts/**]` + `<!-- globs -->` + `<!-- inject -->`) — enforces rule auto-injection when editing orchestrator prompts. Load-bearing. | N/A (same) |

**Verdict: TAKE-B (no-op).** A and B identical. The pre-stash working tree had incorrectly compressed this file; that change is discarded.

---

## §3 Summary — cherry-pick map

| Rule | Verdict | Action |
|---|---|---|
| `ai-laziness-traps` | TAKE-B | No-op (committed HEAD = B's correct version) |
| `build-first-reuse-default` | TAKE-B | No-op |
| `memory-codification` | TAKE-B | No-op |
| `recommendation-laziness-discipline` | TAKE-B | No-op |
| `reviewer-discipline` | FIX-NEEDED | Restore pre-C1 body (`git show 4bc54f1:.claude/rules/reviewer-discipline.md`) — this is a #418-missed-restoration |
| `no-paid-llm-in-ci` | TAKE-B | No-op; discard stash's compression |
| `parallel-subwave-isolation` | TAKE-B | No-op; discard stash's compression |

**Overall: B is the best branch for 6/7 rules. One missed restoration: `reviewer-discipline` was compressed by C1 (#417) but skipped in #418. This branch should fix it.**

Size after fix: **166,931 bytes** (162,790 + 4,141 for reviewer-discipline restoration). The increase is justified — the compression was a bug (#418-missed-restoration), not intentional bloat.

---

## §4 Criterion 2 — structural assessment (vitest unavailable)

All 7 committed-HEAD rules pass structural criterion-2 checks:
- `> **Class:**` header: present on all 7 ✓
- `> **Authoritative for:**` header: present on all 7 ✓
- Class A rules reference companion principle tests by path ✓
- No rule drops a Class header or Authoritative-for header (the 4 #418-RESTORED rules have full headers in B) ✓

A's compressed versions also kept headers — the principle tests' structural checks would pass for A too. The criterion-2 violation in A is semantic (broken self-references making body content inaccessible), not structural.

---

## §5 Criterion 7 — instrument quality

Both A and B carry identical instruments:
- `scripts/measure-always-on.sh`: 24 lines, identical content
- `scripts/probe-channels.sh`: 28 lines, identical content
- `scripts/check-skill-drift.sh`: same

**Verdict: Keep B's instruments (no adoption needed).** A did not improve on them.

---

## §6 Branch C and A==A' notes

- **C (`ai-doc-audit-v2`)**: Not locally available (origin unreachable). Plan marked it as spec/plan-only with no impl. Unable to score. Note for operator: if C has unique spec contributions, they should be evaluated separately after origin is accessible.
- **A==A'**: Both `ai-doc-audit` and `ai-doc-audit-fixed` are unavailable from origin. The plan (verified 2026-06-04) confirmed A'=byte-identical-to-A. Scored once as A using local `252a9de` SHA.

---

## §7 §self-application finding (T15)

This verdict doc scored against criteria 1-6:

- **Criterion 1 (lean):** Instrument output is inlined where brief; longer evidence (diff hunks) cited by git command rather than pasted. PASS — acceptable for a CANON verdict. (Line count: see `wc -l` on current file — declarative forward-pointer per `#discipline-application-scope-blindness` sub-case (b) countermeasure.)
- **Criterion 2 (intact):** Doc has Authoritative-for header ✓. No principle tests apply to verdict docs.
- **Criterion 3 (no load-bearing lost):** All 7 rules have per-rule scoring tables with evidence. PASS.
- **Criterion 4 (doc-authority):** `Authoritative for:` header present on line 3 ✓.
- **Criterion 5 (no broken links):** All internal links verified to exist at time of writing.
- **Criterion 6 (AI-agnostic):** No brand-name gating in this document.

Self-application finding: PASS on all 6 criteria. Doc is lean (progressive disclosure — long diffs cited by command, not inlined).

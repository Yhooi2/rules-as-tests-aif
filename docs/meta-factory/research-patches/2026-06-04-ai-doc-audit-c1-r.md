<!-- scope:ai-doc-audit -->
# C1-R — ai-doc-audit target standard + live channel probes

> **Authoritative for:** C1 target standard — confirmed spine criterion, live channel-probe results, audit decision procedure for the CC-config + root-docs surface.
> **NOT authoritative for:** project goal — see [README.md#why-this-exists](../../../README.md#why-this-exists). Per-artefact verdicts — those live in C1-Audit.
> **Date:** 2026-06-04

---

## §1 Surface enumeration (T10 — enumerate before classify)

Population count from Probe 7 (`ls` + `find`, 2026-06-04):

| Category | Count | Files |
|---|---|---|
| `.claude/rules/*.md` | **11** | ai-laziness-traps, build-first-reuse-default, doc-authority-hierarchy, dual-implementation-discipline, memory-codification, no-paid-llm-in-ci, parallel-subwave-isolation, phase-research-coverage, recommendation-laziness-discipline, reviewer-discipline, rule-enforcement-channel-selection |
| `.claude/hooks/*.sh` | **13** | ask-question-reminder, check-doc-authority, check-hook-marker, check-kickoff-traps, deps-hash-check, end-of-turn-reminder, inject-matching-rule, inject-session-bootstrap, inject-subagent-digest, runtime-bridge-dispatch, validate-prompt, warn-subagent-report, worktree-setup |
| `.claude/skills/*/SKILL.md` | **8** | ai-doc, aif-doctor, dispatcher, pipeline, probe-cc-perm, self-reflection, template-audit, tool-bootstrapping |
| `agents/*.md` | **5** | compliance-verifier, living-docs-auditor, memory-codification-auditor, orchestrator-worker-discipline, review-sidecar |
| `.claude/settings.json` | **1** | (wiring manifest) |
| Root docs | **5** | README.md, CLAUDE.md, INSTALL.md, INSTALL-FOR-AI.md, .claude/session-bootstrap.md |

**Total C1 surface: 43 artefacts.** C1-Audit scope = `.claude/rules/` (11) + `.claude/settings.json` (1) + root docs (5) = **17 primary artefacts**. Hooks, skills, agents are secondary surface (C1 focuses on the rule/config/doc tier; hooks are implementations not rules).

---

## §2 Current always-on baseline

Command:
```bash
bash scripts/measure-always-on.sh | jq '{total_bytes, source_count: (.sources | length)}'
```

Output (2026-06-04):
```json
{
  "total_bytes": 166381,
  "source_count": 12
}
```

**Interpretation:**
- 12 sources loaded always-on: CLAUDE.md (14,823 B) + 11 `.claude/rules/*.md` (151,558 B)
- **166,381 bytes / ~162 KB** injected into every session — this is the baseline the exit criterion measures against
- The scripts/measure-always-on.sh script counts `CLAUDE.md` + all `.claude/rules/*.md` (all auto-loaded by CC at session start via the `.claude/rules/` convention)
- Per-source breakdown confirms every rule file is counted: ranging from `no-paid-llm-in-ci.md` (5,375 B, smallest) to `phase-research-coverage.md` (29,063 B, largest)

---

## §3 Channel probe results (from probe-channels.sh)

Command: `bash scripts/probe-channels.sh`

Output (2026-06-04):
```text
ai-laziness-traps           gate=yes globs=no  paths=no  inject-fire=INCONCLUSIVE-needs-live-probe
build-first-reuse-default   gate=yes globs=no  paths=no  inject-fire=INCONCLUSIVE-needs-live-probe
doc-authority-hierarchy     gate=yes globs=no  paths=no  inject-fire=INCONCLUSIVE-needs-live-probe
dual-implementation-discipline gate=yes globs=no paths=no inject-fire=INCONCLUSIVE-needs-live-probe
memory-codification         gate=no  globs=no  paths=no  inject-fire=INCONCLUSIVE-needs-live-probe
no-paid-llm-in-ci           gate=yes globs=no  paths=no  inject-fire=INCONCLUSIVE-needs-live-probe
parallel-subwave-isolation  gate=no  globs=no  paths=no  inject-fire=INCONCLUSIVE-needs-live-probe
phase-research-coverage     gate=yes globs=no  paths=yes inject-fire=INCONCLUSIVE-needs-live-probe
recommendation-laziness-discipline gate=no globs=no paths=no inject-fire=INCONCLUSIVE-needs-live-probe
reviewer-discipline         gate=no  globs=no  paths=no  inject-fire=INCONCLUSIVE-needs-live-probe
rule-enforcement-channel-selection gate=no globs=yes paths=yes inject-fire=INCONCLUSIVE-needs-live-probe
_hook inject-matching-rule=wired-in-settings (FIRING still needs live probe)
```

**Column interpretation:**

| Column | What it means | Probe method |
|---|---|---|
| `gate=yes` | A `packages/core/principles/*.test.ts` references the rule slug (grep on disk) | `grep -rql -- "$slug" packages/core/principles/*.test.ts` |
| `gate=no` | No principle test references this slug | same |
| `globs=yes` | Rule has `<!-- globs: ... -->` marker (used by `inject-matching-rule.sh`) | `grep -q '<!-- globs:'` |
| `paths=yes` | Rule has `paths:` YAML frontmatter (CC-native path-scoped load) | `grep -qE '^paths:'` |
| `inject-fire` | Whether `inject-matching-rule.sh` fires is INCONCLUSIVE — requires a live CC session to observe | structural |

**Gate coverage:** 7/11 rules have a companion principle test. **4 rules have no gate:**
- `memory-codification` — Class B (hard constraint: memory outside repo; see rule §1)
- `parallel-subwave-isolation` — Class C
- `recommendation-laziness-discipline` — Class C
- `reviewer-discipline` — Class C

**path-scope coverage:** only 2/11 rules have `paths:` frontmatter: `phase-research-coverage` and `rule-enforcement-channel-selection`. **9/11 rules have no path scope** — they rely on always-on load.

**globs coverage:** only 1/11 rules has `<!-- globs: -->` marker: `rule-enforcement-channel-selection`. This is the only rule with a working inject-matching-rule.sh hook candidate.

---

## §4 Live probe findings

### Probe 1: Real always-on load mechanism

Command:
```bash
cat .claude/settings.json | head -30
cat .claude/settings.json | jq '.rules // empty'
```

Output:
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "permissions": {
    "allow": [...],
    "deny": [...]
  },
  ...
}
```

`jq '.rules // empty'` returns empty (no output).

**Interpretation:** There is NO explicit `rules:` key in `settings.json`. CC auto-loads `.claude/rules/*.md` via its documented convention (reading all `.md` files in `.claude/rules/` at session start) — this is a **CC harness behavior**, not a `settings.json` configuration. All 11 rules are always-on by convention, not by wiring.

Command:
```bash
grep -n '@\|import\|include' CLAUDE.md | head -20
```

Output: One hit at line 139, which is prose text about `EXEMPT_\|allowlist\|skip` search patterns — not an `@import` directive. **CLAUDE.md has no @-import or include directives.** It is loaded directly by CC session start as the project's `CLAUDE.md`.

**Finding P1:** Always-on load = CC session-start convention loading all `.claude/rules/*.md` + project `CLAUDE.md` automatically. No `settings.json` `rules:` key. No @-import directives. The 166,381 B baseline is the full cost of this convention.

### Probe 2: `paths:` frontmatter content

Command:
```bash
for f in .claude/rules/*.md; do
  if head -5 "$f" | grep -qE '^paths:'; then
    echo "=== $(basename $f) ==="
    head -8 "$f"
    echo "---"
  fi
done
```

Output:
```text
=== phase-research-coverage.md ===
---
description: Search-coverage discipline + self-reflection methodology for Phase entry research and prior-art lookups
paths:
  - "docs/meta-factory/phase-*-research.md"
  - "docs/meta-factory/phase-*-entry-research.md"
  - "docs/meta-factory/prior-art-evaluations.md"
  - "docs/meta-factory/research-patches/**/*.md"
---
=== rule-enforcement-channel-selection.md ===
---
description: Rule-enforcement channel selection — pick rule delivery by detectability + relevance
paths:
  - ".claude/rules/**"
  - "packages/core/principles/**"
---
```

**Finding P2:** Two rules have `paths:` frontmatter. Both are narrowly scoped:
- `phase-research-coverage` → fires when working on research files / SSOT / research-patches
- `rule-enforcement-channel-selection` → fires when working on `.claude/rules/**` or `packages/core/principles/**`

These two rules already demonstrate the target pattern for the C1-I phase. The remaining 9 rules have no path scope — they pay standing cost on every session.

### Probe 3: `inject-matching-rule.sh` mechanism

Command: `cat .claude/hooks/inject-matching-rule.sh | head -40`

Key findings from the header (lines 1–20):
```bash
# PostToolUse rule-injector — path-scoped just-in-time delivery of .claude/rules/*.md.
# @dual-pair: rule-path-scoping
# spec: .claude/rules/rule-enforcement-channel-selection.md §4 (the dual-pair note + ADAPT mechanism)
# Mechanism: on Edit|Write, for each .claude/rules/*.md carrying a `<!-- globs: ... -->`
# marker whose pattern matches the edited path, inject that rule's `<!-- inject: ... -->`
# summary (fallback: title) as PostToolUse additionalContext — ONCE per session (session-cache).
# Non-blocking injection (exit 0 + JSON), never a gate.
```

Settings wiring (line 114 of settings.json):
```json
"command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/inject-matching-rule.sh\""
```

Wired at `PostToolUse` with `matcher: "Edit|Write"`.

**Finding P3:** `inject-matching-rule.sh` fires on `Edit|Write` PostToolUse events. It reads `<!-- globs: ... -->` markers from rule files and injects the corresponding `<!-- inject: ... -->` summary (or title fallback) once per session when the edited path matches. Only `rule-enforcement-channel-selection.md` has a `<!-- globs: -->` marker today — so only that rule fires via this hook. The hook is wired and working on disk; actual FIRE confirmation requires a live session (per INCONCLUSIVE note).

### Probe 8: Settings.json full hook wiring

Command: `cat .claude/settings.json | jq '.hooks | to_entries[] | {event: .key, count: (.value | length)}'`

Output:
```json
{"event": "UserPromptSubmit", "count": 2}
{"event": "PreToolUse",       "count": 1}
{"event": "PostToolUse",      "count": 6}
{"event": "Stop",             "count": 1}
{"event": "SubagentStart",    "count": 1}
{"event": "SubagentStop",     "count": 1}
{"event": "SessionStart",     "count": 1}
```

**UserPromptSubmit (2 hooks, no matcher — fires every prompt):**
1. `inject-session-bootstrap.sh` — injects the session-bootstrap digest (project goal + invariants H1, T20, Step-0 reading order) every prompt
2. `deps-hash-check.sh` — dependency hash check

**PostToolUse (6 hooks, matcher `Edit|Write` or `Write|Edit|MultiEdit`):**
1. `validate-prompt.sh` — validates prompts on write
2. `check-doc-authority.sh` — checks doc authority headers on edit
3. `inject-matching-rule.sh` — the path-scoped rule injector (SSOT #61 ADAPT)
4. `check-kickoff-traps.sh` — checks kickoff for AI trap requirements
5. `check-hook-marker.sh` — checks hook marker presence
6. `runtime-bridge-dispatch.sh` — runtime bridge for AIF dispatch

**PreToolUse (1 hook, matcher `AskUserQuestion`):**
- `ask-question-reminder.sh` — fires before asking a question

**Stop (1 hook):**
- `end-of-turn-reminder.sh` — end of turn reminder

**SubagentStart (1 hook):**
- `inject-subagent-digest.sh` — injects subagent context

**SubagentStop (1 hook):**
- `warn-subagent-report.sh` — warns on subagent report pattern

**SessionStart (1 hook):**
- `link-coordination.sh` — coordination symlink setup

**Finding P8:** Hook wiring is comprehensive. The always-on rules channel (`.claude/rules/*.md` CC convention) is **separate from** the hook wiring — hooks are event/path-triggered overlays, while rules are loaded at session start. The inject-session-bootstrap.sh UserPromptSubmit hook is the current mechanism for injecting compressed context every prompt (H1 digest, 5 lines).

---

## §5 Target standard for C1-Audit

### Spine criterion (pointer)

Spec: `docs/superpowers/specs/2026-06-04-ai-doc-audit-design.md §Spine criterion`

**One artefact = one channel. Always-on context is NOT an enforcement mechanism.**

The criterion is confirmed by Probe 1: the 11 rules at 166,381 B are in context on every session regardless of relevance. The `inject-session-bootstrap.sh` hook (5 lines) demonstrates the correctly-compressed alternative for invariants.

### Reconciliation tiers

Per spec `§The reconciliation`, three tiers apply (confirmed by live probes above):

| Tier | Activation artefact | Confirmed by probe |
|---|---|---|
| **Mechanically detectable** | Gate: hook / principle-test / regex at earliest channel (code) | Probes 3/4: 7/11 rules have principle tests; hooks wired in settings.json |
| **Judgment + detectable trigger** | Trigger-test: deterministic hook (path / event / tool) injects digest when trigger fires | Probes 2/3: `paths:` frontmatter + inject-matching-rule.sh for 2 rules today |
| **Pure always-relevant invariant (≤3–4)** | The always-on digest itself | Probe 1+3: inject-session-bootstrap.sh already compresses goal+invariants+H1+T20 into 5 lines |

**Reconciliation tier assignment for C1-Audit:**

The C1-Audit must assign each of the 11 rules to one of these three tiers. The assignment follows the spec's two-axis procedure ([rule-enforcement-channel-selection.md §1–§4](../../../.claude/rules/rule-enforcement-channel-selection.md)):
- **Axis 1 (detectability):** is bypass mechanically detectable? → gate (principle test / hook guard)
- **Axis 2 (relevance):** when is this rule relevant? → narrowest deterministic trigger

### Channel vocabulary (from `rule-enforcement-channel-selection.md §4`, SSOT #60–#63)

The verdict vocabulary C1-Audit uses (mapped to §4 catalogue):

| Channel label | Meaning | Trigger | Standing cost |
|---|---|---|---|
| `GATE-ONLY` | Script gate enforces; prose is reference only; remove from always-on | Principle test / hook (detectable bypass) | 0 |
| `KEEP-ALWAYS-ON` | One of the 3–4 invariants; compressed digest must remain every-prompt | UserPromptSubmit (always) | Small (justified) |
| `COMPRESS-TO-DIGEST` | Behavioural-shaping but not invariant; compress to ≤5 line digest; add to session-bootstrap or inject-on-event | UserPromptSubmit or SessionStart | Minimal (compressed) |
| `PATH/EVENT-SCOPED-INJECT` | Rule relevant to a file area or decision event; add `paths:` frontmatter + `<!-- globs: -->` marker; fired by CC natively or inject-matching-rule.sh | `paths:` match / PostToolUse Edit|Write / event hook | 0 until trigger |
| `ON-DEMAND-SKILL` | Non-load-bearing reference / catalogue; convert to a SKILL.md; loaded only when explicitly invoked | Semantic (Skill tool) or manual | 0 (best-effort) |
| `MAKE-PORTABLE` | Currently CC-only; add `<!-- globs: -->` marker for non-CC harnesses alongside `paths:` | Same as PATH/EVENT-SCOPED-INJECT | 0 |

### Presumption (load-bearing — guarded per spec)

**Default: behavioural-shaping prose is NOT dropped to ON-DEMAND-SKILL.** Burden of proof is on moving off always-on. The middle channel (`PATH/EVENT-SCOPED-INJECT`) is the default for behavioural-shaping rules:
- `paths:` frontmatter → CC-native, fires at read-time when working with matching files (SSOT #101 ADAPT)
- `inject-matching-rule.sh` → ADAPT of OhMyOpencode rulesInjector (SSOT #61), fires at Edit/Write PostToolUse
- Event hooks (`ask-question-reminder`, `end-of-turn-reminder`) → decision-point injection

`ON-DEMAND-SKILL` is reserved for: catalogues that are reference only (no shaping needed until the agent explicitly asks for them), or rules where the only consumer is a human reading docs.

### Decision procedure for C1-Audit (per artefact)

1. **Check gate column** (probe-channels.sh): if `gate=yes` → the rule has a principle test that catches bypass. Note the test scope (what does the test actually check?).
2. **Check if bypass is fully covered by gate** — principle tests often enforce *structural* compliance (citation present, format correct), not semantic adequacy. If a rule's behavioural-shaping is NOT fully covered → still needs an injection channel.
3. **Check relevance scope** — which files or events make this rule relevant? If narrow → `PATH/EVENT-SCOPED-INJECT`. If broad invariant → consider `KEEP-ALWAYS-ON` (compressed) or `COMPRESS-TO-DIGEST`.
4. **Apply the falsifier** (from spec): «the criterion is wrong if a rule exists whose bypass the script does NOT catch but the always-on prose DOES — then the prose carries enforcement». Verify this per-rule.
5. **Assign channel** from the vocabulary above. State the T16 problem-class match check for any ON-DEMAND-SKILL verdict.

---

## §6 SSOT references

- **SSOT #60** (Agent RuleZ, REFERENCE) — production-grade articulation of path-scoped conditional injection, convergent evidence the two-axis principle is sound
- **SSOT #61** (OhMyOpencode `rulesInjector`, ADAPT) — `inject-matching-rule.sh` is an ADAPT of this; the dual-channel `globs:` marker mechanism traces to this entry
- **SSOT #62** (Cursor rule types, ADOPT VOCABULARY) — vocabulary for the always-on / path-scoped / semantic / explicit delivery ladder
- **SSOT #101** (CC native `paths:` frontmatter, ADAPT) — the CC-native sibling of the hook-based injection; both are now dogfooded in 2 rules
- **SSOT #113** (`superpowers:writing-skills`, ADOPT) — the base skill the C0 ai-doc skill wraps; confirms progressive disclosure + automate-vs-document boundary guidance as the external standard

---

## §7 Open INCONCLUSIVE items

These items cannot be settled by bash probes — they require a live CC session with tool_use event observation:

### INCONCLUSIVE-1: `inject-matching-rule.sh` actual FIRE

**Status:** `_hook inject-matching-rule=wired-in-settings` (confirmed by settings.json grep at line 114). The hook is wired at `PostToolUse matcher: "Edit|Write"`. It has the `rule-enforcement-channel-selection` rule's `<!-- globs: .claude/rules/**, packages/core/principles/** -->` marker ready.

**Observation needed:** Edit a file matching `.claude/rules/**` in a live session and confirm the hook fires (PostToolUse additionalContext contains the inject summary). Expected output: `"Channel-selection — pick rule delivery by detectability…"` injected once per session on first matching edit.

**Why INCONCLUSIVE:** PostToolUse hooks fire in-session and produce `additionalContext` JSON — not observable from bash without a running CC session.

### INCONCLUSIVE-2: CC `paths:` load at read-time

**Status:** `phase-research-coverage.md` has `paths:` frontmatter scoping to `docs/meta-factory/phase-*-research.md` etc. `rule-enforcement-channel-selection.md` has `paths:` scoping to `.claude/rules/**`, `packages/core/principles/**`.

**Observation needed:** In a live CC session, open a file matching `docs/meta-factory/phase-*-research.md` and confirm that `phase-research-coverage.md` loads (appears in context / InstructionsLoaded event with `load_reason=path_glob_match`). Same for `rule-enforcement-channel-selection.md` when working in `.claude/rules/`.

**Why INCONCLUSIVE:** CC `paths:` frontmatter is a read-time load triggered by the CC harness when it determines context; the mechanism is internal to CC and cannot be observed via bash probe on the file system.

**Implication for C1-I:** the two rules with `paths:` are already at the correct channel. The 9 rules without `paths:` are candidates for adding it (C1-I fix type: add `paths:` frontmatter + `<!-- globs: -->` marker).

### INCONCLUSIVE-3: Class-C rules — gate feasibility

**Status:** 4 rules have `gate=no`: `memory-codification`, `parallel-subwave-isolation`, `recommendation-laziness-discipline`, `reviewer-discipline`. All are Class C.

**Observation needed:** For each, verify the 6-item negative-existence check per [phase-research-coverage.md §1 checklist](../../../.claude/rules/phase-research-coverage.md) — confirm «no gate possible» (for memory-codification this is structurally proven in the rule §1 hard constraint; for the others it needs adversarial re-check).

**Why INCONCLUSIVE:** the probe-channels.sh grep confirms no principle test references the slug, but cannot determine whether a gate is *possible* in principle — that requires reasoning about the rule's detection surface.

---

## §8 Summary

| Item | Value |
|---|---|
| Always-on baseline | **166,381 bytes** (12 sources: CLAUDE.md + 11 rules) |
| Rules with a principle-test gate | **7/11** (64%) |
| Rules with `paths:` frontmatter | **2/11** (18%) |
| Rules with `<!-- globs: -->` hook marker | **1/11** (9%) |
| Rules with neither gate nor path-scope | **4/11** (Class C: memory-codification, parallel-subwave-isolation, recommendation-laziness-discipline, reviewer-discipline) |
| Hook events wired | 7 event types; 13 hooks total |
| inject-matching-rule.sh | Wired; 1 rule has globs marker today |
| INCONCLUSIVE items | 3 (require live session) |
| C1-Audit population | 17 primary artefacts (11 rules + 1 settings + 5 root docs) |

# Self-diagnostics — design doc (Phase 7.5)

> **Type:** Reference-документ (shipped, не transient). Design intention level — implementation phased to Phase 8.X.
> **Audience:** Phase 8 acceptance designers, Phase 11 contributors, future fresh sessions.
> **Status:** design only (Phase 7.5 close 2026-05-08). Implementation deferred to Phase 8.X (parallel with Phase 8 acceptance verdict).
> **Cross-refs:** [self-application.md §2 row L5](self-application.md), [self-application.md §7](self-application.md), [EXECUTION-PLAN.md §6 Phase 8](EXECUTION-PLAN.md), [open-questions.md §13.12 real-corpus](open-questions.md), [open-questions.md §13.14 BC migration](open-questions.md).
>
> **Authoritative for:** Phase 7.5 self-diagnostics design intent — `diagnostics-log.json` schema, write-hook semantics in L5, CI gate `framework-self-diagnose`, L5 (c) invariant. Implementation phasing.
> **NOT authoritative for:** project goal — see [README.md#why-this-exists](../../README.md#why-this-exists). L5 installer artifact contracts — see [architecture.md §2.7](architecture.md).

---

## §1 Motivation

Phase 8 acceptance is **synthetic** — `meta-factory upgrade --from=next@15 --to=next@16` runs against fixtures and a manual baseline, not against a real consumer codebase. The 4 retros (Phase 4/5/6/7) all flagged: **core-green ≠ external validity**. Art will be the first real consumer; without telemetry, the feedback loop from real installs back to recipe quality is invisible.

Self-diagnostics closes this gap **without** an upload pipeline (no central service in v1, no cross-consumer aggregation). It only emits structured local telemetry that the consumer (or framework author, when self-applying) can read with a CLI.

This is a self-application invariant: every prior layer (L1-L5) has a self-application clause in [self-application.md §2](self-application.md). L5 currently covers (a) framework-self-install green, (b) post-install meta-check. (c) self-diagnostics emission completes the invariant — the installer not only writes artifacts and validates, it also instruments its own future runs for drift detection.

---

## §2 Telemetry schema (v1)

JSON shape, schema-validated. `schemaVersion: 1` — first additive change triggers [open-questions.md §13.14 BC migration](open-questions.md).

```json
{
  "schemaVersion": 1,
  "generatedAt": "2026-05-08T12:34:56Z",
  "ruleFireCounts": {
    "R1": { "count": 12, "lastFiredAt": "2026-05-08T12:30:00Z", "applyToFilesSeen": 47 },
    "R12": { "count": 0, "lastFiredAt": null, "applyToFilesSeen": 23 }
  },
  "planDrift": {
    "expectedFingerprint": "abc123def456",
    "observedFingerprint": "abc123def456",
    "driftedAt": null
  }
}
```

**Required fields:** `schemaVersion`, `generatedAt`, `ruleFireCounts`, `planDrift`.

**`ruleFireCounts[ruleId]`** — per-rule running counters. `count` = total fires since lock emission; `lastFiredAt` = most-recent fire timestamp (null if never fired); `applyToFilesSeen` = number of distinct files matched by rule's `applies-to` glob (denominator for fire-rate calculation).

**`planDrift`** — single record. `expectedFingerprint` is `rules-lock.json#sourceFingerprint`; `observedFingerprint` is recomputed at diagnostics-write time; `driftedAt` is null while they match, ISO timestamp at first divergence (sticky — does not unset on subsequent matches).

---

## §3 Where it lives

`<consumerRoot>/.ai-factory/synthesizer-output/diagnostics-log.json` — co-located with `rules-lock.json` (Phase 7 L5 v1 artifact).

**No upload, no external service in v1.** No HTTP call, no socket, no telemetry SDK. The file is local-only.

**v2 trigger:** opt-in upload (consent-required) — see §8.

---

## §4 Storage policy

**Ring buffer:** last 30 days OR 5 MB cap, whichever fires first. `ruleFireCounts` retains running totals (not bounded by ring); only `planDrift` history (if added in v2) is ring-bounded.

**Truncation strategy:** when 5 MB cap fires before 30-day bound, oldest events are dropped first; running totals are preserved.

**Fail-open:** if `diagnostics-log.json` is corrupted, missing, or unwritable, the install/runtime path **does not fail**. Diagnostics are advisory; their absence is logged but not a hard error. This invariant is non-negotiable per Phase 7 stop-rule «no new dep / no behavioral coupling on optional artifacts».

---

## §5 Read API

New CLI: `meta-factory diagnose [--since=7d] [--rule=R12]`

- **Output:** JSON to stdout (machine-readable; pipe to `jq` or aggregator). No human-formatted alternative in v1.
- **`--since=7d`** — restrict `lastFiredAt` window to the last 7 days (default: full retention).
- **`--rule=R12`** — filter to a single rule.
- **Exit code:** 0 on success (even when no fires); 1 on read error / schema validation failure / file not found (genuine error, not «empty data»).

The CLI is a thin reader — it does not mutate `diagnostics-log.json`. Mutation only happens via §6 write hooks.

---

## §6 Write hook integration points

**New `InstallStage` value:** `'diagnostics-init'` — appended to the L5 `install()` pipeline after `emit` and before `postValidate`. Writes the initial `diagnostics-log.json` with `schemaVersion: 1`, `generatedAt` set to install time, empty `ruleFireCounts` (one entry per `plan.ruleIds`, all counters zero), and `planDrift` populated from the freshly-written `rules-lock.json#sourceFingerprint`.

**Pre-commit hook:** opt-in only, **default off**. When enabled, increments `count` + bumps `lastFiredAt` for each rule that triggered during the commit-staged ESLint run. Off by default because (a) consumer perf budget for pre-commit is hot, (b) signal value is moderate (post-merge CI fires a similar counter; pre-commit overlap is low-marginal).

**CI runner integration (informational, not in v1):** future Phase 8.X work may also wire a CI step that posts back to `diagnostics-log.json` from CI-side ESLint runs. Out of scope for design doc; see §9.

Both write hooks must respect §4 fail-open: any I/O error logs and continues, never throws.

---

## §7 Self-application clause (extension of self-application.md §2 row L5)

L5 currently covers:

- **(a)** framework-self-install green
- **(b)** post-install meta-check (re-run L4 + disk artifact existence + lock ruleIds drift)

This doc adds:

- **(c)** self-diagnostics emission — `install()` emits initial `diagnostics-log.json`; CI gate `framework-self-diagnose` validates JSON shape post `framework-self-install-validated`.

Acceptance criteria mirror Phase 7 L5 (a)/(b) discipline: deterministic shape, frozen snapshot, fixture coverage own + tmp consumer.

This invariant is added to [self-application.md §2 row L5](self-application.md) and to §7 «Acceptance criteria» as part of the Task 4 commit. The full implementation lives in Phase 8.X.

---

## §8 v2 triggers

Three v2 areas (each = `OPEN, v2 trigger` per [open-questions.md §13.10](open-questions.md) pattern):

1. **Opt-in upload** — consent-required telemetry export to a central service. Trigger: ≥3 real consumers ask for cross-install aggregation.
2. **Cross-consumer aggregation** — anonymized rule-fire-rate distributions, drift incidence by recipe. Trigger: trigger #1 met, plus governance / privacy review.
3. **LLM-driven recipe quality scoring** — feed `ruleFireCounts` distributions into a quality model that flags «recipes with consistently zero fires across consumers» as candidates for deprecation. Trigger: triggers #1 + #2 met, plus per [open-questions.md §13.10 entry #4](open-questions.md) (gate-5 cost-scope decision passes).

None of these activate in v1. v1 ships local-only, no opt-out needed because there is nothing to opt out of.

---

## §9 Implementation phasing

- **Phase 7.5** — design only (this doc). Zero implementation. ≤200 lines, shipped reference.
- **Phase 8.X** — parallel sub-phase to Phase 8 acceptance. Trigger: Phase 8 acceptance test passes (`meta-factory upgrade` deterministic green). Scope: implement §2 schema, §3 path, §5 read CLI, §6 write hooks, §7 (c) invariant, CI gate `framework-self-diagnose`. Stays Path A (no LLM) — gate quality is structural (schema validation), not semantic.
- **Phase 11+** — v2 areas per §8.

Phase 8 acceptance verdict (GO/REVISE/STOP) is independent of Phase 8.X — the latter does not block Phase 9 entry. Phase 8.X is treated as a parallel sub-phase to keep Phase 8 lean.

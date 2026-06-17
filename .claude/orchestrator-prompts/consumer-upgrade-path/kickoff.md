# consumer-upgrade-path — refresh shipped artefacts on already-installed consumers (GH #551 follow-up)

- **Type:** feature, design-first (brainstorm before code). Medium, clobber-risk surface.
- **Opened:** 2026-06-17.
- **Base:** staging.
- **Tracks:** GH #551 (residual) + the systemic gap surfaced in its re-verify comment. Child of the #550 umbrella.

## Why (concrete, verified)

The original #551 defect — shipped `agents/*.md` declaring non–Claude-Code tool names — is **already fixed at source** (`81a0251`, on staging) and guarded by `packages/core/principles/21-shipped-agent-tools-valid.test.ts` (green). **That part is done.**

The residual, systemic gap: a consumer that installed **before** a fix never receives it. Concrete case from the #551 re-verify comment — `timeliner` installed 2026-06-11; the agents fix landed 2026-06-16; the consumer still runs the broken pre-fix `.claude/agents/*.md`. There is **no safe refresh path**:

- `install.sh` default `copy_safe` is **skip-if-exists** ([install.sh:187](../../../install.sh)) — never updates an existing file.
- `install.sh --force` overwrites **wholesale** ([install.sh:187,224](../../../install.sh)) — it also clobbers consumer-owned customisations (their CI workflow, `.prettierrc`, RULES.md edits, the `.ai-factory/` passport).

So the gap is **not agent-specific** — it bites *every* shipped artefact (hooks, rules, skills, templates, agents): fix any of them upstream and installed consumers are stranded between "never update" and "clobber everything".

## Goal / acceptance

A consumer can refresh **framework-owned** shipped artefacts to the current version **without** clobbering consumer-owned files. Acceptance:

1. A documented, idempotent refresh path (flag, subcommand, or helper) that updates framework-owned artefacts in place.
2. Consumer-owned / consumer-customisable files (per the three-layer authority model + `<file>.override.md` escape hatch, see [INSTALL-FOR-AI.md](../../../INSTALL-FOR-AI.md)) are **preserved** — proven by a test that customises a file, runs refresh, asserts the customisation survives AND the framework-owned artefact updated.
3. Paired-negative: a stale framework-owned artefact (e.g. an `agents/*.md` with old tool names) is actually refreshed by the path → its new content present after.

## Design questions (resolve via `superpowers:brainstorming` at session start — do NOT pre-decide)

1. **Refresh mechanism:** new `install.sh --upgrade` mode? a separate `refresh-framework.sh` helper? extend `copy_safe` with a per-file "framework-owned ⇒ overwrite, consumer-owned ⇒ keep" classifier? (BFR-default: prefer reusing the existing `copy_safe` + SHIPPED_DOCS machinery over building a new installer.)
2. **The framework-owned vs consumer-owned boundary** — where is the authoritative list? Can it be derived from existing signals (`SHIPPED_DOCS`, the three-layer authority model, `.override.md` presence) rather than a hand-maintained allowlist that will drift?
3. **Version awareness** — does refresh need a shipped-version stamp to know what changed, or is "re-copy framework-owned set, leave the rest" sufficient?
4. **Interaction with `.override.md`** — a consumer who overrode a framework file must not have the override clobbered; how does refresh detect and respect it?

## Prior-art consult (mandatory before any "I propose…", per build-first-reuse-default §3)

- DeepWiki `ask_question` ≥3 phrasings + WebSearch ≥3 phrasings on the problem class: "idempotent scaffold upgrade / re-sync vendored files without clobbering user edits" (e.g. `create-react-app eject`/`npx … upgrade`, `cookiecutter`/`cruft` drift-update, `yeoman` conflict resolver, `copier update`). Record verdicts in [prior-art-evaluations.md](../../../docs/meta-factory/prior-art-evaluations.md). `copier update` (3-way merge of templated projects) is a strong candidate to evaluate (ADOPT/ADAPT/REFERENCE).
- Consult SSOT for existing install/refresh entries before adding.

## §6 AI-traps (ai-laziness-traps §3 obligations)

See [.claude/rules/ai-laziness-traps.md §2](../../../.claude/rules/ai-laziness-traps.md). Active traps for this feature: **T2, T3, T11, T12, T15, T16**.

- **T11 / T12** — this is a solved problem class upstream (template-sync tools); do NOT design a bespoke merger without the prior-art sweep above.
- **T16** — do not assume `install.sh --force` or any named tool "already does upgrade" without verifying it preserves consumer files (it does not).
- **T2** — designing the classifier ≠ shipping it; acceptance requires the paired customise-survives / stale-refreshed tests actually run green.
- **T3** — every "consumer X is broken / preserved" claim needs file:line or command output.
- **T15** — self-application: dogfood the refresh on this repo's own shipped surface (or explain why N/A).
- **T-Upgrade-A** (domain-specific) — when building the framework-owned allowlist, the AI is tempted to mark a file "framework-owned, safe to overwrite" by *guessing* rather than verifying it is never consumer-customised. A wrong classification silently clobbers consumer work (irreversible). Counter: derive the boundary from an existing authoritative signal (three-layer model / `.override.md` / SHIPPED_DOCS), and for each file in the overwrite set state the evidence it is framework-owned.

## Out of scope

- The original #551 agents fix (done) and its guardrail (done).
- #547 Point 1 (passport generation) — separate kickoff (`aif-init-passport-gen`).
- Auto-running refresh on every install — refresh is an explicit, opt-in consumer action.

## Dispatch note

Per [kickoff-staging-placement.md](../../../.claude/rules/kickoff-staging-placement.md): this kickoff must be on `staging` before `/pipeline consumer-upgrade-path` or an aif dispatch is initiated.

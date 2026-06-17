# aif-init-passport-gen — AI-generate the project passport instead of shipping placeholders (GH #547 Point 1)

- **Type:** feature, design-first (brainstorm before code). Larger, exploratory.
- **Opened:** 2026-06-17.
- **Base:** staging.
- **Tracks:** GH #547 Point 1. (Point 2 — auto-wire R2 — already shipped via #553; do NOT re-do it.) Child of the #550 umbrella.

## Why (concrete, verified)

`install.sh` copies `.ai-factory/DESCRIPTION.template.md` + `ARCHITECTURE.ts-server.md` into the consumer with `<PLACEHOLDER>` fields a **human** must fill ([install.sh:558-559](../../../install.sh)). Verified on staging — `packages/core/templates/shared/DESCRIPTION.template.md` still ships `# <PROJECT_NAME>`, `<Fastify | Hono | Express | Next.js 15>`, `<Postgres | …> + <Drizzle | …>`, `<Honeycomb | Datadog | …>`.

The paradox #547 raises: the installer drops these context files **into an AI agent's environment**, yet asks a **human** to type what is **trivially readable from the repo** — `apps/api` deps → Hono; `packages/db` → Drizzle + pg; `apps/mobile` → Expo; test runner → Vitest. An AI-native framework should install **understanding the project**, not ship guesses + `<PLACEHOLDER>` and offload reconciliation to the human.

## Goal / acceptance

An `aif-init` step (part of install, or a follow-up command/skill) where the AI reads the consumer repo and **generates a draft** `DESCRIPTION.md` / `ARCHITECTURE.md`; the human reviews/edits rather than authoring from scratch. Acceptance:

1. Run on a fixture consumer repo → produced `DESCRIPTION.md` contains **zero** `<…>` placeholders and names the actual detected stack.
2. Detection is **derived from repo signals**, not hardcoded — proven on ≥2 differently-shaped fixtures (e.g. a Hono+Drizzle monorepo AND a Next.js+Prisma flat repo) → each yields a stack-correct draft.
3. The step is AI-agnostic per [no-paid-llm-in-ci.md](../../../.claude/rules/no-paid-llm-in-ci.md) — runs on the operator's session/subscription, never a paid API-in-CI; and degrades gracefully when no AI session is present (falls back to the current template, never errors).

## Design questions (resolve via `superpowers:brainstorming` at session start — do NOT pre-decide)

1. **Delivery channel:** a new skill (`aif-init`)? an `agents/*.md` sub-agent? a hook? Per [dual-implementation-discipline.md §3](../../../.claude/rules/dual-implementation-discipline.md): consumer-facing ⇒ likely portable markdown the consumer's AI session reads, not a CC-only hook.
2. **When does it run** — during `install.sh` (but install runs before deps are installed / may have no AI in the loop), or as an explicit post-install `aif-init` the consumer invokes in their AI session? (The #548 deps-hash seam shows install-time has no AI; favour an AI-session step.)
3. **Deterministic detection vs LLM inference** — how much is a deterministic repo-scan (read `package.json`, dir layout) vs LLM synthesis? Keep the deterministic core testable; the LLM fills prose.
4. **Review gate** — the human must review the draft; the output is a *draft*, not authoritative. How is "draft, please review" signalled so it is not mistaken for a finished passport?

## Prior-art consult (mandatory before any "I propose…", per build-first-reuse-default §3)

- DeepWiki `ask_question` ≥3 phrasings + WebSearch ≥3 phrasings on "AI/LLM project onboarding / repo-aware scaffold generation / auto-generate project context doc from repo" (e.g. `aider --init`/repo-map, Cursor `.cursorrules` generators, `gitingest`/repo-summarisers, `/init` CLAUDE.md generation). Record verdicts in [prior-art-evaluations.md](../../../docs/meta-factory/prior-art-evaluations.md).
- **Own-stack-first:** Claude Code already ships an `/init` that reads a repo and writes CLAUDE.md — evaluate ADOPT/ADAPT/REFERENCE of that pattern before building bespoke generation.
- Consult SSOT + the existing `tool-bootstrapping` skill (it already reads `package.json` deps) for reuse before building new repo-scan code.

## §6 AI-traps (ai-laziness-traps §3 obligations)

See [.claude/rules/ai-laziness-traps.md §2](../../../.claude/rules/ai-laziness-traps.md). Active traps for this feature: **T2, T11, T12, T13, T15, T16**.

- **T11 / T12** — repo-aware doc generation is an active area; do the WebSearch/DeepWiki sweep at proposal time, not from training-data memory.
- **T13 / T16** — if ADOPTing CC `/init` or `tool-bootstrapping`, verify the problem class matches ("generate CLAUDE.md" vs "generate AIF passport") — do not assume the name transfers the capability.
- **T2** — designing the generator ≠ running it; acceptance requires the placeholder-free output on real fixtures.
- **T15** — self-application: the generator should be able to produce *this* repo's own passport (or explain why N/A).
- **T-Passport-A** (domain-specific) — the AI is tempted to hardcode the timeliner reference stack (Hono / Drizzle / Expo / Vitest) into the generator, so it "works on the demo" but fails on any other consumer. Counter: detection MUST derive from arbitrary repo signals; the ≥2-differently-shaped-fixtures acceptance test is the falsifier.

## Out of scope

- #547 Point 2 (auto-wire R2) — already shipped (#553).
- #551 upgrade-path — separate kickoff (`consumer-upgrade-path`).
- Any paid-LLM-in-CI path — generation is operator-session only.

## Dispatch note

Per [kickoff-staging-placement.md](../../../.claude/rules/kickoff-staging-placement.md): this kickoff must be on `staging` before `/pipeline aif-init-passport-gen` or an aif dispatch is initiated.

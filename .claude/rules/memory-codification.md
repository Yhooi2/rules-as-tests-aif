# Memory codification — discipline rule

> **Class:** B — compensating mechanism without CI test (AI-agnostic auditor agent + local-audit grep). Class A (CI principle test) is **structurally unreachable**: the corpus is user-scope agent memory, which lives outside the repo and outside CI by construction (see §1 hard constraint). Promotion ceiling = B; retirement criterion in §6.
> **Authoritative for:** memory-codification discipline rule — §2 what counts as a *durable convention* (trigger + non-triggers), §3 the write-time codify-then-pointer discipline, §4 compensating mechanisms (local-audit grep + auditor agent; no CI by constraint), §5 anti-patterns, §6 promotion / retirement.
> **NOT authoritative for:** project goal — see [README.md#why-this-exists](../../README.md#why-this-exists). Memory *file format / index* — that is the harness/global memory-instructions block. Doc-authority header spec — see [doc-authority-hierarchy.md](doc-authority-hierarchy.md).

> **Origin:** 2026-05-22 memory coverage audit ([docs/meta-factory/research-patches/2026-05-22-memory-coverage-audit.md §6](../../docs/meta-factory/research-patches/2026-05-22-memory-coverage-audit.md)). The audit swept all 51 memory files and found **15 stage-0** entries (durable conventions living *only* in user-scope memory, never codified into the repo). Successor to the 2026-05-13 memory-to-docs codification audit ([docs/meta-factory/research-patches/2026-05-13-memory-to-docs-codification-audit.md §6-§8](../../docs/meta-factory/research-patches/2026-05-13-memory-to-docs-codification-audit.md)), which named the candidate principle but left the standing discipline open. This rule operationalises it.
>
> **Companion mechanism:** [agents/memory-codification-auditor.md](../../agents/memory-codification-auditor.md) — AI-agnostic sub-agent read by an active session (no paid LLM per [no-paid-llm-in-ci.md §1](no-paid-llm-in-ci.md)).

## The discipline

When writing to memory: if the entry shapes future session behavior («always/never X», «when Y do Z»), **codify it in the repo first** (`.claude/rules/` new rule, or `CLAUDE.md` for AI-tooling conventions), then reduce the memory entry to a one-line pointer.

**Trigger:** memory entries of `type: feedback` or `type: project` with a «How to apply:» line = durable convention → codify then pointer.

**Not a durable convention (leave in memory):** ephemeral state, identity facts, reference pointers, progress.

**Anti-pattern:** `#convention-stranded-in-memory` (durable rule in memory only, no repo artefact, no `TODO-codify:` marker).

Full rule + local-audit grep: `.claude/rules/memory-codification.md` (read on demand).

## See also

- [docs/meta-factory/research-patches/2026-05-22-memory-coverage-audit.md](../../docs/meta-factory/research-patches/2026-05-22-memory-coverage-audit.md) — origin; the full 51-file coverage matrix + §6 proposal this rule implements.
- [docs/meta-factory/research-patches/2026-05-13-memory-to-docs-codification-audit.md](../../docs/meta-factory/research-patches/2026-05-13-memory-to-docs-codification-audit.md) — predecessor audit (memory → docs for 6 entries; named the principle, left discipline open).
- [agents/memory-codification-auditor.md](../../agents/memory-codification-auditor.md) — companion AI-agnostic auditor agent.
- [.claude/rules/phase-research-coverage.md §1.6](phase-research-coverage.md) — push-based sweep pattern this rule's §4(c) mirrors.
- [CLAUDE.md](../../CLAUDE.md) — natural codification home for AI-tooling conventions.

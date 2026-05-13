# Parallel sub-wave isolation — discipline rule

> **Authoritative for:** parallel-subwave-isolation rule — §1 git worktree requirement for parallel Sonnet sessions, §2 sequential-fallback escape hatch, §3 anti-patterns (`#shared-workdir-parallel`, `#branch-race-on-checkout`), §4 promotion / retirement triggers.
> **NOT authoritative for:** project goal — see [README.md#why-this-exists](../../README.md#why-this-exists). Companion to orchestrator skill — global skill at `~/.claude/skills/orchestrator/SKILL.md` may reference this rule.

> **Origin:** Incident 2026-05-12, Wave 8.1/8.1b/8.2 parallel rollout. Shared working directory across parallel Sonnet sessions caused branch contamination — Wave 8.1's commit ended up on `wave-8.1b/compliance-verifier-agent` branch because junior sessions raced on `git checkout -b`. Required orchestrator-side cherry-pick surgery + caused junior REPORTs to surface false-alarm audit failures from stale working-tree files. Codified in repo following the post-Wave-9 memory-to-docs codification audit ([docs/meta-factory/research-patches/2026-05-13-memory-to-docs-codification-audit.md](../../docs/meta-factory/research-patches/2026-05-13-memory-to-docs-codification-audit.md)).

## §1 The discipline

For parallel sub-wave / batch execution under the orchestrator pattern, **always use git worktrees**. Never run parallel Sonnet (or any parallel AI) sessions in the shared working directory.

**Mandatory worktree setup as first step in every Mode-B parallel batch prompt:**

```bash
git worktree add ../<repo>-wave-<N> main
cd ../<repo>-wave-<N>
git checkout -b <wave>/<task>
```

The orchestrator prompt instructs each parallel Sonnet session to invoke worktree-add **before any other operation**. Branch checkout happens inside the worktree, eliminating the shared `.git/index` race.

## §2 Sequential fallback

If worktree-add fails (filesystem constraints, conflicting locks), the orchestrator falls back to **sequential execution** — not concurrent shared-dir execution. Sequential single-worktree completion of all parallel branches is the safe default.

Sequential fallback signature: each Sonnet session completes its commit + push before the next begins. Adds wall-clock time, removes contamination risk.

## §3 Anti-patterns

- **`#shared-workdir-parallel`** — multiple parallel AI sessions opening `~/code/<repo>/` directly. Even if each starts on a different branch, `git checkout -b` mid-session races on the shared `.git/index`. The first to write wins; the second may silently commit to the wrong branch.
- **`#branch-race-on-checkout`** — variant; orchestrator dispatches «Session A: checkout branch X / Session B: checkout branch Y» without worktree isolation. Sessions read each other's working-tree state, producing false-positive audit findings or stale-file regressions.
- **`#worktree-add-failure-ignored`** — Sonnet session encounters `git worktree add` failure, silently proceeds in shared dir. Counter: prompt MUST instruct «if worktree-add fails, STOP and report to orchestrator — do not proceed in shared dir».

## §4 Promotion / retirement

- **Promotion to principle test:** mechanical detection of «two commits on different branches sharing a working-tree state» is hard (post-hoc detection via `git log --graph` requires heuristics). Defer principle test until detection is straightforward (e.g. AST-level orchestrator-prompt analysis post-Wave 10 TS migration).
- **Retirement:** if no shared-dir-parallel incident occurs for 12 consecutive months, archive to prose in CLAUDE.md `## Parallel work` section.

## See also

- [.claude/rules/reviewer-discipline.md](reviewer-discipline.md) — companion rule, parallel codification batch.
- [.claude/rules/phase-research-coverage.md §4 anti-patterns](phase-research-coverage.md) — focus-tunnel family context.
- [docs/meta-factory/research-patches/2026-05-13-memory-to-docs-codification-audit.md](../../docs/meta-factory/research-patches/2026-05-13-memory-to-docs-codification-audit.md) — codification audit origin.

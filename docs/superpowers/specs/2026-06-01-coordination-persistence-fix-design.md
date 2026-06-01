# Design — coordination-persistence-fix

> **Status:** brainstorm-approved-pending (written 2026-06-01, HEAD 056cbf6).
> **Origin:** `/meta-orchestrator coordination-persistence-fix`; planning kickoff `.claude/orchestrator-prompts/coordination-persistence-fix/kickoff.md` (gitignored, rescued to `$CANON`).
> **Authoritative for:** the *design* of the cross-worktree coordination-persistence fix — channel weave, migration semantics, atomicity scope, SSOT anchor. **NOT authoritative for:** project goal (see README.md#why-this-exists); the implementation plan (see writing-plans output); the linker capability itself (SSOT #110, `link-coordination.sh`).
> **Base branch:** staging.

---

## §0 Problem (verified evidence, 2026-06-01)

Gitignored coordination state (`.claude/orchestrator-prompts/<umbrella>/*`, root `_plan-cache.md`, `_master-backlog-delta.json`) does **not** persist across Superset worktrees, so kickoffs/cache/delta written in a worktree are lost on cleanup. Three-part root cause:

- **(A) Superset worktrees never run the linker.** `find .claude/orchestrator-prompts -type l` → **0 symlinks / 326 files** in this worktree. `scripts/link-coordination.sh` is auto-called only from `.claude/hooks/worktree-setup.sh:123` (CC `WorktreeCreate`) and `scripts/create-worktree.sh:97`. Superset creates worktrees via its own `setup` mechanism, bypassing both.
- **(B) Root-level memory is structurally out of scope.** `link-coordination.sh:94,132` iterate only `"$WT_PROMPTS"/*/` (umbrella dirs). Root files `_plan-cache.md` / `_master-backlog-delta.json` are never matched — even running the linker would not share them.
- **(C) Migration hazard.** This worktree was COPY-hydrated (J5 #310 + the Superset `setup` rsync) → files are real in BOTH worktree and `$CANON` → `link-coordination.sh` adopt-then-link hits mass CONFLICT (exit 1, never clobbers).

**Persists fine:** git-tracked exceptions `!.claude/orchestrator-prompts/*/done.md` and root `README.md` — no `$CANON` needed.

### T16 correction (load-bearing — kickoff §5 flagged this trap)

The planning kickoff §3-C assumed a "Superset-native hook in `.superset/hooks/`". **Verified false:** `~/.superset/hooks/` holds only `cursor-hook.sh` / `copilot-hook.sh` / `gemini-hook.sh` — agent session-lifecycle notify hooks (`Start|Stop|SessionStart|SessionEnd` → POST to `$SUPERSET_HOST_AGENT_HOOK_URL`), Superset-owned, no worktree-create event, no `claude-hook.sh`.

The **real** Superset worktree-create primitive is the `setup` array in `~/.superset/projects/<uuid>/config.json`. It currently runs (verbatim):

```sh
mkdir -p "$SUPERSET_WORKSPACE_PATH/.claude/orchestrator-prompts"
rsync -a --ignore-existing "$SUPERSET_ROOT_PATH/.claude/orchestrator-prompts/" "$SUPERSET_WORKSPACE_PATH/.claude/orchestrator-prompts/"
```

**That rsync-COPY is the §0-C root cause.** Channel C is therefore "replace the `setup`-array rsync with the linker", not "add a hooks-dir hook".

### Two facts that shrink scope

- **Atomicity (Q3) — partial: atomic but NOT symlink-preserving (correction, found in planning 2026-06-01).** `update-cache.sh:99,110`, `update-delta.sh:78,82`, `delta-write-from-state.sh:96,103` write via `mktemp`+`mv` — atomic for *real* files. **But Part-2 shares these files as symlinks, and `mv tmp <symlink>` REPLACES the symlink with a real file** (verified empirically: after the first cache write the worktree file stops being a symlink → cross-worktree share lost). So SW-B is a real fix, not just "confirm a test": the helpers must become **symlink-aware** — when the target is a symlink, write the temp file beside the *resolved canonical target* and `mv` onto the resolved path, preserving the worktree symlink. See §2.4.
- **Channel B already covers the Superset *runtime*.** CC reads the repo's `.claude/settings.json`, so a CC `SessionStart` hook fires inside a Superset worktree too. Superset is distinct only at the *worktree-create* moment (the `setup` array) — not at session start.

### Dedup (CLEAR)

`coordination-persistence-fix` has no "deliverable-already-on-staging" dupe and 0 in-flight PRs. The only adjacency is xref-overlap with #346 (the `link-coordination.sh` base we extend, SSOT #110) and #310 (the J5 COPY-hydrate root cause we fix) — both expected per §0, neither a duplicate.

---

## §1 Locked decisions (maintainer, planning session 2026-06-01 — not re-litigated)

1. **Trigger = all three channels** (B CC SessionStart + A skill-§0 self-heal + C Superset-native), composed idempotently, **without hard-coupling to Superset**. C is first-class but additive; B+A are the portable, retroactive, universal floor (T-CPF-A).
2. **Root-memory share = option (i):** share both `_plan-cache.md` and `_master-backlog-delta.json` via the linker, with atomic update helpers.

---

## §2 Design — one idempotent linker, three callers

### §2.1 Core principle

All three channels invoke the **same** `link-coordination.sh`. It is already idempotent — skips existing symlinks (`:100,149`), conflict-detects without clobbering (`:109,154–158`, exit 1). Composition-without-conflict is therefore free: no inter-channel locking. Each channel is a *caller* of one mechanism, never a fork of it (avoids `#two-prompts-drift`, `dual-implementation-discipline.md §7`).

### §2.2 Channel matrix — agnostic core + native advantages (maintainer framing 2026-06-01)

Maintainer requirement: *agnostic, but uses CC's advantages when present, AND has its own portable hook for when CC is absent, so it works everywhere.* This is `dual-implementation-discipline.md §3` (agnostic + native-when-present) + `§4` (capability-check, not brand-name). The earlier draft mislabeled CC `SessionStart` as the "portable floor" — **wrong: CC SessionStart needs CC.** The genuinely harness-agnostic floor is a **git hook** (git is the one substrate in every harness).

| Channel | Substrate (verified) | Role | Delivery | Fires when |
|---|---|---|---|---|
| **G** git `post-checkout` (the "own hook") | committed `.husky/post-checkout` → `link-coordination.sh`; rides existing husky (`core.hooksPath` set, `pre-commit`/`pre-push` already committed) | **agnostic floor — works everywhere git is** | committed (`.husky/` = maintainer-applied per §7) | any `git worktree add` (plain CLI, Aider, Codex, Cursor, …) |
| **B** CC `SessionStart` | `.claude/settings.json` → `SessionStart` hook → linker | **CC-native advantage + re-heal catch** if G didn't fire | committed (settings.json = maintainer-applied) | CC session start (incl. inside Superset) |
| **C** Superset-native | `~/.superset/projects/<uuid>/config.json` `setup` — replace rsync with linker | **Superset-native + removes the rsync ROOT CAUSE** (load-bearing regardless of G — see §2.4a) | per-machine runbook (un-committable: per-UUID, lives in `~/.superset/`) | Superset worktree-create |
| **A** skill §0 self-heal | meta-orchestrator `SKILL.md §1` prepends an idempotent link call | **orchestrator-local last-resort** backstop | committed | meta-orchestrator runs |

**Idempotency contract (the Q1 "meaty" answer):**
- All four call the **same** idempotent `link-coordination.sh`. Any order, any overlap, any subset firing is safe: the second+ caller sees correct symlinks and no-ops; a fresh worktree's empty prompts dir means the linker only *creates* symlinks (no conflicts possible).
- Layering by reach: **G** is the universal floor; **B** adds CC's richer lifecycle and re-heals if G missed; **C** is mandatory on Superset (it must kill the rsync root cause, and Superset may not fire G — §2.4a); **A** is the cheapest backstop when the orchestrator runs.
- No channel hard-depends on another. Drop CC → G+C+(maybe A) still work. Drop Superset → G+B+A still work. Drop everything but git → G alone works. This is the "works everywhere" guarantee.

### §2.3 Q2 — migration of already-diverged worktrees

`link-coordination.sh` gains `--on-conflict=canon|worktree|skip`, **default `skip`** (preserves current exit-1-on-conflict behaviour; the `setup`-array call relies on this default — fresh worktrees never conflict, so it never triggers there).

- `skip` (default): report CONFLICT, leave both files, exit 1. Current behaviour.
- `canon`: canonical wins — delete the worktree's real file, symlink to `$CANON`. (Discards local worktree edits.)
- `worktree`: worktree wins — `mv` the worktree file into `$CANON` (overwriting), then symlink. (Adopts local into canonical.)

Migrating an already-diverged worktree (e.g. this one) is a **separate one-time manual invocation** where the maintainer picks `canon`/`worktree` per case — a data-authority call made at migration time, never baked into the auto-callers (which always use `skip`).

### §2.4 Q3 — atomicity + symlink-preservation (real fix)

The temp-then-`mv` writes are atomic for real files but **break the symlink** when the target is a shared symlink (verified: `mv tmp <symlink>` → real file, share lost). All three helpers (`update-cache.sh`, `update-delta.sh`, `delta-write-from-state.sh`) must become **symlink-aware**:

```sh
# resolve the real target: if FILE is a symlink, follow it; else FILE itself.
target="$FILE"; [ -L "$FILE" ] && target="$(cd "$(dirname "$(readlink "$FILE")")" && pwd)/$(basename "$(readlink "$FILE")")"
tmp="$(mktemp "$(dirname "$target")/$(basename "$FILE").tmpXXXXXX")"
# ...write tmp...
mv "$tmp" "$target"        # writes through to $CANON; worktree symlink preserved
```

This keeps atomicity (still temp-then-`mv`, same dir as target → same filesystem → rename is atomic) AND preserves the cross-worktree symlink. Tests live at `packages/core/hooks/*.test.ts` (existing: `update-cache.test.ts`, `update-delta.test.ts`, `delta-write-from-state.test.ts`). New paired-negative per helper: target is a symlink into `$CANON` → after run, target is **still a symlink** AND `$CANON` content updated AND a second linked worktree sees it. Stripped (non-symlink-aware) variant → target becomes a real file → test fails.

### §2.4a Open verification (T16 — confirm in implementation, do not infer)

`host-service.log` did **not** capture Superset's git invocation, so it is **unconfirmed** whether Superset's worktree-create fires git `post-checkout` (channel G). Two cases, both handled:

- **If Superset fires post-checkout** → G links the worktree, but the `setup` rsync still COPIES first → conflict. So channel **C still must replace the rsync** to remove the root cause. G becomes a redundant safety net on Superset (fine).
- **If Superset does NOT fire post-checkout** → C is the only thing linking Superset worktrees (plus B at first CC session). Still covered.

Either way **C (setup-array) stays load-bearing** — it is the only channel that *removes* the rsync root cause. Liveness check in SW-C confirms which case holds (`find -type l` after a fresh Superset worktree, with and without the `setup` edit). Also note `core.hooksPath` is an **absolute** path to the primary checkout — fresh *clones* need the standard `husky` bootstrap to set it (existing project behaviour, not new scope).

### §2.5 Q4 — SSOT anchor

Root-memory share is the **same capability** as umbrella-file share (cross-worktree share of gitignored coordination state). **Same anchor: SSOT #110, `@dual-pair: cross-worktree-coordination-doc-sync`.** The linker grows a root-file loop beside its umbrella-dir loop. No new SSOT row; no new dependency.

### §2.6 Root-file loop (Part B fix)

Add a loop over the two known root files (`_plan-cache.md`, `_master-backlog-delta.json`) in `link-coordination.sh`, mirroring the umbrella loop's adopt-then-link + conflict logic, targeting `$CANON/<file>` (root of `$CANON`, not under an umbrella dir). Tracked-file skip-list unchanged (root `README.md` stays real).

---

## §3 Sub-waves

| SW | Surface | Type | Parallel | Delivery |
|---|---|---|---|---|
| **A** | `link-coordination.sh`: root-file loop (§2.6) + `--on-conflict` flag (§2.3) + bash tests | I-phase-small | with B | committed |
| **B** | make 3 cache/delta helpers symlink-aware (write-through resolved target) + paired-negative tests (§2.4) | I-phase-small | with A | committed |
| **C** | wiring (4 channels): **G** `.husky/post-checkout` (agnostic floor) + **B** CC `SessionStart` in settings.json + **A** skill §0 self-heal + **C** Superset `setup`-array runbook; all call the extended linker | wiring | after SW-A | mixed commit/runbook |

SW-A ⟂ SW-B (file-disjoint: linker+its tests vs helper tests). SW-C depends on SW-A (every channel calls the *extended* linker). Within SW-C, the git hook (G) + settings.json (B) + skill §0 (A) are committed (maintainer-applied for `.husky/` and `settings.json`); the Superset `setup` edit (C) is a per-machine runbook.

---

## §4 Error handling

- Linker conflict under auto-callers (B/C) → `skip` default → exit 1, diagnostic to stderr, **never clobbers**. The calling hook must not abort the session on linker exit 1 (it's advisory): B/C wrap the call so a non-zero exit logs but does not fail session-start / worktree-create.
- `$CANON` unwritable / absent → `mkdir -p` (existing `:58`); if that fails, linker exits 1, session proceeds unlinked (degraded, not broken — coordination state stays worktree-local, same as today).
- Atomic helpers already rename a corrupt JSON to `.broken.<ts>` (`update-delta.sh:95`, `delta-write-from-state.sh:75`) — unchanged.

## §5 Testing

- SW-A: bash tests for the root-file loop (adopt + link + idempotent re-run) and each `--on-conflict` mode (canon discards local, worktree adopts local, skip exits 1). Paired-negative: a conflict under `skip` must exit 1 and leave both files intact.
- SW-B: per-helper paired-negative — target is a symlink into `$CANON`; after the helper runs assert (1) target is **still a symlink**, (2) `$CANON` content updated, (3) a second linked worktree sees it. Stripped non-symlink-aware variant → target becomes real file → test fails.
- SW-C liveness (manual, session-bound — no CI, `no-paid-llm-in-ci.md`):
  - **G**: `git worktree add` a throwaway worktree (plain git, no CC/Superset) → assert `find .claude/orchestrator-prompts -type l` > 0 (the agnostic floor fires).
  - **C**: fresh Superset worktree with the `setup` edit → symlinks not copies; resolves the §2.4a open question (does Superset fire G?).
  - **B**: open a CC session in an unlinked worktree → SessionStart heals it.

## §6 Recursive self-application (§T15)

The fix must make its own spec + kickoff persist cross-worktree. Acceptance: after SW-A lands, migrate **this** worktree via `link-coordination.sh --on-conflict=worktree` (local is authoritative — it holds the freshest kickoff/spec), then confirm this spec + the kickoff appear as symlinks into `$CANON` and are visible from a second worktree.

## §7 Anti-scope / constraints

- `settings.json`, `.claude/hooks/`, `~/.superset/**` edits = maintainer-applied (agent-self-protected / Superset-owned). Agent produces the diff + runbook; maintainer applies.
- No npm deps; bash + markdown + CC/Superset primitives only.
- Do not hard-depend on Superset internals (`#vendor-lock-by-convenience`, `build-first-reuse-default.md §4`): C is additive; B+A stand alone.
- AI-traps active: **T16** (verified C substrate, not inferred), **T3** (file:line evidence throughout), **T19** (own cold-QA before handoff), **T15** (self-application §6), **T-CPF-A** (portable-fallback-omitted — B+A must work without C).

## §8 See also

- `.claude/orchestrator-prompts/coordination-persistence-fix/kickoff.md` — planning kickoff (gitignored).
- `scripts/link-coordination.sh` — the extended mechanism (SSOT #110, #346).
- `docs/meta-factory/research-patches/2026-05-17-cross-worktree-coord-doc-sync.md §5` — origin verdict.
- `.claude/rules/dual-implementation-discipline.md §3/§7` — channel triage + single-source-of-truth.
- `.claude/rules/build-first-reuse-default.md §4` — `#vendor-lock-by-convenience`.

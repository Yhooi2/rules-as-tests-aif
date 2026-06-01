# Coordination Persistence Fix — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make gitignored cross-worktree coordination state (umbrella prompts + root `_plan-cache.md` / `_master-backlog-delta.json`) persist across worktrees in every harness, via one idempotent linker called from four channels (git-hook agnostic floor + CC + Superset + skill).

**Architecture:** Extend `scripts/link-coordination.sh` (SSOT #110) with a root-file loop + `--on-conflict` flag; make the 3 cache/delta helpers symlink-aware so atomic writes don't break the shared symlink; wire four idempotent callers. Spec: `docs/superpowers/specs/2026-06-01-coordination-persistence-fix-design.md`.

**Tech Stack:** Bash (macOS bash 3.2 compatible — array use OK, no `readlink -f`), vitest (`packages/core/hooks/*.test.ts`, execFileSync over the shell scripts), husky, CC hooks, Superset `setup`-array.

**Permission boundaries (load-bearing — see `.claude/settings.json` deny list):**
- **Agent-writable:** `scripts/link-coordination.sh`, `.claude/skills/meta-orchestrator/SKILL.md`, `packages/core/hooks/*.test.ts`, `.claude/skills/meta-orchestrator/helpers/*.sh`, `docs/**`.
- **Agent-DENIED (maintainer applies):** `.husky/**`, `.git/hooks/**`, `.claude/settings.json`, `~/.superset/**`. The agent writes the exact content into a runbook file under `docs/`; the maintainer copies it into the protected path.

**Base branch:** staging. **Worktree isolation:** dispatch each sub-wave in its own worktree (`parallel-subwave-isolation.md §1`). SW-A ⟂ SW-B (file-disjoint). SW-C after SW-A merges.

---

## File Structure

| File | Responsibility | Sub-wave | Delivery |
|---|---|---|---|
| `scripts/link-coordination.sh` | linker: `--on-conflict` flag + root-file loop | A | agent |
| `packages/core/hooks/link-coordination.test.ts` | linker tests (extend existing 378-LOC suite) | A | agent |
| `.claude/skills/meta-orchestrator/helpers/update-cache.sh` | symlink-aware atomic write | B | agent |
| `.claude/skills/meta-orchestrator/helpers/update-delta.sh` | symlink-aware atomic write | B | agent |
| `.claude/skills/meta-orchestrator/helpers/delta-write-from-state.sh` | symlink-aware atomic write | B | agent |
| `packages/core/hooks/update-cache.test.ts` / `update-delta.test.ts` / `delta-write-from-state.test.ts` | symlink-preservation paired-negatives | B | agent |
| `.claude/skills/meta-orchestrator/SKILL.md` | §1 self-heal link call (channel A) | C | agent |
| `docs/meta-factory/runbooks/coordination-persistence-wiring.md` | exact diffs for `.husky/post-checkout` (G) + settings.json SessionStart (B) + Superset `setup` (C) | C | agent writes; maintainer applies |

---

## SW-A — link-coordination.sh: `--on-conflict` + root-file loop

### Task A1: `--on-conflict=canon|worktree|skip` flag

**Files:**
- Modify: `scripts/link-coordination.sh:43-44` (arg parsing) and `:115-119` (conflict branch)
- Test: `packages/core/hooks/link-coordination.test.ts`

- [ ] **Step 1: Write the failing tests** (append inside the existing `describe` block)

```typescript
it('on-conflict=canon: canonical wins, worktree file relinked', () => {
  // setup: real file in BOTH worktree and CANON (the §0-C diverged case)
  mkdirSync(`${canon}/u1`, { recursive: true });
  writeFileSync(`${canon}/u1/kickoff.md`, 'CANON');
  mkdirSync(`${wt}/.claude/orchestrator-prompts/u1`, { recursive: true });
  writeFileSync(`${wt}/.claude/orchestrator-prompts/u1/kickoff.md`, 'WORKTREE');
  execFileSync('bash', [HELPER, wt, '', '--on-conflict=canon'], { env, encoding: 'utf8' });
  const p = `${wt}/.claude/orchestrator-prompts/u1/kickoff.md`;
  expect(lstatSync(p).isSymbolicLink()).toBe(true);
  expect(readFileSync(p, 'utf8')).toBe('CANON'); // canonical content wins
});

it('on-conflict=worktree: worktree wins, adopted into CANON', () => {
  mkdirSync(`${canon}/u1`, { recursive: true });
  writeFileSync(`${canon}/u1/kickoff.md`, 'CANON');
  mkdirSync(`${wt}/.claude/orchestrator-prompts/u1`, { recursive: true });
  writeFileSync(`${wt}/.claude/orchestrator-prompts/u1/kickoff.md`, 'WORKTREE');
  execFileSync('bash', [HELPER, wt, '', '--on-conflict=worktree'], { env, encoding: 'utf8' });
  const p = `${wt}/.claude/orchestrator-prompts/u1/kickoff.md`;
  expect(lstatSync(p).isSymbolicLink()).toBe(true);
  expect(readFileSync(`${canon}/u1/kickoff.md`, 'utf8')).toBe('WORKTREE'); // adopted
});

it('on-conflict=skip (default): exits 1, leaves both files intact', () => {
  mkdirSync(`${canon}/u1`, { recursive: true });
  writeFileSync(`${canon}/u1/kickoff.md`, 'CANON');
  mkdirSync(`${wt}/.claude/orchestrator-prompts/u1`, { recursive: true });
  writeFileSync(`${wt}/.claude/orchestrator-prompts/u1/kickoff.md`, 'WORKTREE');
  let code = 0;
  try { execFileSync('bash', [HELPER, wt], { env, encoding: 'utf8' }); }
  catch (e: any) { code = e.status; }
  expect(code).toBe(1);
  expect(readFileSync(`${wt}/.claude/orchestrator-prompts/u1/kickoff.md`, 'utf8')).toBe('WORKTREE');
  expect(readFileSync(`${canon}/u1/kickoff.md`, 'utf8')).toBe('CANON');
});

it('on-conflict=bogus: exits 2 (validation)', () => {
  let code = 0;
  try { execFileSync('bash', [HELPER, wt, '', '--on-conflict=bogus'], { env, encoding: 'utf8' }); }
  catch (e: any) { code = e.status; }
  expect(code).toBe(2);
});
```

> Reuse the existing suite's `env` / `wt` / `canon` setup (it sets `CLAUDE_COORDINATION_DIR` to a temp dir per `beforeEach`). If the existing names differ, adapt to them — do NOT touch real `$HOME`.

- [ ] **Step 2: Run to verify FAIL**

Run: `npm --prefix packages/core test -- link-coordination`
Expected: FAIL (flag unparsed → conflict still always exits 1 / canon+worktree assertions fail).

- [ ] **Step 3: Implement flag parsing** — replace `scripts/link-coordination.sh:43-44`:

```bash
# ── ARGS ──────────────────────────────────────────────────────────────────────
ON_CONFLICT="skip"
POSITIONAL=()
for arg in "$@"; do
  case "$arg" in
    --on-conflict=*) ON_CONFLICT="${arg#*=}" ;;
    *)               POSITIONAL+=("$arg") ;;
  esac
done
WT_DIR="${POSITIONAL[0]:-}"
SEED_SRC="${POSITIONAL[1]:-}"

case "$ON_CONFLICT" in
  canon|worktree|skip) ;;
  *) echo "link-coordination: invalid --on-conflict='$ON_CONFLICT' (canon|worktree|skip)" >&2; exit 2 ;;
esac
```

- [ ] **Step 4: Implement conflict-mode branch** — replace the `else` block at `scripts/link-coordination.sh:115-119`:

```bash
      else
        case "$ON_CONFLICT" in
          skip)
            echo "CONFLICT: $file_path exists as real file AND $canon_target exists in \$CANON — resolve manually then re-run" >&2
            CONFLICT=1
            ;;
          canon)
            rm -f "$file_path"
            ln -s "$canon_target" "$file_path"
            echo "link-coordination: on-conflict=canon → canonical wins, relinked $umbrella/$filename" >&2
            ;;
          worktree)
            mv -f "$file_path" "$canon_target"
            ln -s "$canon_target" "$file_path"
            echo "link-coordination: on-conflict=worktree → worktree wins, adopted $umbrella/$filename" >&2
            ;;
        esac
      fi
```

- [ ] **Step 5: Run to verify PASS**

Run: `npm --prefix packages/core test -- link-coordination`
Expected: PASS (all 4 new + existing a–f).

- [ ] **Step 6: Commit**

```bash
git add scripts/link-coordination.sh packages/core/hooks/link-coordination.test.ts
git commit -m "feat(coordination): link-coordination.sh --on-conflict=canon|worktree|skip (default skip)"
```

### Task A2: root-file loop (Part-2 share of `_plan-cache.md` + `_master-backlog-delta.json`)

**Files:**
- Modify: `scripts/link-coordination.sh` — add a root-file ADOPT-THEN-LINK block after the umbrella loop (after `:122`) and a root-file LINK-back block after the CANON umbrella loop (after `:165`)
- Test: `packages/core/hooks/link-coordination.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
it('root-file loop: _plan-cache.md adopted into CANON root and symlinked back', () => {
  const wtPrompts = `${wt}/.claude/orchestrator-prompts`;
  mkdirSync(wtPrompts, { recursive: true });
  writeFileSync(`${wtPrompts}/_plan-cache.md`, 'CACHE-v1');
  execFileSync('bash', [HELPER, wt], { env, encoding: 'utf8' });
  const p = `${wtPrompts}/_plan-cache.md`;
  expect(lstatSync(p).isSymbolicLink()).toBe(true);
  expect(readFileSync(`${canon}/_plan-cache.md`, 'utf8')).toBe('CACHE-v1');
});

it('root-file loop: _master-backlog-delta.json linked from CANON into a fresh worktree', () => {
  writeFileSync(`${canon}/_master-backlog-delta.json`, '{"untracked_seen":[]}');
  const wtPrompts = `${wt}/.claude/orchestrator-prompts`;
  mkdirSync(wtPrompts, { recursive: true });
  execFileSync('bash', [HELPER, wt], { env, encoding: 'utf8' });
  const p = `${wtPrompts}/_master-backlog-delta.json`;
  expect(lstatSync(p).isSymbolicLink()).toBe(true);
  expect(readFileSync(p, 'utf8')).toBe('{"untracked_seen":[]}');
});

it('root-file loop: root README.md stays a real file (tracked-skip)', () => {
  const wtPrompts = `${wt}/.claude/orchestrator-prompts`;
  mkdirSync(wtPrompts, { recursive: true });
  writeFileSync(`${wtPrompts}/README.md`, 'TRACKED');
  execFileSync('bash', [HELPER, wt], { env, encoding: 'utf8' });
  expect(lstatSync(`${wtPrompts}/README.md`).isSymbolicLink()).toBe(false);
});
```

- [ ] **Step 2: Run to verify FAIL**

Run: `npm --prefix packages/core test -- link-coordination`
Expected: FAIL (root files never matched — current loops iterate only `*/` umbrella dirs).

- [ ] **Step 3: Implement root-file ADOPT-THEN-LINK** — insert after `scripts/link-coordination.sh:122` (after the umbrella `for` loop closes, before the `# ── LINK ──` section):

```bash
# ── ROOT-FILE ADOPT-THEN-LINK ───────────────────────────────────────────────
# Root-level coordination memory (NOT under an umbrella dir): share via $CANON root.
# Tracked README.md stays real (skip-list). Same conflict semantics as umbrella loop.
ROOT_FILES="_plan-cache.md _master-backlog-delta.json"

if [[ -d "$WT_PROMPTS" ]]; then
  for filename in $ROOT_FILES; do
    file_path="$WT_PROMPTS/$filename"
    [[ -f "$file_path" ]] || continue
    [[ -L "$file_path" ]] && continue
    canon_target="$CANON/$filename"
    if [[ ! -e "$canon_target" ]]; then
      mv "$file_path" "$canon_target"
      ln -s "$canon_target" "$file_path"
      echo "link-coordination: adopted root $filename → \$CANON" >&2
    else
      case "$ON_CONFLICT" in
        skip)
          echo "CONFLICT: $file_path exists as real file AND $canon_target exists in \$CANON — resolve manually then re-run" >&2
          CONFLICT=1
          ;;
        canon)
          rm -f "$file_path"; ln -s "$canon_target" "$file_path"
          echo "link-coordination: on-conflict=canon → canonical wins, relinked root $filename" >&2
          ;;
        worktree)
          mv -f "$file_path" "$canon_target"; ln -s "$canon_target" "$file_path"
          echo "link-coordination: on-conflict=worktree → worktree wins, adopted root $filename" >&2
          ;;
      esac
    fi
  done
fi
```

- [ ] **Step 4: Implement root-file LINK-back** — insert after `scripts/link-coordination.sh:165` (after the CANON umbrella `for` loop closes, before `# ── EXIT ──`):

```bash
# ── ROOT-FILE LINK ──────────────────────────────────────────────────────────
# For root files present in $CANON but absent in the worktree → symlink in.
if [[ -d "$CANON" ]]; then
  for filename in $ROOT_FILES; do
    canon_file="$CANON/$filename"
    [[ -f "$canon_file" ]] || continue
    wt_target="$WT_PROMPTS/$filename"
    [[ -L "$wt_target" ]] && continue
    [[ -e "$wt_target" ]] && continue
    ln -s "$canon_file" "$wt_target"
    echo "link-coordination: linked root $filename → \$CANON" >&2
  done
fi
```

- [ ] **Step 5: Run to verify PASS**

Run: `npm --prefix packages/core test -- link-coordination`
Expected: PASS (3 new + all prior).

- [ ] **Step 6: Commit**

```bash
git add scripts/link-coordination.sh packages/core/hooks/link-coordination.test.ts
git commit -m "feat(coordination): link-coordination.sh shares root _plan-cache.md + _master-backlog-delta.json (Part-2, SSOT #110)"
```

---

## SW-B — symlink-aware atomic writes (3 helpers)

> **Shared snippet (added to each helper):** a `resolve_target` that follows a symlink to its real path so `mv` writes THROUGH the link instead of replacing it. Portable (no `readlink -f`):
>
> ```bash
> # Resolve a path to its real target: if symlink, follow one level to $CANON; else itself.
> resolve_target() {
>   local f="$1"
>   if [ -L "$f" ]; then
>     local l; l="$(readlink "$f")"
>     case "$l" in
>       /*) printf '%s\n' "$l" ;;                                   # absolute (our linker emits absolute)
>       *)  printf '%s\n' "$(cd "$(dirname "$f")" && cd "$(dirname "$l")" && pwd)/$(basename "$l")" ;;
>     esac
>   else
>     printf '%s\n' "$f"
>   fi
> }
> ```

### Task B1: `update-cache.sh` symlink-aware

**Files:**
- Modify: `.claude/skills/meta-orchestrator/helpers/update-cache.sh:94-111` (`update_existing`)
- Test: `packages/core/hooks/update-cache.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
it('symlink-aware: cache symlink into CANON survives update (share preserved)', () => {
  // canon holds the real cache; worktree has a symlink to it
  const canonCache = `${canonDir}/_plan-cache.md`;
  writeFileSync(canonCache, INITIAL_CACHE_TEMPLATE); // valid '## Last invocation' template
  const wtCache = `${wtDir}/_plan-cache.md`;
  symlinkSync(canonCache, wtCache);
  execFileSync('bash', [HELPER, 'umbrella-x', 'outcome-y'], { env: { ...env, MO_CACHE_FILE: wtCache }, encoding: 'utf8' });
  expect(lstatSync(wtCache).isSymbolicLink()).toBe(true);            // still a symlink
  expect(readFileSync(canonCache, 'utf8')).toMatch(/umbrella-x/);    // canon updated through link
});
```

> Match the existing suite's env-var name for the cache path (read `update-cache.test.ts` head — it is `MO_CACHE_FILE` or similar). `INITIAL_CACHE_TEMPLATE` = a minimal body containing the `## Last invocation` heading + the 4 field lines (copy from the test file's existing fixture).

- [ ] **Step 2: Run to verify FAIL**

Run: `npm --prefix packages/core test -- update-cache`
Expected: FAIL — `lstatSync(wtCache).isSymbolicLink()` is `false` (mv replaced the symlink).

- [ ] **Step 3: Implement** — in `update_existing()`, add `resolve_target` (per shared snippet above) near the top of the file, then change `:99-110`:

```bash
update_existing() {
  local tmp target
  target="$(resolve_target "${CACHE_FILE}")"
  tmp="$(mktemp "$(dirname "${target}")/.plan-cache.tmpXXXXXX")"
  awk -v ts="${TIMESTAMP}" -v umb="${UMBRELLA}" -v sha="${GIT_HEAD}" -v out="${OUTCOME}" '
    BEGIN { in_block = 0 }
    /^## Last invocation$/ { in_block = 1; print; next }
    in_block && /^## / { in_block = 0; print; next }
    in_block && /^- Timestamp \(UTC\): / { print "- Timestamp (UTC): " ts; next }
    in_block && /^- Umbrella: /          { print "- Umbrella: " umb; next }
    in_block && /^- Git HEAD: /          { print "- Git HEAD: " sha; next }
    in_block && /^- Session outcome: /   { print "- Session outcome: " out; next }
    { print }
  ' "${target}" > "${tmp}"
  mv "${tmp}" "${target}"
}
```

> Note: read source from `${target}` (the resolved real file), write tmp in the target's dir (same filesystem → atomic rename), mv onto `${target}` — the worktree symlink at `${CACHE_FILE}` is untouched.

- [ ] **Step 4: Run to verify PASS**

Run: `npm --prefix packages/core test -- update-cache`
Expected: PASS (new + existing).

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/meta-orchestrator/helpers/update-cache.sh packages/core/hooks/update-cache.test.ts
git commit -m "fix(coordination): update-cache.sh symlink-aware — writes through to CANON, preserves share"
```

### Task B2: `update-delta.sh` symlink-aware

**Files:**
- Modify: `.claude/skills/meta-orchestrator/helpers/update-delta.sh:78-82`
- Test: `packages/core/hooks/update-delta.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
it('symlink-aware: delta symlink into CANON survives update', () => {
  const canonDelta = `${canonDir}/_master-backlog-delta.json`;
  writeFileSync(canonDelta, '{"untracked_seen":[],"closed_since_last":[]}');
  const wtDelta = `${wtDir}/_master-backlog-delta.json`;
  symlinkSync(canonDelta, wtDelta);
  execFileSync('bash', [HELPER, 'umbrella-x', 'outcome-y'], { env: { ...env, MO_DELTA_FILE: wtDelta }, encoding: 'utf8' });
  expect(lstatSync(wtDelta).isSymbolicLink()).toBe(true);
  // canon parses as JSON (write-through, not corrupted)
  expect(() => JSON.parse(readFileSync(canonDelta, 'utf8'))).not.toThrow();
});
```

- [ ] **Step 2: Run to verify FAIL**

Run: `npm --prefix packages/core test -- update-delta`
Expected: FAIL — symlink replaced.

- [ ] **Step 3: Implement** — add `resolve_target` near top; change the temp-then-mv at `:78-82`:

```bash
  target="$(resolve_target "${DELTA_FILE}")"
  tmp="$(mktemp "$(dirname "${target}")/.delta.tmpXXXXXX")"
  jq ... "${target}" > "${tmp}"   # read from resolved target
  mv "${tmp}" "${target}"
```

> Keep the exact `jq` filter already in the file (the metadata-update one); only the source/target paths change to `${target}`, and add the `resolve_target` call.

- [ ] **Step 4: Run to verify PASS**

Run: `npm --prefix packages/core test -- update-delta`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/meta-orchestrator/helpers/update-delta.sh packages/core/hooks/update-delta.test.ts
git commit -m "fix(coordination): update-delta.sh symlink-aware — writes through to CANON"
```

### Task B3: `delta-write-from-state.sh` symlink-aware

**Files:**
- Modify: `.claude/skills/meta-orchestrator/helpers/delta-write-from-state.sh:96-103`
- Test: `packages/core/hooks/delta-write-from-state.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
it('symlink-aware: delta symlink into CANON survives array rewrite', () => {
  const canonDelta = `${canonDir}/_master-backlog-delta.json`;
  writeFileSync(canonDelta, '{"untracked_seen":[],"closed_since_last":[]}');
  const wtDelta = `${wtDir}/_master-backlog-delta.json`;
  symlinkSync(canonDelta, wtDelta);
  execFileSync('bash', [HELPER, 'umbrella-x', '["a","b"]', '["c"]'],
    { env: { ...env, MO_DELTA_FILE: wtDelta }, encoding: 'utf8' });
  expect(lstatSync(wtDelta).isSymbolicLink()).toBe(true);
  const obj = JSON.parse(readFileSync(canonDelta, 'utf8'));
  expect(obj.untracked_seen.map((x: any) => x.id)).toEqual(['a', 'b']); // write-through
});
```

> Match this suite's actual positional arg shape for `delta-write-from-state.sh` (umbrella, current_ids_json, resolved_ids_json) — confirm against the existing test's invocations.

- [ ] **Step 2: Run to verify FAIL**

Run: `npm --prefix packages/core test -- delta-write-from-state`
Expected: FAIL — symlink replaced.

- [ ] **Step 3: Implement** — add `resolve_target` near top; change `:96-103`:

```bash
TARGET="$(resolve_target "${DELTA_FILE}")"
TMP="$(mktemp "$(dirname "${TARGET}")/.delta.tmpXXXXXX")"
jq --arg now "${TIMESTAMP}" \
   --argjson current "${CURRENT_JSON}" \
   --argjson resolved "${RESOLVED_JSON}" \
   '.untracked_seen   = ($current  | map({id: ., first_seen: $now})) |
    .closed_since_last = ($resolved | map({id: ., closed_at: $now}))' \
  "${TARGET}" > "${TMP}"
mv "${TMP}" "${TARGET}"
```

> The corrupt-JSON guard at `:72-79` operates on `${DELTA_FILE}` — leave it; reading a symlink with `jq empty` follows the link fine. Only the write block resolves to `${TARGET}`.

- [ ] **Step 4: Run to verify PASS**

Run: `npm --prefix packages/core test -- delta-write-from-state`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/meta-orchestrator/helpers/delta-write-from-state.sh packages/core/hooks/delta-write-from-state.test.ts
git commit -m "fix(coordination): delta-write-from-state.sh symlink-aware — writes through to CANON"
```

---

## SW-C — wiring (4 channels) — dispatch AFTER SW-A merges

### Task C1: skill §0 self-heal (channel A — agent-writable)

**Files:**
- Modify: `.claude/skills/meta-orchestrator/SKILL.md` §1 (add an idempotent link call as the first action of the plan-currency check)

- [ ] **Step 1: Add the self-heal call** at the top of §1 "Step 1 — inject live state", as a new `!`-fenced block BEFORE the existing plan-cache injection:

```markdown
**Step 0 — self-heal coordination links (channel A — idempotent, no-op if already linked):**

​```bash
bash "$CLAUDE_PROJECT_DIR/scripts/link-coordination.sh" 2>/dev/null || true
​```
```

> `|| true` — the linker exiting 1 on an unresolved conflict (default `skip`) must NOT abort the skill. It is advisory self-heal. (Remove the zero-width spaces around the fence when authoring — they are escape artefacts here.)

- [ ] **Step 2: Verify principle tests still pass** (SKILL.md is principle-checked)

Run: `npm --prefix packages/core run test:principles 2>/dev/null | tail -5`
Expected: PASS (no §5 AI-traps / paired-negative regressions).

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/meta-orchestrator/SKILL.md
git commit -m "feat(coordination): meta-orchestrator §1 Step 0 self-heal link call (channel A)"
```

### Task C2: maintainer-apply runbook (channels G + B + C — agent writes, maintainer applies)

**Files:**
- Create: `docs/meta-factory/runbooks/coordination-persistence-wiring.md`

- [ ] **Step 1: Write the runbook** with the three exact artefacts the maintainer copies into protected paths:

````markdown
# Runbook — coordination-persistence wiring (maintainer-applied)

These three edits land in agent-denied paths (`.husky/**`, `.claude/settings.json`, `~/.superset/**`). The agent authored the content; the maintainer applies it. All three call the same idempotent `scripts/link-coordination.sh`.

## Channel G — git post-checkout (agnostic floor)

Create `.husky/post-checkout` (chmod +x), content:

```sh
#!/usr/bin/env sh
# Link gitignored coordination state on every worktree checkout (harness-agnostic floor).
# $3 == 1 means a branch checkout (incl. `git worktree add`); skip file-only checkouts.
[ "$3" = "1" ] || exit 0
bash "$(git rev-parse --show-toplevel)/scripts/link-coordination.sh" >/dev/null 2>&1 || true
exit 0
```

## Channel B — CC SessionStart hook

In `.claude/settings.json`, add under `"hooks"`:

```json
"SessionStart": [
  { "hooks": [ { "type": "command",
    "command": "bash \"$CLAUDE_PROJECT_DIR/scripts/link-coordination.sh\" >/dev/null 2>&1 || true" } ] }
]
```

## Channel C — Superset setup-array (per-machine, replaces the rsync root cause)

In `~/.superset/projects/<project-uuid>/config.json`, REPLACE the rsync line in `setup` with a linker call (keep the node_modules line):

```json
"setup": [
  "bash \"$SUPERSET_ROOT_PATH/scripts/link-coordination.sh\" \"$SUPERSET_WORKSPACE_PATH\" \"$SUPERSET_ROOT_PATH\" >/dev/null 2>&1 || true",
  "<existing node_modules symlink line — unchanged>"
]
```

> The rsync `--ignore-existing` COPY is the §0-C root cause; replacing it makes fresh Superset worktrees LINK, never diverge.
````

- [ ] **Step 2: Commit**

```bash
git add docs/meta-factory/runbooks/coordination-persistence-wiring.md
git commit -m "docs(coordination): maintainer-apply runbook for channels G + B + C wiring"
```

- [ ] **Step 3 (maintainer, manual):** apply the three edits; then run the liveness checks in SW-D.

---

## SW-D — self-application (§6) + liveness — AFTER SW-A + SW-B + SW-C land

- [ ] **Step 1: Migrate THIS worktree (worktree-wins — local holds freshest kickoff/spec)**

Run: `bash scripts/link-coordination.sh "$(git rev-parse --show-toplevel)" "" --on-conflict=worktree`
Expected (stderr): `adopted ...` lines; exit 0.

- [ ] **Step 2: Verify the recursive-self-application gate**

Run: `find .claude/orchestrator-prompts -type l | head` and `ls -l .claude/orchestrator-prompts/coordination-persistence-fix/kickoff.md`
Expected: symlinks now exist (was 0/326); the kickoff is a symlink into `$CANON`.

- [ ] **Step 3: Channel-G liveness (agnostic floor, no CC/Superset)**

Run: `git worktree add /tmp/cpf-probe HEAD && find /tmp/cpf-probe/.claude/orchestrator-prompts -type l | head`
Expected: symlinks present (post-checkout fired). Then `git worktree remove /tmp/cpf-probe`.

- [ ] **Step 4: Channel-B / C liveness** — per the runbook: open a CC session in an unlinked worktree (B heals at SessionStart); create a fresh Superset worktree (C links at create, resolving the §2.4a open question — record which case held).

- [ ] **Step 5: write done.md + SSOT note** — at final-stage merge, write `.claude/orchestrator-prompts/coordination-persistence-fix/done.md` per CLAUDE.md schema; the work extends SSOT #110 (`@dual-pair: cross-worktree-coordination-doc-sync`) — no new row.

---

## Self-Review (writing-plans checklist)

1. **Spec coverage:** §2.2 channels G/B/C/A → SW-C C1+C2; §2.3 `--on-conflict` → A1; §2.4 symlink-aware → B1/B2/B3; §2.6 root-file loop → A2; §2.4a verification → SW-D Step 3/4; §6 self-application → SW-D Step 1/2; §2.5 SSOT → SW-D Step 5. **No gap.**
2. **Placeholder scan:** code shown in every code step; the two "match the existing suite's env-var name / arg shape" notes are deliberate (the worker must read the existing test head to bind the exact fixture name — not a TODO, an explicit bind instruction). No "TBD"/"handle edge cases".
3. **Type/name consistency:** `resolve_target` defined once (shared snippet) and used identically in B1/B2/B3; `--on-conflict` modes `canon|worktree|skip` consistent A1↔A2↔SW-D; `ROOT_FILES` list identical in both A2 blocks.

## Execution Handoff
See dispatch options below.

# Session-story recap — финальная история по актам (`/story`)

> **Scope:** a new "engaging story-in-acts" recap delivered when work is done, via two
> channels — a `/story` skill (manual) + a new branch in the Stop hook
> (`.claude/hooks/end-of-turn-reminder.sh`, auto on PR-create). Shared single
> source-of-truth prompt (`@dual-pair: session-story-recap`), localized via
> `AIF_HOOK_LANG` (EN canonical / RU operator).
> **NOT in scope:** the existing per-turn self-diagnostic recap (`## 🟢 Простыми
> словами`, Branch A/C — untouched); SessionEnd channel (the agent no longer speaks
> there); consumer shipping (this feature is `@cc-only-rationale` internal tooling, not
> in `install.sh`).
> **NOT authoritative for:** project goal — see [README.md#why-this-exists](../../../README.md#why-this-exists).

## Problem

The maintainer wants, **when the work is done and a PR is pushed**, an *engaging,
plain-language* narration of what the whole session accomplished — told as a story,
with jargon explained on the fly, honest about what's shaky, ending on the one decision
left to the human. The reference exemplar (maintainer-supplied, 2026-06-16) is a
"story in acts" recap given right after a PR push.

This is **a different optimisation** from what already exists, on two axes:

| | Existing per-turn recap | This feature |
|---|---|---|
| **When** | every substantial turn (Branch A) | only when work is done (PR pushed) |
| **For whom / how** | "в первую очередь для себя" — dense self-diagnostic checklist | for the human — living, accessible, interesting story |

The existing recap (`aif_msg_eot_branch_a` / `_branch_c` in `lang/ru.sh`) is an
anti-laziness self-check; it is **not** optimised to be read with pleasure. Both jobs
are legitimate and non-conflicting (parallel to the existing Branch A vs C split).

## Build-vs-reuse (own-stack-first)

Prior-art survey run 2026-06-16 (installed companions + SSOT + WebSearch ×2):

- **Installed companions: no match.** Only candidate `session-report`
  (`claude-plugins-official/plugins/session-report`) is **usage analytics** (tokens,
  cache, expensive prompts, HTML dashboard) — different problem class → **REJECT** for
  this purpose (T16 `#pattern-matching-on-name`). Superset not installed; SSOT (121
  entries) has no narrative-recap entry.
- **Wider ecosystem: exists, but different problem class.** `annikalewis/claude-recap`,
  Ben Poole's session-recap, et al. target **cross-session memory / "where did we leave
  off"** (archaeology for the *next* session), not "engaging completion story for the
  human." → **REFERENCE** the mechanism (read `~/.claude/projects/*.jsonl` transcript
  directly, not regex excerpts) — which we **already have** in the Stop hook
  (`end-of-turn-reminder.sh:23` reads `transcript_path`).
- **Cost:** lang-function + skill markdown + helper + hook branch + test = no new
  dependency, no code-module ≥80 LOC under `packages/` → **not a heavy
  capability-commit** per [CLAUDE.md](../../../CLAUDE.md). The story-in-acts *style* is
  maintainer taste — ours to write regardless; no companion saves it.

SSOT residue to land with the implementation: one row recording `session-report` REJECT
+ `claude-recap` REFERENCE.

## Design — one prompt, two channels, one language layer

Maps onto the existing [dual-implementation-discipline.md §7](../../../.claude/rules/dual-implementation-discipline.md)
"one logic, two channels" pattern. Anchor: `@dual-pair: session-story-recap`.

### Component 1 — the story-spec (single source of truth)

The canonical story-instruction prose is **one localized artifact**:
`aif_msg_eot_branch_story()` in `.claude/hooks/lang/en.sh` (EN canonical) +
`lang/ru.sh` (RU operator), selected by `AIF_HOOK_LANG` (default `en`, hard EN
fallback) — exactly the existing recap functions' mechanism. The localized prose **is**
the language carrier: when `AIF_HOOK_LANG=ru` the instruction is Russian, so the model
narrates in Russian (same as today's `## 🟢 Простыми словами` recap). Story-spec
distilled from the exemplar:

1. **Open in one sentence** — what we set out to do and why, in human terms.
2. **By acts** — narrative arc of the key moves, named (file / PR / decision): what we
   did, what went wrong, how it was fixed.
3. **Jargon on the spot** — hit a term (egress, caffeinate, Docker) → explain it with an
   analogy immediately.
4. **Honest** — where it's thinly verified (1 run, 1 case), what's uncertain, what's
   left.
5. **End on the human** — what's left for *you* to decide or do ("one step — your go").
6. **Tone** — interesting, like a story; no filler, no self-congratulation; truth over
   smoothness.

### Component 2 — `/story` skill (manual channel)

- New directory `.claude/skills/story/` (the **directory name is the slash command** —
  `/story`; renaming later = `git mv` the dir).
- **All skill files English-canonical** — `SKILL.md`, any `references/*`, helper
  comments — per the pipeline i18n headline directive
  ([2026-06-03 spec §Design](2026-06-03-pipeline-skill-i18n-design.md)). No Russian-only
  prose anywhere in the skill.
- **i18n crux** (same as pipeline): `SKILL.md` is markdown read by the AI — no runtime
  `source`. So a bash helper bridges: `.claude/skills/story/helpers/emit-story-prompt.sh`
  sources the active-language pack and echoes the story-instruction; `SKILL.md` invokes
  it via `!bash ${CLAUDE_SKILL_DIR}/helpers/emit-story-prompt.sh` (the `!shell`
  injection mechanism, modelled on
  [pipeline `emit-output-strings.sh`](../../../.claude/skills/pipeline/helpers/emit-output-strings.sh)
  + [SKILL.md:465](../../../.claude/skills/pipeline/SKILL.md)).
- **Single SSOT, not a sibling copy.** Because `/story` is **internal** (not shipped,
  unlike `/pipeline`), its helper sources the **shared** hook pack
  (`.claude/hooks/lang/${AIF_HOOK_LANG}.sh`) directly — so the story prose exists in
  **one** place, read by both channels. (The pipeline precedent kept *sibling* packs
  only because a shipped skill must not depend on non-shipped hook files
  — [2026-06-03 spec ¶ shipping](2026-06-03-pipeline-skill-i18n-design.md); that
  constraint does not apply here.)
- Invoked on demand — exactly the exemplar's path (the maintainer asked "расскажи
  интересно" by hand).

### Component 3 — Stop-hook auto branch (auto channel, trigger A)

In `end-of-turn-reminder.sh`, before the existing Branch A/B/C selection:

- Uses the same `aif_msg_eot_branch_story()` lang function (Component 1) — sourced
  directly (the hook already sources `lang/${AIF_HOOK_LANG:-en}.sh` at line 11).
- **New marker** `AIF_STORY_MARKER` — `## 🎬 Как это было` (ru) / `## 🎬 The story`
  (en) — distinct from `AIF_RECAP_MARKER` so the already-recapped guard can tell the two
  apart.
- **Trigger A — PR-create detected this turn.** Either:
  - the last assistant turn has a `Bash` `tool_use` whose `command` contains
    `gh pr create` (jq over `last_line` content), OR
  - the assistant `text` contains a fresh PR URL matching
    `github\.com/[^ )]+/pull/[0-9]+`.
- **Precedence:** when the PR signal is present, the story branch fires **instead of**
  the dry Branch A/C recap for that turn (work is done — self-diagnosis is moot). Other
  turns: unchanged.
- **Debounce by PR number** — store the last "storied" PR (number or URL) in a
  session-scoped flag (`${TMPDIR:-/tmp}/aif-story-<session_id>`, mirroring
  `ask-question-reminder.sh:42`). Same PR → silent; a genuinely new PR → its own story.
- **Already-told guard** — if the current turn text already contains `AIF_STORY_MARKER`,
  exit 0 (mirrors the existing `AIF_RECAP_MARKER` guard at
  `end-of-turn-reminder.sh:81`).
- Delivery uses the existing `decision: block` + `reason` JSON mechanism
  (`end-of-turn-reminder.sh:194`).

### Component 4 — language: EN canonical, RU via the variable

Per maintainer (2026-06-16) — same rule as every other hook + the `/pipeline` skill:

- **Hook code, comments, `en.sh`** — English-canonical. The repo is public.
- **`/story` skill files** — English-canonical (Component 2).
- **Russian reaches the operator only** through the `ru.sh` pack, selected by the
  operator's `AIF_HOOK_LANG=ru` env (`~/.claude/settings.json`). EN fallback if the pack
  is missing.
- **Parity guard** — the new `aif_msg_eot_branch_story()` + `AIF_STORY_MARKER` keys must
  be present in both packs; `.claude/hooks/lang/check-parity.sh` stays green.

### Component 5 — test (rule = test)

Companion test for the new branch (extends the existing hook companion test):

- **Positive:** synthetic transcript whose last assistant turn contains a `gh pr create`
  Bash `tool_use` → assert output contains the story-marker instruction.
- **Negative (no signal):** ordinary long turn, no PR → assert the dry recap fires, NOT
  the story.
- **Debounce:** same PR number twice in the debounce window → second fire is silent.
- **Parity:** `lang/check-parity.sh` green (new function + marker in both packs).
- **Skill helper:** `emit-story-prompt.sh` under `AIF_HOOK_LANG=ru` emits the RU prose;
  missing pack → EN fallback.

## Boundaries / YAGNI

- **Untouched:** the dry per-turn recap (Branch A/C) — it is a working discipline
  mechanism, kept.
- **No SessionEnd channel** — at SessionEnd the agent no longer produces a turn, so it
  cannot narrate; Stop is the only event that can make the agent speak once more.
- **No consumer shipping** — this feature is `@cc-only-rationale` internal tooling; no
  `install.sh` change, zero consumer impact. **If it is ever shipped**, the skill must
  switch to a *sibling* lang pack under `.claude/skills/story/lang/` (it must not depend
  on non-shipped hook files), per the pipeline precedent.

## Files touched

| File | Change |
|---|---|
| `.claude/skills/story/SKILL.md` | NEW — `/story` skill (EN canonical), `!bash` emit + narrate-by-acts |
| `.claude/skills/story/helpers/emit-story-prompt.sh` | NEW — sources shared hook pack, echoes active-language story prose |
| `.claude/hooks/lang/en.sh` | + `aif_msg_eot_branch_story()` + `AIF_STORY_MARKER` (EN) |
| `.claude/hooks/lang/ru.sh` | + `aif_msg_eot_branch_story()` + `AIF_STORY_MARKER` (RU) |
| `.claude/hooks/end-of-turn-reminder.sh` | + PR-detect + debounce + story-branch selection (before existing branches) |
| hook companion test | + positive / negative / debounce / parity / helper cases |
| `docs/meta-factory/prior-art-evaluations.md` | + 1 row (session-report REJECT, claude-recap REFERENCE) |

## Decided

- Command name **`/story`** (maintainer 2026-06-16).
- Auto-trigger **A** (PR-create signal), debounced per PR number.
- Approach **C** (skill + hook), single shared SSOT prose.
- EN canonical + RU via `AIF_HOOK_LANG`, pipeline i18n pattern as precedent.

## Open (minor, decide at implementation)

- Exact marker emoji/wording (`## 🎬 Как это было` / `## 🎬 The story`).
- Debounce keying — lean: strict per-PR-number, no time window (a new PR always earns a
  story).

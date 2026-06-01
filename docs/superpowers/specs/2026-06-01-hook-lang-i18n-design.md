# Hook payload i18n — RU operator / EN canonical

> **Scope:** the two reminder hooks that emit Russian payload prose
> (`.claude/hooks/ask-question-reminder.sh`, `.claude/hooks/end-of-turn-reminder.sh`).
> **NOT in scope:** the other 11 hooks (already English), `questions.ts` CLI strings,
> Russian *code comments* inside the two hooks (separate follow-up).

## Problem

The maintainer runs Claude in English (better reasoning, fewer tokens) but the two
reminder hooks emit Russian payload — the operator reads those nudges in Russian.
The repo is public ("present to the world") and per `layered-language-policy` shipped /
public artefacts should read English. A naive "second English copy of each hook" splits
into two files that drift apart — the named `#two-prompts-drift` anti-pattern
(`.claude/rules/dual-implementation-discipline.md §8`).

Note: both hooks carry `@cc-only-rationale: ... not shipped to consumer projects via
install.sh` — they are **internal** tooling, so the EN need is for the **public repo's
readability**, not for consumer installs. This removes the parity-as-hard-gate need.

## Design — split logic from payload strings

- Hook `.sh` keeps **all logic** (trigger conditions, grep guards, anchor extraction,
  branch selection). One copy. Cannot drift.
- Payload prose moves to **language packs**: `.claude/hooks/lang/en.sh` (canonical
  default) + `.claude/hooks/lang/ru.sh` (operator). Each defines the same set of
  `aif_msg_*` shell functions (so `${anchor}` interpolation happens at call time via
  dynamic scope) plus `AIF_RECAP_MARKER`.
- Selection: `AIF_HOOK_LANG` env var, default `en` (`${AIF_HOOK_LANG:-en}`), with a
  hard fallback to `en.sh` if the requested pack file is missing.
- Consumer / public repo: no env var → English out of the box, zero config.
- Operator: sets `AIF_HOOK_LANG=ru` **once, globally** in `~/.claude/settings.json`
  `env` (NOT the project `.claude/settings.json`, which would force RU on the world).

### The recap-marker coupling

`end-of-turn-reminder.sh` greps for the recap heading (`## 🟢 Простыми словами`) in an
already-recapped guard AND embeds it in the payload. The heading is therefore part of
the language pack (`AIF_RECAP_MARKER`), and the guard reads the same pack variable — so
guard ↔ message stay consistent within whichever language is active.

### Drift protection

`.claude/hooks/lang/check-parity.sh` (~20 LOC, no LLM): asserts `en.sh` and `ru.sh`
define the **same set** of `aif_msg_*` functions. Runs as a local/reviewer step, not a
blocking pre-push gate (hooks are not shipped, so a hard CI gate is unjustified —
matches the cost discipline). Promotable to a gate later if these hooks ever ship.

## Components

| File | Role |
|---|---|
| `.claude/hooks/lang/en.sh` | English payload pack (canonical default) |
| `.claude/hooks/lang/ru.sh` | Russian payload pack (operator) |
| `.claude/hooks/lang/check-parity.sh` | key-parity check between packs |
| `.claude/hooks/ask-question-reminder.sh` | sources pack, calls `aif_msg_question_challenge` |
| `.claude/hooks/end-of-turn-reminder.sh` | sources pack, calls `aif_msg_eot_*` + `AIF_RECAP_MARKER` |

## Testing

- `packages/core/hooks/end-of-turn-reminder.test.ts` + `ask-question-reminder.test.ts`
  assert Russian payload content → run those cases with `AIF_HOOK_LANG=ru` (they become
  the RU-pack contract; transcript *inputs* stay Russian regardless — they simulate a
  Russian session).
- Add a small `AIF_HOOK_LANG=en` smoke per hook: pack is wired, non-empty, English
  marker word present.
- `check-parity.sh` self-runs green.

## Out of scope (surfaced, not done)

- Translating the Russian *code comments* in the two hooks to English.
- Touching the other 11 hooks or `questions.ts`.

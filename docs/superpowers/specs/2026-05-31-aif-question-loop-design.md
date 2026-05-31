# Design — autonomous aif-handoff question-loop (collect → brainstorm-resolve → resume)

> **Status:** DRAFT for maintainer review (brainstorm output, 2026-05-31). Becomes the meta-launch kickoff after approval.
> **Authoritative for:** the design of the question-collection-and-resolution loop on top of the merged runtime-bridge dispatch (#312/#313). Decisions, reuse-vs-build split, MVP vs later, verify-first spikes.
> **NOT authoritative for:** project goal — see [README.md#why-this-exists](../../../README.md#why-this-exists). Bridge dispatch mechanics — see the merged runtime-bridge code + `docs/runtime-bridge-setup.md`.

## §0 Goal (plain)

After planning in `/meta-orchestrator`, dispatch an umbrella to aif-handoff for **autonomous execution that does not stop**. aif does everything it can on its own; the few points that genuinely need a human decision it **parks as questions**. The maintainer comes by whenever convenient, **brainstorms all accumulated questions for that umbrella in one chat** (work continues meanwhile), the answers flow back, and aif finishes the parked items. Replaces manual prompt copy-paste, manual new sessions, and manual result-carrying — on both the send AND the resolve side.

## §1 The loop — 3 layers (max reuse, min build)

### Layer 1 — autonomous work + question auto-triage → **REUSE + a trust posture**
- aif runs in async-batch mode (decided **A**): never blocks the whole task on a question; does all auto-doable work.
- **⚠ Honest limitation (verified `coordinator.ts:398-476` + `reviewGate.ts` + DeepWiki):** aif agents have **NO mid-implementation "pause and ask" primitive** — they implement (guessing on ambiguity) and auto-review *post-hoc*. Auto-close (`accepted` → done) fires when the review finds **no blocking findings** — that bar is "review found no blockers", NOT "a human is sure it's right". A genuine *design fork* is not recognized as a "question" — aif just picks and proceeds. **So aif does NOT by itself guarantee "close only when unambiguous" — it can decide wrong silently.** The maintainer's distrust is well-founded.
- **Trust posture (the design's answer) — 3 levers together:**
  1. **Conservative config** (verified via DeepWiki): `AGENT_MAX_REVIEW_ITERATIONS=1` (hand off to human fast if not converged) + `AGENT_AUTO_REVIEW_STRATEGY=closure_first` + `skipReview:false`. Stricter option: `autoMode:false` → every stage transition needs human action (max control, less autonomy).
  2. **Instruct the agent in the dispatched kickoff:** "on ANY genuine fork/ambiguity, do NOT pick — park it as a question and stop; proceed only when unambiguous." Carries the [`ask-question-reminder.sh:50-54`](../../../.claude/hooks/ask-question-reminder.sh) fork-challenge discipline into the aif agent.
  3. **The resolve loop reviews aif's DECISIONS, not only open questions:** the maintainer reviews each completed task (Approve/Request-changes), so "questions" = open forks **+** aif's autonomous decisions awaiting verification. Trust-but-verify.
- **Trust is a TUNABLE DIAL, not a baked-in distrust (do NOT over-design this upfront):** we cannot know aif's real decision quality without running it. The config levers above are a dial — `MAX_REVIEW_ITERATIONS` high = trust aif more / low = hand off more; autoMode; park-forks strength. **Crucially the loop (collect → resolve-in-chat → resume) is identical at any dial setting**, so the trust level does NOT block the build. Calibrate empirically (best-practice: tune escalation by observed error rate — [permit.io](https://www.permit.io/blog/human-in-the-loop-for-ai-agents-best-practices-frameworks-use-cases-and-demo)): start middle (trust-but-verify), run 2-3 real umbrellas, watch where aif actually erred vs over-asked, then adjust. Don't discard aif's autonomy on a guess.

### Layer 2 — notification → **REUSE, ~0 code (MVP)**
- **MVP (maintainer accepts per-question pings):** aif's built-in **Telegram push** already fires **per parked question** (on `task:moved` when status changes — [`notifier.ts:130`](https://github.com/lee-to/aif-handoff/blob/main/packages/agent/src/notifier.ts); needs `TELEGRAM_BOT_TOKEN`+`TELEGRAM_USER_ID`) + desktop/sound ([`useWebSocket.ts:172`](https://github.com/lee-to/aif-handoff/blob/main/packages/web/src/hooks/useWebSocket.ts)). **Zero build** — just config. Questions arrive as they happen; the maintainer resolves them at any convenient time (resolution is still batched per umbrella, §Layer 3).
- **Optional later (thin BUILD, reuse the WS already consumed in `aifWsStatus.ts`):** a **consolidated** "umbrella X: N questions ready / autonomous work idle" ping — a distinct signal ("aif has nothing left but your answers") layered on top of per-question pings. Demoted to optional since per-question pings are accepted. (Best-practice anti-over-escalation — [permit.io](https://www.permit.io/blog/human-in-the-loop-for-ai-agents-best-practices-frameworks-use-cases-and-demo) — but the maintainer prefers seeing each.)
- **Notify only.** No brainstorming in Telegram (agreed — Telegram can't host a brainstorm).

### Layer 3 — resolve (brainstorm) → **2 thin scripts + REUSE a chat**
- `cli/questions.ts <umbrella>` — pull ALL parked questions for the umbrella (from `manualReviewRequired`/`blocked_external` + `autoReviewState`).
- Brainstorm them together in a chat (the `superpowers:brainstorming` discipline).
- `cli/answer.ts <umbrella>` — push each answer back (append to the task plan / annotate) + resume the parked task → aif finishes it.
- **Per-umbrella isolation + no manual window** (maintainer UX requirements): all questions for one umbrella in ONE chat, another umbrella in another, and the chat opens itself (no manual "open a new window + paste"). → delivered via **Superset** (it already provides this; see §3 spike): on the batch-idle ping, the bridge calls Superset's MCP `start_agent_session` (`superset-chat`) in the umbrella's workspace, seeded with `cli/questions.ts` output → the per-umbrella brainstorm chat opens itself. **Fallback (no Superset):** the maintainer runs `cli/questions.ts <umbrella>` in any Claude session.

## §2 Reuse-vs-build + discipline

| Piece | Verdict |
|---|---|
| Async autonomous run, auto-review convergence, `manualReviewRequired`/`blocked_external` flags | **REUSE** aif-handoff |
| Question auto-triage ("decide clear, flag genuine forks") | **REUSE** `ask-question-reminder.sh` discipline + aif auto-review |
| Notification transport (Telegram/desktop) | **REUSE** aif (free) |
| Per-umbrella auto-opening brainstrom chat | **REUSE** Superset MCP `start_agent_session superset-chat` (verify §3) |
| Pull parked questions / push answers + resume | **BUILD** thin: `cli/questions.ts` + `cli/answer.ts` |
| Batch-idle consolidated ping | **BUILD** thin, on the WS already consumed |

**Discipline — Superset-agnostic core (per [SSOT #86](../../meta-factory/prior-art-evaluations.md) REJECT-substrate):** the shipped bridge MUST NOT hard-depend on Superset. `cli/questions.ts`/`cli/answer.ts` work in any chat. The Superset auto-open-chat is an **opt-in adapter**, capability-checked (Superset MCP present + configured → auto-open there; else → fallback to manual `cli/questions.ts`). Keeps the AI-/tool-agnostic substrate intact. Telegram + Superset are operator-chosen venues, not dependencies.

**No-paid-LLM ([rule](../../../.claude/rules/no-paid-llm-in-ci.md)):** all of this is client-side dispatch/HTTP/WS + the operator's own subscription runs (aif CLI transport, Superset chat). No API-billed calls, no CI LLM. The brainstorm runs on the operator's Claude session.

## §3 Verify-first spikes (before building the dependent parts)

1. **aif resume mechanism (load-bearing for `cli/answer.ts`):** exactly which REST/MCP call re-opens a `done`+`manualReviewRequired` task with the answer in context (a specific event? aif's Approve/Request-changes via REST/MCP?). Verify live on a real parked task. *(R-phase flagged this as the least-certain piece.)*
2. **Superset auto-open per-umbrella chat:** verify Superset's MCP `start_agent_session` (`superset-chat`) can be called by an external tool to open a chat in a target workspace seeded with an initial prompt (DeepWiki-claimed, unverified). If it can't, Layer-3 auto-open degrades to the manual-`cli/questions.ts` fallback (still functional, just one manual step).

## §4 Prerequisite (blocks ALL of this, incl. the merged dispatch)

aif-handoff's project clone must be **initialized so its own runtime writes don't dirty the worktree** — currently `.ai-factory/` (incl. `PLAN.md` written during dispatch) is untracked, so aif's branch-isolation guard rejects every dispatch (live-found 2026-05-31). Fix in the aif-handoff project setup: gitignore `.ai-factory/` (+ commit the static scaffolding). Until then, no autonomous run completes — this is a maintainer/aif-handoff-side setup step, not bridge code.

## §5 MVP vs later

**MVP (build now):**
1. Enable aif's native Telegram (per-question pings) — config, 0 build.
2. `cli/questions.ts <umbrella>` (collector).
3. `cli/answer.ts <umbrella>` (resolver + resume) — after spike §3.1.
4. Brainstorm in a normal Claude session (fallback path).

**Later (optional, separate phases):**
- Consolidated "autonomous-idle" ping (on the WS) — distinct from per-question pings.
- Superset auto-open per-umbrella chat (after spike §3.2) — delivers the "no manual window" UX.
- Extra rule-based question auto-triage (only if recurring auto-answerable patterns appear).
- MCP-target dispatch (ADOPT `@modelcontextprotocol/sdk`, SSOT #92) — gated on upstream aif per-session-transport fix.

## §6 §1.7 self-reflexive

- **Forward:** build-first-reuse ✓ (Layers 1-2 + Superset chat + Telegram all reuse; only 2 thin scripts + a WS-idle ping are BUILD — BFR §3 search for "pull review-questions into a chat + push answers" goes in the kickoff). no-paid-llm ✓ (§2). doc-authority ✓ (this header). dual-implementation ✓ (Superset-agnostic core + capability-checked adapter, not brand-name). reviewer-discipline ✓ (design surfaced for maintainer approval, not self-approved).
- **Backward:** builds on merged #312/#313 (dispatch + read-back); does not modify them. Reuses `aifWsStatus.ts` WS consumption. No artefact superseded.

## §7 Decisions (resolved with maintainer, 2026-05-31)

- **Collection mode:** A — async batch (aif never blocks the whole task; work doesn't stop). ✅
- **Resolution channel:** B — bridge pulls questions into a chat; resolve there; push back. (Not C — no dual-channel reconciliation; web stays read-only.) ✅
- **Superset auto-open chat:** **fast-follow**, not first MVP. Core (`cli/questions.ts`+`cli/answer.ts`+Telegram, manual chat) ships first; Superset auto-open is the immediate next phase after spike §3.2. ✅
- **Notifications:** per-question Telegram pings accepted (aif native, 0 code); consolidated batch-idle ping = optional later. ✅
- **Trust in aif's autonomy:** a tunable dial calibrated empirically (start trust-but-verify; do NOT bake in distrust; loop is identical at any dial). aif kept autonomous (autoMode ON) + agent instructed to park genuine forks. ✅
- **Auto-resolve of clear questions:** done by the resolution agent in-chat **under the maintainer's `ask-question-reminder.sh` fork-challenge** (it auto-decides unambiguous, surfaces only genuine forks) — near-free (it's this-session behavior), not aif's opaque review. ✅
- **Per-umbrella isolation:** one chat per umbrella (= per Superset workspace once the Superset phase lands). ✅

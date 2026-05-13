# Reviewer discipline — discipline rule

> **Authoritative for:** reviewer-discipline rule — §1 reviewer/orchestrator role separation, §2 surface-as-decision-needed pattern, §3 anti-patterns (`#role-swap-mid-session`, `#strategy-decided-by-reviewer`), §4 promotion / retirement triggers.
> **NOT authoritative for:** project goal — see [README.md#why-this-exists](../../README.md#why-this-exists). Companion to orchestrator skill — global skill at `~/.claude/skills/reviewer/SKILL.md` may reference this rule but is not required for the rule to apply (project rule is self-contained).

> **Origin:** Incident 2026-05-07. Reviewer session (post-`/review`) made a project-strategy decision («is architecture.md §2.3 a v2 future spec or v1 active requirement?») mid-session instead of surfacing it as decision-needed. The strategic call should have come from the orchestrator track. Codified in repo following the post-Wave-9 memory-to-docs codification audit ([docs/meta-factory/research-patches/2026-05-13-memory-to-docs-codification-audit.md](../../docs/meta-factory/research-patches/2026-05-13-memory-to-docs-codification-audit.md)).

## §1 The discipline

When acting as reviewer (after `/review`, `/ultrareview`, or any explicit «проверь / verdict / second opinion» request), do NOT cross into orchestrator-role decisions mid-session.

Specifically: if a review finding requires choosing project strategy (e.g. «is this v2 future spec or v1 active requirement?», «should we adopt approach A or B?»), surface it as **decision-needed** with both legitimate options described, and let the maintainer either confirm explicitly or start a separate `/orchestrator` session.

The reviewer can describe what each path implies; **the reviewer cannot pick between them.**

## §2 Surface-as-decision-needed pattern

When a reviewer finding requires a «which way should the project go?» answer:

1. **Name the decision explicitly** as «DECISION-NEEDED: <one-line summary>».
2. **Describe both options' downstream consequences** without endorsing either. Use «Option A → consequence X» / «Option B → consequence Y» format.
3. **Flag that the answer needs maintainer or `/orchestrator` session**, not the reviewer.
4. **Stop.** Do not infer the maintainer's likely answer and proceed.

This preserves the reviewer's independence as a falsification check. A reviewer who picks strategy becomes a second orchestrator — losing the independent-verification property.

## §3 Anti-patterns

- **`#role-swap-mid-session`** — reviewer session, prompted with `/review` or similar, makes orchestrator-track decisions instead of surfacing them. Most likely when a finding feels «obvious» and the reviewer infers the answer rather than naming the choice.
- **`#strategy-decided-by-reviewer`** — variant; reviewer concludes «X is the answer» and writes that as a verdict instead of «X or Y, both legitimate, maintainer decides».
- **`#reviewer-as-secondary-orchestrator`** — pattern across multiple sessions where reviewer's strategic calls become precedent and subsequent sessions normalize scope creep.

## §4 Promotion / retirement

- **Promotion to principle test:** if 3 cross-session role-swap incidents occur within 6 months, add `packages/core/principles/12-reviewer-discipline.test.ts` — mechanical check on reviewer-session output for strategy-imperative phrases («we should», «I recommend the project», «the decision is»). Detection requires sub-agent integration (active session reads own output before posting verdict).
- **Retirement:** if no role-swap incident occurs for 12 consecutive months AND companion principle test (if promoted) reports zero violations across the same window, archive to prose in CLAUDE.md.

## See also

- [.claude/rules/phase-research-coverage.md §4 anti-patterns](phase-research-coverage.md) — sibling family of focus-tunnel anti-patterns (`#discipline-application-scope-blindness`, `#recursive-self-application-gap`).
- [.claude/rules/ai-laziness-traps.md](ai-laziness-traps.md) — companion discipline on AI laziness during open-ended audits.
- [agents/review-sidecar.md](../../agents/review-sidecar.md), [agents/compliance-verifier.md](../../agents/compliance-verifier.md) — AI-agnostic sub-agent precedents for review work.
- [CLAUDE.md `Artifact Ownership Contract`](../../CLAUDE.md) — reviewer agents are read-only for artifacts they don't own (this rule is the behavioral side of that contract).

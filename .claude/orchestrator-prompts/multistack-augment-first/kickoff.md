# multistack-augment-first — extend live-research default delivery to react-spa / react-native / ts-server

> **Type:** single umbrella implementation kickoff covering **3 independent stacks**. Commit-per-stack; lands as **1–3 PRs to `staging`** (recommended cadence in §13). NOT a meta-launch / Stage-gated index — dispatch the per-stack work directly; it produces code + PR(s) to `staging`.
> **Authoritative for:** extending the augment-first live-research delivery (live-research = *primary* stack-rule delivery, presets = *fallback baseline*) from `react-next` to **`react-spa`, `react-native`, `ts-server`**; closing #812. NOT authoritative for project goal — see [README.md#why-this-exists](../../../README.md#why-this-exists).
> **Base:** `staging`. **Template of record:** PR [#824](https://github.com/artyhoo/rules-as-tests-aif/pull/824) + [`.claude/orchestrator-prompts/live-research-default-delivery/kickoff.md`](../live-research-default-delivery/kickoff.md) — the `react-next` slice. **Mirror its D1–D4 + non-vacuous §6 oracle structure per stack.**
> **$0-in-CI, deterministic, no network/MCP in the container** (fixture provenance constraint — see §11).
> **Closes:** [#812](https://github.com/artyhoo/rules-as-tests-aif/issues/812) (live-research as default delivery for all stacks).

## 0. One-line goal

`react-next` already delivers live-research as the primary stack-rule path (presets demoted to fallback) via PR #824. Do the **same augment-first flip for `react-spa`, `react-native`, `ts-server`** — give each stack the per-stack *surface* that the (already stack-general) wiring needs to fire, so a consumer's live-research output lands in that stack's `eslint.config.mjs` as primary, with the preset as fallback baseline + a staleness WARN.

## 1. Why — the verified gap (evidence, read from `origin/staging` @ `5beeb8496`)

The augment-first **wiring is already stack-general and already runs for every stack** — only the per-stack *inputs* are react-next-only. Verified:

**Already stack-general (DO NOT rebuild — see §2):**
- `setup.d/99-finalize.sh:36` invokes the synth-wirer with `--stack "${STACK:-ts-server}"` for **every** stack (not react-next-gated).
- `packages/core/install/synth-and-wire.ts` `mergeLiveRules()` (`:87`) + `readLiveSnippet()` (`:120`) merge the live snippet with the preset baseline **keyed on rule-id, not on stack** — stack-agnostic by construction.
- The D3 "presets are the fallback — prefer live-research" notice (`setup.d/99-finalize.sh:49-57`) already uses `${STACK:-ts-server}` — fires for all stacks.

**React-next-only inputs (this is the work, per stack):**
- `STACK_PATTERNS` in `synth-and-wire.ts:38` has **only `react-next`** (ts-server is intentionally empty — `:36` "no qualifying patterns → no-op"; spa/native are absent). This is the **override baseline** source — its absence silently breaks D2 (§6, the load-bearing gotcha).
- The #811 staleness WARN is **react-next-only**: `setup.d/99-finalize.sh:70` `elif [ "${STACK:-}" = "react-next" ]`, and only `packages/preset-next-15-canonical/preset.meta.json` exists.
- `packages/core/research/allowlist.ts:9-13` has `next.official`, `react.official` (→ react.dev), `tailwind.official`, `typescript.official` — but **no `react-native.official` → `reactnative.dev`** key.
- The only **live-format** demo fixtures (`*.research.json` + `*.selection.json`) are `react-next` (`no-head-element.*`). spa/native have only the **older `*-research-plan.json`** half (research-only, no `.selection.json`, and with **invalid allowlist keys** — `react.dev`/`reactnative.dev`/`github.com` used as *keys*, see §11). ts-server has **nothing**.

## 2. What is ALREADY stack-general — DO NOT rebuild, only verify

Touching any of these is scope creep (T16 — "merge sounds like new work"). They are REUSE targets:
- `mergeLiveRules` / `readLiveSnippet` / `unionWrapperSelectors` (`synth-and-wire.ts`).
- `wireNRules()` ts-morph AST merge + its override path (`packages/core/install/wire-eslint-r2.ts`) — REUSE; do **not** hand-roll a merger.
- `synthesizeGenerate` + `FileResearchClient` / `FileGenerateClient` / `withManualDrop` (`packages/core/synthesizer/file-clients.ts`) — the deterministic, $0 live-generate builder the §6 oracle uses.
- The D3 fallback notice (`99-finalize.sh:49-57`) — already stack-general; verify it fires, do not re-author.

## 3. Scope boundary (do NOT expand)

- **IN:** for each of `react-spa`, `react-native`, `ts-server` — give the stack-general wiring its per-stack inputs so live-research lands as primary: (D1) ensure the live snippet wires into that stack's config; (D2) live-wins-on-collision against that stack's *shipped* preset rules; (D3) verify the fallback notice fires; (D4) ship the #811 staleness marker + extend the WARN; plus a **genuinely declarative-forbid** demo fixture + the non-vacuous §6 oracle proving the live rule literally lands (§4, §8).
- **OUT (do NOT touch):** the react-next slice (done, #824 — do not re-touch its files except the shared `synth-and-wire.ts` STACK_PATTERNS map and `99-finalize.sh` WARN block, additively); deleting presets / full replace (augment-first — keep preset hand-inlining so principle 26 + offline consumers stay green); the live MCP doc-research itself (consumer's interactive session, not the container — §11); the install-self-verification surface (#810/#823); recipe authoring for new stacks (spa/native are recipe-less by design — §4). Surface anything else as a one-line `## Out-of-scope observations` in the PR body (CLAUDE.md «PR strategy»).

## 4. ⚑ LOAD-BEARING CAVEAT — the existing spa/native patterns are mostly `manual` → masquerade/theatre risk

The single biggest trap in this umbrella (domain-specific trap **T-MAF-A**, §12). The patterns already researched for spa/native are **NOT declarative-forbid** and will be **dropped** by `withManualDrop` → an oracle with nothing to assert = green-but-inert theatre:
- **react-spa:** `generate-react-spa.test.ts:86-102` proves all three SPA patterns resolve to **`manual`** — `spa-error-boundary` (glob-scoped, tautological-on-corpus), `spa-a11y` (plugin rule, not in L4 `KNOWN_PLUGINS`), `spa-hooks` (plugin rule). **None is a declarative-forbid selector.**
- **react-native:** `rn-web-globals` (forbid `window`/`document`/`localStorage`/… in RN) **is** declarative-forbid-expressible **as a `no-restricted-syntax` selector** → the clean demo. ⚠ The **existing** `stubGenerateRN` (`generate-stubs.ts:24-46`) emits it as `no-restricted-globals` with an `eslintConfig` array of plain global-name strings — **that form does NOT wire** (`buildRuleValueExpr`/`wrapperSelectorsPresent` in `wire-eslint-r2.ts:262,237` only land `{selector,message}` wrapper entries; plain-string array entries are silently dropped → `['error', ]`). So the demo MUST be **re-expressed** as a `presence:"forbid"` + `selector` selection (§5a), NOT reused from the stub. `rn-styles` / `rn-a11y` are plugin/manual.

**Binding rule for every stack:** the demo fixture's selected rule MUST be **genuinely declarative-forbid** (`check.type === 'declarative'`, a real `selector`, producing a **firing** negative test). It must survive `withManualDrop` and **literally land** in the merged config (§8). If a stack has **no** real declarative-forbid anti-pattern from a canonical-host doc, that stack ships **wire + allowlist + D4 + degrade-notice only**, with the demo recorded **research-only** — **never invent a contrived rule to fill the demo slot** (T-MAF-C). Honest degrade > theatre. This is the project thesis applied to itself ("documents lie; tests don't").

## 5. Per-stack deliverables

For each stack mirror #824's D1–D4 (above). Stack-specific notes:

### 5a. react-native (clearest declarative demo — likely first)
- **Demo:** convert `rn-web-globals` into the live format — a `<demo>.research.json` (reuse the real `reactnative.dev/docs/platform-specific-code` provenance already in `fixtures/rn-research-plan.json`) **plus** a `<demo>.selection.json` carrying a declarative-forbid `selector` for the web-global access (mirror `no-head-element.selection.json` shape: `entryId`, `ruleId`, `presence:"forbid"`, `selector`, `message`, `negativeTest`; e.g. a selector targeting `MemberExpression[object.name='localStorage']` / `window` / `document`). **Do NOT reuse the existing `stubGenerateRN` `no-restricted-globals` eslintConfig form** — `wireNRules` only lands the `no-restricted-syntax` wrapper shape (array entries must be `{selector,message}`), so the stub form would pass an oracle-source-real check yet fail to wire (the green-but-unwirable case, T-MAF-A). Fixtures live under `packages/core/synthesizer/fixtures/` (NOT `.ai-factory/` — gitignored).
- **allowlist:** add `'react-native.official': ['reactnative.dev']` to `packages/core/research/allowlist.ts` (+ a case in `allowlist.test.ts`). The existing fixture's `allowlistKey: "reactnative.dev"` is **invalid** (host-as-key) — the live `FileResearchClient` validates, so the new fixture MUST use the **key** `react-native.official`.
- **override baseline (D2):** see §6 — add a `STACK_PATTERNS['react-native']` entry mirroring the rule-ids the RN preset hand-inlines (or the §6 alternative), so a same-id live rule overrides rather than being skipped.
- **D4:** ship `packages/preset-react-native/preset.meta.json` (schema mirrors `preset-next-15-canonical/preset.meta.json`: `schemaVersion`, `snapshotDate`, `framework`, `note`, `pins`) + extend the `99-finalize.sh` WARN block to resolve the per-stack `preset.meta.json` (note the expo vs bare-rn template split: `eslint.config.expo.mjs` / `eslint.config.bare-rn.mjs`).

### 5b. react-spa (needs a declarative-forbid demo expressed — its 3 researched patterns are all `manual`, §4)
- **Demo:** pick a **real** SPA anti-pattern that *is* declarative-forbid-expressible from a `react.official` (react.dev) canonical doc — e.g. a JSX `no-restricted-syntax` selector — and author the `.research.json` + `.selection.json` pair. Do **not** convert `spa-error-boundary`/`spa-a11y`/`spa-hooks` as-is (they are `manual` → dropped → theatre, §4). If no clean declarative-forbid SPA rule from a canonical host surfaces, degrade per §4 (wire + allowlist + D4 + notice; demo research-only).
- **allowlist:** `react.official` already exists (`allowlist.ts:10`). The existing `react-spa-research-plan.json` uses `allowlistKey: "react.dev"` (invalid host-as-key) and `"github.com"` (not allowlisted) — the new fixture MUST use `react.official`.
- **override baseline (D2) + D4:** as 5a — `STACK_PATTERNS['react-spa']` (or §6 alternative) mirroring the SPA preset's hand-inlined rule-ids. ⚠ For the D2/Negative-2 override demo, target an **unconditional** preset rule-id — `no-unsafe-zod-parse` (`eslint.config.react.mjs:245`) or `require-error-boundary` (`:255`) — **NOT** `no-direct-time-randomness` (R7) / `require-otel-span` (R8), which ship only behind `AIF_STRICT_RUNTIME` (`:52`) and are absent in a default install (overriding a rule-id that isn't in the config proves nothing). Ship `packages/preset-react-spa/preset.meta.json` + WARN.

### 5c. ts-server (hardest — wire + degrade by default; demo only if a real declarative rule is found)
- ts-server is **recipe-less and `STACK_PATTERNS`-empty by design**; server anti-patterns are usually cross-file/runtime → **not** single-file declarative-forbid. Default deliverable = **wire the live path + allowlist + degrade-notice** (so when a consumer researches a real ts-server rule it lands), **no demo rule** unless research surfaces a genuinely declarative-forbid one (then author it; never contrived — §4).
- **config target:** ts-server has a base config at `templates/ts-server/eslint.config.mjs` (copied by `setup.d/40-configs.sh`; `:222` is the per-workspace monorepo path — for a **flat** ts-server install the wiring target is the **root** `eslint.config.mjs` that `99-finalize.sh:24` wires). Verify the live snippet wires into it.
- **allowlist:** `typescript.official` already exists (`allowlist.ts:13`).
- **D4:** ts-server has no preset *package*; either ship a minimal `templates/ts-server/preset.meta.json` (pins: `typescript`, `eslint`, `typescript-eslint`; no `framework`) + WARN, or skip D4 for ts-server with a one-line rationale in the PR body. Pragmatic — do not contort.
- **#812 closes** when all three stacks' live path is **wired** (demo non-vacuity is proven by the stacks that have a declarative demo; ts-server's wired-path + degrade is sufficient for "default delivery available for all stacks").

## 6. ⚑ The empty-`STACK_PATTERNS` → D2-override-silently-skipped gotcha (verify, don't assume)

Domain-specific trap **T-MAF-B**. `mergeLiveRules(presetRules, liveRules)` (`synth-and-wire.ts:87-114`) computes `overrideKeys` from `presetRules` = `synthesize()` over `STACK_PATTERNS[stack]`. For spa/native/ts-server `STACK_PATTERNS[stack]` is **absent/empty** → `presetRules = {}` → a live rule reusing a **hand-inlined preset rule-id** hits `!Object.hasOwn({}, id)` → treated as **pure augment, NOT override** → `wireNRules` sees the rule-id already in the config string (`simpleRulePresent`, `wire-eslint-r2.ts`) → **SKIP → the preset wins, the opposite of live-wins**. The react-next override path does **not** transfer for free.

**Invariant (binding):** a live rule sharing a stack's **shipped** preset rule-id MUST override the preset's options/severity in the merged config. **Mechanism is the worker's call, REUSE-first** — the natural fix is to add a `STACK_PATTERNS[stack]` entry whose synthesized rule-ids equal the stack's hand-inlined preset rule-ids (so `presetRules` carries them and `overrideKeys` is computed correctly). The **proof** is the §8 Negative-2 (override) oracle per stack — that test, not a claim, is what closes this.

## 7. Principle 28 + byte-identical baselines — stay GREEN (verify per stack, do not blind-recapture)

- **Principle 28** (`packages/core/principles/28-synth-wire-oracle.test.ts`) is **recipe-sourced** (react-next recipes + preset template). spa/native are recipe-less and the preset templates are unchanged → principle 28 is unaffected. **Do NOT modify it.** Run after changes, confirm green (#824 §4 reasoning).
- **Byte-identical** (`tests/install-sh/baselines/<stack>/*.fingerprint`): the new live-snippet read is gated on the snippet **file existing** (`readLiveSnippet` returns `{}` when absent — `synth-and-wire.ts:120`), and the capture fixtures have **no** `.ai-factory/synthesizer-output/eslint-rules-snippet.json` → snippet-absent ⇒ no-op ⇒ fingerprints unchanged. **VERIFY** via `bash tests/install-sh/byte-identical.test.sh` after each stack; **re-capture (`SNAPSHOT_MODE=capture bash tests/install-sh/snapshot.sh`) ONLY if it actually drifts** (the wrapper hardcodes compare, ignores env — memory `reference_byte_identical_baseline_regen_on_template_edit`). Adding a new preset package file (`preset.meta.json`) or a `STACK_PATTERNS` entry can shift fingerprints — if so, recapture deliberately and note which path + why in the PR body.

## 8. §6-equivalent non-vacuous oracle — the live-path proof, PER STACK (T15 / T-LRD-A)

Mirror `packages/core/install/wire-live-snippet.test.ts` (the react-next oracle) for each stack that ships a demo. It MUST be non-vacuous — a merge test that can't fail is theatre:
- **Existence (non-vacuous):** the stack's template + `<demo>.research.json` + `<demo>.selection.json` exist.
- **Oracle-source-real:** the built live snippet genuinely carries the demo `selector` (`toContain(SELECTOR)`) — proves the generate half produced a declarative rule (catches the §4 `manual`-dropped case).
- **Positive (augment):** feed the snippet to the wirer over the stack's preset template fixture (built via `synthesizeGenerate(plan, withManualDrop(new FileGenerateClient(selection), …))`, $0, no network) → assert the merged `eslint.config.mjs` **literally contains** the demo selector **AND** still contains the stack's preset rule-ids (augment, not replace).
- **Negative-1 (absent ⇒ no-op):** absent snippet ⇒ merged config == preset baseline, no live rule (this keeps §7 baselines green).
- **Negative-2 (override / D2):** a live rule sharing a stack preset rule-id but with a changed option ⇒ `overrideKeys.has(id) === true` **and** the merged config carries the **live** value (preset overridden) — the proof for §6.
- Wire any new `tests/install-sh/*.test.sh` into `.github/workflows/audit-self.yml` as an explicit `run:` step (the install-sh meta-gate is "armed-but-not-fired" otherwise — PR #796 lesson). Mirror how #824 gated `wire-live-snippet.test.ts` + `preset-staleness.test.sh`.

## 9. Build-vs-reuse + capability-commit + Prior-art

REUSE-dominant: this connects existing stack-general primitives to per-stack inputs. New per-stack data (STACK_PATTERNS entries, fixtures, allowlist key, preset.meta.json) is data, not new mechanism. Consult `docs/meta-factory/prior-art-evaluations.md`; the relevant precedent is **#183** (rule-bootstrapping / live-adapter). Carry a `Prior-art:` trailer on each capability commit (cite `#183 ADAPT — extends the live-adapter to additional stacks`; add a new SSOT id only if a genuinely new capability emerges — verify max id `grep -oE '^\| *[0-9]+ ' docs/meta-factory/prior-art-evaluations.md | grep -oE '[0-9]+' | sort -n | tail -1`). A new SSOT row is **not** expected for a stack-extension. If you add `react-native.official` to the allowlist or a new declarative selector, that is data/config, not a capability commit by the CLAUDE.md definition — but a new ≥80-LOC fixture/test file may trip the pre-push capability detector → carry the `Prior-art:` trailer or the escape hatch.

## 10. Acceptance criteria (verify-before-harvest)

Per stack shipped:
1. On a `--full` install for the stack WITH `.ai-factory/rules-research/<stack>.{research,selection}.json` present → the generated declarative rule appears in the consumer's `eslint.config.mjs`; WITHOUT them → config == preset baseline + the fallback notice (degrade, never error).
2. D2 override proven on a fixture (§8 Negative-2): a stack preset rule-id X + a live rule with the same id X but a different option ⇒ merged config carries the **live** value for X **and** `overrideKeys.has(X)`. (Do NOT assert `RuleCollisionError` — synthesis-time-only, not on this path.)
3. The demo rule is **genuinely declarative-forbid** and its §8 oracle is **non-vacuous** (oracle-source-real assertion present + positive literally-lands + both negatives). A stack with no real declarative rule ships wire+allowlist+D4+notice **without a demo**, and the PR body says so explicitly (no contrived rule — §4).
4. Principle 28 GREEN + unmodified; byte-identical baselines verified (recaptured only if actually affected, with a one-line note of which path + why).
5. #811 marker shipped for the stack (or rationale if skipped for ts-server) + WARN fires when installed major ≠ recorded major (proven on a fixture/dry-run).
6. `npm test --workspaces` + principle meta-tests green; new install-sh tests wired into `audit-self.yml`.
7. PR body: `Closes #812` (on the PR that completes the last stack; earlier PRs use `Refs #812`); `### §1.7 Forward-check applied` + `### §1.7 Backward-check applied` (each ≥40 chars, ≥1 file:line — `discipline-self-check.yml` gate).

## 11. Fixture provenance + egress / harvest

- **Provenance is host-gated, not content-gated** (`validateProvenance` — memory). Each demo fixture's `provenance[].url` MUST be a **real, live** canonical-doc page under the matching allowlist key. **Reuse the already-verified canonical URLs** present in the existing `*-research-plan.json` fixtures (e.g. `reactnative.dev/docs/platform-specific-code`) — those were fetched+quoted when authored. If you introduce a **new** URL, it must be verified live (fetch+quote) — that is an interactive-session step, since the **container network is blocked** (only `api.github.com` reachable). Do NOT invent or guess a doc URL (T3).
- **Egress = host-push default** ([egress-no-api-bypass.md §1](../../../.claude/rules/egress-no-api-bypass.md)): land via host-pull + rebase onto live `origin/staging` + host `git push` (runs the real `.husky/pre-push`). API-land is break-glass only.
- **Run the FULL CI-equivalent gate set locally before harvest** (memory `feedback_harvest_run_full_ci_gate_set_locally`): reproduce the CI install order (`npm ci --prefix packages/core` → root `npm install`) **before** the synth-bundle #755 drift check — the semver-drift trap bit #824 twice. If `synth-and-wire.ts` is edited, rebuild + commit `synth-and-wire.bundle.mjs` (drift gate).

## 12. AI-laziness traps (per [.claude/rules/ai-laziness-traps.md §2-§3](../../../.claude/rules/ai-laziness-traps.md))

**Active traps:** T2, T3, T5, T13, T15, T16.
- **T2** — do not write `# would merge`; run the wirer on the fixture and assert the rule is in the output config string.
- **T3** — every acceptance claim carries a command + observed output; do not trust the existing fixtures' allowlist keys / `manual`-vs-declarative status from memory — re-verify (this kickoff's §4 + §11 are themselves T3 catches against the older fixtures).
- **T5** (no drive-by) — stay within the 3 stacks; do not delete presets, do not re-touch the react-next slice beyond the shared `STACK_PATTERNS` map + WARN block, do not touch #810/#823.
- **T13** — the existing `*-research-plan.json` fixtures are NOT zero-work "already validated": they were never validated on the stub path (invalid allowlist keys) and their patterns are mostly `manual`. Audit each before reuse.
- **T15** — the §8 oracle per stack must itself be proven able to fail (oracle-source-real + literally-lands + paired negatives).
- **T16** — REUSE `wireNRules` / `mergeLiveRules` / `synthesizeGenerate`; do NOT hand-roll a merger or a second generate path because "another stack" sounds like new work.

**Domain-specific traps (this umbrella):**
- **T-MAF-A «manual-pattern masquerade»** — converting an existing spa/native research pattern as-is; it resolves to `manual`, `withManualDrop` drops it, the oracle has nothing to assert → green-but-inert. Counter: §4 — each demo MUST be genuinely declarative-forbid with a firing test, or degrade research-only.
- **T-MAF-B «empty-STACK_PATTERNS → override skipped»** — assuming the react-next D2 override transfers; for empty-baseline stacks a same-id live rule is pure-augment and the preset silently wins. Counter: §6 invariant + the Negative-2 oracle.
- **T-MAF-C «contrived rule to fill the demo slot»** — inventing a synthetic declarative rule (esp. for ts-server) just to make the oracle non-vacuous. That is theatre. Counter: §4 — honest degrade (wire+allowlist+notice, demo research-only) beats a fake rule.

## 13. Output contract

- One umbrella, **commit per stack**. **Recommended cadence (durability + risk isolation):** land `react-native` first (clearest declarative demo), then `react-spa` (express a real declarative demo or degrade), then `ts-server` (wire+degrade, demo only if a real declarative rule is found). `react-native` + `react-spa` MAY share one PR; **`ts-server` SHOULD be its own PR** (isolate its risk so it cannot block the others). Final stage's PR carries `Closes #812`; earlier PRs `Refs #812`.
- Base `staging`; do NOT push to `main`; do NOT open speculative extra PRs (CLAUDE.md «PR strategy»).
- **Pre-dispatch:** this kickoff must be merged to `staging` before any `/pipeline` / aif dispatch (it is read from `staging`) — [kickoff-staging-placement.md §1](../../../.claude/rules/kickoff-staging-placement.md). Probe in-flight before dispatch (CLAUDE.md «Pre-dispatch in-flight probe»).
- **REPORT per stack:** files changed (path:line); the fixture-merge output proving the live declarative rule is in the config + presets retained; the §8 oracle (positive + both negatives, non-vacuous, oracle-source-real); principle 28 green (unmodified); which byte-identical path the baselines exercise (+ whether recaptured + why); the staleness WARN firing; `npm test --workspaces` result. State explicitly for each stack whether it shipped a demo rule or degraded research-only, with the reason. Confidence + ATTN.

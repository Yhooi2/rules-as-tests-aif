---
name: probe-cc-perm
description: One-shot probe — records the literal pattern CC emits to its permission check for a !-fenced helper invocation. Used by 2026-05-28 meta-orch-no-arg-overview umbrella Stage 0 §1.5d. Delete after use.
---

## Probe 1 — direct shell builtin (control, never matches a Bash(*) allow-rule pattern related to helpers)

```!
echo probe-ok-direct
```

## Probe 2 — compound `||` (matches P4-b compound-matcher concern)

```!
true || true
```

## Probe 3 — direct-path helper invocation (matches the EXACT failing pattern in P4 §0)

```!
${CLAUDE_SKILL_DIR}/helpers/probe.sh probe-arg
```

# setup.d — Layer registry

> **Authoritative for:** the modular install.sh layer table — what each numbered layer file does,
> what variables it consumes from the dispatcher scope, and what globals it exports.
> **NOT authoritative for:** project goal — see [README.md#why-this-exists](../README.md#why-this-exists).

## Overview

`install.sh` is a thin dispatcher. It sources `setup.d/lib.sh` for shared helpers, then
sources each numbered layer file in lexicographic order. Layers run in the SAME shell process
(not subprocesses), so mutations to `SKIPPED`, `DEVDEPS`, `_r2_verdict`, `DEPS_INSTALLED` etc.
persist across layers and are visible to the finalize tail in `install.sh`.

## Layer table

| Number | File | Purpose | Origin (install.sh lines) |
|--------|------|---------|--------------------------|
| —      | `lib.sh` | Shared helpers + lib-only guard | L216-528 (helpers); L39-56 (transform_internal_refs) |
| 05     | `05-mcp.sh` | MCP configuration **stub** (S2) | net-new |
| 10     | `10-skills.sh` | §1 Skills — rules-as-tests, tool-bootstrapping, orchestration skills | L689-745 |
| 15     | `15-companions-stack.sh` | Companions stack **stub** (S3) | net-new |
| 20     | `20-agents.sh` | §2 Sub-agents + §3c skill-context overrides (MIXED split) | L747-800, L839-846 |
| 30     | `30-templates.sh` | §3a AI Factory base + §3b tool-decisions.md + §3d stack ARCH/RULES | L802-858 |
| 40     | `40-configs.sh` | §4 Scripts + §5a shared configs + §5b' ESLint barrel + §6a stack configs | L866-1123 |
| 50     | `50-hooks.sh` | §1b Claude hooks + §5c .husky/ + TS-core hooks + git activation | L747-777, L950-994 |
| 60     | `60-ci.sh` | §6b .nvmrc drift + §6b-bis R2 auto-wire L1 + §6c CI-orphan WARN+wire | L1125-1356 |
| 70     | `70-deps.sh` | §7 package.json scripts + §8 dev-dep install + §8b tsx-at-root | L1358-1595 |

**Finalize tail** (in `install.sh` dispatcher, after the layer loop):
- §6b-bis-L2 R2 AST-wire Layer 2 (consumes `_r2_verdict` from 60-ci)
- otel-WARN
- `ignore_shipped_configs` call
- SKIPPED summary
- Done banner + Next-steps

## lib.sh public API

All symbols below are available to any layer that sources `lib.sh`. The lib-only guard at the
END of `lib.sh` means sourcing with `INSTALL_SH_LIB_ONLY=1` exposes all helpers without
running any install logic.

### Variables set by lib.sh

| Variable | Type | Description |
|----------|------|-------------|
| `UPSTREAM_BLOB_URL` | string | GitHub blob base URL for internal-ref rewriting |
| `PRETTIERIGNORE_BEGIN` | string | Begin-marker for AIF managed block in .prettierignore |
| `PRETTIERIGNORE_END` | string | End-marker for AIF managed block in .prettierignore |
| `PRETTIERIGNORE_CFG_BEGIN` | string | Begin-marker for shipped-configs block |
| `PRETTIERIGNORE_CFG_END` | string | End-marker for shipped-configs block |

### Functions defined by lib.sh

| Function | Signature | Description |
|----------|-----------|-------------|
| `transform_internal_refs` | `(file)` | Rewrite repo-internal `.md` links to blob URLs in-place |
| `copy_safe` | `(src dst)` | Copy src→dst, skip-if-exists (respects FORCE/DRY_RUN) |
| `refresh_safe` | `(src dst)` | Copy src→dst, overwrite unless .override.md present |
| `merge_prettierignore` | `(src dst)` | Non-destructive .prettierignore merge |
| `_prettierignore_in_skipped` | `(path)` | Test if path is in SKIPPED array |
| `ignore_shipped_configs` | `()` | Add freshly-shipped configs to .prettierignore |
| `mkdir_safe` | `(dir)` | `mkdir -p` respecting --dry-run |
| `chmod_safe` | `(mode files...)` | `chmod` respecting --dry-run |
| `detect_pm` | `()` → stdout | Detect consumer PM: npm \| pnpm \| yarn |
| `patch_stryker_package_manager` | `()` | Patch stryker.config.json packageManager key |
| `copy_skill_with_transform` | `(slug)` | Copy .claude/skills/<slug>/ + internal-ref rewrite |
| `refresh_skill_with_transform` | `(slug)` | refresh_safe semantics for skill directories |

### Variables consumed from dispatcher scope

Layers assume these are exported by the dispatcher before any layer is sourced:

| Variable | Set by | Description |
|----------|--------|-------------|
| `PKG_ROOT` | install.sh | Absolute path to the framework package |
| `PROJECT_ROOT` | install.sh | Consumer project root (pwd at install time) |
| `FORCE` | install.sh flag parse | `--force` or empty |
| `DRY_RUN` | install.sh flag parse | `--dry-run` or empty |
| `FULL` | install.sh flag parse | `--full` or empty |
| `WIRE_CI` | install.sh flag parse | `--wire-ci` or empty |
| `STACK` | install.sh (flag/picker) | `ts-server` \| `react-next` \| `react-spa` \| `react-native` |
| `SKIPPED` | install.sh (array `=()`) | Array of skipped destination paths (layers append) |
| `SHIPPED_DOCS` | install.sh (array) | Canonical shipped artefact list (header-verified) |

### Variables exported to the finalize tail

| Variable | Set by | Read by |
|----------|--------|---------|
| `_r2_verdict` | `60-ci.sh` §6b-bis | install.sh finalize tail §6b-bis-L2 |
| `DEPS_INSTALLED` | `70-deps.sh` §8 | install.sh finalize tail Next-steps |
| `DEVDEPS` | `70-deps.sh` §8 | install.sh finalize tail Next-steps manual fallback |

## Stub layers

### 05-mcp.sh (S2 stub)

Populated in S2 with: context7 MCP configuration, stack-specific MCP entries, user-scope
DeepWiki detect-first install. Currently a no-op placeholder.

### 15-companions-stack.sh (S3 stub)

Populated in S3 with: companion detect-first installs (from `companions.manifest` +
`engine.sh`), tool-bootstrap revival, aif-handoff runtime bridge setup. Currently a no-op.

## Ordering constraints

- `10-skills.sh` must run before `20-agents.sh` (skills dir must exist for aif-doctor helpers chmod)
- `20-agents.sh` must run before `30-templates.sh` (skill-context dirs depend on agents/ being present)
- `40-configs.sh` must run before `50-hooks.sh` (settings.json may be created by 40; hooks register into it) — actually 50 creates settings.json if absent, 40 has no dependency on it. Independent.
- `60-ci.sh` must run after `40-configs.sh` (eslint.config.mjs must exist for R2 auto-wire)
- `70-deps.sh` must run after `40-configs.sh` and `50-hooks.sh` (scripts + hooks must land before deps install)
- Finalize tail (install.sh) must run after `60-ci.sh` (`_r2_verdict`) and `70-deps.sh` (`DEPS_INSTALLED`, `DEVDEPS`)

The lexicographic 05/10/15/20/30/40/50/60/70 order satisfies all constraints.

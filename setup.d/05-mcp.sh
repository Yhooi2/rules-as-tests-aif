#!/usr/bin/env bash
# setup.d/05-mcp.sh — MCP configuration layer (stub — populated in S2).
# S0/O7: no install.sh rows — this layer is net-new, populated in S2.
# Prior art: legacy setup.sh:289–307 context7 .mcp.json jq-merge.
#
# Variables consumed from dispatcher scope:
#   PKG_ROOT, PROJECT_ROOT, FORCE, DRY_RUN, SKIPPED (array)

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# S2: context7 + stack MCP + user-scope DeepWiki detect-first install goes here.
: # no-op placeholder — S2 populates this layer

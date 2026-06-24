#!/usr/bin/env bash
# setup.d/15-companions-stack.sh — Companions stack layer (stub — populated in S3).
# S0/O7: sourced from setup wrapper + companions.manifest, not install.sh.
#
# Variables consumed from dispatcher scope:
#   PKG_ROOT, PROJECT_ROOT, FORCE, DRY_RUN, SKIPPED (array)

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# S3: companion detect-first installs + tool-bootstrap revival go here.
: # no-op placeholder — S3 populates this layer

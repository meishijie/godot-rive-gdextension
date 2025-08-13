#!/usr/bin/env bash
set -euo pipefail

# Restore full working tree after enabling sparse-checkout.
# This script will not remove itself.

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
cd "$ROOT_DIR"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "[error] not a git repo"; exit 1; }

if git sparse-checkout -h >/dev/null 2>&1; then
  echo "[sparse] disabling sparse-checkout (restore full tree)"
  git sparse-checkout disable || git sparse-checkout set "/*" || true
else
  echo "[info] sparse-checkout not enabled or Git too old; nothing to do"
fi

echo "[done] Full tree restored."


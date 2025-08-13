#!/usr/bin/env bash
set -euo pipefail

# Safe local cleanup script for this repo.
# Default: only remove known build outputs (won't delete this script).
# Options:
#   --sparse    Enable sparse-checkout to exclude large thirdparty dirs (reversible)
#   --deep      Additionally run git clean -xfd on selected dirs with exclusions
#
# Run from anywhere; it will locate repo root by build/SConstruct.

# Locate repo root (it is the directory that contains build/SConstruct)
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
if [[ ! -f "$ROOT_DIR/build/SConstruct" ]]; then
  echo "[error] Could not find build/SConstruct from $ROOT_DIR" >&2
  exit 1
fi
cd "$ROOT_DIR"

echo "[info] Repo root: $ROOT_DIR"

# 1) Clean extension build outputs (scons -c)
if command -v scons >/dev/null 2>&1; then
  echo "[clean] scons -c in build/"
  (cd build && scons -c || true)
else
  echo "[warn] scons not found; skip scons -c"
fi

# 2) Clean godot-cpp build outputs
if [[ -f godot-cpp/SConstruct ]]; then
  if command -v scons >/dev/null 2>&1; then
    echo "[clean] scons -c in godot-cpp/"
    (cd godot-cpp && scons -c || true)
  fi
fi

# 3) Remove demo/bin
if [[ -d demo/bin ]]; then
  echo "[clean] rm -rf demo/bin/*"
  rm -rf demo/bin/* || true
fi

# 4) Remove heavy thirdparty build caches (safe targeted)
for p in \
  thirdparty/rive-cpp/build \
  thirdparty/rive-cpp/skia/renderer/build \
  thirdparty/rive-cpp/skia/dependencies/skia/out
do
  if [[ -d "$p" ]]; then
    echo "[clean] rm -rf $p"
    rm -rf "$p" || true
  fi
done

# 5) Optional: enable sparse-checkout
if [[ ${1:-} == "--sparse" || ${2:-} == "--sparse" ]]; then
  if command -v git >/dev/null 2>&1; then
    echo "[sparse] enabling sparse-checkout to exclude heavy directories..."
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "[error] not a git repo"; exit 1; }
    git sparse-checkout init --no-cone || true
    git sparse-checkout set "/*" \
      "!/thirdparty/rive-cpp/skia/dependencies/skia/third_party/externals/*" \
      "!/thirdparty/rive-cpp/skia/dependencies/skia/out/*" \
      "!/thirdparty/rive-cpp/skia/renderer/build/*" \
      "!/thirdparty/rive-cpp/build/*" \
      "!/godot-cpp/bin/*"
    echo "[sparse] applied. To restore full tree: scripts/restore_full.sh"
  else
    echo "[warn] git not found, skip sparse-checkout"
  fi
fi

# 6) Optional: deep clean with git clean -xfd on selected dirs only
if [[ ${1:-} == "--deep" || ${2:-} == "--deep" ]]; then
  if command -v git >/dev/null 2>&1; then
    echo "[deep] git clean -xfd on selected directories (with exclusions)"
    # Limit scope to known build output dirs to avoid accidental deletions.
    for scope in demo/bin godot-cpp/bin thirdparty/rive-cpp/build thirdparty/rive-cpp/skia/renderer/build thirdparty/rive-cpp/skia/dependencies/skia/out; do
      if [[ -d "$scope" ]]; then
        echo "  - cleaning $scope"
        git clean -xfd -e scripts/ -- "$scope" || true
      fi
    done
  else
    echo "[warn] git not found, skip deep clean"
  fi
fi

echo "[done] Local cleanup complete."


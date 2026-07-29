#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${COBIE_ITERATION_ID:-}" ]]; then
  echo "Set COBIE_ITERATION_ID (for example I01)." >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

export COBIE_V2_STAGE="${COBIE_V2_STAGE:-final}"
export COBIE_RENDER_ID="cover-v2/${COBIE_ITERATION_ID}-neutral"
export COBIE_LOOKDEV_ID="cover-v2/${COBIE_ITERATION_ID}-lookdev"
export COBIE_RENDER_BASELINE_ID="${COBIE_RENDER_BASELINE_ID:-prototype-v1}"

UV=(uv run --project cobie-collectible/tools --locked)
BLENDER="/Applications/Blender.app/Contents/MacOS/Blender"

"${UV[@]}" python cobie-collectible/scripts/build_figurine_v2.py
"${BLENDER}" --background \
  --python cobie-collectible/scripts/validate_refinement_master.py
"${UV[@]}" python cobie-collectible/tests/test_collectible.py
"${UV[@]}" python cobie-collectible/scripts/print_check.py
"${UV[@]}" python cobie-collectible/scripts/slicer_import_check.py
"${UV[@]}" python cobie-collectible/scripts/render_figurine.py
"${UV[@]}" python cobie-collectible/scripts/compare_figurine_renders.py
"${UV[@]}" python cobie-collectible/scripts/render_figurine_lookdev.py

echo "COBIE_REFINEMENT_ITERATION: PASS (${COBIE_ITERATION_ID}, ${COBIE_V2_STAGE})"
echo "Visual review and a ratings/${COBIE_ITERATION_ID}.json packet are still required."

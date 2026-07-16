#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUN_PREFIX="${1:-motion-$(date -u +%Y%m%dT%H%M%SZ)}"

for fps in 30 60 120; do
  "$SCRIPT_DIR/capture.sh" \
    --view salmon_sports_field \
    --view salmon_walker_arena \
    --aspect 1280x720 \
    --render-fps "$fps" \
    --physics-tps 60 \
    --run-id "${RUN_PREFIX}-${fps}fps"
done

"$SCRIPT_DIR/capture.sh" \
  --view salmon_sports_field \
  --view salmon_walker_arena \
  --aspect 1280x720 \
  --render-fps 60 \
  --physics-tps 10 \
  --run-id "${RUN_PREFIX}-10tps-diagnostic"
echo "Motion matrix complete under builds/visual-quality/candidates/${RUN_PREFIX}-*"

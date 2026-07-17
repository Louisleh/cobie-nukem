#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-/opt/homebrew/bin/godot}"
OUTPUT_DIR="${1:-docs/evidence/agentic-overhaul/native-route}"
CAPTURE_WIDTH="${CAPTURE_WIDTH:-1280}"
CAPTURE_HEIGHT="${CAPTURE_HEIGHT:-720}"
CAPTURE_FPS="${CAPTURE_FPS:-30}"
CAPTURE_PHYSICS_TPS="${CAPTURE_PHYSICS_TPS:-60}"
CAPTURE_FORCE_TOUCH="${CAPTURE_FORCE_TOUCH:-0}"
CAPTURE_SEED="${CAPTURE_SEED:-2026071601}"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
CAPTURE_PROJECT="$TEMP_DIR/project"
CAPTURE_HOME="$TEMP_DIR/home"

mkdir -p "$OUTPUT_DIR" "$CAPTURE_HOME"
python3 tools/visual_quality/prepare_capture_project.py "$PWD" "$CAPTURE_PROJECT" "$CAPTURE_WIDTH" "$CAPTURE_HEIGHT"

user_args=(--capture-size="${CAPTURE_WIDTH}x${CAPTURE_HEIGHT}" --capture-seed="$CAPTURE_SEED" --physics-tps="$CAPTURE_PHYSICS_TPS")
if [[ "$CAPTURE_FORCE_TOUCH" == "1" ]]; then
  user_args+=(--force-touch)
fi

HOME="$CAPTURE_HOME" "$GODOT_BIN" --path "$CAPTURE_PROJECT" --resolution "${CAPTURE_WIDTH}x${CAPTURE_HEIGHT}" \
  --write-movie "$TEMP_DIR/capture.png" --fixed-fps "$CAPTURE_FPS" --quit-after 220 \
  res://scenes/debug/vertical_slice_capture.tscn -- "${user_args[@]}"

copy_frame() {
  local frame="$1"
  local name="$2"
  local source
  source="$(printf '%s/capture%08d.png' "$TEMP_DIR" "$frame")"
  [[ -s "$source" ]] || { echo "ERROR missing capture frame $frame"; exit 1; }
  cp "$source" "$OUTPUT_DIR/$name.png"
}

copy_frame 10 00-salmon-opening
copy_frame 25 01-forbidden-field
copy_frame 55 02-equipment-shed
copy_frame 85 03-maintenance-tunnels
copy_frame 115 04-compliance-lab
copy_frame 145 05-walker-arena
copy_frame 150 05b-walker-defeat
copy_frame 175 06-death
copy_frame 205 07-victory

echo "Native route evidence captured in $OUTPUT_DIR (${CAPTURE_WIDTH}x${CAPTURE_HEIGHT}, render ${CAPTURE_FPS} FPS, physics ${CAPTURE_PHYSICS_TPS} TPS)"

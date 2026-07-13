#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-/opt/homebrew/bin/godot}"
OUTPUT_DIR="${1:-docs/evidence/agentic-overhaul/native-route}"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

mkdir -p "$OUTPUT_DIR"

"$GODOT_BIN" --path . --resolution 1280x720 \
  --write-movie "$TEMP_DIR/capture.png" --fixed-fps 30 --quit-after 220 \
  res://scenes/debug/vertical_slice_capture.tscn

copy_frame() {
  local frame="$1"
  local name="$2"
  local source
  source="$(printf '%s/capture%08d.png' "$TEMP_DIR" "$frame")"
  [[ -s "$source" ]] || { echo "ERROR missing capture frame $frame"; exit 1; }
  cp "$source" "$OUTPUT_DIR/$name.png"
}

copy_frame 25 01-forbidden-field
copy_frame 55 02-equipment-shed
copy_frame 85 03-maintenance-tunnels
copy_frame 115 04-compliance-lab
copy_frame 145 05-walker-arena
copy_frame 175 06-death
copy_frame 205 07-victory

echo "Native route evidence captured in $OUTPUT_DIR"

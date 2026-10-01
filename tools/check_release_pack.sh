#!/usr/bin/env bash
set -euo pipefail

fail() { echo "ERROR: $*" >&2; exit 1; }

[[ $# -eq 1 ]] || fail "release pack check requires exactly one file path"
pack_path="$1"
[[ -f "$pack_path" && -r "$pack_path" && -s "$pack_path" ]] \
  || fail "release pack is not a readable nonempty regular file: $pack_path"
# Prevent a relative filename beginning with '-' from becoming a tool option.
[[ "$pack_path" != -* ]] || pack_path="./$pack_path"
for tool in strings grep mktemp rm; do
  command -v "$tool" >/dev/null 2>&1 || fail "release pack check requires $tool"
done

scan_file="$(mktemp)" || fail "could not allocate release pack scan file"
trap 'rm -f "$scan_file"' EXIT
trap 'exit 1' HUP INT TERM

# Finish the producer before searching. An early grep -q match must never
# SIGPIPE strings and turn a forbidden match into a false no-match.
if strings "$pack_path" >"$scan_file"; then
  :
else
  status=$?
  fail "release pack strings extraction failed (exit $status): $pack_path"
fi

forbidden_markers=(
  "godot_ai_bridge"
  "GodotAIBridgeRuntime"
  "production_asset_gallery"
  "vertical_slice_capture"
  "assets/models/pilot"
  "assets/sprites/experiments"
  "docs/evidence"
  "cobie_production_pilot.blend"
  "/Users/louislehmann"
)
for marker in "${forbidden_markers[@]}"; do
  search_status=0
  grep -Fq "$marker" "$scan_file" || search_status=$?
  case "$search_status" in
    0) fail "forbidden development marker entered release pack $pack_path: $marker" ;;
    1) ;; # A completed search found no forbidden marker.
    *) fail "release pack marker search failed (exit $search_status): $pack_path" ;;
  esac
done
echo "RELEASE PACK CHECK: PASS ($pack_path)"

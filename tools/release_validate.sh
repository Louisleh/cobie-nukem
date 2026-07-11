#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-/opt/homebrew/bin/godot}"
if [[ ! -x "$GODOT_BIN" ]]; then
  GODOT_BIN="$(command -v godot || command -v godot4 || true)"
fi
if [[ -z "$GODOT_BIN" || ! -x "$GODOT_BIN" ]]; then
  echo "ERROR: Godot 4.7 executable not found. Set GODOT_BIN."
  exit 1
fi
if [[ "$($GODOT_BIN --version)" != 4.7.* ]]; then
  echo "ERROR: release validation requires Godot 4.7 stable."
  "$GODOT_BIN" --version
  exit 1
fi

run_godot_test() {
  local script="$1"
  echo "==> $script"
  "$GODOT_BIN" --headless --path . --script "$script"
}

echo "==> import/parser validation"
"$GODOT_BIN" --headless --path . --editor --quit
run_godot_test res://tests/run_tests.gd
run_godot_test res://tests/unit/input_system_test.gd
run_godot_test res://tests/unit/combat_test_runner.gd
run_godot_test res://tests/unit/enemy_contract_tests.gd
run_godot_test res://tests/unit/ui_scene_test.gd
run_godot_test res://tests/unit/gameplay_foundation_test.gd
run_godot_test res://tests/integration/integration_test_runner.gd
run_godot_test res://tests/integration/test_episode_1_level.gd
run_godot_test res://tests/smoke/smoke_test_runner.gd
run_godot_test res://tests/smoke/performance_smoke.gd
bash tools/asset_ip_scan.sh
run_godot_test res://tools/validate_content.gd

required_release_paths=(
  docs/PRD.md
  docs/QA_PLAN.md
  docs/ASSET_MANIFEST.md
  docs/KNOWN_ISSUES.md
  export_presets.cfg
  assets/brand/cobie_nukem_cover.png
)
for path in "${required_release_paths[@]}"; do
  [[ -s "$path" ]] || { echo "ERROR required release path missing/empty: $path"; exit 1; }
done

if ! find scenes/menus -type f -name '*.tscn' -print -quit 2>/dev/null | grep -q .; then
  echo "ERROR release requires at least one menu scene."
  exit 1
fi
if ! find scenes/levels -type f -name '*.tscn' -print -quit 2>/dev/null | grep -q .; then
  echo "ERROR release requires at least one playable level scene."
  exit 1
fi

if [[ "${QA_EXPORTS:-0}" == "1" ]]; then
  echo "==> release exports"
  mkdir -p builds/web builds/macos
  "$GODOT_BIN" --headless --path . --export-release Web builds/web/index.html
  "$GODOT_BIN" --headless --path . --export-release macOS builds/macos/CobieNukem.zip
  test -s builds/web/index.html
  test -s builds/macos/CobieNukem.zip
else
  echo "SKIP exports (set QA_EXPORTS=1 for release artifacts)"
fi

echo "Automated release validation passed. Complete docs/MANUAL_UX_CHECKLIST.md before release."
